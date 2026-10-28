local Snapshot=require 'PZHarness/Snapshot'
-- Test-only server orchestration. Both participants are real network clients.
local ready, players, started, finished = {}, {}, false, false
local round, verified, completed, firstRewards = 1, {}, {}, {}
local worldBefore,worldOpts,startedAt
local modCommands=0
local nativeCommand=sendServerCommand
sendServerCommand=function(player,module,command,args)
    if module=="DinnerTogether" then modCommands=modCommands+1 end
    return nativeCommand(player,module,command,args)
end
local complete = ISEatFoodAction.complete
function ISEatFoodAction:complete()
    local before=self.character:getStats():get(CharacterStat.HUNGER)
    local result = complete(self)
    assert(result and before-self.character:getStats():get(CharacterStat.HUNGER)>=0.05,'Fixture food was not consumed')
    local name = self.character:getUsername()
    completed[name] = (completed[name] or 0)+1
    print('PZ_TEST_PASS server food completion '..name..' item='..self.item:getID()..' count='..completed[name])
    return result
end
Events.OnServerStarted.Add(function() print('PZ_TEST_SERVER_UP') end)
Events.OnClientCommand.Add(function(module, command, player)
    if module ~= 'DinnerProbe' then return end
    if command == 'verified' then
        verified[player:getUsername()] = true
        if verified.Alice and verified.Beth then
            if round == (PZ_TEST_ROUNDS or 1) then
                print('PZ_TEST_SERVER_PASS rounds=' .. round)
            else
                round=round+1; ready={}; verified={}; started=false; finished=false
                for name,p in pairs(players) do
                    if not (PZ_TEST_RECONNECT and name=='Beth') then sendServerCommand(p,'DinnerProbe','reset',{}) end
                end
                if PZ_TEST_RECONNECT then print('PZ_TEST_RECONNECT_READY') end
            end
        end
    end
    if command == 'ready' then
        ready[player:getUsername()] = true
        players[player:getUsername()] = player
    end
end)
Events.OnTick.Add(function()
    if ready.Alice and ready.Beth and not started then
        started = true
        startedAt=getTimestampMs()
        if round==1 then
            local rewards=ModData.getOrCreate('DinnerTogetherRewards')
            assert(not rewards.Alice and not rewards.Beth,'Forged client command awarded a meal')
            print('PZ_TEST_PASS forged client meal commands had no authority')
        end
        local anchor=players.Alice
        worldOpts={x=math.floor(anchor:getX()),y=math.floor(anchor:getY()),z=math.floor(anchor:getZ()),radius=4,levels={math.floor(anchor:getZ())},ignore=Snapshot.DEFAULT_IGNORE}
        worldBefore=Snapshot.take(worldOpts)
        for _, name in ipairs({'Alice', 'Beth'}) do
            local p = players[name]
            p:setInvincible(true); p:setGhostMode(true)
            if PZ_TEST_PHOTOS then
                getGameTime():setTimeOfDay(20.5)
                local shirt=name=='Alice' and 'Base.Shirt_Lumberjack' or 'Base.Jumper_RoundNeck'
                for _,kind in ipairs({shirt,'Base.Trousers_Denim','Base.Shoes_TrainerTINT'}) do
                    local clothing=assert(p:getInventory():AddItem(kind),kind)
                    if kind==shirt then
                        clothing:getVisual():setTint(name=='Alice' and ImmutableColor.new(0.35,0.50,0.30) or ImmutableColor.new(0.65,0.35,0.22))
                    end
                    sendAddItemToContainer(p:getInventory(),clothing)
                    p:setWornItem(clothing:getBodyLocation(),clothing)
                    sendClothing(p,clothing:getBodyLocation(),clothing)
                end
                syncVisuals(p);syncClothingFields(p)
            end
            p:getStats():set(CharacterStat.HUNGER, 0.8)
            p:getStats():set(CharacterStat.BOREDOM, 50)
            p:getStats():set(CharacterStat.UNHAPPINESS, 50)
            for _, stat in ipairs({CharacterStat.HUNGER, CharacterStat.BOREDOM, CharacterStat.UNHAPPINESS}) do
                syncPlayerStats(p, SyncPlayerStatsPacket.getBitMaskForStat(stat))
            end
            local food = p:getInventory():AddItem('Base.Apple')
            sendAddItemToContainer(p:getInventory(), food)
            sendServerCommand(p, 'DinnerProbe', 'eat', {foodID=food:getID(),round=round})
        end
        print('PZ_TEST_PASS two connected clients ready at ' .. players.Alice:getX() .. ',' .. players.Alice:getY()
            .. ' and ' .. players.Beth:getX() .. ',' .. players.Beth:getY())
    end
    if started and not finished then
        if getTimestampMs()-startedAt>30000 then
            finished=true
            print('PZ_TEST_FAIL food actions timed out: Alice='..(completed.Alice or 0)..' Beth='..(completed.Beth or 0)..' round='..round)
            return
        end
        local rewards = ModData.getOrCreate('DinnerTogetherRewards')
        if rewards.Alice and rewards.Beth and (completed.Alice or 0)>=round and (completed.Beth or 0)>=round then
            finished = true
            assert(modCommands==2,'Unexpected production notification count: '..modCommands)
            local world=Snapshot.take(worldOpts)
            if not PZ_TEST_PHOTOS then
                local leaks=Snapshot.addLines({},Snapshot.diff(worldBefore,world))
                assert(#leaks==0,table.concat(leaks,'; '))
            end
            local tiles={}
            for key,signature in pairs(world.squares) do tiles[Snapshot.where(key)]=Snapshot.syncSignature(signature) end
            for _, p in pairs(players) do
                local stats = p:getStats()
                if stats:get(CharacterStat.BOREDOM)>51 or math.abs(stats:get(CharacterStat.UNHAPPINESS)-(round==1 and 47 or 50))>1 then
                    print('PZ_TEST_FAIL authoritative stats differ for ' .. p:getUsername() .. ': ' .. stats:get(CharacterStat.BOREDOM) .. ',' .. stats:get(CharacterStat.UNHAPPINESS))
                    return
                end
                local name=p:getUsername()
                if round==1 then firstRewards[name]=rewards[name] else assert(rewards[name]==firstRewards[name], 'Cooldown reset between rounds') end
                sendServerCommand(p,'DinnerProbe','expected',{round=round,final=round==(PZ_TEST_ROUNDS or 1),boredom=stats:get(CharacterStat.BOREDOM),unhappiness=stats:get(CharacterStat.UNHAPPINESS),notices=(PZ_TEST_RECONNECT and round==2 and name=='Beth') and 0 or 1,tiles=tiles,world={x=worldOpts.x,y=worldOpts.y,z=worldOpts.z,radius=4}})
            end
            print('PZ_TEST_ROUND_PASS ' .. round .. ' both real food actions completed')
        end
    end
end)

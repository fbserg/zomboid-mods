-- Test-only server orchestration. Both participants are real network clients.
local ready, players, started, finished = {}, {}, false, false
local round, verified, completed, firstRewards = 1, {}, {}, {}
local complete = ISEatFoodAction.complete
function ISEatFoodAction:complete()
    local result = complete(self)
    local name = self.character:getUsername()
    completed[name] = (completed[name] or 0)+1
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
                for _,p in pairs(players) do sendServerCommand(p,'DinnerProbe','reset',{}) end
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
        for _, name in ipairs({'Alice', 'Beth'}) do
            local p = players[name]
            p:setInvincible(true); p:setGhostMode(true)
            if PZ_TEST_PHOTOS then
                getGameTime():setTimeOfDay(12)
                for _,kind in ipairs({'Base.Shirt_FormalWhite','Base.Trousers_Denim','Base.Shoes_TrainerTINT'}) do
                    local clothing=assert(p:getInventory():AddItem(kind),kind)
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
            sendServerCommand(p, 'DinnerProbe', 'eat', {})
        end
        print('PZ_TEST_PASS two connected clients ready at ' .. players.Alice:getX() .. ',' .. players.Alice:getY()
            .. ' and ' .. players.Beth:getX() .. ',' .. players.Beth:getY())
    end
    if started and not finished then
        local rewards = ModData.getOrCreate('DinnerTogetherRewards')
        if rewards.Alice and rewards.Beth and (completed.Alice or 0)>=round and (completed.Beth or 0)>=round then
            finished = true
            for _, p in pairs(players) do
                local stats = p:getStats()
                if stats:get(CharacterStat.BOREDOM)>51 or math.abs(stats:get(CharacterStat.UNHAPPINESS)-(round==1 and 47 or 50))>1 then
                    print('PZ_TEST_FAIL authoritative stats differ for ' .. p:getUsername() .. ': ' .. stats:get(CharacterStat.BOREDOM) .. ',' .. stats:get(CharacterStat.UNHAPPINESS))
                    return
                end
                local name=p:getUsername()
                if round==1 then firstRewards[name]=rewards[name] else assert(rewards[name]==firstRewards[name], 'Cooldown reset between rounds') end
                sendServerCommand(p,'DinnerProbe','expected',{round=round,final=round==(PZ_TEST_ROUNDS or 1),boredom=stats:get(CharacterStat.BOREDOM),unhappiness=stats:get(CharacterStat.UNHAPPINESS)})
            end
            print('PZ_TEST_ROUND_PASS ' .. round .. ' both real food actions completed')
        end
    end
end)

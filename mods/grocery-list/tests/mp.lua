local Snapshot=require 'PZHarness/Snapshot'
-- Test-only server orchestration. Both participants are real network clients.
-- Alice writes through the vanilla journal window. The fixture moves the list between players
-- and hands Beth the groceries. The mod's own EveryOneMinute scan does everything else.
local TYPE='SharedGroceryList.GroceryList'
local ROUNDS={
    {text='Canned beans\n- apples\n2 x rice\nbatteries', items={'Base.TinnedBeans','Base.Apple','Base.Rice','Base.Battery'}},
    {text='milk\nflour\nsugar', items={'Base.Milk','Base.Flour2','Base.Sugar'}},
}
local players,ready,verified={},{},{}
local round,step,list,startedAt=1,nil,nil,nil
local worldBefore,worldOpts
local commands={}
local nativeCommand=sendServerCommand
sendServerCommand=function(player,module,command,args)
    if module=='SharedGroceryList' then
        local key=player:getUsername()..':'..command
        commands[key]=(commands[key] or 0)+1
    end
    return nativeCommand(player,module,command,args)
end
local function give(p,kind)
    local item=assert(p:getInventory():AddItem(kind),kind)
    sendAddItemToContainer(p:getInventory(),item)
    return item
end
local function move(from,to)
    from:getInventory():Remove(list);sendRemoveItemFromContainer(from:getInventory(),list)
    to:getInventory():AddItem(list);sendAddItemToContainer(to:getInventory(),list)
end
Events.OnServerStarted.Add(function()
    assert(SandboxVars.Zombies==6 and SandboxVars.ZombieConfig.PopulationMultiplier==0,'List test world must have zero zombie population')
    print('PZ_TEST_ZERO_POPULATION_PASS');print('PZ_TEST_SERVER_UP')
end)
Events.OnClientCommand.Add(function(module,command,player)
    if module~='GroceryProbe' then return end
    local name=player:getUsername()
    if command=='ready' then ready[name]=true;players[name]=player;print('PZ_TEST_READY '..name..' round='..round) end
    if command=='written' then step='written' end
    if command=='marks' then step='marks' end
    if command=='verified' then
        verified[name]=true
        if verified.Alice and verified.Beth then
            if round==(PZ_TEST_ROUNDS or 1) then
                print('PZ_TEST_SERVER_PASS rounds='..round)
            else
                round=round+1;ready={};verified={};step=nil;commands={}
                for n,p in pairs(players) do
                    if not (PZ_TEST_RECONNECT and n=='Beth') then sendServerCommand(p,'GroceryProbe','reset',{}) end
                end
                if PZ_TEST_RECONNECT then print('PZ_TEST_RECONNECT_READY') end
            end
        end
    end
end)
Events.OnTick.Add(function()
    if ready.Alice and ready.Beth and not step then
        step='write';startedAt=getTimestampMs()
        if round==1 then
            for id in pairs(ModData.getOrCreate('SharedGroceryListRewards')) do error('Forged client command awarded '..id) end
            print('PZ_TEST_PASS forged client reward commands had no authority')
        end
        local anchor=players.Alice
        worldOpts={x=math.floor(anchor:getX()),y=math.floor(anchor:getY()),z=math.floor(anchor:getZ()),radius=4,levels={math.floor(anchor:getZ())},ignore=Snapshot.DEFAULT_IGNORE}
        worldBefore=Snapshot.take(worldOpts)
        for _,name in ipairs({'Alice','Beth'}) do
            local p=players[name]
            p:setInvincible(true);p:setGhostMode(true)
            if PZ_TEST_PHOTOS then
                getGameTime():setTimeOfDay(18.0)
                -- Beth shops in a denim shirt and beanie like the illustration. Alice gets a tinted jumper.
                local outfit=name=='Alice' and {'Base.Jumper_RoundNeck','Base.Trousers_Denim','Base.Shoes_TrainerTINT'}
                    or {'Base.Shirt_Denim','Base.Hat_Beany','Base.Trousers_Denim','Base.Shoes_TrainerTINT'}
                for _,kind in ipairs(outfit) do
                    local clothing=give(p,kind)
                    if kind=='Base.Jumper_RoundNeck' then clothing:getVisual():setTint(ImmutableColor.new(0.80,0.60,0.20)) end
                    p:setWornItem(clothing:getBodyLocation(),clothing)
                    sendClothing(p,clothing:getBodyLocation(),clothing)
                end
                syncVisuals(p);syncClothingFields(p)
            end
            p:getStats():set(CharacterStat.BOREDOM,50);p:getStats():set(CharacterStat.UNHAPPINESS,50)
            for _,stat in ipairs({CharacterStat.BOREDOM,CharacterStat.UNHAPPINESS}) do
                syncPlayerStats(p,SyncPlayerStatsPacket.getBitMaskForStat(stat))
            end
            sendServerCommand(p,'GroceryProbe','round',{round=round})
        end
        if round==1 then give(players.Alice,'Base.Pen') end
        list=give(players.Alice,TYPE)
        sendServerCommand(players.Alice,'GroceryProbe','write',{id=list:getID(),text=ROUNDS[round].text})
        print('PZ_TEST_PASS round '..round..' blank list handed to Alice item='..list:getID())
    end
    if not step or step=='checked' then return end
    if getTimestampMs()-startedAt>60000 then
        step='checked'
        print('PZ_TEST_FAIL round '..round..' timed out at step '..tostring(step)..' page='..tostring(list and list:seePage(1)))
        return
    end
    local data=list:getModData()
    if step=='written' and list:seePage(1)==ROUNDS[round].text and data.author=='Alice' then
        print('PZ_TEST_PASS server received the page from the vanilla write window and credited Alice')
        move(players.Alice,players.Beth)
        for _,kind in ipairs(ROUNDS[round].items) do give(players.Beth,kind) end
        step='shopping'
    elseif step=='shopping' and data.done then
        assert(data.shopper=='Beth' and not data.delivered,'Wrong shopper or early delivery')
        sendServerCommand(players.Beth,'GroceryProbe','checkMarks',{id=list:getID(),count=#ROUNDS[round].items})
        step='marking'
    elseif step=='marks' then
        print('PZ_TEST_PASS Beth finished the list and her client shows every crossed-off line')
        move(players.Beth,players.Alice)
        step='delivering'
    elseif step=='delivering' and data.delivered then
        step='checked'
        local items=#ROUNDS[round].items
        local expected={['Beth:got']=items,['Beth:done']=1,['Beth:delivered']=1,['Alice:thanks']=1}
        for key,n in pairs(commands) do assert(expected[key]==n,'Unexpected notification '..key..'='..n) end
        for key,n in pairs(expected) do assert(commands[key]==n,'Missing notification '..key) end
        local page=list:seePage(1)
        local signature='~ '..players.Beth:getDescriptor():getForename()..' <3'
        assert(page:sub(-#signature)==signature,'Server page was not signed by Beth\'s character: '..page)
        local world=Snapshot.take(worldOpts)
        if not PZ_TEST_PHOTOS then
            local leaks=Snapshot.addLines({},Snapshot.diff(worldBefore,world))
            assert(#leaks==0,table.concat(leaks,'; '))
        end
        -- Round 1 pays: Beth -10 boredom, -15 unhappiness. Alice -10 unhappiness. Round 2 is inside the cooldown.
        local want=round==1 and {Alice={50,40},Beth={40,35}} or {Alice={50,50},Beth={50,50}}
        for name,p in pairs(players) do
            local stats=p:getStats()
            local b,u=stats:get(CharacterStat.BOREDOM),stats:get(CharacterStat.UNHAPPINESS)
            -- Natural drift stays well under the 10-point rewards. A missing or extra payout still fails.
            assert(math.abs(b-want[name][1])<=4 and math.abs(u-want[name][2])<=4,'Authoritative stats for '..name..': '..b..','..u)
            local notices=0
            for key,n in pairs(commands) do if key:sub(1,#name+1)==name..':' then notices=notices+n end end
            if PZ_TEST_RECONNECT and round==2 and name=='Beth' then print('PZ_TEST_PASS reconnected Beth kept her username cooldown') end
            sendServerCommand(p,'GroceryProbe','expected',{round=round,final=round==(PZ_TEST_ROUNDS or 1),boredom=b,unhappiness=u,
                notices=notices,page=name=='Alice' and page or nil,id=list:getID()})
        end
        print('PZ_TEST_ROUND_PASS '..round..' list written, shopped, marked, handed back and signed')
    end
end)

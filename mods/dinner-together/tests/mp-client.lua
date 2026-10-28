local role = '@ROLE@'
Events.OnMainMenuEnter.Add(function()
    getCore():setOptionShowSurvivalGuide(false)
    getCore():setTutorialDone(true)
    serverConnect(role, 'test-only', '127.0.0.1', '127.0.0.1', '16511', '', 'pz-test', false, true, 1, '')
end)
Events.OnConnected.Add(function()
    local region = assert(MapSpawnSelect.instance:useDefaultSpawnRegion(), 'No spawn region')
    setSpawnRegion(region.name)
    getWorld():setMap("Muldraugh, KY")
    getWorld():setLuaPlayerDesc(SurvivorFactory.CreateSurvivor())
    GameWindow.doRenderEvent(false)
    forceChangeState(LoadingQueueState.new())
end)
Events.OnConnectFailed.Add(function(message) print('PZ_TEST_FAIL connect ' .. role .. ' ' .. tostring(message)) end)
local ticks, sent, eat, queued, notified, done = 0, false, false, false, false, false
local expected
local notices=0
Events.OnGameStart.Add(function()
    -- The mod Lua state is rebuilt during connection. Capture the actual production notification.
    local info=assert(getModInfoByID('DinnerTogether'),'Mod panel metadata missing')
    assert(info:getModVersion()=='0.1.0' and info:getPosterCount()==3,'Wrong mod panel version/posters')
    assert(getTexture(info:getIcon()),'Mod icon does not load')
    for i=0,info:getPosterCount()-1 do assert(getTexture(info:getPoster(i)),'Mod poster does not load') end
    print('PZ_TEST_PASS mod panel icon and three posters decoded '..role)
    local show = DinnerTogether.show
    DinnerTogether.show = function(player)
        show(player)
        notified = true; notices=notices+1
        print('PZ_TEST_PASS translated notification ' .. role .. ' ' .. getText('IGUI_DinnerTogether_SharedMeal'))
    end
end)
Events.OnServerCommand.Add(function(module, command, args)
    if module == 'DinnerProbe' and command == 'reset' then ticks=0; sent=false; eat=false; queued=false; expected=nil; done=false end
    if module == 'DinnerProbe' and command == 'eat' then eat = true end
    if module == 'DinnerProbe' and command == 'expected' then expected = args end
end)
Events.OnTick.Add(function()
    local p = getSpecificPlayer(0)
    if not p or not isClient() or done then return end
    ticks = ticks+1
    if ticks > 180 and not sent then
        sent = true
        for _,stat in ipairs({CharacterStat.BOREDOM,CharacterStat.UNHAPPINESS}) do p:getStats():set(stat,50) end
        p:getStats():set(CharacterStat.HUNGER,0.8)
        sendClientCommand(p, 'DinnerProbe', 'ready', {})
    end
    if eat and not queued then
        local food = p:getInventory():getFirstType('Base.Apple')
        if food then
            queued = true
            ISTimedActionQueue.add(ISEatFoodAction:new(p, food, 1))
            print('PZ_TEST_PASS queued vanilla food action ' .. role)
        end
    end
    if notified and expected then
        local stats = p:getStats()
        if math.abs(stats:get(CharacterStat.BOREDOM)-expected.boredom)<1 and math.abs(stats:get(CharacterStat.UNHAPPINESS)-expected.unhappiness)<1 then
            assert(getText('IGUI_DinnerTogether_SharedMeal') == 'A meal with good company', 'Translation did not load')
            assert(notices==1, 'Duplicate reward notification')
            print((expected.final and 'PZ_TEST_CLIENT_PASS ' or 'PZ_TEST_ROUND_CLIENT_PASS ') .. role .. ' round=' .. expected.round .. ' stats synced, notices=' .. notices)
            sendClientCommand(p,'DinnerProbe','verified',{})
            done = true
        end
    end
end)

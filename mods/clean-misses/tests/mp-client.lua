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
local sent = false
Events.OnTick.Add(function()
    local player = getSpecificPlayer(0)
    if sent or not player or not isClient() then return end
    local config = getCombatConfig()
    local slope = config:get(CombatConfigKey.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY)
    local increment = config:get(CombatConfigKey.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY_INCREMENT)
    sendClientCommand(player, "CleanMissesProbe", "report", { slope=slope, increment=increment })
    sent=true
end)
Events.OnServerCommand.Add(function(module,command)
    if module=="CleanMissesProbe" and command=="accepted" then
        print("PZ_TEST_CLIENT_PASS "..role)
    end
end)

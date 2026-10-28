-- Loopback multiplayer join in a disposable clone of the game. Never installed.
Events.OnMainMenuEnter.Add(function()
    getCore():setOptionShowSurvivalGuide(false)
    getCore():setTutorialDone(true)
    print("BIRDS_MP_CONNECTING")
    serverConnect("admin", "birds-test-local-only", "127.0.0.1", "127.0.0.1", "16491", "", "birds-mp", false, true, 1, "")
end)

Events.OnConnected.Add(function()
    print("BIRDS_MP_CONNECTED")
    if checkSavePlayerExists() then return end
    local region = assert(MapSpawnSelect.instance:useDefaultSpawnRegion(), "Server sent no spawn region")
    setSpawnRegion(region.name)
    getWorld():setLuaPlayerDesc(SurvivorFactory.CreateSurvivor())
    GameWindow.doRenderEvent(false)
    forceChangeState(LoadingQueueState.new())
end)

Events.OnConnectFailed.Add(function(message, detail)
    print("BIRDS_MP_CLIENT_FAIL connect " .. tostring(message) .. " " .. tostring(detail))
end)

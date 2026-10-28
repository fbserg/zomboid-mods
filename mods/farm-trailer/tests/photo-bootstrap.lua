-- Native test setup in a disposable clone of the game. Never installed.
print("FARM_PHOTO_BOOTSTRAP_LOADED")
Events.OnMainMenuEnter.Add(function()
    print("FARM_PHOTO_MAIN_MENU")
    local mods = ActiveMods.getById("currentGame")
    for _, id in ipairs({"damnlib", "KI5trailers", "PROJECTRVInterior42", "FarmTrailer", "FarmPhotos"}) do mods:setModActive(id, true) end
    mods:getMapOrder():clear()
    mods:getMapOrder():add("map_distanciado")
    mods:getMapOrder():add("Muldraugh, KY")
    if ActiveMods.requiresResetLua(mods) then
        getCore():ResetLua("currentGame", "farmPhotos")
        return
    end
    getCore():setOptionShowSurvivalGuide(false)
    getCore():setTutorialDone(true)
    local world = getWorld()
    world:setGameMode("Sandbox")
    world:setWorld("FarmTrailerPhotos")
    world:setMap("map_distanciado;Muldraugh, KY")
    world:setLuaPlayerDesc(SurvivorFactory.CreateSurvivor())
    world:setLuaPosX(22566); world:setLuaPosY(12520); world:setLuaPosZ(0)
    createWorld("FarmTrailerPhotos")
    GameWindow.doRenderEvent(false)
    print("FARM_PHOTO_WORLD_LOADING")
    forceChangeState(LoadingQueueState.new())
end)

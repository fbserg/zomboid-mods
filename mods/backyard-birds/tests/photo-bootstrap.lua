-- Native test setup in a disposable clone of the game. Never installed.
Events.OnMainMenuEnter.Add(function()
    local mods = ActiveMods.getById("currentGame")
    for _, id in ipairs({"BackyardBirds", "BirdPhotos"}) do mods:setModActive(id, true) end
    mods:getMapOrder():clear()
    mods:getMapOrder():add("Muldraugh, KY")
    if ActiveMods.requiresResetLua(mods) then
        getCore():ResetLua("currentGame", "birdPhotos")
        return
    end
    getCore():setOptionShowSurvivalGuide(false)
    getCore():setTutorialDone(true)
    local world = getWorld()
    world:setGameMode("Sandbox")
    world:setWorld("BackyardBirdsPhotos")
    world:setMap("Muldraugh, KY")
    world:setLuaPlayerDesc(SurvivorFactory.CreateSurvivor())
    world:setLuaPosX(10628); world:setLuaPosY(10650); world:setLuaPosZ(0)
    createWorld("BackyardBirdsPhotos")
    GameWindow.doRenderEvent(false)
    print("BIRDS_PHOTO_WORLD_LOADING")
    forceChangeState(LoadingQueueState.new())
end)

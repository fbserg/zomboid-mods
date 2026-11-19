-- Demonstration setup only. Appended to the two real network clients by --photos.
-- Alice captures the real note beside the staged horde, then the real Mod Options page.
local photoTicks, hordeAt, optionsAt, finished = 0, nil, nil, false
Events.OnGameStart.Add(function()
    getCore():setAutoZoom(0, false)
    for i = 1, 4 do getCore():doZoomScroll(0, -1) end
    getGameTime():setTimeOfDay(14.0)
    ISUIHandler.setVisibleAllUI(false)
    getClimateManager():stopWeatherAndThunder()
    for _, id in ipairs({ 3, 5, 8 }) do
        local value = getClimateManager():getClimateFloat(id)
        value:setEnableAdmin(true); value:setAdminValue(0)
    end
    -- The test scenario fires a dozen events in one second. Only the horde note is shown, so the photo is readable.
    local add = HaloTextHelper.addText
    HaloTextHelper.addText = function(player, text)
        if string.find(text, 'horde', 1, true) then add(player, text) end
    end
    local note = KnoxScanner.note
    KnoxScanner.note = function(player, kind)
        note(player, kind)
        if kind == 'horde' and PZ_PHOTO_ROLE == 'Alice' then hordeAt = photoTicks end
    end
end)
Events.OnTick.Add(function()
    local p = getSpecificPlayer(0)
    if not p or PZ_PHOTO_ROLE ~= 'Alice' or finished then return end
    photoTicks = photoTicks + 1
    for x = PZ_TEST_SPAWN.x - 20, PZ_TEST_SPAWN.x + 20 do
        for y = PZ_TEST_SPAWN.y - 20, PZ_TEST_SPAWN.y + 20 do
            local square = getCell():getGridSquare(x, y, 0)
            if square then square:setIsSeen(0, true) end
        end
    end
    if photoTicks == 100 then
        getPlayerInfoPanel(0):setVisible(false)
        ISUIHandler.setVisibleAllUI(false)
    end
    if hordeAt then p:faceLocation(PZ_TEST_SPAWN.x + 1, PZ_TEST_SPAWN.y - 6) end
    if hordeAt and photoTicks == hordeAt + 30 then
        getCore():TakeFullScreenshot('scanner-horde.png')
        print('PZ_TEST_PHOTO horde captured with the real note and the staged zombies')
    end
    if hordeAt and photoTicks == hordeAt + 60 then
        local screen = MainScreen.instance
        screen:setVisible(true)
        screen.mainOptions:toUI()
        screen.mainOptions:setVisible(true)
        screen.mainOptions.tabs:activateView(getText('UI_mainscreen_mods'))
        optionsAt = photoTicks
    end
    if optionsAt and photoTicks == optionsAt + 40 then
        getCore():TakeFullScreenshot('scanner-options.png')
        MainScreen.instance.mainOptions:setVisible(false)
        MainScreen.instance:setVisible(false)
        finished = true
        print('PZ_TEST_PHOTOS_PASS real Mod Options page captured')
    end
end)

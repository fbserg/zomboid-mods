-- Loopback multiplayer probe, server half. Never installed.
if isClient() then return end
local B = BackyardBirds
Events.OnServerStarted.Add(function() print("BIRDS_MP_SERVER_UP") end)

Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= "BirdsMP" or command ~= "ready" then return end
    local ok, message = pcall(function()
        local square = assert(getCell():getGridSquare(args.x, args.y, 0), "Bath square is not loaded on the server")
        local bath = IsoObject.new(square, "vegetation_ornamental_01_50", "Bird Bath")
        square:AddTileObject(bath)
        bath:transmitCompleteItemToClients()
        getGameTime():setTimeOfDay(12)
        getClimateManager():stopWeatherAndThunder()
        local stats = player:getStats()
        stats:set(CharacterStat.BOREDOM, 50)
        stats:set(CharacterStat.UNHAPPINESS, 50)
        B.CHANCE = { morning = 100, midday = 100, evening = 100 }
        B.tick()
        print("BIRDS_MP_SERVER_TICK boredom=" .. stats:get(CharacterStat.BOREDOM) .. " unhappiness=" .. stats:get(CharacterStat.UNHAPPINESS))
    end)
    print(ok and "BIRDS_MP_SERVER_PASS" or ("BIRDS_MP_SERVER_FAIL " .. tostring(message)))
end)

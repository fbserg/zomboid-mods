-- Server probe: real B42 sprites, squares, climate, stats and stat sync, no client.
local B = BackyardBirds
local X, Y = 10628, 10650
local started, done = false, false
Events.OnServerStarted.Add(function() started = true end)
Events.OnTick.Add(function()
    if not started or done or not farmTestKeepLoaded then return end
    farmTestKeepLoaded(X, Y)
    local square = getCell():getGridSquare(X + 3, Y - 2, 0)
    if not square then return end
    done = true
    local ok, message = pcall(function()
        assert(isServer() and B.tick, "Scheduler is not loaded on the server")
        local baths = {}
        for i = 0, 63 do
            local name = "vegetation_ornamental_01_" .. i
            local sprite = getSprite(name)
            if sprite and sprite:getProperties():get("CustomName") == B.CUSTOM_NAME then baths[#baths + 1] = name end
        end
        assert(#baths >= 1 and baths[1] == "vegetation_ornamental_01_50", "Bird bath sprites: " .. table.concat(baths, ","))
        print("BIRDS_PASS game sprites named Bird Bath: " .. table.concat(baths, ","))

        square:AddTileObject(IsoObject.new(square, "vegetation_ornamental_01_50", "Bird Bath"))
        assert(square:isOutside(), "Probe square is indoors")
        local player = IsoPlayer.new(getCell())
        player:setX(X + 0.5); player:setY(Y + 0.5); player:setZ(0)
        player:setCurrent(getCell():getGridSquare(X, Y, 0))
        local found = B.bathsNear(player)
        assert(#found == 1 and found[1] == square, "Found " .. #found .. " baths")
        print("BIRDS_PASS a placed vanilla bird bath on an outdoor square is found")

        local boredom = SyncPlayerStatsPacket.getBitMaskForStat(CharacterStat.BOREDOM)
        local unhappiness = SyncPlayerStatsPacket.getBitMaskForStat(CharacterStat.UNHAPPINESS)
        assert(boredom > 0 and unhappiness > 0 and boredom ~= unhappiness, "Sync masks " .. boredom .. " " .. unhappiness)
        print("BIRDS_PASS stat sync masks resolve: boredom=" .. boredom .. " unhappiness=" .. unhappiness)

        getGameTime():setTimeOfDay(12)
        getClimateManager():stopWeatherAndThunder()
        local stats = player:getStats()
        stats:set(CharacterStat.BOREDOM, 50)
        stats:set(CharacterStat.UNHAPPINESS, 50)
        -- The probe player has no connection. Capture the sends; the real sync call runs.
        local sent = {}
        sendServerCommand = function(target, module, command, args) sent[#sent + 1] = { target = target, module = module, command = command, args = args } end
        B.players = function() return { player } end
        local climate = getClimateManager()
        local noon = B.visitChance(12, climate:getRainIntensity(), climate:getTemperature(), 99)
        assert(noon == B.CHANCE.midday or noon == math.floor(B.CHANCE.midday * 1.5), "Noon chance " .. noon .. " at " .. climate:getTemperature() .. "C")
        print("BIRDS_PASS real noon weather gives a " .. noon .. "% visit chance at " .. climate:getTemperature() .. "C")
        B.CHANCE = { morning = 100, midday = 100, evening = 100 }
        B.tick()
        assert(#sent == 1 and sent[1].target == player and sent[1].module == "BackyardBirds" and sent[1].command == "visit", "Sent " .. #sent)
        local args = sent[1].args
        assert(args.x == X + 3 and args.y == Y - 2 and args.z == 0 and args.boosted == true, "Visit args")
        B.speciesById(args.species)
        assert(args.count >= 1 and args.count <= 3 and args.minutes >= 4 and args.minutes <= 12, "Visit size")
        assert(math.abs(stats:get(CharacterStat.BOREDOM) - 45) < 0.01 and math.abs(stats:get(CharacterStat.UNHAPPINESS) - 47) < 0.01,
            "Stats " .. stats:get(CharacterStat.BOREDOM) .. " " .. stats:get(CharacterStat.UNHAPPINESS))
        print("BIRDS_PASS server tick sends one " .. args.species .. " visit and lifts boredom and unhappiness")
        B.tick()
        assert(#sent == 1, "A second visit started during the first")
        print("BIRDS_PASS one visit at a time per bath")
    end)
    print(ok and "BIRDS_ENGINE_PASS" or ("BIRDS_ENGINE_FAIL " .. tostring(message)))
end)

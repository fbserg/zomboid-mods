-- Native client fixture: real bird baths, real visits, real captures. Never installed.
local B = BackyardBirds
local X, Y = 10628, 10658
local BATHS = {
    { dx = 3, dy = -2, species = "cardinal", count = 3 },
    { dx = -2, dy = 3, species = "bluejay", count = 2 },
    { dx = 4, dy = 3, species = "goldfinch", count = 1 },
}
local step, ticks = "place", 0
local cardinalSong

local function hold(player)
    player:setX(X + 0.5); player:setLastX(X + 0.5)
    player:setY(Y + 0.5); player:setLastY(Y + 0.5)
    player:setZ(0); player:setLastZ(0)
end

local function clearZombies()
    local zombies = getCell():getZombieList()
    for i = zombies:size() - 1, 0, -1 do zombies:get(i):removeFromWorld() end
end

-- Hiding the UI lands a frame later, so hide first and shoot on a later tick.
local function showUI(ui)
    ISUIHandler.setVisibleAllUI(ui)
    for _, visit in pairs(B.visits) do visit:setVisible(true) end
end

local function capture(name)
    getCore():TakeFullScreenshot(name)
    print("BIRDS_PHOTO_CAPTURED " .. name)
end

-- Reveal the yard for the photograph, like an explored save.
local function reveal()
    for x = X - 16, X + 16 do
        for y = Y - 16, Y + 16 do
            local square = getCell():getGridSquare(x, y, 0)
            if square then square:setIsSeen(0, true) end
        end
    end
end

local function zoom(steps)
    for i = 1, 8 do getCore():doZoomScroll(0, 1) end
    for i = 1, steps do getCore():doZoomScroll(0, -1) end
end

local function startVisits(player)
    for _, bath in ipairs(BATHS) do
        B.showVisit(player, { x = X + bath.dx, y = Y + bath.dy, z = 0, species = bath.species, count = bath.count,
            minutes = 600, boosted = bath.species == "cardinal" })
    end
end

Events.OnGameStart.Add(function()
    local player = getSpecificPlayer(0)
    hold(player)
    player:setGodMod(true)
    player:setGhostMode(true)
    getCore():setAutoZoom(0, false)
    UIManager.getSpeedControls():SetCurrentGameSpeed(1)
end)

Events.OnTick.Add(function()
    local player = getSpecificPlayer(0)
    if not player then return end
    ticks = ticks + 1
    clearZombies()
    reveal()
    if step == "place" then
        if not getCell():getGridSquare(X + 4, Y + 3, 0) then return end
        getGameTime():setTimeOfDay(12)
        getClimateManager():stopWeatherAndThunder()
        -- Pin fog, clouds and rain off, as the farm photos do.
        for _, id in ipairs({3, 5, 8}) do
            local value = getClimateManager():getClimateFloat(id)
            value:setEnableAdmin(true); value:setAdminValue(0)
        end
        for i = 48, 55 do
            local sprite = getSprite("vegetation_ornamental_01_" .. i)
            print("BIRDS_SPRITE vegetation_ornamental_01_" .. i .. " " .. tostring(sprite and sprite:getProperties():get("CustomName")))
        end
        for _, bath in ipairs(BATHS) do
            local square = getCell():getGridSquare(X + bath.dx, Y + bath.dy, 0)
            square:AddTileObject(IsoObject.new(square, "vegetation_ornamental_01_50", "Bird Bath"))
            assert(B.hasBirdBath(square), "Placed bath is not detected")
            print("BIRDS_PHOTO_BATH " .. bath.species .. " outside=" .. tostring(square:isOutside()))
        end
        hold(player)
        zoom(3)
        step, ticks = "visits", 0
    elseif step == "visits" and ticks == 120 then
        getPlayerInfoPanel(0):setVisible(false)
        startVisits(player)
        for key, visit in pairs(B.visits) do
            assert(visit.sound ~= 0 and visit.emitter:isPlaying(visit.sound), "No bird song at " .. key)
        end
        cardinalSong = B.visits[B.key(X + 3, Y - 2, 0) .. "#0"]
        print("BIRDS_PHOTO_PASS each visit plays the vanilla BirdInTree song at its bath")
        step, ticks = "halo", 0
    elseif step == "halo" and ticks == 20 then
        capture("birds-halo.png")
        showUI(false)
        step, ticks = "yard", 0
    elseif step == "yard" and ticks == 360 then -- every bird has landed
        capture("birds-yard.png")
        zoom(7)
        step, ticks = "close", 0
    elseif step == "close" and ticks == 60 then
        capture("birds-close.png")
        zoom(3)
        ISUIHandler.setVisibleAllUI(true)
        -- Walk up to the cardinals: only that bath flees.
        player:setX(X + 3.5); player:setY(Y - 0.5)
        step, ticks = "flee", 0
    elseif step == "flee" and ticks == 150 then
        local cardinal = B.visits[B.key(X + 3, Y - 2, 0) .. "#0"]
        local jays = B.visits[B.key(X - 2, Y + 3, 0) .. "#0"]
        assert(cardinal == nil, "Cardinals stayed with the player beside the bath")
        assert(jays and not jays.scared, "Blue jays fled from a player six tiles away")
        assert(cardinalSong.sound == nil, "Cardinal song kept playing after they fled")
        -- The vanilla burst ends after a few seconds. The jays must have started another.
        assert(jays.songs >= 2, "Blue jays sang " .. jays.songs .. " bursts")
        print("BIRDS_PHOTO_PASS song stops with the scared flock and repeats for the jays: " .. jays.songs .. " bursts")
        print("BIRDS_PHOTO_PASS birds flee a close player and stay for a distant one")
        for _, visit in pairs(B.visits) do visit:close() end
        hold(player)
        -- The single-player path of the server scheduler: real time, weather, baths and stats.
        local stats = player:getStats()
        stats:set(CharacterStat.BOREDOM, 50)
        stats:set(CharacterStat.UNHAPPINESS, 50)
        local chance = B.CHANCE
        B.CHANCE = { morning = 100, midday = 100, evening = 100 }
        B.tick()
        B.CHANCE = chance
        local count = 0
        for _ in pairs(B.visits) do count = count + 1 end
        assert(count == #BATHS, "Scheduler started " .. count .. " visits")
        assert(math.abs(stats:get(CharacterStat.BOREDOM) - (50 - B.BOREDOM)) < 0.01, "Boredom is " .. stats:get(CharacterStat.BOREDOM))
        assert(math.abs(stats:get(CharacterStat.UNHAPPINESS) - (50 - B.UNHAPPINESS)) < 0.01, "Unhappiness is " .. stats:get(CharacterStat.UNHAPPINESS))
        print("BIRDS_PHOTO_PASS single-player scheduler visits every bath and lifts the mood once")
        -- Cost on the real game: the ten-minute bath scan, and one visit's per-frame update and draw.
        local start = getTimestampMs()
        for i = 1, 50 do B.bathsNear(player) end
        local scan = (getTimestampMs() - start) / 50
        local visit = B.visits[B.key(X - 2, Y + 3, 0) .. "#0"]
        start = getTimestampMs()
        for i = 1, 1000 do visit:update(); visit:prerender(); visit:render() end
        local frame = (getTimestampMs() - start) / 1000
        assert(scan < 20 and frame < 0.5, "Too slow: scan " .. scan .. " ms, frame " .. frame .. " ms")
        print(string.format("BIRDS_PHOTO_PASS cost: %.2f ms per 21x21 bath scan, %.3f ms per visit per frame", scan, frame))
        step = "done"
        print("BIRDS_PHOTOS_DONE")
    end
end)

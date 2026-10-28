local placed = false
local F = require "FarmTrailer"
local room = F.rooms[1]

local function scene()
    local player = getSpecificPlayer(0)
    if not player or placed then return end
    local last = getCell():getGridSquare(room.x + 13, room.y + 41, 0)
    if not last then return end
    player:setGodMod(true)
    player:setGhostMode(true)
    player:dressInNamedOutfit("Farmer")
    getGameTime():setTimeOfDay(12)
    getClimateManager():stopWeatherAndThunder()
    for _, id in ipairs({3, 5, 8}) do
        local value = getClimateManager():getClimateFloat(id)
        value:setEnableAdmin(true); value:setAdminValue(0)
    end
    for x = 1, 12 do
        for y = 1, 40 do
            local square = getCell():getGridSquare(room.x + x, room.y + y, 0)
            if x == 6 or x == 7 then square:addFloor("carpentry_02_56") end
            if y >= 25 and x ~= 6 and x ~= 7 then square:addFloor("blends_natural_01_16") end
            if y == 24 and x ~= 6 and x ~= 7 then
                square:AddTileObject(IsoObject.new(square, "fencing_01_25", "Demo pen fence"))
            end
            if y >= 6 and y <= 20 and y % 2 == 0 and (x <= 4 or x >= 9) then
                SFarmingSystem.instance:plow(square)
                local crop = SFarmingSystem.instance:getLuaObjectAt(square:getX(), square:getY(), 0)
                crop:seed(x <= 4 and "Carrots" or "Cabbages", 10)
                crop.waterLvl = 80
                for n = 1, 4 do SFarmingSystem.instance:growPlant(crop, nil, true) end
                crop:setSpriteName(farming_vegetableconf.getSpriteName(crop))
                crop:saveData()
            end
        end
    end
    for _, definition in ipairs({"cow", "cow"}) do
        local all, def = getAllAnimalsDefinitions(), nil
        for i = 0, all:size() - 1 do
            if all:get(i):getAnimalType() == definition then def = all:get(i) end
        end
        assert(def, "Missing demo animal " .. definition)
        local x = room.x + ZombRand(2, 5)
        addAnimal(getCell(), x, room.y + ZombRand(29, 36), 0, definition, def:getRandomBreed())
    end
    DesignationZoneAnimal.new("Backseat beef", room.x + 1, room.y + 25, 0, room.x + 13, room.y + 41, true)
    getCore():setAutoZoom(0, false)
    for i = 1, 8 do getCore():doZoomScroll(0, 1) end
    if F.awaitWaterNotice then
        local trailer=assert(addVehicleDebug(F.script,IsoDirections.N,nil,
            getCell():getGridSquare(room.x+6,room.y+3,0)))
        trailer:setTrunkLocked(false)
        player:setX(room.x+6);player:setY(room.y+3)
        player:setCurrent(getCell():getGridSquare(room.x+6,room.y+3,0))
        player:getModData().projectRV_playerId="photo-water"
        trailer:getModData().projectRV_uniqueId="photo-water"
        local rv=F.rvData()
        rv.Players=rv.Players or {}
        rv.Players["photo-water"]={RoomType=F.type,VehicleId="photo-water",ActualRoom=room}
        assert(require("RVHooks").emit("postEnter",{player=player,vehicle=trailer,
            room=room,typeKey=F.type,side="SP"})==false,"Farm entry hook fell through")
        local checks=0
        local verifyWater
        verifyWater=function()
            checks=checks+1
            if checks<5 then return end
            assert(F.waterStatusText(trailer)=="Farm water: 0 / 800 L (LOW) (snapshot)",
                "Native entry did not measure low farm water")
            print("FARM_PHOTO_PASS native entry low-water notice and exterior snapshot")
            trailer:removeFromWorld()
            Events.OnTick.Remove(verifyWater)
        end
        Events.OnTick.Add(verifyWater)
    end
    placed = true
    print("FARM_PHOTOS_SCENE_READY")
    Events.OnTick.Remove(scene)
end
Events.OnGameStart.Add(function()
    local player = getSpecificPlayer(0)
    player:setX(room.x + 6); player:setLastX(room.x + 6)
    player:setY(room.y + 20); player:setLastY(room.y + 20)
    player:setZ(0); player:setLastZ(0)
    player:setGodMod(true)
    UIManager.getSpeedControls():SetCurrentGameSpeed(1)
    for i = 1, 8 do getCore():doZoomScroll(0, 1) end
    Events.OnTick.Add(scene)
end)

-- Photo controls are confined to this disposable demonstration world.
local photoName, countdown
local autoTicks = 0
local captureKeys = {Keyboard.KEY_F6, Keyboard.KEY_F7, Keyboard.KEY_F8}
local function framePhoto(key)
    if not placed then return end
    local player = getSpecificPlayer(0)
    if key == Keyboard.KEY_F6 then
        for i = 1, 8 do getCore():doZoomScroll(0, 1) end
        player:setX(room.x + 6); player:setY(room.y + 20)
        player:setLastX(room.x + 6); player:setLastY(room.y + 20)
        photoName, countdown = "farm-overview.png", 90
    elseif key == Keyboard.KEY_F7 then
        for i = 1, 8 do getCore():doZoomScroll(0, -1) end
        for i = 1, 3 do getCore():doZoomScroll(0, 1) end
        player:setX(room.x + 6); player:setY(room.y + 31)
        player:setLastX(room.x + 6); player:setLastY(room.y + 31)
        photoName, countdown = "farm-livestock.png", 90
    elseif key == Keyboard.KEY_F8 then
        for i = 1, 8 do getCore():doZoomScroll(0, -1) end
        for i = 1, 3 do getCore():doZoomScroll(0, 1) end
        player:setX(room.x + 6); player:setY(room.y + 12)
        player:setLastX(room.x + 6); player:setLastY(room.y + 12)
        photoName, countdown = "farm-crops.png", 90
    end
end
Events.OnKeyPressed.Add(framePhoto)
Events.OnTick.Add(function()
    if placed then
        -- Reveal the staged plot for the photograph, like an explored demo save.
        for x = 0, 13 do
            for y = 0, 41 do
                local square = getCell():getGridSquare(room.x + x, room.y + y, 0)
                if square then
                    square:setIsSeen(0, true)
                end
            end
        end
        autoTicks = autoTicks + 1
        if autoTicks <= 240 and autoTicks % 30 == 0 then
            local stops = {3, 10, 20, 30, 38, 30, 20, 10}
            local player = getSpecificPlayer(0)
            player:setX(room.x + 6); player:setLastX(room.x + 6)
            player:setY(room.y + stops[autoTicks / 30]); player:setLastY(room.y + stops[autoTicks / 30])
            player:setDir(autoTicks <= 120 and IsoDirections.N or IsoDirections.S)
        end
        if autoTicks % 240 == 0 and autoTicks <= 720 then framePhoto(captureKeys[autoTicks / 240]) end
    end
    if not countdown then return end
    countdown = countdown - 1
    if countdown == 30 then ISUIHandler.setVisibleAllUI(false) end
    if countdown == 0 then
        getCore():TakeFullScreenshot(photoName)
        print("FARM_PHOTO_CAPTURED " .. photoName)
        countdown = nil
    end
end)

-- Server-stack welcome panels may pause after OnGameStart. Keep the unattended demo moving.
Events.OnTickEvenPaused.Add(function()
    if placed then
        ISUIHandler.setVisibleAllUI(false)
        UIManager.getSpeedControls():SetCurrentGameSpeed(1)
    end
end)

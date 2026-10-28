local F = require "FarmTrailer"
local started, done = false, false
local ticks = 0
local function findCow(room)
    for x = room.x - 4, room.x + 17 do
        for y = room.y - 4, room.y + 45 do
            local square = getCell():getGridSquare(x, y, 0)
            if square then
                local objects = square:getMovingObjects()
                for i = 0, objects:size() - 1 do
                    local object = objects:get(i)
                    if instanceof(object, "IsoAnimal") and object:getModData().FarmProbeIdentity == "native-cow" then return object end
                end
            end
        end
    end
end
Events.OnServerStarted.Add(function()
    started = true
    print("FARM_ENGINE_STARTED")
end)
Events.OnTick.Add(function()
    if not started or done or not farmTestKeepLoaded then return end
    ticks = ticks + 1
    for x = 22550, 22630, 32 do
        for y = 12490, 12560, 32 do farmTestKeepLoaded(x, y) end
    end
    local room = F.rooms[1]
    local first = getCell():getGridSquare(room.x, room.y, 0)
    local last = getCell():getGridSquare(room.x + 13, room.y + 41, 0)
    if not first or not last then return end
    local objects = F.waterObjects(room)
    if not objects or #objects ~= 2 then return end
    if F.state(room).ProbeSaved and not findCow(room) then return end
    done = true
    local ok, message = pcall(function()
        assert(first:getModData().FarmTrailerBuilt, "Farm was not initialized")
        for x = 1, 12 do
            for y = 1, 40 do
                local square = assert(getCell():getGridSquare(room.x + x, room.y + y, 0))
                assert(square:isOutside(), "Farm square is indoors")
                assert(not square:haveRoofFull(), "Farm has a roof")
                assert(square:getFloor():getSprite():getName() == "blends_natural_01_16", "Farm soil missing")
            end
        end
        print("FARM_PASS 480 outdoor soil squares")
        local function wallProperties(x, y)
            local objects = getCell():getGridSquare(x, y, 0):getObjects()
            for i = 0, objects:size() - 1 do
                if objects:get(i):getName() == "Farm wall" then
                    return objects:get(i):getProperties()
                end
            end
            error("Opaque farm wall missing")
        end
        local north = wallProperties(room.x + 8, room.y)
        local west = wallProperties(room.x, room.y + 8)
        assert(north:has(IsoFlagType.collideN) and not north:has(IsoFlagType.transparentN), "North wall is see-through")
        assert(west:has(IsoFlagType.collideW) and not west:has(IsoFlagType.transparentW), "West wall is see-through")
        assert(north:has(IsoFlagType.CantClimb) and west:has(IsoFlagType.CantClimb), "Farm walls are still climbable")
        print("FARM_PASS opaque collidable perimeter with no roof")
        local function boundaryObject(square)
            for i=0,square:getObjects():size()-1 do
                local object=square:getObjects():get(i)
                if F.isBoundary(object) then return object end
            end
            error("Missing protected boundary at " .. square:getX() .. "," .. square:getY())
        end
        local probePlayer=IsoPlayer.new(getCell())
        local probes={probePlayer}
        local definitions=getAllAnimalsDefinitions()
        for _,kind in ipairs({"hen","cow"}) do
            local definition
            for i=0,definitions:size()-1 do
                if definitions:get(i):getAnimalType()==kind then definition=definitions:get(i) end
            end
            assert(definition,"Missing boundary probe animal "..kind)
            probes[#probes+1]=addAnimal(getCell(),room.x+6,room.y+6,0,kind,definition:getRandomBreed())
        end
        local edges={
            {x=room.x+8,y=room.y,dx=0,dy=-1,dir=IsoDirections.N},
            {x=room.x+8,y=room.y+41,dx=0,dy=1,dir=IsoDirections.S},
            {x=room.x,y=room.y+8,dx=-1,dy=0,dir=IsoDirections.W},
            {x=room.x+13,y=room.y+8,dx=1,dy=0,dir=IsoDirections.E},
        }
        for _,edge in ipairs(edges) do
            local inside=assert(getCell():getGridSquare(edge.x,edge.y,0))
            local outside=assert(getCell():getGridSquare(edge.x+edge.dx,edge.y+edge.dy,0))
            local wall=boundaryObject(inside)
            local barrier=boundaryObject(outside)
            assert(outside:isSolidTrans(),"Outer border is not solid")
            assert(barrier:isSpriteInvisible(),"Outer border is visible")
            local climbX=edge.x-(edge.dx>0 and 1 or 0)
            local climbY=edge.y-(edge.dy>0 and 1 or 0)
            probePlayer:setX(climbX+0.5);probePlayer:setY(climbY+0.5);probePlayer:setZ(0)
            probePlayer:setCurrent(getCell():getGridSquare(climbX,climbY,0))
            assert(not probePlayer:canClimbOverWall(edge.dir),"Native player can climb farm boundary")
            for _,actor in ipairs(probes) do
                assert(inside:testCollideAdjacent(actor,edge.dx,edge.dy,0),"Player/animal crosses outer ring")
                assert(not wall:getThumpableFor(actor),"Farm wall is an attack target")
                assert(not barrier:getThumpableFor(actor),"Outer barrier is an attack target")
            end
            local action=ISDestroyStuffAction:new(probePlayer,wall)
            assert(not action:isValid() and not action:complete(),"Sledge destroys farm wall")
            inside:BurnWalls(false,false)
            outside:BurnWalls(false,false)
            assert(wall:getObjectIndex()~=-1 and wall:getSprite():getName()~=nil,"Fire removed wall")
            assert(barrier:getObjectIndex()~=-1 and outside:isSolidTrans(),"Fire removed outer barrier")
        end
        for _,corner in ipairs({{x=room.x,y=room.y,dx=-1,dy=-1},
            {x=room.x+13,y=room.y,dx=1,dy=-1},
            {x=room.x,y=room.y+41,dx=-1,dy=1},
            {x=room.x+13,y=room.y+41,dx=1,dy=1}}) do
            local square=assert(getCell():getGridSquare(corner.x,corner.y,0))
            for _,actor in ipairs(probes) do
                assert(square:testCollideAdjacent(actor,corner.dx,corner.dy,0),"Actor crosses outer corner")
            end
        end
        local migrationSquare=getCell():getGridSquare(room.x+5,room.y,0)
        local migrationWall=boundaryObject(migrationSquare)
        if F.state(room).ProbeSaved then
            assert(migrationWall:getName()=="Farm fence" and migrationWall:getModData().FarmProbeLegacy=="keep",
                "Saved original fence lost custom state during upgrade")
            assert(migrationWall:getProperties():has(IsoFlagType.CantClimb),"Saved original fence was not upgraded")
            print("FARM_PASS saved original fence upgrades in place with custom state intact")
        end
        for i=2,#probes do probes[i]:removeFromWorld();probes[i]:removeFromSquare() end
        local ringCount=0
        for x=room.x-1,room.x+14 do
            for y=room.y-1,room.y+42 do
                local r,mode=F.boundaryAt(x,y,0)
                if mode=="outer" then
                    local square=assert(getCell():getGridSquare(x,y,0))
                    boundaryObject(square)
                    local count=square:getObjects():size()
                    F.upgradeBoundary(square);F.upgradeBoundary(square)
                    assert(square:getObjects():size()==count,"Duplicate outer barriers")
                    ringCount=ringCount+1
                end
            end
        end
        assert(ringCount==116,"Outer border has a gap")
        print("FARM_PASS permanent nonclimbable boundary blocks native player, chicken and cow; fire and sledge refused")
        print("FARM_PASS 116 outer border tiles persist without duplicates")


        assert(objects[1]:getFluidCapacity() == 400 and objects[2]:getFluidCapacity() == 400)
        if not F.state(room).ProbeSaved then
        assert(objects[1]:getFluidAmount() == 0 and objects[2]:getFluidAmount() == 0)
        F.state(room).pending = 700
        F.updateWater(room)
        assert(F.state(room).known == 700 and F.state(room).pending == 0)
        objects[1]:useFluid(100)
        F.updateWater(room)
        assert(F.state(room).known == 600)
        F.state(room).pending = 200
        F.updateWater(room)
        assert(F.state(room).known == 800 and F.state(room).pending == 0)
        assert(objects[1]:isTaintedWater(), "River refill lost contamination")
        print("FARM_PASS finite native fluid transfer, consumption, cap and contamination")
        else F.updateWater(room) end
        local amount = objects[1]:getFluidAmount()
        F.buildSquare(objects[1]:getSquare())
        assert(#F.waterObjects(room) == 2 and objects[1]:getFluidAmount() == amount)
        print("FARM_PASS initialization does not reset existing contents")
        local types = require("RVVehicleTypes").VehicleTypes
        assert(types[F.type].scripts[1] == F.script)
        local state = F.state(room)
        local cropSquare = assert(getCell():getGridSquare(room.x + 8, room.y + 8, 0))
        if state.ProbeSaved then
            assert(F.state(room).known == 800, "Water did not survive restart")
            local plant = SFarmingSystem.instance:getLuaObjectAt(room.x + 8, room.y + 8, 0)
            assert(plant and plant.typeOfSeed == "Carrots", "Crop did not survive restart")
            local corpseSquare = getCell():getGridSquare(room.x + 9, room.y + 9, 0)
            assert(corpseSquare:getDeadBody(), "Corpse did not survive restart")
            local animal = assert(findCow(room), "Live cow did not survive restart")
            assert(animal:getModData().FarmProbeIdentity == "native-cow", "Cow state changed after restart")
            local list = getCell():getGridSquare(room.x+11,room.y+11,0):getObjects()
            local savedCarrier
            for i=0,list:size()-1 do
                local object=list:get(i)
                if object:getModData().FarmProbeCarrier then savedCarrier=object:getContainer():getItems():get(0) end
            end
            assert(savedCarrier and instanceof(savedCarrier,"AnimalInventoryItem"), "Interrupted carrier lost on restart")
            assert(savedCarrier:getAnimal():getModData().FarmProbeIdentity == "held-cow", "Carrier animal lost identity")
            assert(savedCarrier:getModData().FarmTrailerTransferVehicle == "other-trailer")
            assert(F.rvData().AssignedRooms["legacy-probe"], "Legacy room lost on restart")
            assert(not F.rvData()["AssignedRooms" .. F.type]["legacy-probe"])
            print("FARM_PASS restart preserves interrupted carrier and legacy room")
            print("FARM_PASS full server restart preserves water, crop, corpse and live cow")
        else
            SFarmingSystem.instance:plow(cropSquare)
            local plant = assert(SFarmingSystem.instance:getLuaObjectAt(room.x + 8, room.y + 8, 0))
            plant:seed("Carrots", 10)
            assert(plant.exterior, "Native crop does not see outdoor farm")
            local stage = plant.nbOfGrow
            plant.waterLvl = plant.waterNeeded
            plant.nextGrowing = SFarmingSystem.instance.hoursElapsed
            plant:saveData()
            SFarmingSystem.instance:checkPlant2(plant)
            assert(plant.nbOfGrow > stage, "Native crop did not advance")
            print("FARM_PASS native crop growth")
            local definitions = getAllAnimalsDefinitions()
            local definition
            for i = 0, definitions:size() - 1 do
                if definitions:get(i):getAnimalType() == "cow" then definition = definitions:get(i) end
            end
            assert(definition, "Cow definition missing")
            local animal = addAnimal(getCell(), room.x + 7, room.y + 7, 0, "cow", definition:getRandomBreed())
            animal:getModData().FarmProbeIdentity = "native-cow"
            local id = animal:getOnlineID()
            local item = instanceItem("Base.Animal")
            item:setAnimal(animal)
            animal:removeFromWorld(); animal:removeFromSquare(); animal:setSquare(nil)
            local square = getCell():getGridSquare(room.x + 7, room.y + 7, 0)
            assert(square:AddWorldInventoryItem(item, 0.5, 0.5, 0, true))
            local moving = square:getMovingObjects()
            local restored
            for i = 0, moving:size() - 1 do
                local object = moving:get(i)
                if instanceof(object, "IsoAnimal") and object:getOnlineID() == id then restored = object end
            end
            assert(restored and restored:getModData().FarmProbeIdentity == "native-cow", "Animal state or identity changed")
            print("FARM_PASS native cattle handoff preserves identity and custom state")
            local vehicle = assert(addVehicleDebug(F.script, IsoDirections.N, nil,
                getCell():getGridSquare(room.x + 6, room.y + 3, 0)), "Trailer spawn failed")
            local player = IsoPlayer.new(getCell())
            player:setX(room.x + 6); player:setY(room.y + 3); player:setZ(0)
            player:setCurrent(getCell():getGridSquare(room.x + 6, room.y + 3, 0))
            vehicle:getModData().projectRV_uniqueId = "farm-probe"
            vehicle:getModData().projectRV_type = F.type
            F.rvData()["AssignedRooms" .. F.type] = {["farm-probe"] = room}
            vehicle:setTrunkLocked(false)
            vehicle:addAnimalInTrailer(restored)
            assert(vehicle:getCurrentTotalAnimalSize()>0,"Loaded cow did not occupy exterior trailer")
            local action = ISFarmTrailerAction:new(player, "animalIn", vehicle, restored)
            assert(action:isValid(), "Native trailer prerequisites failed: speed=" .. vehicle:getCurrentSpeedKmHour() .. " z=" .. vehicle:getZ() .. " distance=" .. player:DistToSquared(vehicle))
            assert(action:complete(), "Native trailer transfer failed")
            assert(vehicle:getAnimals():size()==0 and vehicle:getCurrentTotalAnimalSize()==0,
                "Cow occupancy stayed in exterior trailer after transfer")
            print("FARM_PASS cow transfer clears exterior trailer occupancy")
            F.releaseCargo(player)
            local transferred = assert(getAnimal(id), "Transfer lost the cow")
            assert(transferred:getModData().FarmProbeIdentity == "native-cow")
            state.ProbeAnimalId = id
            F.updateMass(vehicle, room)
            assert(vehicle:getInitialMass() >= 800, "Water load missing from trailer mass")
            print("FARM_PASS farm action uses native trailer handoff and adds water mass")
            local dead = addAnimal(getCell(), room.x + 9, room.y + 9, 0, "cow", definition:getRandomBreed())
            local body = IsoDeadBody.new(dead, false)
            assert(getCell():getGridSquare(room.x + 9, room.y + 9, 0):getDeadBody() == body)
            vehicle:getModData().projectRV_uniqueId = "farm-probe"
            vehicle:getModData().projectRV_type = F.type
            F.rvData()["AssignedRooms" .. F.type] = {["farm-probe"] = room}
            GetInToRV(player, vehicle)
            assert(F.playerData(player).RoomType == F.type, "Parent entry did not assign farm")
            local tow = assert(addVehicleDebug("Base.PickUpTruck", IsoDirections.N, nil,
                getCell():getGridSquare(room.x + 6, room.y + 10, 0)), "Tow vehicle spawn failed")
            tow:setVehicleTowing(vehicle, "trailer", "trailer")
            vehicle:setVehicleTowedBy(tow, "trailer", "trailer")
            local battery = assert(tow:getBattery():getInventoryItem(), "Tow battery missing")
            battery:setCurrentUsesFloat(1)
            player:getInventory():AddItem("Base.RubberHose")
            getCell():getGridSquare(room.x + 6, room.y + 7, 0):getProperties():set(IsoFlagType.water)
            objects[1]:useFluid(20)
            local intake = ISFarmTrailerAction:new(player, "pump", vehicle)
            assert(intake:isValid() and intake:complete(), "Native powered shoreline refill failed")
            assert(math.abs(battery:getCurrentUsesFloat() - 0.995) < 0.00001, "Pump battery use is wrong")
            assert(F.state(room).known == 800 and objects[1]:isTaintedWater(), "Pump lost water or contamination")
            print("FARM_PASS powered shoreline intake uses native hose, tow battery and water tiles")
            -- A second native player must keep its assignment when the first leaves.
            local second = IsoPlayer.new(getCell())
            second:setX(room.x + 6); second:setY(room.y + 3); second:setZ(0)
            second:setCurrent(getCell():getGridSquare(room.x + 6, room.y + 3, 0))
            second:getModData().projectRV_playerId = "farm-second"
            GetInToRV(second, vehicle)
            assert(F.playerData(second).VehicleId == "farm-probe")
            local outgoing = ISFarmTrailerAction:new(player, "animalOut", nil, transferred)
            assert(outgoing:isValid() and outgoing:complete(), "Return cattle handoff failed")
            assert(F.playerData(second), "First exit cleared second player")
            RVServer.GetOutFromRV(second)
            assert(not F.playerData(second), "Second player could not exit")
            print("FARM_PASS two native player entries and independent exits")
            assert(not F.playerData(player), "Farm exit did not clear player state")
            assert(getCell():getGridSquare(room.x + 9, room.y + 9, 0):getDeadBody() == body,
                "Exit deleted the corpse")
            player:setX(room.x - 2); player:setY(room.y + 3)
            player:setCurrent(getCell():getGridSquare(room.x - 2, room.y + 3, 0))
            F.releaseCargo(player)
            assert(findCow(room), "Exit deleted live livestock")
            print("FARM_PASS cattle return trip through native pickup and release")
            assert(F.state(room).known == 800, "Exit changed water")
            assert(SFarmingSystem.instance:getLuaObjectAt(room.x + 8, room.y + 8, 0), "Exit deleted crop")
            print("FARM_PASS real parent entry and farm exit preserve all contents")
            -- Existing RV assignments must win before the parent chooses a farm.
            local legacy = assert(addVehicleDebug(F.script, IsoDirections.N, nil,
                getCell():getGridSquare(room.x + 6, room.y + 20, 0)))
            legacy:getModData().projectRV_uniqueId = "legacy-probe"
            legacy:getModData().projectRV_type = "normal"
            local oldRoom = types.normal.rooms[1]
            F.rvData().AssignedRooms = F.rvData().AssignedRooms or {}
            F.rvData().AssignedRooms["legacy-probe"] = oldRoom
            GetInToRV(second, legacy)
            assert(F.playerData(second).ActualRoom == oldRoom, "Existing interior redirected")
            assert(F.playerData(second).RoomType == "normal")
            assert(not F.rvData()["AssignedRooms" .. F.type]["legacy-probe"], "Legacy entry consumed a farm")
            print("FARM_PASS existing trailer keeps its assigned interior and farm pool")

            -- Persist an interrupted native carrier inside a world container.
            local heldCow = addAnimal(getCell(), room.x + 10, room.y + 10, 0, "cow", definition:getRandomBreed())
            heldCow:getModData().FarmProbeIdentity = "held-cow"
            local holder = IsoPlayer.new(getCell())
            holder:setX(room.x+10);holder:setY(room.y+10);holder:setZ(0)
            holder:setCurrent(getCell():getGridSquare(room.x+10,room.y+10,0))
            vehicle:addAnimalInTrailer(heldCow)
            local pickup = ISRemoveAnimalFromTrailer:new(holder,vehicle,heldCow,true)
            assert(pickup:complete(), "Native interrupted handoff setup failed")
            local carrier = holder:getPrimaryHandItem()
            carrier:getModData().FarmTrailerTransfer = "farm"
            carrier:getModData().FarmTrailerTransferVehicle = "other-trailer"
            F.releaseCargo(holder)
            assert(holder:getPrimaryHandItem() == carrier, "Interrupted transfer released into wrong farm")
            local sq = getCell():getGridSquare(room.x+11,room.y+11,0)
            local crate = IsoThumpable.new(getCell(),sq,"carpentry_01_16",false,{})
            crate:setIsContainer(true);sq:AddSpecialObject(crate)
            crate:getModData().FarmProbeCarrier = true
            holder:getInventory():Remove(carrier)
            holder:setPrimaryHandItem(nil);holder:setSecondaryHandItem(nil)
            crate:getContainer():AddItem(carrier)
            print("FARM_PASS interrupted carrier retains animal and rejects wrong destination")
            migrationWall:setSpriteFromName("fencing_01_25")
            migrationWall:setName("Farm fence")
            migrationWall:getModData().FarmTrailerBoundary=nil
            migrationWall:getModData().FarmProbeLegacy="keep"
            migrationSquare:RecalcAllWithNeighbours(true)
            state.ProbeSaved = true
            print("FARM_PASS native outdoor crop and corpse creation")
        end
        print("FARM_ENGINE_PASS")
    end)
    if not ok then print("FARM_ENGINE_FAIL " .. tostring(message)) end
end)

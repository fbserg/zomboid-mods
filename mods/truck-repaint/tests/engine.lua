-- Server probe: real B42 items, inventory and KI5 truck, no client.
local X, Y = 10628, 10647
local started, done = false, false
Events.OnServerStarted.Add(function() started = true end)
Events.OnTick.Add(function()
    if not started or done or not farmTestKeepLoaded then return end
    farmTestKeepLoaded(X, Y)
    local square = getCell():getGridSquare(X, Y, 0)
    if not square then return end
    done = true
    local ok, message = pcall(function()
        assert(isServer(), "Probe is not running on a server")
        for name, skins in pairs(TruckRepaint.SKINS) do
            local script = assert(getScriptManager():getVehicle("Base." .. name), "Missing truck script " .. name)
            local keys = {}
            for skinIndex in pairs(skins) do
                assert(skinIndex < script:getSkinCount(), name .. " has no skin " .. skinIndex)
                keys[#keys + 1] = tostring(skinIndex)
            end
            print("TRUCK_KEYS " .. name .. " " .. table.concat(keys, ","))
        end
        print("TRUCK_PASS skin table fits loaded KI5 scripts, including appended bus camo")

        local vehicle = assert(addVehicleDebug("Base.87fordF700box", IsoDirections.N, 3, square), "Truck spawn failed")
        assert(vehicle:getScript():getName() == "87fordF700box", "Script name is " .. vehicle:getScript():getName())
        assert(vehicle:getSkinIndex() == 3, "Spawned skin is " .. vehicle:getSkinIndex())
        local player = IsoPlayer.new(getCell())
        local function standAt(x, y)
            player:setX(x); player:setY(y); player:setZ(0)
            player:setCurrent(getCell():getGridSquare(math.floor(x), math.floor(y), 0))
        end
        local door = vehicle:getAreaCenter(TruckRepaint.AREA)
        standAt(X + 8, Y + 8)
        local inventory = player:getInventory()
        inventory:AddItem("Base.Paintbrush")
        inventory:AddItem("Base.PaintWhite")
        assert(not ISRepaintTruck:new(player, vehicle, 5):isValid(), "Repaint allowed away from the driver door")
        -- The server never calls isValid on network actions, so complete must refuse on its own.
        assert(ISRepaintTruck:new(player, vehicle, 5):complete() == false and vehicle:getSkinIndex() == 3, "Remote complete repainted the truck")
        assert(TruckRepaint.getPaintUses(player, "PaintWhite") == 10, "Remote complete spent paint")
        standAt(door:getX(), door:getY())
        assert(ISRepaintTruck:new(player, vehicle, 5):isValid(), "Repaint refused at the driver door")
        inventory:Remove(inventory:getFirstTypeRecurse("Paintbrush"))
        inventory:Remove(inventory:getFirstTypeRecurse("PaintWhite"))
        print("TRUCK_PASS repaint needs the painter at the driver door")
        inventory:AddItem("Base.PaintRed")
        inventory:AddItem("Base.PaintWhite")
        assert(TruckRepaint.getPaintUses(player, "PaintRed") == 10, "New bucket is not full")
        assert(not ISRepaintTruck:new(player, vehicle, 7):isValid(), "Repaint allowed without a brush")
        inventory:AddItem("Base.Paintbrush")
        local action = ISRepaintTruck:new(player, vehicle, 7)
        assert(action:isValid(), "Real paint and brush rejected")
        assert(action:complete(), "Repaint failed")
        assert(vehicle:getSkinIndex() == 7, "Skin is " .. vehicle:getSkinIndex())
        assert(TruckRepaint.getPaintUses(player, "PaintRed") == 5 and TruckRepaint.getPaintUses(player, "PaintWhite") == 5,
            "Paint spent wrong")
        print("TRUCK_PASS two-tone repaint spends 5 + 5 real bucket uses on the server")

        local white = ISRepaintTruck:new(player, vehicle, 5)
        assert(not white:isValid(), "Solid white allowed with half a bucket")
        inventory:AddItem("Base.PaintWhite")
        assert(white:isValid() and white:complete(), "Solid white repaint failed")
        assert(vehicle:getSkinIndex() == 5, "Skin is " .. vehicle:getSkinIndex())
        assert(TruckRepaint.getPaintUses(player, "PaintWhite") == 5, "White paint spent wrong")
        assert(inventory:getCountTypeRecurse("PaintbucketEmpty") >= 1, "Drained bucket was not replaced")
        print("TRUCK_PASS solid repaint drains across buckets and leaves empties")
    end)
    print(ok and "TRUCK_ENGINE_PASS" or ("TRUCK_ENGINE_FAIL " .. tostring(message)))
end)

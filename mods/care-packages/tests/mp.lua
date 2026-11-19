local C = require "CarePackages"
local Snapshot = require "PZHarness/Snapshot"
local players, verified = {}, {}
local phase, round = "waiting", 1
local parcelID, baseline, world
local syncCount = 0
local startTime
local note = "Extra batteries and my route notes.\nSee you at dawn."
local sync = syncItemModData
syncItemModData = function(player, item)
    if C.isParcel(item) then syncCount = syncCount + 1 end
    sync(player, item)
end

Events.OnServerStarted.Add(function()
    assert(SandboxVars.Zombies == 6 and SandboxVars.ZombieConfig.PopulationMultiplier == 0)
    print("PZ_TEST_SERVER_UP")
end)

local function announce(role, action, args)
    args = args or {}
    args.id = parcelID
    args.round = round
    sendServerCommand(players[role], "CareProbe", action, args)
end

Events.OnClientCommand.Add(function(module, command, player)
    if module ~= "CareProbe" then return end
    local role = player:getUsername()
    if command == "ready" then
        players[role] = player
        print("PZ_TEST_DIAG server saw ready " .. role)
    end
    if command == "verified" then verified[role] = true end
end)

local function owner(role)
    return players[role]:getInventory():getItemWithID(parcelID)
end

local function floorParcel()
    local x, y, z = PZ_TEST_SPAWN.x, PZ_TEST_SPAWN.y, PZ_TEST_SPAWN.z
    for offset = -2, 2 do
        local square = getCell():getGridSquare(x, y + offset, z)
        if square then
            local objects = square:getWorldObjects()
            for i = 0, objects:size() - 1 do
                local item = objects:get(i):getItem()
                if item and item:getID() == parcelID then return item end
            end
        end
    end
end

local function checkCargo(parcel, revision)
    assert(C.revision(parcel) == revision, "Unexpected parcel revision")
    local label = assert(C.label(parcel))
    assert(label.toName == (revision < 3 and "Beth" or "Alice"), "Wrong recipient")
    assert(label.fromName == (revision < 3 and "Alice" or "Beth"), "Wrong sender")
    assert(label.note == note, "Note changed")
    local cargo = parcel:getInventory()
    assert(cargo:getItems():size() == 2 and cargo:getFirstType("Base.Battery"), "Cargo lost or duplicated")
    local bag = assert(cargo:getFirstType("Base.Bag_Schoolbag"), "Nested bag missing")
    assert(bag:getInventory():getFirstType("Base.Notebook"):seePage(1) == "Call at dawn.", "Nested note changed")
    assert(bag:getModData().other.story == "Still here.", "Nested item mod state changed")
end

Events.OnTick.Add(function()
    if phase == "done" or not players.Alice or not players.Beth then return end
    if startTime and getTimestampMs() - startTime > 90 * 1000 then
        print("PZ_TEST_FAIL MP phase timed out: " .. phase)
        phase = "done"
        return
    end
    if phase == "waiting" then
        startTime = getTimestampMs()
        world = { x=PZ_TEST_SPAWN.x, y=PZ_TEST_SPAWN.y, z=PZ_TEST_SPAWN.z, radius=4,
            levels={PZ_TEST_SPAWN.z}, ignore=Snapshot.DEFAULT_IGNORE }
        baseline = Snapshot.take(world)
        if PZ_TEST_PHOTOS then
            for name, player in pairs(players) do
                local shirt = name == "Alice" and "Base.Shirt_Lumberjack" or "Base.Jumper_RoundNeck"
                local tint = name == "Alice" and ImmutableColor.new(0.33, 0.49, 0.44) or ImmutableColor.new(0.62, 0.40, 0.23)
                for _, kind in ipairs({shirt, "Base.Trousers_Denim", "Base.Shoes_TrainerTINT"}) do
                    local clothing = player:getInventory():AddItem(kind)
                    if kind == shirt then clothing:getVisual():setTint(tint) end
                    sendAddItemToContainer(player:getInventory(), clothing)
                    player:setWornItem(clothing:getBodyLocation(), clothing)
                    sendClothing(player, clothing:getBodyLocation(), clothing)
                end
                syncVisuals(player)
                syncClothingFields(player)
            end
        end
        local inventory = players.Alice:getInventory()
        local parcel = inventory:AddItem(C.itemType)
        parcel:getInventory():AddItem("Base.Battery")
        local bag = parcel:getInventory():AddItem("Base.Bag_Schoolbag")
        bag:getModData().other = { story = "Still here." }
        bag:getInventory():AddItem("Base.Notebook"):addPage(1, "Call at dawn.")
        parcelID = parcel:getID()
        sendAddItemToContainer(inventory, parcel)
        print("PZ_TEST_DIAG server issued parcel " .. parcelID)
        announce("Alice", "seal", { note = note, recipient = "Beth" })
        phase = "seal"
    elseif phase == "seal" then
        local parcel = owner("Alice")
        if parcel and C.isSealed(parcel) then
            checkCargo(parcel, 1)
            assert(not owner("Beth") and syncCount == 1)
            print("PZ_TEST_PASS real Alice seal action committed once")
            announce("Alice", "drop")
            phase = "floor"
        end
    elseif phase == "floor" then
        local parcel = floorParcel()
        if parcel then
            local recipient = round == 1 and "Beth" or "Alice"
            assert(not owner("Alice") and not owner("Beth") and C.isSealed(parcel), "Parcel did not transfer atomically to floor")
            checkCargo(parcel, round * 2 - 1)
            announce(recipient, "pickup")
            phase = "open"
        end
    elseif phase == "open" then
        local recipient = round == 1 and "Beth" or "Alice"
        local parcel = owner(recipient)
        if parcel and not C.isSealed(parcel) and verified[recipient] then
            assert(not floorParcel() and not owner(round == 1 and "Alice" or "Beth"), "Parcel duplicated across owners")
            checkCargo(parcel, round * 2)
            assert(syncCount == round * 2, "Wrong parcel sync count " .. syncCount)
            print("PZ_TEST_PASS real " .. recipient .. " pickup and open committed once with native cargo")
            if round == 1 and PZ_TEST_RECONNECT then
                announce("Beth", "seal", { note = note, recipient = "Alice" })
                verified = {}
                phase = "reseal"
            else
                local leaks = Snapshot.addLines({}, Snapshot.diff(baseline, Snapshot.take(world)))
                assert(#leaks == 0, table.concat(leaks, "; "))
                announce("Alice", "pass")
                announce("Beth", "pass")
                phase = "done"
                print("PZ_TEST_SERVER_PASS rounds=" .. round .. " known seal/open sync packets=" .. syncCount .. " clean world")
            end
        end
    elseif phase == "reseal" then
        local parcel = owner("Beth")
        if parcel and C.isSealed(parcel) and verified.Beth then
            checkCargo(parcel, 3)
            assert(syncCount == 3)
            players.Beth = nil
            verified = {}
            phase = "reconnect"
            print("PZ_TEST_RECONNECT_READY")
        end
    elseif phase == "reconnect" then
        local parcel = owner("Beth")
        if parcel then
            checkCargo(parcel, 3)
            assert(C.isSealed(parcel), "Seal lost on reconnect")
            round = 2
            startTime = getTimestampMs()
            announce("Beth", "drop")
            phase = "floor"
            print("PZ_TEST_PASS reconnect kept sealed parcel under Beth's ownership")
        end
    end
end)

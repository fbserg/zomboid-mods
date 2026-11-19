local C = require "CarePackages"
require "TimedActions/ISCareParcelAction"

local X, Y = 10628, 10658
local started, done = false, false
local function checkItems(parcel)
    local cargo = parcel:getInventory()
    assert(cargo:getItems():size() == 2, "Parcel contents changed")
    local bag = assert(cargo:getFirstType("Base.Bag_Schoolbag"), "Nested bag missing")
    assert(bag:getModData().unknown.bag == "untouched", "Unknown bag data changed")
    local inner = bag:getInventory()
    local gun = assert(inner:getFirstType("Base.Pistol"), "Pistol missing")
    assert(gun:getCurrentAmmoCount() == 7 and gun:getCondition() == 4, "Pistol state changed")
    local journal = assert(inner:getFirstType("Base.Notebook"), "Journal missing")
    assert(journal:seePage(1) == "Bring the spare radio." and journal:getModData().other.answer == 42, "Journal state changed")
    assert(cargo:getFirstType("Base.Apple"), "Food missing")
    return cargo:getFirstType("Base.Apple")
end

Events.OnServerStarted.Add(function() started = true end)
Events.OnTick.Add(function()
    if not started or done or not farmTestKeepLoaded then return end
    farmTestKeepLoaded(X, Y)
    local square = getCell():getGridSquare(X, Y, 0)
    if not square then return end
    done = true
    local ok, failure = pcall(function()
        local marker = ModData.getOrCreate("CarePackagesProbe")
        local player = IsoPlayer.new(getCell())
        player:setUsername("Alice")
        local inventory = player:getInventory()
        if marker.saved then
            local parcel
            local objects = square:getWorldObjects()
            for i = 0, objects:size() - 1 do
                local item = objects:get(i):getItem()
                if C.isParcel(item) then parcel = item end
            end
            assert(parcel and C.isSealed(parcel), "Sealed parcel missing after restart")
            local label = C.label(parcel)
            assert(label.toName == "Beth" and label.fromName == "Alice" and label.note == "For the long road.\nStay safe.")
            local apple = checkItems(parcel)
            assert(apple:getAge() >= marker.age and apple:getAge() < marker.age + 0.25, "Saved food age changed")
            assert(math.abs(apple:getHeat() - marker.heat) < 0.08, "Saved temperature changed: " .. apple:getHeat())
            assert(parcel:getModData().unrelated == "preserve", "Other parcel mod data changed")
            print("PZ_TEST_RESTART_PASS seal, note, nested items, ammo, condition, journal, mod data and live food state survived process restart")
            return
        end
        assert(getScriptManager():getItem(C.itemType), "Parcel item script missing")
        local recipes = getScriptManager():getAllCraftRecipes()
        local recipe
        for i = 0, recipes:size() - 1 do
            if recipes:get(i):getName() == "MakeCarePackage" then recipe = recipes:get(i) end
        end
        assert(recipe and recipe:getInputs():size() == 2 and recipe:getOutputs():size() == 1, "Parcel recipe missing")
        local paper1 = inventory:AddItem("Base.SheetPaper2")
        local paper2 = inventory:AddItem("Base.GraphPaper")
        local twine = inventory:AddItem("Base.Twine")
        local twineBefore = twine:getCurrentUsesFloat()
        local sources = ArrayList.new()
        sources:add(inventory)
        local crafting = HandcraftLogic.new(player, nil, nil)
        crafting:setContainers(sources)
        crafting:setRecipe(recipe)
        assert(crafting:canPerformCurrentRecipe() and crafting:performCurrentRecipe(), "Native handcraft recipe failed")
        local produced = ArrayList.new()
        crafting:getCreatedOutputItems(produced)
        assert(produced:size() == 1 and C.isParcel(produced:get(0)), "Handcraft produced wrong item")
        crafting:getRecipeData():processDestroyAndUsedItems(player)
        assert(not inventory:contains(paper1) and not inventory:contains(paper2), "Paper was not consumed")
        assert(math.abs(twineBefore - twine:getCurrentUsesFloat() - 0.2) < 0.001, "Recipe did not consume one use of twine")
        print("PZ_TEST_PASS native handcraft consumed two sheets and one use of twine")
        local parcel = inventory:AddItem(produced:get(0))
        assert(instanceof(parcel, "InventoryContainer"), "Parcel is not a native container")
        assert(not C.canHandle(player, parcel, "seal"), "Empty parcel accepted")
        parcel:getModData().unrelated = "preserve"
        local cargo = parcel:getInventory()
        local bag = cargo:AddItem("Base.Bag_Schoolbag")
        bag:getModData().unknown = { bag = "untouched" }
        local inner = bag:getInventory()
        local gun = inner:AddItem("Base.Pistol")
        gun:setCondition(4)
        gun:setCurrentAmmoCount(7)
        local journal = inner:AddItem("Base.Notebook")
        journal:addPage(1, "Bring the spare radio.")
        journal:getModData().other = { answer = 42 }
        local apple = cargo:AddItem("Base.Apple")
        apple:setAge(1.5)
        apple:setHeat(0.5)
        local sync = syncItemModData
        local command = sendServerCommand
        local syncs, messages = 0, 0
        syncItemModData = function(p, item)
            assert(p == player and item == parcel)
            syncs = syncs + 1
        end
        sendServerCommand = function(p, module, action)
            assert(p == player and module == "ui" and action == "dirtyUI")
            messages = messages + 1
        end
        local invalid = ISCareParcelAction:new(player, parcel, "seal", C.revision(parcel), "   ", "Alice", "bad")
        assert(not invalid:complete() and not C.label(parcel) and checkItems(parcel) == apple)
        local seal = ISCareParcelAction:new(player, parcel, "seal", C.revision(parcel), " Beth ", "Alice", "For the long road.\nStay safe.")
        assert(seal:isValid() and seal:complete() and not seal:complete(), "Seal must commit once")
        assert(C.insideSeal(inner) and not cargo:isItemAllowed(instanceItem("Base.Battery")), "Seal allowed native addition")
        assert(checkItems(parcel) == apple and apple:getAge() == 1.5 and apple:getHeat() == 0.5, "Seal mutated contents")
        apple:setLastAged(math.max(0, getGameTime():getWorldAgeHours() - 1))
        apple:updateAge(false)
        assert(apple:getAge() > 1.5, "Food failed to age in sealed parcel: " .. apple:getAge())
        print("PZ_TEST_PASS native food age advanced while sealed")
        local open = ISCareParcelAction:new(player, parcel, "open", C.revision(parcel))
        assert(open:isValid() and open:complete() and not open:complete(), "Open must commit once")
        assert(not C.insideSeal(inner) and cargo:isItemAllowed(instanceItem("Base.Battery")), "Open left parcel inaccessible")
        assert(C.label(parcel).note == "For the long road.\nStay safe." and checkItems(parcel) == apple, "Open lost label or contents")
        assert(not seal:complete(), "Stale seal changed reopened parcel")
        seal = ISCareParcelAction:new(player, parcel, "seal", C.revision(parcel), "Beth", "Alice", "For the long road.\nStay safe.")
        assert(seal:complete() and not open:complete() and syncs == 3 and messages == 3, "Stale open or unexpected sync count")
        syncItemModData = sync
        sendServerCommand = command
        inventory:Remove(parcel)
        apple:setHeat(0.6)
        marker.age = apple:getAge()
        marker.heat = apple:getHeat()
        square:AddWorldInventoryItem(parcel, 0.5, 0.5, 0)
        marker.saved = true
        print("PZ_TEST_PASS successful actions kept native cargo identities, failures kept inventory intact, registered recipe and note")
    end)
    print(ok and "PZ_TEST_ENGINE_PASS" or ("PZ_TEST_FAIL " .. tostring(failure)))
end)

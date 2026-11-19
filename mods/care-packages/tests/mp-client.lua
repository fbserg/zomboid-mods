local role = '@ROLE@'
local C = require "CarePackages"
Events.OnMainMenuEnter.Add(function()
    getCore():setOptionShowSurvivalGuide(false)
    getCore():setTutorialDone(true)
    serverConnect(role, 'test-only', '127.0.0.1', '127.0.0.1', '16511', '', 'pz-test', false, true, 1, '')
end)
Events.OnConnected.Add(function()
    local region = assert(MapSpawnSelect.instance:useDefaultSpawnRegion(), 'No spawn region')
    setSpawnRegion(region.name)
    getWorld():setMap("Muldraugh, KY")
    getWorld():setLuaPlayerDesc(SurvivorFactory.CreateSurvivor())
    GameWindow.doRenderEvent(false)
    forceChangeState(LoadingQueueState.new())
end)
Events.OnConnectFailed.Add(function(message) print('PZ_TEST_FAIL connect ' .. role .. ' ' .. tostring(message)) end)

local ticks, task, form, played, ready, done = 0, nil, nil, false, false, false
local createChildren = CareParcelForm.createChildren
function CareParcelForm:createChildren()
    createChildren(self)
    form = self
end

Events.OnGameStart.Add(function()
    local player = getSpecificPlayer(0)
    player:setInvincible(true)
    player:setGhostMode(true)
    local x, y = PZ_TEST_SPAWN.x + 0.5, PZ_TEST_SPAWN.y + (role == "Beth" and 1.5 or 0.5)
    player:setX(x)
    player:setLastX(x)
    player:setY(y)
    player:setLastY(y)
    player:setCurrent(getCell():getGridSquare(math.floor(x), math.floor(y), PZ_TEST_SPAWN.z))
    assert(getText("IGUI_CarePackages_open") == "Open Care Package", "Menu translation missing")
    assert(getItemNameFromFullType(C.itemType) == "Care Package", "Item translation missing")
    local info = assert(getModInfoByID("CarePackages"), "Mod panel metadata missing")
    assert(info:getModVersion() == "0.1.0" and info:getPosterCount() == 3, "Unexpected mod panel metadata")
    assert(getTexture(info:getIcon()), "Mod icon did not load")
    for i = 0, info:getPosterCount() - 1 do
        assert(getTexture(info:getPoster(i)), "Mod poster did not load")
    end
end)

Events.OnServerCommand.Add(function(module, command, args)
    if module == "CareProbe" then
        print("PZ_TEST_DIAG " .. role .. " saw task " .. command .. " item=" .. args.id)
        task, played = args, false
        task.command = command
    end
end)

local function option(item, key, carried)
    local context = ISInventoryPaneContextMenu.createMenu(0, carried, { item }, 25, 110)
    local found = context:getOptionFromName(getText("IGUI_CarePackages_" .. key))
    context:hideAndChildren()
    return found
end

local function choose(item, key, carried)
    local selected = assert(option(item, key, carried), "Missing native menu option " .. key)
    selected.onSelect(selected.target, selected.param1, selected.param2)
end

local function verifyClosed(player, parcel)
    assert(parcel and C.isSealed(parcel))
    local cargo = parcel:getInventory()
    local crafting = ISInventoryPaneContextMenu.getContainers(player)
    assert(not crafting:contains(cargo), "Sealed cargo exposed to hand crafting")
    local battery = assert(cargo:getFirstType("Base.Battery"))
    local action = ISInventoryTransferUtil.newInventoryTransferAction(player, battery, cargo, player:getInventory())
    assert(not action:isValid(), "Sealed contents accepted a transfer")
end

Events.OnTick.Add(function()
    local player = getSpecificPlayer(0)
    if not player or done then return end
    ticks = ticks + 1
    if ticks > 180 and not ready then
        ready = true
        sendClientCommand(player, "CarePackages", "seal", { toName = "Bogus", fromName = "Bogus" })
        sendClientCommand(player, "CareProbe", "ready", {})
    end
    if not task or player:hasTimedActions() then return end
    local inventory = player:getInventory()
    local parcel = inventory:getItemWithID(task.id)
    if task.command == "seal" then
        if parcel and not played then
            played = true
            print("PZ_TEST_DIAG " .. role .. " has item " .. task.id)
            choose(parcel, "seal", true)
            assert(form and form.editing)
            form.toField:setText(task.recipient)
            form.fromField:setText(role)
            form.noteField:setText(task.note)
            form:onSubmit()
        elseif parcel and played and C.isSealed(parcel) then
            assert(C.label(parcel).note == task.note, "Synced note differs")
            verifyClosed(player, parcel)
            task = nil
            sendClientCommand(player, "CareProbe", "verified", {})
        end
    elseif task.command == "drop" then
        if parcel and not played and C.isSealed(parcel) then
            verifyClosed(player, parcel)
            ISInventoryPaneContextMenu.onDropItems({ parcel }, 0)
            played = true
            print("PZ_TEST_PASS " .. role .. " dropped the whole sealed parcel with vanilla action")
        end
    elseif task.command == "pickup" then
        if not played then
            ISInventoryPage.dirtyUI()
            local floor = ISInventoryPage.GetFloorContainer(0)
            local found = floor:getItemWithID(task.id)
            if not found then return end
            verifyClosed(player, found)
            assert(not option(found, "open", false), "Floor parcel can be opened by a non-owner")
            ISInventoryPaneContextMenu.onGrabItems({ found }, 0)
            played = "picking up"
        elseif played == "picking up" and parcel then
            assert(C.isSealed(parcel), "Seal lost on pickup")
            verifyClosed(player, parcel)
            choose(parcel, "open", true)
            played = "opening"
        elseif played == "opening" and parcel and not C.isSealed(parcel) then
            choose(parcel, "read", true)
            assert(form and not form.editing and form.fromField:getText() == (role == "Beth" and "Alice" or "Beth"))
            assert(form.toField:getText() == role and form.noteField:getText() == "Extra batteries and my route notes.\nSee you at dawn.")
            assert(parcel:getInventory():isItemAllowed(instanceItem("Base.Battery")), "Open parcel rejected cargo")
            form:close()
            local cargo = parcel:getInventory()
            assert(cargo:getFirstType("Base.Bag_Schoolbag"):getModData().other.story == "Still here.")
            print("PZ_TEST_PASS " .. role .. " opened and read the actual keepsake panel with synced cargo")
            task = nil
            sendClientCommand(player, "CareProbe", "verified", {})
        end
    elseif task.command == "pass" then
        done = true
        print("PZ_TEST_CLIENT_PASS " .. role)
    end
end)

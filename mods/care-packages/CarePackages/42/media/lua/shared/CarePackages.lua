CarePackages = {}
local C = CarePackages

C.itemType = "CarePackages.Parcel"
C.nameLimit = 48
C.noteLimit = 500

function C.isParcel(item)
    return item and item:getFullType() == C.itemType
end

function C.label(item)
    return item:getModData().CarePackages
end

function C.isSealed(item)
    if not C.isParcel(item) then return false end
    local label = C.label(item)
    return label ~= nil and label.sealed == true
end

function C.insideSeal(container)
    while container do
        local item = container:getContainingItem()
        if not item then return false end
        if C.isSealed(item) then return true end
        container = item:getContainer()
    end
    return false
end

function C.acceptItem(container, item)
    return not C.insideSeal(container)
end

local function clean(value, limit, multiline)
    if type(value) ~= "string" or #value > limit then return nil end
    value = value:gsub("\r\n", "\n")
    local singleLine = value:gsub("\n", "")
    if singleLine:find("%c") or (not multiline and value ~= singleLine) then return nil end
    return value:match("^%s*(.-)%s*$")
end

function C.validate(toName, fromName, note)
    toName = clean(toName, C.nameLimit)
    fromName = clean(fromName, C.nameLimit)
    note = clean(note, C.noteLimit, true)
    if not toName or toName == "" or not fromName or fromName == "" or not note then return nil end
    return { toName = toName, fromName = fromName, note = note, sealed = true }
end

function C.revision(item)
    local label = C.label(item)
    return label and label.revision or 0
end

function C.canHandle(player, item, operation)
    if not C.isParcel(item) or item:getContainer() ~= player:getInventory()
        or not player:getInventory():contains(item) then return false end
    if operation == "open" then return C.isSealed(item) == true end
    return operation == "seal" and not C.isSealed(item) and not item:getInventory():getItems():isEmpty()
end

function C.change(player, item, operation, revision, toName, fromName, note)
    if not C.canHandle(player, item, operation) or C.revision(item) ~= revision then return false end
    local label = C.label(item)
    if operation == "seal" then
        label = C.validate(toName, fromName, note)
        if not label then return false end
    else
        label = { toName = label.toName, fromName = label.fromName, note = label.note, sealed = false }
    end
    label.revision = revision + 1
    item:getModData().CarePackages = label
    if isServer() then
        syncItemModData(player, item)
        sendServerCommand(player, "ui", "dirtyUI", {})
    elseif not isClient() then
        ISInventoryPage.dirtyUI()
    end
    return true
end

return C

require "Vehicles/ISUI/ISVehicleMenu"
require "TruckRepaint"

local function requirementLine(text, met)
    local color = met and "<RGB:1,1,1>" or "<RGB:1,0,0>"
    return " <LINE> " .. color .. " " .. text
end

-- Like vanilla washing: walk to the driver door, not into the truck's center square.
local function onRepaint(playerObj, vehicle, skinIndex)
    ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, vehicle, TruckRepaint.AREA))
    ISTimedActionQueue.add(ISRepaintTruck:new(playerObj, vehicle, skinIndex))
end

-- Runs on every vehicle right-click. Other vehicles stop at the first table lookup.
local function addRepaintMenu(playerObj, context, vehicle)
    local skins = TruckRepaint.SKINS[vehicle:getScript():getName()]
    if not skins then return end
    local targets = {}
    for skinIndex in pairs(skins) do
        if skinIndex ~= vehicle:getSkinIndex() and TruckRepaint.getSkin(vehicle, skinIndex) then table.insert(targets, skinIndex) end
    end
    if #targets == 0 then return end
    table.sort(targets)

    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(context:addOption("Repaint Truck"), subMenu)
    local hasBrush = TruckRepaint.hasBrush(playerObj)
    for _, skinIndex in ipairs(targets) do
        local skin = skins[skinIndex]
        local option = subMenu:addOption(skin.name, playerObj, onRepaint, vehicle, skinIndex)
        local toolTip = ISWorldObjectContextMenu.addToolTip()
        toolTip:setName("Repaint: " .. skin.name)
        local description = requirementLine(getItemNameFromFullType("Base.Paintbrush"), hasBrush)
        for paintType, needed in pairs(skin.paint) do
            local uses = TruckRepaint.getPaintUses(playerObj, paintType)
            local text = getItemNameFromFullType("Base." .. paintType) .. " " .. uses .. "/" .. needed .. " uses"
            description = description .. requirementLine(text, uses >= needed)
        end
        toolTip.description = description
        option.toolTip = toolTip
        option.notAvailable = not TruckRepaint.canPaint(playerObj, skin)
    end
end

local fillMenuOutsideVehicle = ISVehicleMenu.FillMenuOutsideVehicle
function ISVehicleMenu.FillMenuOutsideVehicle(player, context, vehicle, test)
    local result = fillMenuOutsideVehicle(player, context, vehicle, test)
    addRepaintMenu(getSpecificPlayer(player), context, vehicle)
    return result
end

-- The server has already set the index. Clients rebuild the visible model.
Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "TruckRepaint" or command ~= "updateSkin" then return end
    local vehicle = getVehicleById(args.vehicle)
    if not vehicle then return end
    vehicle:setSkinIndex(args.index)
    vehicle:updateSkin()
end)

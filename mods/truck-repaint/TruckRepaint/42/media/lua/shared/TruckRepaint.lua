require "TimedActions/ISBaseTimedAction"

TruckRepaint = {}

-- Plain paint jobs per KI5 vehicle script, keyed by the script's 0-based skin index.
-- Liveries (Spiffo, Knox Bank, SWAT, US Army) are left out: paint covers a livery but never creates one.
-- Paint is in vanilla bucket uses. One full bucket holds 10. A wall takes 1.
-- The Oshkosh entries stay idle unless KI5's '86 Oshkosh P19A mod is loaded.
local CAMO = { PaintGreen = 4, PaintBrown = 3, PaintBlack = 3 }
local REDNECK_CAMO = { name = "Redneck Camo", paint = { PaintGreen = 5, PaintBrown = 5 } }
TruckRepaint.SKINS = {
    ["87fordF700box"] = {
        [0] = { name = "Blue and White", paint = { PaintBlue = 5, PaintWhite = 5 } },
        [2] = { name = "Red and Black", paint = { PaintRed = 5, PaintBlack = 5 } },
        [5] = { name = "White", paint = { PaintWhite = 10 } },
        [6] = { name = "Yellow", paint = { PaintYellow = 10 } },
        [7] = { name = "Red and White", paint = { PaintRed = 5, PaintWhite = 5 } },
    },
    ["87fordF700bank"] = {
        [0] = { name = "Red and Black", paint = { PaintRed = 5, PaintBlack = 5 } },
        [1] = { name = "Silver and Black", paint = { PaintGrey = 5, PaintBlack = 5 } },
    },
    ["87fordF700swat"] = {
        [0] = { name = "Black", paint = { PaintBlack = 10 } },
    },
    ["87fordB700military"] = { [1] = REDNECK_CAMO },
    -- Index 1 is the camo skin this mod appends to each one-skin bus below.
    ["87fordB700school"] = { [1] = REDNECK_CAMO },
    ["87fordB700prison"] = { [1] = REDNECK_CAMO },
    ["86oshkoshUSMC"] = {
        [0] = { name = "USMC Green", paint = { PaintGreen = 10 } },
        [1] = { name = "NATO Green", paint = { PaintGreen = 5, PaintBlack = 5 } },
        [2] = { name = "Desert Tan", paint = { PaintLightBrown = 10 } },
        [3] = { name = "Camo", paint = CAMO },
    },
    ["86oshkoshFRTR55"] = {
        [0] = { name = "NATO Green", paint = { PaintGreen = 5, PaintBlack = 5 } },
        [1] = { name = "USMC Green", paint = { PaintGreen = 10 } },
        [2] = { name = "Desert Tan", paint = { PaintLightBrown = 10 } },
        [3] = { name = "Camo", paint = CAMO },
    },
    ["86oshkoshKYFD"] = {
        [0] = { name = "Red", paint = { PaintRed = 10 } },
        [1] = { name = "Yellow", paint = { PaintYellow = 10 } },
        [2] = { name = "Red and White", paint = { PaintRed = 5, PaintWhite = 5 } },
    },
}

-- KI5's school and prison buses ship one skin each. Append the military bus's camo. All three share one body model.
-- Removal is safe: the game clamps a saved skin index that the script no longer has.
local BUS_CAMO = "Vehicles/Vehicles_87fordB700military_Shell_redneckCamo"
function TruckRepaint.addBusCamo()
    for _, name in ipairs({ "87fordB700school", "87fordB700prison" }) do
        local script = getScriptManager():getVehicle("Base." .. name)
        if script:getSkinCount() == 1 then
            script:Load(name, "{ skin { texture = " .. BUS_CAMO .. ", } }")
            if not isServer() then BaseVehicle.LoadVehicleTextures(script) end
        end
        assert(script:getSkinCount() == 2, name .. " has " .. script:getSkinCount() .. " skins")
    end
end
Events.OnInitWorld.Add(TruckRepaint.addBusCamo)

-- Wall painting takes 100 ticks per bucket use.
TruckRepaint.DURATION = 1200
-- The painter stands at the driver door, like vanilla washing stands at a vehicle area.
TruckRepaint.AREA = "SeatFrontLeft"
-- The paint animation can nudge the painter out of the exact area. Two tiles still rules out remote or drive-away jobs.
TruckRepaint.REACH = 2

function TruckRepaint.isNear(vehicle, character)
    local door = vehicle:getAreaCenter(TruckRepaint.AREA)
    local dx, dy = door:getX() - character:getX(), door:getY() - character:getY()
    return dx * dx + dy * dy <= TruckRepaint.REACH * TruckRepaint.REACH
end

-- A KI5 update could drop a skin. Never set an index the truck no longer has.
function TruckRepaint.getSkin(vehicle, skinIndex)
    local skins = TruckRepaint.SKINS[vehicle:getScript():getName()]
    return skins and skinIndex < vehicle:getSkinCount() and skins[skinIndex] or nil
end

function TruckRepaint.getPaintUses(character, paintType)
    local items = character:getInventory():getAllTypeRecurse(paintType)
    local uses = 0
    for i = 0, items:size() - 1 do
        uses = uses + items:get(i):getCurrentUses()
    end
    return uses
end

function TruckRepaint.hasBrush(character)
    return character:getInventory():getFirstTagRecurse(ItemTag.PAINTBRUSH) ~= nil
end

function TruckRepaint.canPaint(character, skin)
    if not TruckRepaint.hasBrush(character) then return false end
    for paintType, needed in pairs(skin.paint) do
        if TruckRepaint.getPaintUses(character, paintType) < needed then return false end
    end
    return true
end

ISRepaintTruck = ISBaseTimedAction:derive("ISRepaintTruck")

function ISRepaintTruck:isValid()
    if self.vehicle:isRemovedFromWorld() or not TruckRepaint.isNear(self.vehicle, self.character) then return false end
    local skin = TruckRepaint.getSkin(self.vehicle, self.skinIndex)
    return skin ~= nil and TruckRepaint.canPaint(self.character, skin)
end

function ISRepaintTruck:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end

function ISRepaintTruck:update()
    self.character:faceThisObject(self.vehicle)
    self.character:setMetabolicTarget(Metabolics.LightWork)
end

function ISRepaintTruck:start()
    self:setActionAnim(CharacterActionAnims.Paint)
    self:setOverrideHandModels("PaintBrush", nil)
    self.sound = self.character:playSound("Painting")
end

function ISRepaintTruck:stop()
    if self.sound then self.character:stopOrTriggerSound(self.sound) end
    ISBaseTimedAction.stop(self)
end

function ISRepaintTruck:perform()
    if self.sound then self.character:stopOrTriggerSound(self.sound) end
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end

-- Runs on the server in multiplayer and locally in singleplayer.
-- The B42 server never calls isValid on a network action, so complete repeats it. Vanilla washing does the same.
function ISRepaintTruck:complete()
    if not self:isValid() then return false end
    local skin = TruckRepaint.getSkin(self.vehicle, self.skinIndex)
    for paintType, needed in pairs(skin.paint) do
        local items = self.character:getInventory():getAllTypeRecurse(paintType)
        for i = 0, items:size() - 1 do
            if needed == 0 then break end
            local item = items:get(i)
            local used = math.min(needed, item:getCurrentUses())
            for _ = 1, used do item:UseAndSync() end
            needed = needed - used
        end
    end
    self.vehicle:setSkinIndex(self.skinIndex)
    if isServer() then
        self.vehicle:transmitSkinIndex()
        sendServerCommand("TruckRepaint", "updateSkin", { vehicle = self.vehicle:getId(), index = self.skinIndex })
    else
        self.vehicle:updateSkin()
    end
    return true
end

function ISRepaintTruck:getDuration()
    if self.character:isTimedActionInstant() then return 1 end
    return TruckRepaint.DURATION
end

-- The server rebuilds this action from fields named like the constructor arguments.
function ISRepaintTruck:new(character, vehicle, skinIndex)
    local o = ISBaseTimedAction.new(self, character)
    o.vehicle = vehicle
    o.skinIndex = skinIndex
    o.maxTime = o:getDuration()
    return o
end

require "ISUI/ISUIElement"
require "BackyardBirds"

local B = BackyardBirds
B.visits = {}

-- Screen pixels at zoom 1, tuned against native captures.
local RIM_Z = 0.28 -- bath rim height in floor levels
local BIRD_PX = 32
-- Feet positions on the bowl rim: front, back right, back left. The bowl is about 84 x 44 at zoom 1.
local SLOTS = { { -8, -2 }, { 22, -14 }, { -26, -16 } }
local FLIGHT_PX = 48
local ARRIVE_MS, LEAVE_MS = 800, 1200
-- Tiles at which a player scares the birds off.
local SNEAK_RANGE, WALK_RANGE, RUN_RANGE = 1.5, 3, 5
local ZOMBIE_FLEE_RANGE = 4

local textures = {}
function B.texture(species, frame, facing)
    local name = "media/textures/BackyardBirds/" .. species .. "_" .. frame .. "_" .. facing .. ".png"
    textures[name] = textures[name] or assert(getTexture(name), "Missing " .. name)
    return textures[name]
end

function B.scareRange(player)
    if player:isSneaking() then return SNEAK_RANGE end
    if player:isRunning() or player:isSprinting() then return RUN_RANGE end
    return WALK_RANGE
end

-- Drawn like forage icons: a UI element pinned to the bath's tile. It never takes mouse input.
BirdVisit = ISUIElement:derive("BirdVisit")

-- Birds land one by one and leave one by one, on game time, so fast-forward speeds them up.
function BirdVisit:new(playerNum, args)
    local o = ISUIElement.new(self, 0, 0, 1, 1)
    o.playerNum = playerNum
    o.args = args
    o.zoom = 1
    local start = getGameTime():getWorldAgeHours()
    local ends = start + args.minutes / 60
    o.nextZombieCheck = getTimestampMs()
    o.birds = {}
    for i = 1, args.count do
        local arrive = i == 1 and start or start + ZombRand(20, 90) / 3600
        o.birds[i] = { slot = SLOTS[i], frame = "flap", facing = ZombRand(2) == 0 and "l" or "r", state = "waiting",
            arriveAt = arrive, leaveAt = math.max(arrive + 1 / 60, ends - ZombRand(0, 120) / 3600), hopUntil = 0 }
    end
    -- Back of the bowl first, so front birds overlap it.
    table.sort(o.birds, function(a, b) return a.slot[2] < b.slot[2] end)
    return o
end

function BirdVisit:prerender()
    local a = self.args
    self.zoom = getCore():getZoom(self.playerNum)
    self:setX(isoToScreenX(self.playerNum, a.x + 0.5, a.y + 0.5, a.z + RIM_Z))
    self:setY(isoToScreenY(self.playerNum, a.x + 0.5, a.y + 0.5, a.z + RIM_Z))
end

function BirdVisit:render()
    local a = self.args
    local square = getCell():getGridSquare(a.x, a.y, a.z)
    if not square or not square:isCouldSee(self.playerNum) then return end
    local now = getTimestampMs()
    local width = BIRD_PX / self.zoom
    local height = width * 14 / 16
    for _, bird in ipairs(self.birds) do
        local alpha, lift, drift = 1, 0, 0
        local away = bird.facing == "r" and 1 or -1
        if bird.state == "arriving" then
            local t = math.min(1, (now - bird.since) / ARRIVE_MS)
            alpha, lift = t, (1 - t) * FLIGHT_PX / self.zoom
            drift = -away * lift
        elseif bird.state == "leaving" then
            local t = math.min(1, (now - bird.since) / LEAVE_MS)
            alpha, lift = 1 - t, t * FLIGHT_PX / self.zoom
            drift = away * lift
        elseif bird.state == "present" and now < bird.hopUntil then
            lift = 3 / self.zoom
        end
        if bird.state ~= "waiting" and bird.state ~= "gone" then
            self:drawTextureScaled(B.texture(a.species, bird.frame, bird.facing),
                bird.slot[1] / self.zoom - width / 2 + drift, bird.slot[2] / self.zoom - height - lift,
                width, height, alpha, 1, 1, 1)
        end
    end
end

local function leave(bird, now)
    bird.state, bird.since, bird.frame = "leaving", now, "flap"
end

function BirdVisit:scare(now)
    self.scared = true
    for _, bird in ipairs(self.birds) do
        if bird.state == "waiting" then bird.state = "gone" end
        if bird.state == "arriving" or bird.state == "present" then leave(bird, now) end
    end
end

function BirdVisit:update()
    local a = self.args
    local now = getTimestampMs()
    local hours = getGameTime():getWorldAgeHours()
    local player = getSpecificPlayer(self.playerNum)
    if not player or not getCell():getGridSquare(a.x, a.y, a.z) then return self:close() end
    if not self.scared and B.distance(player, a.x, a.y) < B.scareRange(player) then self:scare(now) end
    if not self.scared and now >= self.nextZombieCheck then
        self.nextZombieCheck = now + 1000
        if B.zombieNear(a.x, a.y, a.z, ZOMBIE_FLEE_RANGE) then self:scare(now) end
    end
    local active, gone = 0, 0
    for _, bird in ipairs(self.birds) do
        if bird.state == "waiting" and hours >= bird.arriveAt then
            bird.state, bird.since = "arriving", now
        elseif bird.state == "arriving" and now - bird.since >= ARRIVE_MS then
            bird.state, bird.frame, bird.nextAt = "present", "perch", now + ZombRand(300, 1200)
        elseif bird.state == "present" and hours >= bird.leaveAt then
            leave(bird, now)
        elseif bird.state == "present" and now >= bird.nextAt then
            local roll = ZombRand(100)
            bird.frame = roll < 35 and "peck" or roll < 50 and "bathe" or "perch"
            if roll >= 50 and roll < 60 then bird.facing = bird.facing == "l" and "r" or "l" end
            if roll >= 60 and roll < 68 then bird.hopUntil = now + 250 end
            bird.nextAt = now + ZombRand(400, 1600)
        elseif bird.state == "leaving" and now - bird.since >= LEAVE_MS then
            bird.state = "gone"
        end
        if bird.state == "waiting" or bird.state == "arriving" or bird.state == "present" then active = active + 1 end
        if bird.state == "gone" then gone = gone + 1 end
    end
    -- BirdInTree is a short burst of chirps. Sing again after a pause until the last bird takes off.
    if active == 0 then
        self:stopSound()
    elseif self.sound and not self.emitter:isPlaying(self.sound) then
        self.sound, self.nextSongAt = nil, now + ZombRand(500, 3000)
    elseif not self.sound and now >= self.nextSongAt then
        self:sing()
    end
    if gone == #self.birds then self:close() end
end

-- A fresh free emitter each time: the world recycles one as soon as its burst ends.
function BirdVisit:sing()
    local a = self.args
    self.emitter = getWorld():getFreeEmitter(a.x + 0.5, a.y + 0.5, a.z)
    self.sound = self.emitter:playSound("BirdInTree")
    self.songs = self.songs + 1
end

function BirdVisit:stopSound()
    if self.sound then
        self.emitter:stopSound(self.sound)
        self.sound = nil
    end
end

function BirdVisit:close()
    self:stopSound()
    self:removeFromUIManager()
    if B.visits[self.key] == self then B.visits[self.key] = nil end
end

function B.showVisit(player, args)
    local playerNum = player:getPlayerNum()
    local key = B.key(args.x, args.y, args.z) .. "#" .. playerNum
    if B.visits[key] then B.visits[key]:close() end
    local visit = BirdVisit:new(playerNum, args)
    visit.key = key
    visit:initialise()
    visit:addToUIManager()
    visit.javaObject:setConsumeMouseEvents(false)
    visit:backMost()
    visit.songs = 0
    visit:sing()
    B.visits[key] = visit
    -- Text only when the mood lifts (at most hourly) or a rare bird is in view. Ordinary visits stay quiet.
    local square = getCell():getGridSquare(args.x, args.y, args.z)
    if args.boosted then
        HaloTextHelper.addTextWithArrow(player, B.visitText(args), true, HaloTextHelper.getGoodColor())
    elseif B.speciesById(args.species).rare and square and square:isCouldSee(playerNum) then
        HaloTextHelper.addText(player, B.visitText(args))
    end
    return visit
end

Events.OnServerCommand.Add(function(module, command, args)
    if module == "BackyardBirds" and command == "visit" then B.showVisit(getPlayer(), args) end
end)

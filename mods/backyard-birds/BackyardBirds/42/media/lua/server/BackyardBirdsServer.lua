if isClient() then return end
require "BackyardBirds"

local B = BackyardBirds
-- Transient: a restart only clears pending visits and boost cooldowns.
local visitEnds = {}
local lastBoost = {} -- ceiling: one entry per player seen this session, keyed by the player object.

function B.players()
    local players = {}
    if isServer() then
        local online = getOnlinePlayers()
        for i = 0, online:size() - 1 do players[#players + 1] = online:get(i) end
    else
        for i = 0, getNumActivePlayers() - 1 do
            local player = getSpecificPlayer(i)
            if player then players[#players + 1] = player end
        end
    end
    return players
end

-- The server owns mood changes, the same path vanilla flower harvests use.
function B.boost(player, now)
    if lastBoost[player] and now - lastBoost[player] < B.COOLDOWN_HOURS then return false end
    lastBoost[player] = now
    local stats = player:getStats()
    stats:remove(CharacterStat.BOREDOM, B.BOREDOM)
    stats:remove(CharacterStat.UNHAPPINESS, B.UNHAPPINESS)
    if isServer() then
        syncPlayerStats(player, SyncPlayerStatsPacket.getBitMaskForStat(CharacterStat.BOREDOM))
        syncPlayerStats(player, SyncPlayerStatsPacket.getBitMaskForStat(CharacterStat.UNHAPPINESS))
    end
    return true
end

function B.announce(square, args, players, now)
    local x, y, z = square:getX(), square:getY(), square:getZ()
    for _, player in ipairs(players) do
        local distance = B.distance(player, x, y)
        if math.floor(player:getZ()) == z and distance <= B.VIEW_RANGE then
            local message = { x = x, y = y, z = z, species = args.species, count = args.count, minutes = args.minutes,
                boosted = distance <= B.RANGE and B.boost(player, now) }
            if isServer() then
                sendServerCommand(player, "BackyardBirds", "visit", message)
            else
                B.showVisit(player, message)
            end
        end
    end
end

local lastRain = -1000
function B.tick()
    local time = getGameTime()
    local climate = getClimateManager()
    local now = time:getWorldAgeHours()
    local rain = climate:getRainIntensity()
    if rain >= B.MAX_RAIN then lastRain = now end
    local chance = B.visitChance(time:getHour(), rain, climate:getTemperature(), now - lastRain)
    if chance == 0 then return end
    local players = B.players()
    local baths, order = {}, {}
    for _, player in ipairs(players) do
        for _, square in ipairs(B.bathsNear(player)) do
            local key = B.key(square:getX(), square:getY(), square:getZ())
            if not baths[key] then baths[key] = square; order[#order + 1] = key end
        end
    end
    for _, key in ipairs(order) do
        local square = baths[key]
        if (visitEnds[key] or 0) <= now and ZombRand(100) < chance
            and not B.zombieNear(square:getX(), square:getY(), square:getZ(), B.ZOMBIE_RANGE) then
            local minutes = ZombRand(B.VISIT_MINUTES[1], B.VISIT_MINUTES[2] + 1)
            visitEnds[key] = now + minutes / 60
            B.announce(square, { species = B.pickSpecies(time:getMonth()).id, count = ZombRand(3) + 1, minutes = minutes }, players, now)
        end
    end
end

Events.EveryTenMinutes.Add(function() B.tick() end)

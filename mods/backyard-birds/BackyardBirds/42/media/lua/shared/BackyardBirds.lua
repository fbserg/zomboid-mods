BackyardBirds = {}

-- Kentucky yard birds. Months use the game's 0-based getMonth().
local ALL_YEAR = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }
local MARCH_TO_OCTOBER = { 2, 3, 4, 5, 6, 7, 8, 9 }
local APRIL_TO_OCTOBER = { 3, 4, 5, 6, 7, 8, 9 }
BackyardBirds.SPECIES = {
    { id = "cardinal", name = "Northern Cardinal", plural = "Northern Cardinals", months = ALL_YEAR },
    { id = "bluejay", name = "Blue Jay", plural = "Blue Jays", months = ALL_YEAR },
    { id = "chickadee", name = "Carolina Chickadee", plural = "Carolina Chickadees", months = ALL_YEAR },
    { id = "robin", name = "American Robin", plural = "American Robins", months = MARCH_TO_OCTOBER },
    { id = "goldfinch", name = "American Goldfinch", plural = "American Goldfinches", months = APRIL_TO_OCTOBER },
    { id = "bluebird", name = "Eastern Bluebird", plural = "Eastern Bluebirds", months = ALL_YEAR, rare = true },
}

BackyardBirds.CUSTOM_NAME = "Bird Bath"
BackyardBirds.RANGE = 10 -- tiles from a player to a bath that birds visit
BackyardBirds.VIEW_RANGE = 40 -- tiles within which other players see the visit
-- Percent per bath per ten game minutes. Busy mornings, a midday lull, a second evening wave.
BackyardBirds.CHANCE = { morning = 30, midday = 8, evening = 18 }
BackyardBirds.RARE_CHANCE = 5 -- percent of visits that bring the rare species
BackyardBirds.ZOMBIE_RANGE = 5
BackyardBirds.MAX_RAIN = 0.2
BackyardBirds.HOT, BackyardBirds.AFTER_RAIN_HOURS = 27, 2 -- Celsius, hours: each makes a visit 1.5 times as likely
BackyardBirds.VISIT_MINUTES = { 4, 12 }
BackyardBirds.BOREDOM, BackyardBirds.UNHAPPINESS = 5, 3
BackyardBirds.COOLDOWN_HOURS = 1

function BackyardBirds.speciesById(id)
    for _, species in ipairs(BackyardBirds.SPECIES) do
        if species.id == id then return species end
    end
    error("Unknown bird " .. tostring(id))
end

function BackyardBirds.speciesFor(month, rare)
    local found = {}
    for _, species in ipairs(BackyardBirds.SPECIES) do
        for _, m in ipairs(species.months) do
            if m == month and (species.rare == true) == rare then found[#found + 1] = species end
        end
    end
    return found
end

function BackyardBirds.pickSpecies(month)
    local pool = BackyardBirds.speciesFor(month, ZombRand(100) < BackyardBirds.RARE_CHANCE)
    return pool[ZombRand(#pool) + 1]
end

-- Percent chance of a visit this ten-minute tick. No birds at night, in rain, or on frozen water.
function BackyardBirds.visitChance(hour, rain, temperature, hoursSinceRain)
    if hour < 6 or hour >= 20 or rain >= BackyardBirds.MAX_RAIN or temperature <= 0 then return 0 end
    local chance = hour < 9 and BackyardBirds.CHANCE.morning or hour < 15 and BackyardBirds.CHANCE.midday or BackyardBirds.CHANCE.evening
    if temperature >= BackyardBirds.HOT then chance = chance * 1.5 end
    if hoursSinceRain < BackyardBirds.AFTER_RAIN_HOURS then chance = chance * 1.5 end
    return math.floor(chance)
end

function BackyardBirds.isBirdBath(object)
    local sprite = object:getSprite()
    return sprite ~= nil and sprite:getProperties():get("CustomName") == BackyardBirds.CUSTOM_NAME
end

function BackyardBirds.hasBirdBath(square)
    local objects = square:getObjects()
    for i = 0, objects:size() - 1 do
        if BackyardBirds.isBirdBath(objects:get(i)) then return true end
    end
    return false
end

function BackyardBirds.key(x, y, z)
    return x .. "," .. y .. "," .. z
end

-- Outdoor bird baths on the player's level within RANGE tiles.
function BackyardBirds.bathsNear(player)
    local found = {}
    local px, py, z = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    local cell = getCell()
    for x = px - BackyardBirds.RANGE, px + BackyardBirds.RANGE do
        for y = py - BackyardBirds.RANGE, py + BackyardBirds.RANGE do
            local square = cell:getGridSquare(x, y, z)
            if square and square:isOutside() and BackyardBirds.hasBirdBath(square) then found[#found + 1] = square end
        end
    end
    return found
end

function BackyardBirds.zombieNear(x, y, z, range)
    local cell = getCell()
    for sx = x - range, x + range do
        for sy = y - range, y + range do
            local square = cell:getGridSquare(sx, sy, z)
            if square then
                local moving = square:getMovingObjects()
                for i = 0, moving:size() - 1 do
                    if instanceof(moving:get(i), "IsoZombie") then return true end
                end
            end
        end
    end
    return false
end

function BackyardBirds.distance(player, x, y)
    local dx, dy = player:getX() - (x + 0.5), player:getY() - (y + 0.5)
    return math.sqrt(dx * dx + dy * dy)
end

function BackyardBirds.visitText(args)
    local species = BackyardBirds.speciesById(args.species)
    local rare = species.rare and "rare " or ""
    if args.count == 1 then
        local article = (rare .. species.name):match("^[AEIOUaeiou]") and "An " or "A "
        return article .. rare .. species.name .. " visits the bird bath"
    end
    return args.count .. " " .. rare .. species.plural .. " visit the bird bath"
end

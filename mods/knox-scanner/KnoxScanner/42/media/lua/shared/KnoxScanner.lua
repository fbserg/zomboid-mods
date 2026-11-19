-- Knox Scanner writes notable events of the local player to Zomboid/Lua/KnoxScanner.txt.
-- Each line is JSON with plain fields (kind, place, day, hour, text) and a ready Discord
-- message ("username", "content"), so a one-line tail command can post it to a webhook
-- and any other tool can read the fields.
-- A dedicated server loads this file and does nothing with it. The client file adds the
-- options and the event hooks.

KnoxScanner = KnoxScanner or {}
local S = KnoxScanner

-- The game only opens ini, cfg, txt, log and json files for mods.
S.FILE = "KnoxScanner.txt"
S.HORDE_SIZE = 40
S.HORDE_RADIUS = 20
S.HORDE_COOLDOWN_HOURS = 6
S.KILL_STEP = 100
S.DAY_STEP = 7

-- ceiling: hand-drawn rectangles around each town, replace with map zone data if the game exposes town names
S.TOWNS = {
    { "Muldraugh", 10500, 9200, 11100, 10700 },
    { "West Point", 10800, 6500, 12400, 7200 },
    { "Riverside", 5700, 5100, 7500, 6100 },
    { "Rosewood", 7550, 11200, 8600, 12400 },
    { "March Ridge", 9700, 12400, 10500, 13300 },
    { "Valley Station", 12300, 4700, 14200, 5900 },
    { "Louisville", 11700, 900, 14700, 4700 },
    { "Fallas Lake", 7100, 8100, 7500, 8500 },
    { "Ekron", 100, 9450, 800, 10100 },
    { "Brandenburg", 1600, 5600, 2800, 6600 },
    { "Irvington", 1500, 13900, 2700, 14800 },
    { "Echo Creek", 3300, 10600, 3900, 11200 },
}

-- Matched against the lower-case room name, first hit wins.
S.LANDMARKS = {
    { "police", "a police station" },
    { "gunstore", "a gun store" },
    { "prison", "the prison" },
    { "fire", "a fire station" },
    { "pharmacy", "a pharmacy" },
    { "hospital", "the hospital" },
    { "medical", "a medical clinic" },
    { "spiffo", "a Spiffo's" },
    { "army", "an army storeroom" },
    { "church", "a church" },
    { "bank", "a bank" },
    { "school", "a school" },
    { "classroom", "a school" },
}

-- Tick boxes in Mod Options, in display order. Every event kind is one of these ids.
S.TOGGLES = { "enabled", "note", "death", "bitten", "hurt", "town", "landmark", "helicopter", "power",
    "storm", "horde", "kills", "days", "request" }

function S.on(id)
    return S.options:getOption(id):getValue()
end

function S.townAt(x, y)
    for _, town in ipairs(S.TOWNS) do
        if x >= town[2] and y >= town[3] and x <= town[4] and y <= town[5] then return town[1] end
    end
end

function S.landmarkIn(roomName)
    local name = string.lower(roomName)
    for _, landmark in ipairs(S.LANDMARKS) do
        if string.find(name, landmark[1], 1, true) then return landmark[2] end
    end
end

local function quoted(text)
    return '"' .. string.gsub(string.gsub(text, "\\", "\\\\"), '"', '\\"') .. '"'
end

function S.note(player, kind)
    HaloTextHelper.addText(player, getText("IGUI_KnoxScanner_sent", kind))
end

function S.emit(kind, text)
    if not (S.on("enabled") and S.on(kind)) then return end
    local player = getSpecificPlayer(0)
    local time = getGameTime()
    local hour = time:getHour()
    local day = math.floor(time:getWorldAgeHours() / 24) + 1
    local place = S.townAt(player:getX(), player:getY()) or "the countryside"
    local content = kind .. " | " .. place .. " | day " .. day .. ", " .. (hour < 10 and "0" or "") .. hour .. ":00 | " .. text
    local writer = getFileWriter(S.FILE, true, true)
    -- 📡 is the satellite antenna emoji as a JSON escape, so the file stays ASCII.
    writer:write('{"username":"Knox Scanner","content":"\\ud83d\\udce1 ' .. string.sub(quoted(content), 2)
        .. ',"kind":' .. quoted(kind) .. ',"place":' .. quoted(place) .. ',"day":' .. day .. ',"hour":' .. hour
        .. ',"text":' .. quoted(text) .. '}\n')
    writer:close()
    if S.on("note") then S.note(player, kind) end
end

function S.zombiesNear(player)
    -- One engine call per zombie for the distance. Reading x and y separately cost half as much again.
    local zombies = getCell():getZombieList()
    local reach = S.HORDE_RADIUS * S.HORDE_RADIUS
    local count = 0
    for i = 0, zombies:size() - 1 do
        if player:DistToSquared(zombies:get(i)) <= reach then count = count + 1 end
    end
    return count
end

-- Runs once a game minute. The first poll of a character records where things stand and
-- reports nothing. A check whose tick box is off costs nothing.
function S.poll()
    if not S.on("enabled") then return end
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return end
    local time = getGameTime()
    local body = player:getBodyDamage()
    local town = S.townAt(player:getX(), player:getY())
    local bites = body:getNumPartsBitten()
    local health = body:getOverallBodyHealth()
    local killMark = math.floor(player:getZombieKills() / S.KILL_STEP)
    local power = getWorld():isHydroPowerOn()
    local helicopter = time:getNightsSurvived() == time:getHelicopterDay1()
        and time:getTimeOfDay() >= time:getHelicopterStartHour() and time:getTimeOfDay() < time:getHelicopterEndHour()
    local landmark
    if S.on("landmark") then
        local square = player:getCurrentSquare()
        local room = square and square:getRoom()
        landmark = room and S.landmarkIn(room:getName())
    end
    local was = S.state
    if not was then
        S.state = { town = town, landmark = landmark, bites = bites, hurt = health < 50, killMark = killMark,
            power = power, helicopter = helicopter, hordeAt = -S.HORDE_COOLDOWN_HOURS }
        return
    end

    if town and town ~= was.town then
        was.town = town
        S.emit("town", "A survivor reached " .. town .. ".")
    end
    if landmark and landmark ~= was.landmark then
        S.emit("landmark", "A survivor went into " .. landmark .. ".")
    end
    was.landmark = landmark
    if bites > was.bites then S.emit("bitten", "A survivor was bitten by a zombie.") end
    was.bites = bites
    if health < 50 and not was.hurt then
        was.hurt = true
        S.emit("hurt", "A survivor is badly hurt.")
    elseif health >= 70 then
        was.hurt = false
    end
    if killMark > was.killMark then
        S.emit("kills", "A survivor has killed " .. (killMark * S.KILL_STEP) .. " zombies.")
    end
    was.killMark = killMark
    if was.power and not power then S.emit("power", "The power grid went down.") end
    was.power = power
    if helicopter and not was.helicopter then S.emit("helicopter", "A helicopter is circling overhead.") end
    was.helicopter = helicopter
    -- The zombie scan is the one check that grows with the world, so it waits out its cooldown.
    if S.on("horde") and time:getWorldAgeHours() - was.hordeAt >= S.HORDE_COOLDOWN_HOURS then
        local horde = S.zombiesNear(player)
        if horde >= S.HORDE_SIZE then
            was.hordeAt = time:getWorldAgeHours()
            S.emit("horde", "A horde of about " .. horde .. " zombies is closing in on a survivor.")
        end
    end
end

function S.onDeath(player)
    if not player:isLocalPlayer() then return end
    S.emit("death", "A survivor died after " .. math.floor(player:getHoursSurvived() / 24) .. " days and "
        .. player:getZombieKills() .. " zombie kills.")
    S.state = nil
end

function S.onDay()
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return end
    local days = math.floor(player:getHoursSurvived() / 24)
    if days > 0 and days % S.DAY_STEP == 0 then S.emit("days", "A survivor has lasted " .. days .. " days.") end
end

function S.onWeather(period)
    local storm = period:isBlizzard() and "A blizzard" or period:isTropicalStorm() and "A tropical storm"
        or period:isThunderStorm() and "A thunderstorm"
    if storm then S.emit("storm", storm .. " is rolling in.") end
end

function S.onKey(key)
    if key ~= 0 and key == S.requestKey:getValue() and getSpecificPlayer(0) then
        S.emit("request", "A survivor is asking for a broadcast.")
    end
end

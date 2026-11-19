-- Knox Scanner writes notable events of the local player to ~/Zomboid/Lua/KnoxScanner.jsonl.
-- Each line is a ready Discord webhook body, so a one-line tail command can post it.
-- Line content: "<satellite emoji> kind | place | day N, HH:00 | text".

KnoxScanner = KnoxScanner or {}
local S = KnoxScanner

S.FILE = "KnoxScanner.jsonl"
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

S.TOGGLES = {
    { "enabled", "Scanner on", "Master switch. Off writes nothing." },
    { "death", "Deaths", "Your character dies." },
    { "bitten", "Bites", "Your character gets a new zombie bite." },
    { "hurt", "Bad injuries", "Your health drops below half." },
    { "town", "Towns", "You reach a town." },
    { "landmark", "Landmarks", "You walk into a police station, gun store, prison, hospital and the like." },
    { "helicopter", "Helicopter", "The helicopter event starts." },
    { "power", "Power grid", "The power grid shuts off." },
    { "storm", "Storms", "A thunderstorm, tropical storm or blizzard starts." },
    { "horde", "Hordes", "Forty or more zombies within twenty tiles." },
    { "kills", "Kill milestones", "Every hundred zombie kills." },
    { "days", "Survival milestones", "Every seventh day survived." },
    { "request", "Broadcast request key", "The key below asks for a broadcast." },
}

S.options = PZAPI.ModOptions:create("KnoxScanner", "Knox Scanner")
S.options:addDescription("Writes the events ticked below to Zomboid/Lua/KnoxScanner.jsonl. A small command outside the game posts them to Discord.")
for _, toggle in ipairs(S.TOGGLES) do
    S.options:addTickBox(toggle[1], toggle[2], true, toggle[3])
end
S.requestKey = S.options:addKeyBind("requestKey", "Request a broadcast", 0, "Unbound by default.")

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

function S.emit(kind, text)
    if not (S.on("enabled") and S.on(kind)) then return end
    local player = getSpecificPlayer(0)
    local time = getGameTime()
    local hour = time:getHour()
    local content = kind .. " | " .. (S.townAt(player:getX(), player:getY()) or "the countryside")
        .. " | day " .. (math.floor(time:getWorldAgeHours() / 24) + 1) .. ", " .. (hour < 10 and "0" or "") .. hour .. ":00"
        .. " | " .. text
    content = string.gsub(string.gsub(content, "\\", "\\\\"), '"', '\\"')
    local writer = getFileWriter(S.FILE, true, true)
    -- 📡 is the satellite antenna emoji as a JSON escape, so this file stays ASCII.
    writer:write('{"username":"Knox Scanner","content":"\\ud83d\\udce1 ' .. content .. '"}\n')
    writer:close()
end

function S.zombiesNear(player)
    local zombies = getCell():getZombieList()
    local count = 0
    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if math.abs(zombie:getX() - player:getX()) <= S.HORDE_RADIUS and math.abs(zombie:getY() - player:getY()) <= S.HORDE_RADIUS then
            count = count + 1
        end
    end
    return count
end

-- The first poll of a character records where things stand and reports nothing.
function S.poll()
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return end
    local time = getGameTime()
    local body = player:getBodyDamage()
    local square = player:getCurrentSquare()
    local room = square and square:getRoom()
    local now = {
        town = S.townAt(player:getX(), player:getY()),
        landmark = room and S.landmarkIn(room:getName()),
        bites = body:getNumPartsBitten(),
        health = body:getOverallBodyHealth(),
        killMark = math.floor(player:getZombieKills() / S.KILL_STEP),
        power = getWorld():isHydroPowerOn(),
        helicopter = time:getNightsSurvived() == time:getHelicopterDay1()
            and time:getTimeOfDay() >= time:getHelicopterStartHour() and time:getTimeOfDay() < time:getHelicopterEndHour(),
        horde = S.zombiesNear(player),
    }
    local was = S.state
    if not was then
        S.state = { town = now.town, landmark = now.landmark, bites = now.bites, hurt = now.health < 50,
            killMark = now.killMark, power = now.power, helicopter = now.helicopter, hordeAt = -S.HORDE_COOLDOWN_HOURS }
        return
    end

    if now.town and now.town ~= was.town then
        was.town = now.town
        S.emit("town", "A survivor reached " .. now.town .. ".")
    end
    if now.landmark and now.landmark ~= was.landmark then
        S.emit("landmark", "A survivor went into " .. now.landmark .. ".")
    end
    was.landmark = now.landmark
    if now.bites > was.bites then S.emit("bitten", "A survivor was bitten by a zombie.") end
    was.bites = now.bites
    if now.health < 50 and not was.hurt then
        was.hurt = true
        S.emit("hurt", "A survivor is badly hurt.")
    elseif now.health >= 70 then
        was.hurt = false
    end
    if now.killMark > was.killMark then
        S.emit("kills", "A survivor has killed " .. (now.killMark * S.KILL_STEP) .. " zombies.")
    end
    was.killMark = now.killMark
    if was.power and not now.power then S.emit("power", "The power grid went down.") end
    was.power = now.power
    if now.helicopter and not was.helicopter then S.emit("helicopter", "A helicopter is circling overhead.") end
    was.helicopter = now.helicopter
    if now.horde >= S.HORDE_SIZE and time:getWorldAgeHours() - was.hordeAt >= S.HORDE_COOLDOWN_HOURS then
        was.hordeAt = time:getWorldAgeHours()
        S.emit("horde", "A horde of about " .. now.horde .. " zombies is closing in on a survivor.")
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

Events.OnCreatePlayer.Add(function() S.state = nil end)
Events.EveryOneMinute.Add(S.poll)
Events.OnPlayerDeath.Add(S.onDeath)
Events.EveryDays.Add(S.onDay)
Events.OnWeatherPeriodStart.Add(S.onWeather)
Events.OnKeyPressed.Add(S.onKey)

-- Grocery List: write a list, carry the items, bring it home to whoever wrote it.
-- The server (or the single-player game) reads the vanilla page text once per game minute.
SharedGroceryList = {}
local G = SharedGroceryList
local MODULE, TYPE = "SharedGroceryList", "SharedGroceryList.GroceryList"
local MARK = "[x] "
local MIN_LINES, COOLDOWN = 3, 24
local REWARDS = {
    done = { [CharacterStat.BOREDOM] = 10, [CharacterStat.UNHAPPINESS] = 5 },
    thanks = { [CharacterStat.UNHAPPINESS] = 10 },
    delivered = { [CharacterStat.UNHAPPINESS] = 10 },
}

function G.show(player, command, text)
    local name = "IGUI_SharedGroceryList_" .. command
    HaloTextHelper.addGoodText(player, text and getText(name, text) or getText(name))
end

if isClient() then
    Events.OnServerCommand.Add(function(module, command, args)
        if module == MODULE and (command == "got" or REWARDS[command]) then
            G.show(getSpecificPlayer(0), command, args.text)
        end
    end)
    return
end

local function key(player)
    if isServer() then return player:getUsername() end
    return "local:" .. player:getPlayerNum()
end

local function players()
    local result = {}
    if isServer() then
        local online = getOnlinePlayers()
        for i = 0, online:size()-1 do result[#result+1] = online:get(i) end
    else
        for i = 0, getNumActivePlayers()-1 do
            local p = getSpecificPlayer(i)
            if p then result[#result+1] = p end
        end
    end
    return result
end

local function notify(player, command, text)
    if isServer() then
        sendServerCommand(player, MODULE, command, { text = text })
    else
        G.show(player, command, text)
    end
end

local function reward(player, kind, now, text)
    local ledger = ModData.getOrCreate("SharedGroceryListRewards")
    local id = kind .. ":" .. key(player)
    if not ledger[id] or now - ledger[id] >= COOLDOWN or now < ledger[id] then
        ledger[id] = now
        local stats = player:getStats()
        for stat, amount in pairs(REWARDS[kind]) do
            stats:remove(stat, amount)
            if isServer() then syncPlayerStats(player, SyncPlayerStatsPacket.getBitMaskForStat(stat)) end
        end
    end
    notify(player, kind, text)
end

-- "2 cans of beans" and "- milk" both mean the item name. "[x] " is the server's own mark.
function G.parse(text)
    local lines = {}
    for raw in (text .. "\n"):gmatch("([^\n]*)\n") do
        local want = raw:gsub("^%s+", ""):gsub("%s+$", "")
        if want:sub(1, #MARK) == MARK then want = want:sub(#MARK + 1) end
        want = want:gsub("^[-*]+%s*", ""):gsub("^%d+%s*[xX]?%s+", ""):gsub("%s+", " ")
        local item = #want >= 3 and want:sub(1, 1) ~= "~"
        lines[#lines+1] = { raw = raw, want = want, key = item and want:lower() or nil }
    end
    return lines
end

local function candidates(word)
    local result = { word }
    if word:sub(-3) == "ies" then result[#result+1] = word:sub(1, -4) .. "y" end
    if word:sub(-2) == "es" then result[#result+1] = word:sub(1, -3) end
    if word:sub(-1) == "s" then result[#result+1] = word:sub(1, -2) end
    return result
end

function G.matches(word, names)
    for _, candidate in ipairs(candidates(word)) do
        for _, name in ipairs(names) do
            if name:find(candidate, 1, true) then return true end
        end
    end
    return false
end

local function carried(player)
    local names = {}
    player:getInventory():getAllEvalRecurse(function(item)
        if item:getFullType() ~= TYPE then names[#names+1] = item:getDisplayName():lower() end
        return false
    end)
    return names
end

local function forename(player)
    return player:getDescriptor():getForename()
end

local function find(id)
    for _, p in ipairs(players()) do
        if key(p) == id then return p end
    end
end

function G.check(player, list, now, names)
    local data = list:getModData()
    local lines = G.parse(list:seePage(1) or "")
    local items = {}
    for _, line in ipairs(lines) do
        if line.key then items[#items+1] = line.key end
    end
    if #items == 0 then return names end
    -- ceiling: the first holder seen with text is the author; a hand-off inside one game minute misattributes it.
    local dirty, changed = false, false
    if not data.author then
        data.author, data.got, dirty = key(player), {}, true
    end
    for _, line in ipairs(lines) do
        if line.key and not data.got[line.key] then
            names = names or carried(player)
            if G.matches(line.key, names) then
                data.got[line.key], dirty = true, true
                notify(player, "got", line.want)
            end
        end
        if line.key and data.got[line.key] and line.raw:gsub("^%s+", ""):sub(1, #MARK) ~= MARK then
            line.raw = MARK .. line.raw:gsub("^%s+", "")
            changed = true
        end
    end
    local complete = #items >= MIN_LINES
    for _, item in ipairs(items) do complete = complete and data.got[item] == true end
    if complete and not data.done then
        data.done, data.shopper, data.shopperName, dirty = true, key(player), forename(player), true
        reward(player, "done", now)
    end
    if data.done and not data.delivered and data.author == key(player) and data.shopper ~= data.author then
        data.delivered, dirty = true, true
        lines[#lines+1] = { raw = getText("IGUI_SharedGroceryList_note", data.shopperName) }
        changed = true
        reward(player, "thanks", now, data.shopperName)
        local shopper = find(data.shopper)
        if shopper then reward(shopper, "delivered", now) end
    end
    if changed then
        local page = {}
        for i, line in ipairs(lines) do page[i] = line.raw end
        list:addPage(1, table.concat(page, "\n"))
    end
    -- The client keeps its own copy of pages and mod data and sends both back when it next writes.
    if (changed or dirty) and isServer() then syncItemFields(player, list) end
    return names
end

function G.scan(player, now)
    if player:isDead() then return end
    local lists = player:getInventory():getAllTypeRecurse(TYPE)
    local names
    for i = 0, lists:size()-1 do
        names = G.check(player, lists:get(i), now, names)
    end
end

function G.scanAll()
    local now = getGameTime():getWorldAgeHours()
    for _, player in ipairs(players()) do G.scan(player, now) end
end

Events.EveryOneMinute.Add(G.scanAll)

require "TimedActions/ISEatFoodAction"

DinnerTogether = {}
local D = DinnerTogether
local recent = {} -- ceiling: recent eaters only, pruned on every meal; no world scan.
local RANGE, WINDOW, COOLDOWN = 4, 10 / 60, 24

function D.show(player)
    HaloTextHelper.addGoodText(player, getText("IGUI_DinnerTogether_SharedMeal"))
end

if isClient() then
    Events.OnServerCommand.Add(function(module, command)
        if module == "DinnerTogether" and command == "sharedMeal" then D.show(getSpecificPlayer(0)) end
    end)
    return
end

local function key(player)
    if isServer() then return player:getUsername() end
    return "local:" .. player:getPlayerNum()
end

local function position(player)
    return { x = player:getX(), y = player:getY(), z = math.floor(player:getZ()) }
end

local function near(a, b)
    return a.z == b.z and (a.x - b.x)^2 + (a.y - b.y)^2 <= RANGE^2
end

local function clear(a, b)
    local result = tostring(LosUtil.lineClear(getCell(), math.floor(a.x), math.floor(a.y), a.z,
        math.floor(b.x), math.floor(b.y), b.z, false))
    return result == "Clear" or result == "ClearThroughOpenDoor"
end

local function reward(player, now)
    local rewards = ModData.getOrCreate("DinnerTogetherRewards")
    local id = key(player)
    if rewards[id] and now - rewards[id] < COOLDOWN then return end
    rewards[id] = now
    local stats = player:getStats()
    stats:remove(CharacterStat.BOREDOM, 5)
    stats:remove(CharacterStat.UNHAPPINESS, 3)
    if isServer() then
        syncPlayerStats(player, SyncPlayerStatsPacket.getBitMaskForStat(CharacterStat.BOREDOM))
        syncPlayerStats(player, SyncPlayerStatsPacket.getBitMaskForStat(CharacterStat.UNHAPPINESS))
        sendServerCommand(player, "DinnerTogether", "sharedMeal", {})
    else
        D.show(player)
    end
end

function D.meal(player)
    local now = getGameTime():getWorldAgeHours()
    local here = position(player)
    local online = {}
    if isServer() then
        local players = getOnlinePlayers()
        for i = 0, players:size()-1 do online[players:get(i)] = true end
    end
    recent[player] = { time = now, place = here }
    for other, meal in pairs(recent) do
        if (isServer() and not online[other]) or other:isDead() or now - meal.time > WINDOW or now < meal.time then
            recent[other] = nil
        elseif other ~= player and near(here, meal.place) then
            local there = position(other)
            if near(here, there) and clear(here, there) then
                reward(player, now)
                reward(other, now)
            end
        end
    end
end

-- complete() is the B42 authority path, perform() only clears the client's action.
-- Keep the vanilla completion and its return value. Interrupted partial meals do not qualify.
local complete = ISEatFoodAction.complete
function ISEatFoodAction:complete()
    if isClient() then return complete(self) end
    local before = self.character:getStats():get(CharacterStat.HUNGER)
    local food = instanceof(self.item, "Food")
    local result = complete(self)
    local eaten = before - self.character:getStats():get(CharacterStat.HUNGER)
    if result and food and eaten >= 0.05 - 0.000001 and not self.character:isDead() then
        D.meal(self.character)
    end
    return result
end

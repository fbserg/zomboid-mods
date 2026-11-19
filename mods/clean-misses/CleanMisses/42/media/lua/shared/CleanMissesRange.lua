local originalPenalty, originalIncrement
local function restoreRange()
    if originalPenalty == nil then return end
    local config = getCombatConfig()
    local keys = CombatConfigKey
    if config:get(keys.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY) == 2 then
        config:set(keys.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY, originalPenalty)
    end
    if config:get(keys.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY_INCREMENT) == 0 then
        config:set(keys.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY_INCREMENT, originalIncrement)
    end
    originalPenalty, originalIncrement = nil, nil
end

local function applyRange()
    if not getSandboxOptions():getOptionByName("CleanMisses.GentlerRangePenalty"):getValue() then
        restoreRange()
        return
    end
    local config = getCombatConfig()
    local keys = CombatConfigKey
    if originalPenalty == nil then
        originalPenalty = config:get(keys.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY)
        originalIncrement = config:get(keys.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY_INCREMENT)
    end
    config:set(keys.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY, 2)
    config:set(keys.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY_INCREMENT, 0)
end

Events.OnGameStart.Add(applyRange)
Events.OnServerStarted.Add(applyRange)
Events.OnDisconnect.Add(restoreRange)
Events.OnMainMenuEnter.Add(restoreRange)

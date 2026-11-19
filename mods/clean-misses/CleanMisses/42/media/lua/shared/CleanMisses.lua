local function useHitChance()
    local options = getSandboxOptions()
    if options:getOptionByName("FirearmUseDamageChance"):getValue() ~= 1 then
        options:set("FirearmUseDamageChance", 1)
    end
end

Events.OnGameStart.Add(useHitChance)
Events.OnServerStarted.Add(useHitChance)
-- A server settings refresh can replace the option after the world has loaded.
Events.OnWeaponSwingHitPoint.Add(function(_, weapon)
    if weapon and weapon:isRanged() then useHitChance() end
end)

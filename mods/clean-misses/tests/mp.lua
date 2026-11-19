local reports = {}
Events.OnServerStarted.Add(function()
    assert(getCombatConfig():get(CombatConfigKey.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY_INCREMENT)==0)
    print("PZ_TEST_SERVER_UP range option active")
end)
Events.OnClientCommand.Add(function(module, command, player, data)
    if module~="CleanMissesProbe" or command~="report" then return end
    if data.slope~=2 or data.increment~=0 then
        print("PZ_TEST_FAIL client coefficients "..player:getUsername().." "..data.slope.."/"..data.increment)
        return
    end
    reports[player:getUsername()]=true
    sendServerCommand(player,"CleanMissesProbe","accepted",{})
    if reports.Alice and reports.Beth then print("PZ_TEST_SERVER_PASS both connected shooters have range tuning") end
end)

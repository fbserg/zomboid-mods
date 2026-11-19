local started, finished = false, false
Events.OnServerStarted.Add(function() started = true end)
Events.OnTick.Add(function()
    if not started or finished or not farmTestKeepLoaded or not rangeWorldChance then return end
    local x, y = PZ_TEST_SPAWN.x, PZ_TEST_SPAWN.y
    farmTestKeepLoaded(x,y)
    local square = getCell():getGridSquare(x,y,0)
    if not square then return end
    finished = true
    local ok, errorMessage = pcall(function()
        local state = ModData.getOrCreate("CleanMissesRangeTest")
        local cfg = getCombatConfig()
        local k = CombatConfigKey
        local slope = cfg:get(k.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY)
        local increment = cfg:get(k.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY_INCREMENT)
        local enabled = state.baseline ~= nil
        assert(slope == (enabled and 2 or 4) and math.abs(increment-(enabled and 0 or 0.3))<0.00001, "unexpected coefficients "..slope..","..increment)
        local player = IsoPlayer.new(getCell())
        player:setCurrent(square)
        player:setX(x+0.5); player:setY(y+0.5)
        local zombie = IsoZombie.new(getCell())
        zombie:setCurrent(square)
        local rows={}
        for _,name in ipairs({"Pistol","Shotgun","VarmintRifle","HuntingRifle","ScopedRifle"}) do
            local weapon=assert(player:getInventory():AddItem("Base."..(name=="ScopedRifle" and "HuntingRifle" or name)))
            if name=="ScopedRifle" then
                local scope=assert(player:getInventory():AddItem("Base.x8Scope"))
                weapon:attachWeaponPart(scope)
                weapon:setActiveSight(scope)
            end
            for _,distance in ipairs({5,10,15,20,30}) do
                if distance<=weapon:getMaxRange(player) then
                    local key=name.."/"..distance
                    local chance=rangeWorldChance(player,weapon,zombie,distance)
                    rows[key]=chance
                    print("PZ_TEST_RANGE "..key.." enabled="..tostring(enabled).." threshold="..chance)
                    if name=="HuntingRifle" and distance==20 then
                        local damaging=rangeWorldDamage(player,weapon,zombie,chance)
                        assert(damaging>0 and damaging<512,"invalid health-loss count "..damaging)
                        print("PZ_TEST_HEALTH 20 tiles enabled="..tostring(enabled).." health loss on "..damaging.."/512 rolls")
                        if enabled then assert(damaging>state.damaging,"no improvement in damaging rolls")
                        else state.damaging=damaging end
                    end
                    if enabled then
                        if name=="HuntingRifle" and distance==20 then assert(chance>state.baseline[key],key.." did not improve") end
                    end
                end
            end
        end
        if enabled then print("PZ_TEST_RESTART_PASS full chance calculation with range enabled"); return end
        state.baseline=rows
        getSandboxOptions():set("CleanMisses.GentlerRangePenalty",true)
        assert(getSandboxOptions():saveServerLuaFile("pz-test"),"sandbox save failed")
        print("PZ_TEST_ENGINE_PASS full chance calculation and sandbox save")
    end)
    if not ok then print("PZ_TEST_FAIL "..tostring(errorMessage)) end
end)

local started, finished = false, false
Events.OnServerStarted.Add(function() started=true end)
Events.OnTick.Add(function()
    if not started or finished or not farmTestKeepLoaded or not rangeWorldChance then return end
    local x,y=PZ_TEST_SPAWN.x,PZ_TEST_SPAWN.y
    farmTestKeepLoaded(x,y)
    local square=getCell():getGridSquare(x,y,0)
    if not square then return end
    finished=true
    local ok,msg=pcall(function()
        local state=ModData.getOrCreate("CleanMissesBowProbe")
        local player=IsoPlayer.new(getCell())
        player:setCurrent(square)
        player:setX(x+0.5); player:setY(y+0.5)
        player:setPerkLevelDebug(Perks.Archery,4)
        local zombie=IsoZombie.new(getCell())
        zombie:setCurrent(square)
        local arrow=assert(player:getInventory():AddItem("Base.CarbonHuntingArrow"))
        local count=0
        for name,scale in pairs(RadArchery.BowArcheryScaling) do
            local bow=assert(player:getInventory():AddItem("Base."..name))
            bow:getModData().RadArchery_loadedArrow=arrow:getFullType()
            bow:setCurrentAmmoCount(1)
            assert(RadArchery.loadedArrow(bow).item==arrow:getFullType(),"wrong arrow")
            -- Local Workshop scripts may already contain the operator's sight edit.
            bow:setMinSightRange(0); bow:setMaxSightRange(0)
            triggerEvent("OnEquipPrimary",player,bow)
            assert(bow:getHitChance()==scale.hitChance+4*scale.hitChancePerLevel+5,"Archery bonus "..name)
            assert(bow:getMinDamage()==bow:getScriptItem():getMinDamage()*2,"arrow damage "..name)
            assert(bow:getMinSightRange()==3 and bow:getMaxSightRange()==14,"sight "..name)
            local distance=15
            local tuned=rangeWorldChance(player,bow,zombie,distance)
            bow:setMinSightRange(0); bow:setMaxSightRange(0)
            local stock=rangeWorldChance(player,bow,zombie,distance)
            assert(tuned>stock,"no improvement "..name)
            if name=="CompoundBowBlack" or name=="CompoundBowHeavyBlack" then
                local options=getSandboxOptions()
                options:set("FirearmUseDamageChance",2)
                local before=rangeWorldDamage(player,bow,zombie,stock,true)
                options:set("FirearmUseDamageChance",1)
                triggerEvent("OnEquipPrimary",player,bow)
                local after=rangeWorldDamage(player,bow,zombie,tuned,true)
                assert(after>before,"no health improvement "..name)
                print("PZ_TEST_BOW "..name.." rangeOption="..tostring(state.done==true).." stock/adjusted thresholds "..stock.."/"..tuned.." health loss "..before.."/"..after.." of 512 each")
            end
            count=count+1
        end
        assert(count==21,"expected 21 bows; found "..count)
        if state.done then print("PZ_TEST_RESTART_PASS 21 bows"); return end
        state.done=true
        getSandboxOptions():set("CleanMisses.GentlerRangePenalty",true)
        assert(getSandboxOptions():saveServerLuaFile("pz-test"))
        print("PZ_TEST_ENGINE_PASS 21 bows")
    end)
    if not ok then print("PZ_TEST_FAIL "..tostring(msg)) end
end)

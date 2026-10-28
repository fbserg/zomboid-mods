-- Native hot-path budget. Synthetic native players test CPU scaling, not 64 network connections.
local Snapshot=require 'PZHarness/Snapshot'
local X,Y=10628,10658
local started,done=false,false
Events.OnServerStarted.Add(function() started=true end)
Events.OnTick.Add(function()
    if not started or done or not farmTestKeepLoaded then return end
    farmTestKeepLoaded(X,Y)
    local square=getCell():getGridSquare(X,Y,0)
    if not square then return end
    done=true
    local ok,message=pcall(function()
        local opts={x=X,y=Y,z=0,radius=4,levels={0},ignore=Snapshot.DEFAULT_IGNORE}
        local before=Snapshot.take(opts)
        local all={}
        getOnlinePlayers=function() return {size=function() return #all end,get=function(_,i) return all[i+1] end} end
        local notifications=0
        sendServerCommand=function() notifications=notifications+1 end -- Synthetic players have no sockets.
        local wrapped=ISEatFoodAction.complete
        reloadLuaFile('media/lua/shared/TimedActions/ISEatFoodAction.lua')
        local vanilla=ISEatFoodAction.complete
        assert(vanilla~=wrapped,'Vanilla baseline reload failed')
        ISEatFoodAction.complete=wrapped
        local function percentile(values,p)
            table.sort(values)
            return values[math.ceil(#values*p)]
        end
        local function samples(fn)
            local times={}
            for batch=1,31 do
                local start=getTimestampMs()
                for i=1,32 do fn() end
                times[#times+1]=(getTimestampMs()-start)/32
            end
            return {p50=percentile(times,0.5),p95=percentile(times,0.95)}
        end
        local function budget(value,limit) return value<=limit end
        local metrics={}
        for _,count in ipairs({2,16,64}) do
            all={}
            for i=1,count do
                local p=IsoPlayer.new(getCell())
                p:setUsername('Perf'..i);p:setX(X+0.5);p:setY(Y+0.5);p:setZ(0);p:setCurrent(square)
                all[i]=p
                ModData.getOrCreate('DinnerTogetherRewards')[p:getUsername()]=getGameTime():getWorldAgeHours()
            end
            for _,p in ipairs(all) do DinnerTogether.meal(p) end
            local actor=all[1]
            local function eat(callback)
                actor:getStats():set(CharacterStat.HUNGER,0.8)
                local food=actor:getInventory():AddItem('Base.Apple')
                assert(callback(ISEatFoodAction:new(actor,food,1)))
            end
            for i=1,64 do eat(vanilla);eat(wrapped) end
            -- Two vanilla baselines expose timer/JIT noise instead of presenting it as a gain.
            local a=samples(function() eat(vanilla) end)
            local b=samples(function() eat(vanilla) end)
            local mod=samples(function() eat(wrapped) end)
            local baseline=(a.p95+b.p95)/2
            local noise=math.max(math.abs(a.p95-b.p95),1/32)
            local added=math.max(0,mod.p95-baseline)
            local limit=count==64 and 2 or 0.5
            assert(budget(added,limit),'Meal callback over budget at '..count..' players: '..added..' ms')
            metrics[#metrics+1]=string.format('{"players":%d,"baseline_p95_batch_mean_ms":%.5f,"mod_p50_batch_mean_ms":%.5f,"mod_p95_batch_mean_ms":%.5f,"added_p95_ms":%.5f,"noise_ms":%.5f,"budget_ms":%.2f}',count,baseline,mod.p50,mod.p95,added,noise,limit)
            print('PZ_TEST_PERF '..metrics[#metrics])
        end
        collectgarbage('collect')
        local heapBefore=collectgarbage('count')
        for i=1,10000 do DinnerTogether.meal(all[(i%#all)+1]) end
        collectgarbage('collect')
        local retainedKiB=collectgarbage('count')-heapBefore
        assert(retainedKiB<16384,'Whole JVM retained more than 16 MiB after stress: '..retainedKiB..' KiB')
        assert(notifications==0,'Cooldown stress generated network notifications')
        local slow=samples(function()
            local stop=getTimestampMs()+1
            while getTimestampMs()<stop do end
        end)
        assert(not budget(slow.p95,0.5),'Slow callback negative control escaped budget')
        print('PZ_TEST_PASS performance budget rejects a deliberately slow callback')
        local delta=Snapshot.diff(before,Snapshot.take(opts))
        local leaks=Snapshot.addLines({},delta)
        assert(#leaks==0,table.concat(leaks,'; '))
        local after=Snapshot.take(opts)
        local leakSquare=getCell():getGridSquare(X+1,Y,0)
        local object=IsoObject.new(leakSquare,'carpentry_01_16','Deliberate probe leak')
        leakSquare:AddTileObject(object)
        assert(#Snapshot.diff(after,Snapshot.take(opts)).squares>0,'Upstream leak negative control escaped')
        leakSquare:RemoveTileObject(object)
        assert(#Snapshot.addLines({},Snapshot.diff(after,Snapshot.take(opts)))==0,'Fixture did not restore its leak')
        print('PZ_TEST_PASS upstream Snapshot detects and clears a real native object leak')
        local report=string.format('{"clock_resolution_ms":1,"batch_iterations":32,"samples":31,"cases":[%s],"retained_jvm_kib":%.2f,"retained_budget_kib":16384,"cooldown_notifications":%d,"stress_meals":10000,"negative_controls":2}',table.concat(metrics,','),retainedKiB,notifications)
        local writer=getFileWriter('dinner-performance.json',true,false);writer:write(report);writer:close()
        print('PZ_TEST_PERFORMANCE_PASS '..report)
    end)
    if not ok then print('PZ_TEST_FAIL '..tostring(message)) end
end)

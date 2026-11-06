-- Native budget for the once-per-game-minute scan. Synthetic native players test CPU scaling, not 64 network connections.
-- Declared budgets (p95 of 32-call batch means):
--   idle: players without a list, 0.5 ms per scan at 2/16 players, 2 ms at 64.
--   holding: every player carries a 10-line list nobody can finish and 100 other items,
--            0.5 ms per holder per scan (worst case: a full inventory read every minute).
local Snapshot=require 'PZHarness/Snapshot'
local X,Y=10628,10658
local TYPE='SharedGroceryList.GroceryList'
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
        local notifications,syncs=0,0
        sendServerCommand=function() notifications=notifications+1 end -- Synthetic players have no sockets.
        syncItemFields=function() syncs=syncs+1 end
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
        local stock={'Base.Apple','Base.TinnedBeans','Base.Battery','Base.Rice','Base.Bandage','Base.Pen','Base.Hammer','Base.WaterBottle','Base.Socks','Base.Matches'}
        local function players(count,holding)
            all={}
            for i=1,count do
                local p=IsoPlayer.new(getCell())
                p:setUsername('Perf'..i);p:setX(X+0.5);p:setY(Y+0.5);p:setZ(0);p:setCurrent(square)
                if holding then
                    for n=1,100 do p:getInventory():AddItem(stock[(n%#stock)+1]) end
                    p:getInventory():AddItem(TYPE):addPage(1,'caviar\ntruffles\nchampagne\nlobster\nsaffron\nvanilla pods\nfoie gras\nwagyu\nmatcha\nespresso')
                end
                all[i]=p
            end
        end
        local function baseline() end
        local metrics={}
        for _,case in ipairs({{2,false},{16,false},{64,false},{2,true},{16,true},{64,true}}) do
            local count,holding=case[1],case[2]
            players(count,holding)
            SharedGroceryList.scanAll()
            notifications,syncs=0,0
            for i=1,256 do SharedGroceryList.scanAll();baseline() end
            local a=samples(baseline)
            local b=samples(baseline)
            local mod=samples(SharedGroceryList.scanAll)
            local noise=math.max(math.abs(a.p95-b.p95),1/32)
            assert(noise<=0.25,'Baseline is too noisy for its declared budget')
            local added=math.max(0,mod.p95-(a.p95+b.p95)/2)
            local limit=holding and 0.5*count or (count==64 and 2 or 0.5)
            assert(added<=limit,'Scan over budget at '..count..' players holding='..tostring(holding)..': '..added..' ms')
            assert(notifications==0 and syncs==0,'Steady-state scan sent notifications or item syncs')
            metrics[#metrics+1]=string.format('{"players":%d,"holding_list":%s,"mod_p50_batch_mean_ms":%.5f,"mod_p95_batch_mean_ms":%.5f,"added_p95_ms":%.5f,"noise_ms":%.5f,"budget_ms":%.2f}',count,tostring(holding),mod.p50,mod.p95,added,noise,limit)
            print('PZ_TEST_PERF '..metrics[#metrics])
        end
        collectgarbage('collect')
        local heapBefore=collectgarbage('count')
        for i=1,10000 do SharedGroceryList.scan(all[(i%#all)+1],getGameTime():getWorldAgeHours()) end
        collectgarbage('collect')
        local retainedKiB=collectgarbage('count')-heapBefore
        assert(retainedKiB<16384,'Whole JVM retained more than 16 MiB after stress: '..retainedKiB..' KiB')
        assert(notifications==0 and syncs==0,'Stress scans generated network traffic')
        local slow=samples(function()
            local stop=getTimestampMs()+1
            while getTimestampMs()<stop do end
        end)
        assert(slow.p95>0.5,'Slow callback negative control escaped budget')
        print('PZ_TEST_PASS performance budget rejects a deliberately slow callback')
        for _,p in ipairs(all) do p:getInventory():clear() end
        local leaks=Snapshot.addLines({},Snapshot.diff(before,Snapshot.take(opts)))
        assert(#leaks==0,table.concat(leaks,'; '))
        local after=Snapshot.take(opts)
        local leakSquare=getCell():getGridSquare(X+1,Y,0)
        local object=IsoObject.new(leakSquare,'carpentry_01_16','Deliberate probe leak')
        leakSquare:AddTileObject(object)
        assert(#Snapshot.diff(after,Snapshot.take(opts)).squares>0,'Upstream leak negative control escaped')
        leakSquare:RemoveTileObject(object)
        assert(#Snapshot.addLines({},Snapshot.diff(after,Snapshot.take(opts)))==0,'Fixture did not restore its leak')
        print('PZ_TEST_PASS upstream Snapshot detects and clears a real native object leak')
        local report=string.format('{"clock_resolution_ms":1,"batch_iterations":32,"samples":31,"items_per_holder":100,"open_lines_per_list":10,"cases":[%s],"retained_jvm_kib":%.2f,"retained_budget_kib":16384,"steady_state_notifications":%d,"steady_state_item_syncs":%d,"stress_scans":10000,"negative_controls":2}',table.concat(metrics,','),retainedKiB,notifications,syncs)
        local writer=getFileWriter('grocery-performance.json',true,false);writer:write(report);writer:close()
        print('PZ_TEST_PERFORMANCE_PASS '..report)
    end)
    if not ok then print('PZ_TEST_FAIL '..tostring(message)) end
end)

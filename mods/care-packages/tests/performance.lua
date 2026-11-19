-- Budgets: <= 0.5 ms added p95 per individual transition (32-transition batch means).
-- Stress: 10,000 transitions, < 16 MiB retained whole-JVM heap, exactly two packet
-- requests per commit, zero for invalid transitions. No idle, tick or draw work on authority.
local C = require "CarePackages"
local started, done = false, false

local function sample(fn)
    local batches = {}
    for batch = 1, 31 do
        local start = getTimestampMs()
        for i = 1, 32 do fn() end
        batches[batch] = (getTimestampMs() - start) / 32
    end
    table.sort(batches)
    return batches[16], batches[30]
end

Events.OnServerStarted.Add(function() started = true end)
Events.OnTick.Add(function()
    if not started or done then return end
    done = true
    local ok, failure = pcall(function()
        local requests = 0
        syncItemModData = function() requests = requests + 1 end
        sendServerCommand = function() requests = requests + 1 end
        local player = IsoPlayer.new(getCell())
        local parcel = player:getInventory():AddItem(C.itemType)
        local cargo = parcel:getInventory()
        local note = string.rep("x", 500)
        local function baseline()
            local operation = C.isSealed(parcel) and "open" or "seal"
            assert(C.canHandle(player, parcel, operation), "Benchmark parcel cannot " .. operation)
            assert(C.revision(parcel) >= 0)
        end
        local function toggle()
            local operation = C.isSealed(parcel) and "open" or "seal"
            assert(C.change(player, parcel, operation, C.revision(parcel), "Beth", "Alice", note))
        end
        local results = {}
        for _, count in ipairs({2, 64}) do
            while cargo:getItems():size() < count do cargo:AddItem("Base.Battery") end
            for i = 1, 256 do baseline(); toggle() end
            local _, a = sample(baseline)
            local p50, p95 = sample(toggle)
            local _, b = sample(baseline)
            local noise = math.max(math.abs(a - b), 1 / 32)
            local added = math.max(0, p95 - (a + b) / 2)
            assert(noise <= 0.25 and added <= 0.5, "Seal/open performance over budget: " .. added .. " ms")
            results[#results + 1] = string.format(
                '{"cargo":%d,"p50_ms":%.5f,"p95_ms":%.5f,"added_p95_ms":%.5f,"noise_ms":%.5f}',
                count, p50, p95, added, noise)
        end
        collectgarbage("collect")
        local before = collectgarbage("count")
        requests = 0
        for i = 1, 10000 do
            toggle()
            assert(not C.change(player, parcel, "open", -1))
        end
        collectgarbage("collect")
        local retained = collectgarbage("count") - before
        assert(retained < 16384 and requests == 20000 and cargo:getItems():size() == 64, "Stress exceeded contract")
        local _, slow = sample(function()
            local endTime = getTimestampMs() + 1
            while getTimestampMs() < endTime do end
        end)
        assert(slow > 0.5, "Timing negative control escaped budget")
        local report = string.format(
            '{"cases":[%s],"batch_iterations":32,"samples":31,"budget_ms":0.5,"retained_jvm_kib":%.2f,"retained_budget_kib":16384,"transitions":10000,"packet_requests":%d,"negative_controls":1}',
            table.concat(results, ","), retained, requests)
        local writer = getFileWriter("care-performance.json", true, false)
        writer:write(report)
        writer:close()
        print("PZ_TEST_PERFORMANCE_PASS " .. report)
    end)
    if not ok then print("PZ_TEST_FAIL " .. tostring(failure)) end
end)

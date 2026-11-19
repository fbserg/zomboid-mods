-- Runs on two real network clients. Each drives its own character, reads back the real
-- feed file and checks every line. Alice also measures the declared performance budgets.
local role = '@ROLE@'
Events.OnMainMenuEnter.Add(function()
    getCore():setOptionShowSurvivalGuide(false)
    getCore():setTutorialDone(true)
    serverConnect(role, 'test-only', '127.0.0.1', '127.0.0.1', '16511', '', 'pz-test', false, true, 1, '')
end)
Events.OnConnected.Add(function()
    local region = assert(MapSpawnSelect.instance:useDefaultSpawnRegion(), 'No spawn region')
    setSpawnRegion(region.name)
    getWorld():setMap("Muldraugh, KY")
    getWorld():setLuaPlayerDesc(SurvivorFactory.CreateSurvivor())
    GameWindow.doRenderEvent(false)
    forceChangeState(LoadingQueueState.new())
end)
Events.OnConnectFailed.Add(function(message) print('PZ_TEST_FAIL connect ' .. role .. ' ' .. tostring(message)) end)

local S
local ticks, sent, done = 0, false, false
local queue, notes, startLines, beforeHorde = {}, 0, 0, 0
local MARK = '{"username":"Knox Scanner","content":"\\ud83d\\udce1 '

local function feed()
    local lines = {}
    local reader = getFileReader('KnoxScanner.txt', false)
    if not reader then return lines end
    while true do
        local line = reader:readLine()
        if not line then break end
        lines[#lines + 1] = line
    end
    reader:close()
    return lines
end
local function run(fn) queue[#queue + 1] = { fn = fn } end
local function wait(label, limit, cond) queue[#queue + 1] = { label = label, limit = limit, cond = cond, age = 0 } end
local function checkLine(kind, line, part)
    assert(string.find(line, MARK .. kind .. ' | ', 1, true) == 1, kind .. ' line starts wrong: ' .. line)
    assert(string.find(line, '"kind":"' .. kind .. '"', 1, true) and string.sub(line, -1) == '}', kind .. ' line lacks fields: ' .. line)
    if part then assert(string.find(line, part, 1, true), kind .. ' line lacks ' .. part .. ': ' .. line) end
    print('PZ_TEST_PASS ' .. role .. ' ' .. kind .. ' line ' .. string.sub(line, 50))
end
local function expectLine(kind, action, part)
    local before = #feed()
    action()
    local lines = feed()
    assert(#lines == before + 1, kind .. ' wrote ' .. (#lines - before) .. ' lines, expected 1')
    checkLine(kind, lines[#lines], part)
end
local function expectSilence(label, action)
    local before = #feed()
    action()
    assert(#feed() == before, label .. ' wrote a line')
end
local function nextKills(p) return (math.floor(p:getZombieKills() / 100) + 1) * 100 end

-- Budgets are declared in tests/checks.json. Part one runs in a world with no zombies, part
-- two beside the real fixture horde. Neither may write to the real feed.
local perf = {}
local function percentile(values, q) table.sort(values); return values[math.ceil(#values * q)] end
local function samples(fn, per)
    local times = {}
    for batch = 1, 31 do
        local start = getTimestampMs()
        for i = 1, per do fn() end
        times[#times + 1] = (getTimestampMs() - start) / per
    end
    return { p50 = percentile(times, 0.5), p95 = percentile(times, 0.95) }
end
local function within(value, limit) return value <= limit end
local function performanceQuiet()
    local before = #feed()
    assert(getCell():getZombieList():size() == 0, 'Quiet budget needs an empty world')
    local enabled = S.options:getOption('enabled')
    for i = 1, 4000 do S.poll() end
    enabled:setValue(false)
    perf.idle = samples(S.poll, 2000)
    enabled:setValue(true)
    S.state.hordeAt = -S.HORDE_COOLDOWN_HOURS
    perf.quiet = samples(S.poll, 2000)
    local file, note = S.FILE, S.options:getOption('note')
    S.FILE = 'KnoxScannerPerf.txt'; note:setValue(false)
    perf.write = samples(function() S.emit('request', 'Performance probe line.') end, 8)
    S.FILE = file; note:setValue(true)
    assert(within(perf.idle.p95, 0.005), 'Switched-off poll over budget: ' .. perf.idle.p95 .. ' ms')
    assert(within(perf.quiet.p95, 0.05), 'Quiet poll over budget: ' .. perf.quiet.p95 .. ' ms')
    assert(within(perf.write.p95, 2), 'Line write over budget: ' .. perf.write.p95 .. ' ms')
    local slow = samples(function()
        local stop = getTimestampMs() + 1
        while getTimestampMs() < stop do end
    end, 8)
    assert(not within(slow.p95, 0.05), 'Slow callback negative control escaped the poll budget')
    collectgarbage('collect')
    local heap = collectgarbage('count')
    for i = 1, 20000 do S.poll() end
    collectgarbage('collect')
    perf.retained = collectgarbage('count') - heap
    assert(perf.retained < 16384, 'Whole JVM retained more than 16 MiB after 20,000 polls: ' .. perf.retained .. ' KiB')
    assert(#feed() == before, 'The quiet performance probe wrote to the real feed')
end
local function performanceHorde(p)
    local before = #feed()
    local horde = S.zombiesNear(p)
    assert(horde >= S.HORDE_SIZE, 'Scan budget needs the real horde: ' .. horde)
    local scan = samples(function() S.zombiesNear(p) end, 500)
    local cooling = samples(S.poll, 2000)
    assert(within(scan.p95 / horde, 0.0015), 'Zombie scan over budget: ' .. scan.p95 .. ' ms for ' .. horde .. ' zombies')
    assert(#feed() == before, 'The horde performance probe wrote to the real feed')
    local report = string.format('{"clock_resolution_ms":1,"samples":31,"polls_per_sample":2000,"switched_off_poll_p95_ms":%.6f,"switched_off_budget_ms":0.005,"quiet_poll_p50_ms":%.6f,"quiet_poll_p95_ms":%.6f,"quiet_poll_budget_ms":0.05,"cooldown_poll_beside_horde_p95_ms":%.6f,"zombies_in_scan":%d,"zombie_scan_p95_ms":%.6f,"zombie_scan_budget_ms_per_zombie":0.0015,"line_write_p95_ms":%.5f,"line_write_budget_ms":2,"retained_jvm_kib_after_20000_polls":%.2f,"retained_budget_kib":16384,"polls_per_real_second_at_default_day_length":0.4,"per_frame_hooks":0,"network_messages":0,"negative_controls":1}',
        perf.idle.p95, perf.quiet.p50, perf.quiet.p95, cooling.p95, horde, scan.p95, perf.write.p95, perf.retained)
    local writer = getFileWriter('scanner-performance.json', true, false); writer:write(report); writer:close()
    print('PZ_TEST_PERFORMANCE_PASS ' .. report)
end

local function scenario(args)
    local p = getSpecificPlayer(0)
    local body, time = p:getBodyDamage(), getGameTime()
    local option = function(id) return S.options:getOption(id) end
    if args.round == 1 then
        run(function()
            assert(PZAPI.ModOptions:getOptions('KnoxScanner') == S.options, 'Mod Options panel missing')
            for _, id in ipairs(S.TOGGLES) do
                assert(option(id).type == 'tickbox' and option(id):getValue() == true, 'Tick box not on by default: ' .. id)
            end
            assert(S.requestKey.type == 'keybind' and S.requestKey:getValue() == 0, 'Request key must start unbound')
            local info = assert(getModInfoByID('KnoxScanner'), 'Mod panel metadata missing')
            assert(info:getModVersion() == '0.1.0' and info:getPosterCount() == 3, 'Wrong mod panel version or posters')
            assert(getTexture(info:getIcon()), 'Mod icon does not load')
            for i = 0, info:getPosterCount() - 1 do assert(getTexture(info:getPoster(i)), 'Mod poster does not load') end
            assert(getText('IGUI_KnoxScanner_town') == 'Towns' and getText('IGUI_KnoxScanner_sent', 'town') == 'Scanner: town', 'Translations did not load')
            print('PZ_TEST_PASS ' .. role .. ' ' .. #S.TOGGLES .. ' translated tick boxes and one unbound key in Mod Options')
        end)
    end
    wait('the game-minute hook to record a baseline', 3600, function() return S.state ~= nil end)
    run(function()
        assert(#feed() == startLines, 'The first poll of a character wrote a line')
        print('PZ_TEST_PASS ' .. role .. ' real EveryOneMinute baseline was silent, feed had ' .. startLines .. ' lines')
        p:setZombieKills(nextKills(p))
    end)
    wait('the game-minute hook to report the kill milestone', 3600, function() return #feed() > startLines end)
    run(function()
        local lines = feed()
        assert(#lines == startLines + 1, 'The hook wrote ' .. (#lines - startLines) .. ' lines for one milestone')
        checkLine('kills', lines[#lines], 'zombies.')
        assert(notes == 1, 'The note did not show once: ' .. notes)
        print('PZ_TEST_PASS ' .. role .. ' real EveryOneMinute hook wrote the line and showed the note')
    end)
    if args.round == 1 then
        run(function()
            expectLine('town', function() S.state.town = nil; S.poll() end, '"place":"Muldraugh"')
            expectSilence('same town', S.poll)
            expectLine('bitten', function() body:getBodyPart(BodyPartType.Hand_L):SetBitten(true); S.poll() end)
            expectSilence('healed bite', function() body:RestoreToFullHealth(); S.poll() end)
            expectLine('hurt', function() body:setOverallBodyHealth(40); S.poll() end)
            expectSilence('recovery', function() body:RestoreToFullHealth(); body:setOverallBodyHealth(100); S.poll() end)
            expectLine('power', function() getWorld():setHydroPowerOn(false); S.poll() end)
            expectSilence('power back', function() getWorld():setHydroPowerOn(true); S.poll() end)
            local day, from, to = time:getHelicopterDay1(), time:getHelicopterStartHour(), time:getHelicopterEndHour()
            expectLine('helicopter', function()
                time:setHelicopterDay(time:getNightsSurvived()); time:setHelicopterStartHour(0); time:setHelicopterEndHour(24)
                S.poll()
            end)
            expectSilence('same helicopter', S.poll)
            time:setHelicopterDay(day); time:setHelicopterStartHour(from); time:setHelicopterEndHour(to)
            S.poll()
            local room = p:getCurrentSquare():getRoom()
            expectSilence('ordinary room', function()
                if room then assert(S.landmarkIn(room:getName()) == nil, 'Spawn room reads as a landmark: ' .. room:getName()) end
                S.state.landmark = nil; S.poll()
            end)
            print('PZ_TEST_PASS ' .. role .. ' real room lookup: ' .. (room and room:getName() or 'outdoors'))
            expectLine('days', function() p:setHoursSurvived(24 * 7); S.onDay() end, '7 days')
            expectSilence('ordinary weather', function() S.onWeather(getClimateManager():getWeatherPeriod()) end)
            S.requestKey:setValue(67)
            expectLine('request', function() S.onKey(67) end)
            expectSilence('another key', function() S.onKey(68) end)
            option('kills'):setValue(false)
            expectSilence('kills tick box off', function() p:setZombieKills(nextKills(p)); S.poll() end)
            option('kills'):setValue(true)
            option('enabled'):setValue(false)
            expectSilence('master switch off', function() getWorld():setHydroPowerOn(false); S.poll() end)
            option('enabled'):setValue(true)
            local shown = notes
            option('note'):setValue(false)
            expectLine('power', S.poll)
            assert(notes == shown, 'The note showed with its tick box off')
            option('note'):setValue(true)
            getWorld():setHydroPowerOn(true); S.poll()
            print('PZ_TEST_PASS ' .. role .. ' tick boxes, master switch and note switch silence the feed')
            if role == 'Alice' then performanceQuiet() end
            beforeHorde = #feed()
            sendClientCommand(p, 'ScannerProbe', 'horde', {})
        end)
        wait('forty real zombies to load nearby', 3600, function() return S.zombiesNear(p) >= S.HORDE_SIZE end)
        run(function()
            -- The real game-minute hook may report the horde before this direct poll does. Either way it is one line.
            S.poll()
            local lines = feed()
            assert(#lines == beforeHorde + 1, 'The horde wrote ' .. (#lines - beforeHorde) .. ' lines, expected 1')
            checkLine('horde', lines[#lines], 'zombies is closing in')
            expectSilence('horde cooldown', S.poll)
            if role == 'Alice' then performanceHorde(p) end
        end)
        -- The photo fixture needs the horde on screen for its capture.
        local held = 0
        wait('the photo capture', 600, function() held = held + 1; return not PZ_PHOTO_ROLE or held > 90 end)
        run(function() sendClientCommand(p, 'ScannerProbe', 'clear', {}) end)
        -- The server removes its zombies. A client can keep a stale copy, so it drops leftovers after five seconds.
        local waited = 0
        wait('the fixture zombies to leave', 3600, function()
            waited = waited + 1
            if waited > 300 then
                local zombies = getCell():getZombieList()
                for i = zombies:size() - 1, 0, -1 do zombies:get(i):removeFromWorld() end
            end
            return S.zombiesNear(p) == 0
        end)
    end
    run(function()
        if args.final then
            sendClientCommand(p, 'ScannerProbe', 'checked', {})
            return
        end
        print('PZ_TEST_ROUND_CLIENT_PASS ' .. role .. ' round=' .. args.round)
        sendClientCommand(p, 'ScannerProbe', 'verified', {})
        done = true
    end)
end

Events.OnGameStart.Add(function()
    S = KnoxScanner
    local p = getSpecificPlayer(0)
    p:setInvincible(true); p:setGhostMode(true)
    local x = PZ_TEST_SPAWN.x + 0.5
    local y = PZ_TEST_SPAWN.y + (role == 'Beth' and 2 or 0.5)
    p:setX(x); p:setLastX(x); p:setY(y); p:setLastY(y); p:setZ(PZ_TEST_SPAWN.z); p:setLastZ(PZ_TEST_SPAWN.z)
    p:setCurrent(getCell():getGridSquare(math.floor(x), math.floor(y), PZ_TEST_SPAWN.z))
    startLines = #feed()
    local note = S.note
    S.note = function(player, kind)
        note(player, kind)
        notes = notes + 1
    end
end)
Events.OnServerCommand.Add(function(module, command, args)
    if module ~= 'ScannerProbe' then return end
    local p = getSpecificPlayer(0)
    if command == 'reset' then ticks = 0; sent = false; done = false; queue = {}; notes = 0; startLines = #feed() end
    if command == 'go' then scenario(args) end
    if command == 'die' then
        local before = #feed()
        run(function()
            sendClientCommand(p, 'ScannerProbe', 'verified', {})
            p:setInvincible(false); p:setGhostMode(false)
            p:Kill(nil)
        end)
        wait('the death line', 3600, function() return #feed() == before + 1 end)
        run(function()
            local lines = feed()
            checkLine('death', lines[#lines], 'A survivor died after')
            print('PZ_TEST_CLIENT_PASS ' .. role .. ' real death wrote one line, feed has ' .. #lines .. ' lines')
            done = true
        end)
    end
    if command == 'watch' then
        local before = #feed()
        wait('the other player to die', 5400, function()
            local online = getOnlinePlayers()
            for i = 0, online:size() - 1 do
                local other = online:get(i)
                if other:getUsername() == 'Alice' then return other:isDead() end
            end
            return true
        end)
        local settle = 0
        wait('the other death to settle', 600, function() settle = settle + 1; return settle > 180 end)
        run(function()
            local lines = feed()
            assert(#lines == before, 'Another player\'s death wrote a line here')
            for _, line in ipairs(lines) do assert(not string.find(line, '"kind":"death"', 1, true), 'Death line in the wrong feed') end
            print('PZ_TEST_CLIENT_PASS ' .. role .. ' another player\'s death wrote nothing here, feed has ' .. #lines .. ' lines')
            sendClientCommand(p, 'ScannerProbe', 'verified', {})
            done = true
        end)
    end
end)
Events.OnTick.Add(function()
    local p = getSpecificPlayer(0)
    if not p or not isClient() or done then return end
    ticks = ticks + 1
    if ticks > 180 and not sent then
        sent = true
        sendClientCommand(p, 'ScannerProbe', 'ready', {})
    end
    local item = queue[1]
    if not item then return end
    if item.fn then
        table.remove(queue, 1)
        local ok, message = pcall(item.fn)
        if not ok then print('PZ_TEST_FAIL ' .. role .. ' ' .. tostring(message)); done = true end
        return
    end
    item.age = item.age + 1
    if item.cond() then
        table.remove(queue, 1)
    elseif item.age > item.limit then
        print('PZ_TEST_FAIL ' .. role .. ' timed out waiting for ' .. item.label)
        done = true
    end
end)

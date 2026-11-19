-- Test-only server orchestration. Knox Scanner runs on clients only. The server stages
-- real zombies, sequences the rounds and proves the mod sends nothing over the network.
local ready, players, verified, checked, cleared, wanted = {}, {}, {}, {}, {}, {}
local round, started, dying = 1, false, false
local traffic = 0
local nativeCommand = sendServerCommand
sendServerCommand = function(...)
    local a, b = ...
    if a == 'KnoxScanner' or b == 'KnoxScanner' then traffic = traffic + 1 end
    return nativeCommand(...)
end
Events.OnServerStarted.Add(function()
    assert(SandboxVars.Zombies == 6 and SandboxVars.ZombieConfig.PopulationMultiplier == 0, 'Scanner test world must start with zero zombie population')
    assert(KnoxScanner and KnoxScanner.townAt and KnoxScanner.options == nil, 'The server must load the shared file only')
    print('PZ_TEST_ZERO_POPULATION_PASS'); print('PZ_TEST_SERVER_UP')
end)
Events.OnClientCommand.Add(function(module, command, player)
    if module == 'KnoxScanner' then traffic = traffic + 1 end
    if module ~= 'ScannerProbe' then return end
    local name = player:getUsername()
    if command == 'ready' then
        ready[name] = true; players[name] = player
        print('PZ_TEST_READY ' .. name .. ' round=' .. round)
    elseif command == 'horde' then
        -- Both clients must finish their quiet checks before any zombie exists.
        wanted[name] = true
        if wanted.Alice and wanted.Beth then
            wanted = {}
            -- The shared fixture world has zombies switched off, and the game refuses to spawn then.
            local zombies = getSandboxOptions():getOptionByName('Zombies')
            zombies:setValue(5)
            local anchor = players.Alice
            local before = getCell():getZombieList():size()
            for i = 0, 44 do
                -- The photo fixture puts the horde up the road, in view of the camera.
                local dx, dy = 3 + i % 9, 3 + math.floor(i / 9)
                if PZ_TEST_PHOTOS then dx, dy = i % 9 - 2, -3 - math.floor(i / 9) end
                createZombie(anchor:getX() + dx, anchor:getY() + dy, 0, nil, 0, IsoDirections.S)
            end
            zombies:setValue(6)
            local spawned = getCell():getZombieList():size() - before
            assert(spawned == 45, 'Fixture horde did not spawn: ' .. spawned)
            print('PZ_TEST_PASS server spawned ' .. spawned .. ' real zombies beside both clients')
        end
    elseif command == 'clear' then
        cleared[name] = true
        if cleared.Alice and cleared.Beth then
            cleared = {}
            local zombies = getCell():getZombieList()
            local count = zombies:size()
            for i = count - 1, 0, -1 do
                local zombie = zombies:get(i)
                zombie:removeFromWorld(); zombie:removeFromSquare()
            end
            print('PZ_TEST_PASS server removed ' .. count .. ' fixture zombies')
        end
    elseif command == 'checked' then
        checked[name] = true
    elseif command == 'verified' then
        verified[name] = true
        if not (verified.Alice and verified.Beth) then return end
        if round == (PZ_TEST_ROUNDS or 1) then
            assert(traffic == 0, 'The mod sent ' .. traffic .. ' network messages')
            print('PZ_TEST_SERVER_PASS rounds=' .. round .. ' mod network messages=0')
            return
        end
        round = round + 1; ready = {}; verified = {}; checked = {}; started = false
        for other, p in pairs(players) do
            if not (PZ_TEST_RECONNECT and other == 'Beth') then sendServerCommand(p, 'ScannerProbe', 'reset', {}) end
        end
        if PZ_TEST_RECONNECT then print('PZ_TEST_RECONNECT_READY') end
    end
end)
Events.OnTick.Add(function()
    if ready.Alice and ready.Beth and not started then
        started = true
        for _, name in ipairs({ 'Alice', 'Beth' }) do
            local p = players[name]
            p:setInvincible(true); p:setGhostMode(true)
            if PZ_TEST_PHOTOS then
                getGameTime():setTimeOfDay(14.0)
                local shirt = name == 'Alice' and 'Base.Shirt_Lumberjack' or 'Base.Jumper_RoundNeck'
                for _, kind in ipairs({ shirt, 'Base.Trousers_Denim', 'Base.Shoes_TrainerTINT' }) do
                    local clothing = assert(p:getInventory():AddItem(kind), kind)
                    sendAddItemToContainer(p:getInventory(), clothing)
                    p:setWornItem(clothing:getBodyLocation(), clothing)
                    sendClothing(p, clothing:getBodyLocation(), clothing)
                end
                syncVisuals(p); syncClothingFields(p)
            end
            sendServerCommand(p, 'ScannerProbe', 'go', { round = round, final = round == (PZ_TEST_ROUNDS or 1) })
        end
        print('PZ_TEST_PASS two connected clients started round ' .. round)
    end
    if started and checked.Alice and checked.Beth and not dying then
        dying = true
        sendServerCommand(players.Beth, 'ScannerProbe', 'watch', {})
        sendServerCommand(players.Alice, 'ScannerProbe', 'die', {})
    end
end)

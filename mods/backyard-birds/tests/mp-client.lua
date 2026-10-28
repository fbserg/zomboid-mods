-- Loopback multiplayer probe, client half. Lives in the disposable game clone. Never installed.
local X, Y = 10628, 10658
local step, ticks = "spawn", 0

local function fail(message)
    print("BIRDS_MP_CLIENT_FAIL " .. message)
    step = "done"
end

Events.OnTick.Add(function()
    local player = getSpecificPlayer(0)
    if not player or step == "done" or not isClient() then return end
    local B = BackyardBirds
    ticks = ticks + 1
    if step == "spawn" and ticks == 60 then
        getPlayerInfoPanel(0):setVisible(false)
        SendCommandToServer(string.format("/teleportto %d,%d,0", X, Y))
        step, ticks = "teleport", 0
    elseif step == "teleport" then
        if math.floor(player:getX()) == X and math.floor(player:getY()) == Y and getCell():getGridSquare(X + 3, Y - 2, 0) then
            if ticks > 120 then
                sendClientCommand(player, "BirdsMP", "ready", { x = X + 3, y = Y - 2 })
                print("BIRDS_MP_CLIENT_READY")
                step, ticks = "visit", 0
            end
        elseif ticks > 1800 then
            fail("teleport did not land at " .. X .. "," .. Y .. ": " .. player:getX() .. "," .. player:getY())
        end
    elseif step == "visit" then
        local visit = B.visits[B.key(X + 3, Y - 2, 0) .. "#0"]
        if visit then
            print("BIRDS_MP_CLIENT_VISIT " .. visit.args.species .. " x" .. visit.args.count .. " boosted=" .. tostring(visit.args.boosted)
                .. " song=" .. tostring(visit.sound ~= nil and visit.emitter:isPlaying(visit.sound)))
            if not visit.args.boosted then return fail("server did not boost the player beside the bath") end
            step, ticks = "stats", 0
        elseif ticks > 900 then
            fail("no visit reached the client")
        end
    elseif step == "stats" and ticks == 240 then
        local stats = player:getStats()
        local boredom, unhappiness = stats:get(CharacterStat.BOREDOM), stats:get(CharacterStat.UNHAPPINESS)
        print("BIRDS_MP_CLIENT_STATS boredom=" .. boredom .. " unhappiness=" .. unhappiness)
        if math.abs(boredom - 45) > 1 or math.abs(unhappiness - 47) > 1 then return fail("stats did not sync from the server") end
        -- Landing and animation are client-only and covered by birds-photos. A live server's zombies may already have scared this flock.
        print("BIRDS_MP_CLIENT_PASS")
        step = "done"
    end
end)

-- Knox Scanner runs on clients. This probe proves a dedicated server that lists the mod
-- loads the shared file cleanly, writes no feed and saves nothing, before and after a restart.
local started, done = false, false
Events.OnServerStarted.Add(function() started = true end)
Events.OnTick.Add(function()
    if not started or done then return end
    done = true
    local ok, message = pcall(function()
        local S = assert(KnoxScanner, 'Shared file did not load on the dedicated server')
        assert(S.options == nil and S.requestKey == nil, 'Client options reached the server')
        assert(S.townAt(10628, 10658) == 'Muldraugh' and S.townAt(9000, 9000) == nil, 'Town lookup failed on the server')
        assert(S.landmarkIn('policestorage') == 'a police station' and S.landmarkIn('bedroom') == nil, 'Landmark lookup failed on the server')
        assert(getFileReader('KnoxScanner.txt', false) == nil, 'The server wrote a feed file')
        assert(not ModData.exists('KnoxScanner'), 'The mod saved world data')
        local phase = ModData.getOrCreate('KnoxScannerProbe')
        if phase.finished then
            print('PZ_TEST_RESTART_PASS no feed file and no mod data after a real save and process restart')
            return
        end
        phase.finished = true
        print('PZ_TEST_ENGINE_PASS shared file loaded on a dedicated server that writes and saves nothing')
    end)
    if not ok then print('PZ_TEST_FAIL ' .. tostring(message)) end
end)

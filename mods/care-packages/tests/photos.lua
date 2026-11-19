-- Test-only camera and timing. The images show the actual parcel form.
local frames = 0
local capture
local captured = 0

Events.OnGameStart.Add(function()
    local p = getSpecificPlayer(0)
    local x, y = PZ_TEST_SPAWN.x, PZ_TEST_SPAWN.y
    getCore():setAutoZoom(0, false)
    for i = 1, 5 do getCore():doZoomScroll(0, -1) end
    getClimateManager():stopWeatherAndThunder()
    for _, id in ipairs({3, 5, 8}) do
        local value = getClimateManager():getClimateFloat(id)
        value:setEnableAdmin(true)
        value:setAdminValue(0)
    end
    getGameTime():setTimeOfDay(17)
    getCell():addLamppost(x, y, 0, 1.0, 0.82, 0.62, 9)
    p:faceLocation(x + 1, y + 1)
    getPlayerInfoPanel(0):setVisible(false)
end)

if PZ_PHOTO_ROLE == "Alice" then
    local submit = CareParcelForm.onSubmit
    function CareParcelForm:onSubmit()
        self:setX(825)
        self:setY(415)
        capture = { name = "care-pack.png", at = frames + 40, form = self, finish = submit }
    end

    local close = CareParcelForm.close
    function CareParcelForm:close()
        if self.editing then return close(self) end
        self:setX(825)
        self:setY(415)
        capture = {name = "care-note.png", at = frames + 40, form = self, finish = close}
    end

    Events.OnTick.Add(function()
        local p = getSpecificPlayer(0)
        if not p then return end
        frames = frames + 1
        if frames == 100 then
            assert(p:getSquare():getRoom(), "Photo actor did not spawn inside a home")
            ISUIHandler.setVisibleAllUI(false)
        end
        if not capture or frames < capture.at then return end
        getCore():TakeFullScreenshot(capture.name)
        local result = capture
        capture = nil
        captured = captured + 1
        result.finish(result.form)
        if captured == 2 then print("PZ_TEST_PHOTOS_PASS captured the real seal and keepsake read panels") end
    end)
end

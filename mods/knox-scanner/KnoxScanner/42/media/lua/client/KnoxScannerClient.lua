require "KnoxScanner"
local S = KnoxScanner

S.options = PZAPI.ModOptions:create("KnoxScanner", "Knox Scanner")
S.options:addDescription("IGUI_KnoxScanner_about")
for _, id in ipairs(S.TOGGLES) do
    S.options:addTickBox(id, getText("IGUI_KnoxScanner_" .. id), true, getText("IGUI_KnoxScanner_" .. id .. "_tip"))
end
S.requestKey = S.options:addKeyBind("requestKey", getText("IGUI_KnoxScanner_requestKey"), 0, getText("IGUI_KnoxScanner_requestKey_tip"))

Events.OnCreatePlayer.Add(function() S.state = nil end)
Events.EveryOneMinute.Add(S.poll)
Events.OnPlayerDeath.Add(S.onDeath)
Events.EveryDays.Add(S.onDay)
Events.OnWeatherPeriodStart.Add(S.onWeather)
Events.OnKeyPressed.Add(S.onKey)

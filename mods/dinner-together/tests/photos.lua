-- Demonstration setup only. Appended to the two real network clients by --photos.
local photoTicks, photoReward, capturedMeal, capturedReward = 0, false, false, false
local mealTicks=0
Events.OnGameStart.Add(function()
    local p = getSpecificPlayer(0)
    if PZ_PHOTO_ROLE == 'Beth' then
        p:setX(p:getX()+2); p:setLastX(p:getX()); p:setCurrent(getCell():getGridSquare(math.floor(p:getX()),math.floor(p:getY()),0))
    end
    p:setInvincible(true); p:setGhostMode(true)
    getCore():setAutoZoom(0,false)
    for i=1,8 do getCore():doZoomScroll(0,-1) end
    ISUIHandler.setVisibleAllUI(false)
    getClimateManager():stopWeatherAndThunder()
    for _,id in ipairs({3,5,8}) do
        local value=getClimateManager():getClimateFloat(id)
        value:setEnableAdmin(true);value:setAdminValue(0)
    end
    local show=DinnerTogether.show
    DinnerTogether.show=function(player)
        show(player)
        photoReward=true
    end
end)
Events.OnTick.Add(function()
    local p=getSpecificPlayer(0)
    if not p or PZ_PHOTO_ROLE~='Alice' then return end
    photoTicks=photoTicks+1
    local zombies=getCell():getZombieList()
    for i=zombies:size()-1,0,-1 do zombies:get(i):removeFromWorld() end
    for x=10610,10645 do
        for y=10640,10675 do
            local square=getCell():getGridSquare(x,y,0)
            if square then square:setIsSeen(0,true) end
        end
    end
    if photoTicks==100 then
        getPlayerInfoPanel(0):setVisible(false)
        ISUIHandler.setVisibleAllUI(false)
    end
    if p:hasTimedActions() then mealTicks=mealTicks+1 end
    if not capturedMeal and mealTicks==45 then
        capturedMeal=true
        getCore():TakeFullScreenshot('dinner-meal.png')
        print('PZ_TEST_PHOTO meal captured during actual queued food action')
    end
    if photoReward and not capturedReward then
        capturedReward=true;photoTicks=0
    elseif capturedReward and photoTicks==30 then
        getCore():TakeFullScreenshot('dinner-company.png')
        print('PZ_TEST_PHOTOS_PASS actual shared-meal notification captured')
    end
end)

-- Demonstration setup only. Appended to the two real network clients by --photos.
-- Alice captures the actual thank-you notice, then opens the signed list read-only in the vanilla window.
local photoTicks, thanked, capturedThanks, opened, capturedList = 0, false, false, false, false
local listModal
Events.OnGameStart.Add(function()
    local p = getSpecificPlayer(0)
    p:setInvincible(true); p:setGhostMode(true)
    getCore():setAutoZoom(0,false)
    for i=1,8 do getCore():doZoomScroll(0,-1) end
    getGameTime():setTimeOfDay(18.0)
    getCell():addLamppost(PZ_TEST_SPAWN.x,PZ_TEST_SPAWN.y,0,1.0,0.78,0.45,8)
    ISUIHandler.setVisibleAllUI(false)
    getClimateManager():stopWeatherAndThunder()
    for _,id in ipairs({3,5,8}) do
        local value=getClimateManager():getClimateFloat(id)
        value:setEnableAdmin(true);value:setAdminValue(0)
    end
    local show=SharedGroceryList.show
    SharedGroceryList.show=function(player,command,text)
        show(player,command,text)
        if command=='thanks' then thanked=true end
    end
    local start=ISWriteSomething.start
    ISWriteSomething.start=function(action)
        start(action)
        if thanked then listModal=action.modal end
    end
end)
Events.OnTick.Add(function()
    local p=getSpecificPlayer(0)
    if not p or PZ_PHOTO_ROLE~='Alice' then return end
    photoTicks=photoTicks+1
    local zombies=getCell():getZombieList()
    for i=zombies:size()-1,0,-1 do zombies:get(i):removeFromWorld() end
    for x=PZ_TEST_SPAWN.x-15,PZ_TEST_SPAWN.x+15 do
        for y=PZ_TEST_SPAWN.y-15,PZ_TEST_SPAWN.y+15 do
            local square=getCell():getGridSquare(x,y,0)
            if square then square:setIsSeen(0,true) end
        end
    end
    if photoTicks==100 then
        assert(p:getSquare():getRoom(),'Photo actor did not spawn inside a home')
        p:faceLocation(PZ_TEST_SPAWN.x,PZ_TEST_SPAWN.y+2)
        getPlayerInfoPanel(0):setVisible(false)
        ISUIHandler.setVisibleAllUI(false)
    end
    if thanked and not capturedThanks then
        capturedThanks=true;thanked=photoTicks
    elseif capturedThanks and not opened and photoTicks==thanked+30 then
        getCore():TakeFullScreenshot('grocery-thanks.png')
        print('PZ_TEST_PHOTO actual thank-you notice captured')
        local lists=p:getInventory():getAllTypeRecurse('SharedGroceryList.GroceryList')
        assert(lists:size()==1,'Alice should hold exactly the signed list')
        opened=photoTicks
        ISInventoryPaneContextMenu.onWriteSomething(lists:get(0),false,0)
    elseif listModal and not capturedList and photoTicks>=opened+40 then
        capturedList=true
        getCore():TakeFullScreenshot('grocery-list.png')
        listModal:onClick(listModal.no)
        print('PZ_TEST_PHOTOS_PASS signed list captured in the vanilla read window')
    end
end)

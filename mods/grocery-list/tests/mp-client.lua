local role = '@ROLE@'
local TYPE = 'SharedGroceryList.GroceryList'
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
local ticks, sent, done = 0, false, false
local write, modal, written, marks, expected
local notices = 0
Events.OnGameStart.Add(function()
    local p = getSpecificPlayer(0)
    p:setInvincible(true); p:setGhostMode(true)
    local x = PZ_TEST_SPAWN.x + 0.5
    local y = PZ_TEST_SPAWN.y + (role == 'Beth' and 2 or 0.5)
    p:setX(x); p:setLastX(x); p:setY(y); p:setLastY(y); p:setZ(PZ_TEST_SPAWN.z); p:setLastZ(PZ_TEST_SPAWN.z)
    p:setCurrent(getCell():getGridSquare(math.floor(x), math.floor(y), PZ_TEST_SPAWN.z))
    local info = assert(getModInfoByID('SharedGroceryList'), 'Mod panel metadata missing')
    assert(info:getModVersion() == '0.1.0' and info:getPosterCount() >= 1, 'Wrong mod panel version or no posters')
    assert(getTexture(info:getIcon()), 'Mod icon does not load')
    for i = 0, info:getPosterCount()-1 do assert(getTexture(info:getPoster(i)), 'Mod poster does not load') end
    assert(getItemNameFromFullType(TYPE) == 'Grocery List', 'Item name did not translate: ' .. tostring(getItemNameFromFullType(TYPE)))
    local recipe
    local recipes = getScriptManager():getAllCraftRecipes()
    for i = 0, recipes:size()-1 do
        if recipes:get(i):getName() == 'MakeGroceryList' then recipe = recipes:get(i) end
    end
    assert(recipe and recipe:getTranslationName() == 'Make Grocery List', 'Recipe name did not translate')
    assert(getText('IGUI_SharedGroceryList_done') == 'Got everything on the list!', 'Notice translation did not load')
    print('PZ_TEST_PASS mod panel, item name, recipe name and notices translated ' .. role)
    local show = SharedGroceryList.show
    SharedGroceryList.show = function(player, command, text)
        show(player, command, text)
        notices = notices + 1
        print('PZ_TEST_PASS notification ' .. role .. ' ' .. command .. ' ' .. (text and getText('IGUI_SharedGroceryList_' .. command, text) or getText('IGUI_SharedGroceryList_' .. command)))
    end
    local start = ISWriteSomething.start
    ISWriteSomething.start = function(action)
        start(action)
        modal = action.modal
    end
end)
Events.OnServerCommand.Add(function(module, command, args)
    if module ~= 'GroceryProbe' then return end
    if command == 'reset' then ticks = 0; sent = false; done = false end
    if command == 'round' then notices = 0; write = nil; modal = nil; written = false; marks = nil; expected = nil end
    if command == 'write' then write = args end
    if command == 'checkMarks' then marks = args end
    if command == 'expected' then expected = args end
end)
local function find(p, id)
    local items = p:getInventory():getAllTypeRecurse(TYPE)
    for i = 0, items:size()-1 do
        if items:get(i):getID() == id then return items:get(i) end
    end
end
Events.OnTick.Add(function()
    local p = getSpecificPlayer(0)
    if not p or not isClient() or done then return end
    ticks = ticks + 1
    if ticks > 180 and not sent then
        sent = true
        sendClientCommand(p, 'SharedGroceryList', 'done', {})
        sendClientCommand(p, 'SharedGroceryList', 'thanks', {text='Forger'})
        sendClientCommand(p, 'GroceryProbe', 'ready', {})
    end
    if write and not modal and not written and not p:hasTimedActions() then
        local list = find(p, write.id)
        if list then
            ISInventoryPaneContextMenu.onWriteSomething(list, true, 0)
            write.queued = true
        end
    end
    if write and modal and not written then
        modal.entry:setText(write.text)
        modal:onClick(modal.yes)
        written = true
        print('PZ_TEST_PASS ' .. role .. ' wrote the list through the vanilla journal window')
        sendClientCommand(p, 'GroceryProbe', 'written', {})
    end
    if marks then
        local list = find(p, marks.id)
        local page = list and list:seePage(1) or ''
        local n = 0
        for line in (page .. '\n'):gmatch('([^\n]*)\n') do
            if line:sub(1, 4) == '[x] ' then n = n + 1 end
        end
        if n == marks.count then
            marks = nil
            sendClientCommand(p, 'GroceryProbe', 'marks', {})
        end
    end
    if expected and not p:hasTimedActions() and notices == expected.notices then
        local stats = p:getStats()
        local page = expected.page and (find(p, expected.id) or {seePage=function() return '' end}):seePage(1)
        if math.abs(stats:get(CharacterStat.BOREDOM) - expected.boredom) < 1
            and math.abs(stats:get(CharacterStat.UNHAPPINESS) - expected.unhappiness) < 1
            and page == expected.page then
            print((expected.final and 'PZ_TEST_CLIENT_PASS ' or 'PZ_TEST_ROUND_CLIENT_PASS ') .. role .. ' round=' .. expected.round .. ' stats, page and notices synced, notices=' .. notices)
            sendClientCommand(p, 'GroceryProbe', 'verified', {})
            done = true
        end
    end
end)

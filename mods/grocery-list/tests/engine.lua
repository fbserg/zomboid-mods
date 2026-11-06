-- Native server probe: real item script, real vanilla items and bags, real world save and restart.
local X, Y = 10628, 10658
local TYPE = 'SharedGroceryList.GroceryList'
local started, done = false, false
Events.OnServerStarted.Add(function() started = true end)
Events.OnTick.Add(function()
    if not started or done or not farmTestKeepLoaded then return end
    farmTestKeepLoaded(X, Y)
    local square = getCell():getGridSquare(X, Y, 0)
    if not square then return end
    done = true
    local ok, message = pcall(function()
        local all = {}
        getOnlinePlayers = function()
            return {size=function() return #all end, get=function(_,i) return all[i+1] end}
        end
        local sent = {}
        sendServerCommand = function(p, module, command, args) -- no connections in this server-only probe.
            if module == 'SharedGroceryList' then sent[#sent+1] = p:getUsername()..':'..command end
        end
        local syncs = 0
        syncItemFields = function() syncs = syncs + 1 end -- the network gate checks real field sync.
        local function count(prefix)
            local n = 0
            for _, v in ipairs(sent) do if v:sub(1, #prefix) == prefix then n = n + 1 end end
            return n
        end
        local function player(name, dx)
            local p = IsoPlayer.new(getCell())
            p:setUsername(name); p:getDescriptor():setForename(name)
            p:setX(X + dx + 0.5); p:setY(Y + 0.5); p:setZ(0)
            p:setCurrent(assert(getCell():getGridSquare(X + dx, Y, 0)))
            p:getStats():set(CharacterStat.BOREDOM, 50)
            p:getStats():set(CharacterStat.UNHAPPINESS, 50)
            all[#all+1] = p
            return p
        end
        local function stat(p, s) return math.floor(p:getStats():get(s) + 0.5) end
        local phase = ModData.getOrCreate('GroceryListProbe')
        if phase.finished then
            local found
            local objects = square:getWorldObjects()
            for i = 0, objects:size()-1 do
                local item = objects:get(i):getItem()
                if item:getFullType() == TYPE then found = item end
            end
            assert(found, 'Delivered list missing after real restart')
            local page = found:seePage(1)
            assert(page:find('[x] Canned beans', 1, true) and page:sub(-9) == '~ Beth <3', 'Page lost after restart: '..page)
            assert(found:getModData().delivered and found:getModData().author == 'Alice', 'List mod data lost after restart')
            assert(ModData.getOrCreate('SharedGroceryListRewards')['thanks:Alice'], 'Reward cooldown missing after restart')
            local b = player('Beth', 1)
            local again = b:getInventory():AddItem(TYPE)
            again:addPage(1, 'milk\nrice\nbatteries')
            for _, kind in ipairs({'Base.Milk', 'Base.Rice', 'Base.Battery'}) do b:getInventory():AddItem(kind) end
            SharedGroceryList.scanAll()
            assert(count('Beth:done') == 1, 'Fresh list did not finish after restart: '..table.concat(sent, ','))
            assert(stat(b, CharacterStat.BOREDOM) == 50, 'Real restart reset the reward cooldown')
            print('PZ_TEST_RESTART_PASS list page, list mod data and reward cooldown survived engine save and process restart')
            return
        end

        local item = instanceItem(TYPE)
        assert(item, 'Grocery List item script did not load')
        assert(item:canBeWrite() and item:getPageToWrite() == 1, 'Grocery List is not a one-page writable item')
        local recipe
        local recipes = ScriptManager.instance:getAllCraftRecipes()
        for i = 0, recipes:size()-1 do
            if recipes:get(i):getName() == 'MakeGroceryList' then recipe = recipes:get(i) end
        end
        assert(recipe, 'Craft recipe did not load')
        print('PZ_TEST_DIAG recipe '..recipe:getScriptObjectFullType()..' outputs='..recipe:getOutputs():size()..' inputs='..recipe:getInputs():size())
        print('PZ_TEST_PASS item script and craft recipe registered; clients check translated names')

        local a, b = player('Alice', 0), player('Beth', 1)
        local list = a:getInventory():AddItem(TYPE)
        list:addPage(1, 'Canned beans\n- apples\n2 x rice\nbatteries')
        SharedGroceryList.scanAll()
        assert(#sent == 0 and list:getModData().author == 'Alice', 'Empty-handed author was credited')
        a:getInventory():Remove(list); b:getInventory():AddItem(list)
        for _, kind in ipairs({'Base.TinnedBeans', 'Base.Apple', 'Base.Battery'}) do b:getInventory():AddItem(kind) end
        SharedGroceryList.scanAll()
        assert(count('Beth:got') == 3 and not list:getModData().done, 'Carried vanilla items did not cross off: '..table.concat(sent, ','))
        local bag = b:getInventory():AddItem('Base.Bag_Schoolbag')
        bag:getInventory():AddItem('Base.Rice')
        SharedGroceryList.scanAll()
        assert(count('Beth:got') == 4 and count('Beth:done') == 1, 'Item inside a carried bag did not count')
        assert(stat(b, CharacterStat.BOREDOM) == 40 and stat(b, CharacterStat.UNHAPPINESS) == 45, 'Shopper reward mismatch')
        local page = list:seePage(1)
        assert(page == '[x] Canned beans\n[x] - apples\n[x] 2 x rice\n[x] batteries', 'Page was not marked: '..page)
        print('PZ_TEST_PASS real vanilla items, display names and a nested bag cross off a native page')

        SharedGroceryList.scanAll()
        assert(count('Beth:delivered') == 0 and count('Beth:done') == 1, 'Shopper was paid twice or before hand-back')
        b:getInventory():Remove(list); a:getInventory():AddItem(list)
        SharedGroceryList.scanAll()
        assert(count('Alice:thanks') == 1 and count('Beth:delivered') == 1, 'Hand-back did not thank both')
        assert(stat(a, CharacterStat.UNHAPPINESS) == 40 and stat(b, CharacterStat.UNHAPPINESS) == 35, 'Delivery reward mismatch')
        page = list:seePage(1)
        assert(page:sub(-9) == '~ Beth <3', 'Signature missing: '..page)
        SharedGroceryList.scanAll()
        assert(count('Alice:thanks') == 1, 'Delivery repeated')
        print('PZ_TEST_PASS hand-back thanks both players once and signs the list')

        local floor = instanceItem(TYPE)
        floor:addPage(1, 'apples\nbatteries\nrice')
        square:AddWorldInventoryItem(floor, 0.2, 0.2, 0)
        local before = #sent
        SharedGroceryList.scanAll()
        assert(#sent == before and not floor:getModData().author, 'A list on the floor was scanned')
        square:transmitRemoveItemFromSquare(floor:getWorldItem())
        print('PZ_TEST_PASS lists that nobody carries are ignored')

        a:getInventory():Remove(list)
        square:AddWorldInventoryItem(list, 0.5, 0.5, 0)
        phase.finished = true
        print('PZ_TEST_PASS item syncs requested='..syncs)
    end)
    print(ok and 'PZ_TEST_ENGINE_PASS' or ('PZ_TEST_FAIL ' .. tostring(message)))
end)

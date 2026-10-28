local X, Y = 10628, 10658
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
        local function player(name, dx)
            local p = IsoPlayer.new(getCell())
            p:setUsername(name); p:setX(X + dx + 0.5); p:setY(Y + 0.5); p:setZ(0)
            p:setCurrent(assert(getCell():getGridSquare(X + dx, Y, 0)))
            p:getStats():set(CharacterStat.HUNGER, 0.8)
            p:getStats():set(CharacterStat.BOREDOM, 50)
            p:getStats():set(CharacterStat.UNHAPPINESS, 50)
            all[#all+1] = p
            return p
        end
        local a, b = player('Alice', 0), player('Beth', 1)
        local sent = 0
        sendServerCommand = function() sent = sent + 1 end -- no connections in this server-only probe.
        local function eat(p)
            local food = p:getInventory():AddItem('Base.Apple')
            local before = p:getStats():get(CharacterStat.HUNGER)
            assert(ISEatFoodAction:new(p, food, 1):complete())
            assert(before - p:getStats():get(CharacterStat.HUNGER) >= 0.05, 'Real food did not reduce hunger')
        end
        assert(tostring(LosUtil.lineClear(getCell(), X, Y, 0, X+1, Y, 0, false)) == 'Clear', 'Probe path obstructed')
        local phase = ModData.getOrCreate('DinnerTogetherProbe')
        if phase.finished then
            assert(ModData.getOrCreate('DinnerTogetherRewards').Alice, 'Cooldown missing after real restart')
            eat(a); eat(b)
            assert(sent == 0, 'Real restart reset the cooldown')
            print('PZ_TEST_RESTART_PASS cooldown survived engine save and process restart')
            return
        end
        eat(a)
        assert(sent == 0, 'Solitary meal rewarded')
        eat(b)
        assert(sent == 2, 'Pair did not reward: ' .. sent)
        assert(a:getStats():get(CharacterStat.BOREDOM) == 45 and b:getStats():get(CharacterStat.UNHAPPINESS) == 47, 'Mood mismatch')
        print('PZ_TEST_PASS real apples consumed through vanilla completion, two real players rewarded')
        eat(a); eat(b)
        assert(sent == 2, 'Cooldown did not apply')
        local saved = ModData.getOrCreate('DinnerTogetherRewards').Alice
        assert(saved == getGameTime():getWorldAgeHours(), 'Cooldown not stored')
        print('PZ_TEST_PASS native stats and world cooldown store')
        a:setX(X+100); b:setX(X+100)
        local c, d = player('Far', 0), player('Away', 6)
        eat(c); eat(d)
        assert(sent == 2, 'Far pair rewarded')
        print('PZ_TEST_PASS real distance excludes separated diners')
        c:setX(X+100); d:setX(X+100)
        local e, f = player('Down', 0), player('Up', 1)
        f:setZ(1)
        eat(e); eat(f)
        assert(sent == 2, 'Floor mismatch rewarded')
        print('PZ_TEST_PASS real floor excludes separated diners')
        e:setX(X+100); f:setX(X+100)
        local tile
        for i = 0,127 do
            local name = 'walls_exterior_house_01_' .. i
            local sprite = getSprite(name)
            if sprite and sprite:getProperties():has(IsoFlagType.collideW)
                and sprite:getProperties():has(IsoFlagType.cutW) then tile=name; break end
        end
        assert(tile, 'No native solid wall sprite')
        local wallSquare = getCell():getGridSquare(X+1,Y,0)
        local wallObject = IsoThumpable.new(getCell(), wallSquare, tile, false, {})
        wallSquare:AddSpecialObject(wallObject)
        wallSquare:RecalcAllWithNeighbours(true)
        local g,h = player('WallA',0),player('WallB',1)
        eat(g); eat(h)
        assert(sent == 2, 'Wall-separated pair rewarded')
        print('PZ_TEST_PASS real placed wall excludes diners: ' .. tile)
        wallSquare:RemoveTileObject(wallObject)
        wallSquare:RecalcAllWithNeighbours(true)
        phase.finished = true
    end)
    print(ok and 'PZ_TEST_ENGINE_PASS' or ('PZ_TEST_FAIL ' .. tostring(message)))
end)

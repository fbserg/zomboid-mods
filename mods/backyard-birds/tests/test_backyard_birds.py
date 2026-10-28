"""Portable behaviour tests with Lua, separate from the native engine and photo gates."""
from pathlib import Path
import unittest
from lupa import LuaRuntime

MOD = Path(__file__).resolve().parents[1] / "BackyardBirds/42/media"
LUA = MOD / "lua"

FIXTURE = r'''
Events = setmetatable({}, {__index=function(t,k)
    local handlers = {}
    local e = {Add=function(fn) handlers[#handlers+1]=fn end, handlers=handlers}
    rawset(t,k,e); return e
end})
package.preload["BackyardBirds"] = function() end
package.preload["ISUI/ISUIElement"] = function() end
server, client = true, false
function isServer() return server end
function isClient() return client end
function instanceof(o, kind) return o.kind == kind end
function array(items) return {size=function() return #items end, get=function(_,i) return items[i+1] end} end

rolls = {}
function ZombRand(a, b)
    if #rolls > 0 then return table.remove(rolls, 1) end
    return b and a or 0
end

clock = {hour=12, month=4, age=100}
function getGameTime()
    return {getHour=function() return clock.hour end, getMonth=function() return clock.month end,
        getWorldAgeHours=function() return clock.age end}
end
rain, temperature = 0, 20
function getClimateManager() return {getRainIntensity=function() return rain end, getTemperature=function() return temperature end} end

squares = {}
function bath(name) return {getSprite=function() return {getProperties=function()
    return {get=function(_, key) assert(key == "CustomName"); return name end} end} end} end
function addSquare(x, y, z, objects, outside)
    local s = {x=x, y=y, z=z, objects=objects or {}, moving={}, outside=outside ~= false, seen=true}
    function s:getX() return self.x end
    function s:getY() return self.y end
    function s:getZ() return self.z end
    function s:getObjects() return array(self.objects) end
    function s:getMovingObjects() return array(self.moving) end
    function s:isOutside() return self.outside end
    function s:isCouldSee() return self.seen end
    squares[x .. "," .. y .. "," .. z] = s
    return s
end
function getCell() return {getGridSquare=function(_, x, y, z) return squares[x .. "," .. y .. "," .. z] end} end

CharacterStat = {BOREDOM="boredom", UNHAPPINESS="unhappiness"}
SyncPlayerStatsPacket = {getBitMaskForStat=function(stat) return stat == "boredom" and 8 or 16 end}
synced, sent = {}, {}
function syncPlayerStats(player, mask) synced[#synced+1] = {player=player.name, mask=mask} end
function sendServerCommand(player, module, command, args) sent[#sent+1] = {player=player.name, module=module, command=command, args=args} end
function makePlayer(name, x, y, z)
    local p = {name=name, x=x, y=y, z=z or 0, num=0, stat={boredom=50, unhappiness=50}, gait="walk"}
    function p:getX() return self.x end
    function p:getY() return self.y end
    function p:getZ() return self.z end
    function p:getPlayerNum() return self.num end
    function p:isSneaking() return self.gait == "sneak" end
    function p:isRunning() return self.gait == "run" end
    function p:isSprinting() return self.gait == "sprint" end
    function p:getStats()
        return {remove=function(_, stat, amount) p.stat[stat] = p.stat[stat] - amount end}
    end
    return p
end
online = {}
function getOnlinePlayers() return array(online) end
function getNumActivePlayers() return #online end
function getSpecificPlayer(i) return online[i+1] end
function getPlayer() return online[1] end

-- Client side.
zoom, now = 1, 1000
function getCore() return {getZoom=function() return zoom end} end
function getTimestampMs() return now end
function isoToScreenX(n, x, y, z) return x * 10 end
function isoToScreenY(n, x, y, z) return y * 10 - z * 100 end
function getTexture(name) return {name=name} end
emitter = {played={}, stopped={}}
function emitter:playSound(name) self.played[#self.played+1] = name; return #self.played end
function emitter:stopSound(id) self.stopped[#self.stopped+1] = id end
emitter.ended = {}
function emitter:isPlaying(id)
    for _, s in ipairs(self.stopped) do if s == id then return false end end
    return not self.ended[id]
end
function getWorld() return {getFreeEmitter=function() return emitter end} end
halos = {}
HaloTextHelper = {getGoodColor=function() return "good" end,
    addTextWithArrow=function(p, text, up, color) halos[#halos+1] = {text=text, arrow=up, color=color} end,
    addText=function(p, text) halos[#halos+1] = {text=text} end}
ui = {}
ISUIElement = {}
ISUIElement.__index = ISUIElement
function ISUIElement:derive(name) local o = setmetatable({Type=name}, self); o.__index = o; return o end
function ISUIElement.new(class, x, y, w, h) return setmetatable({x=x, y=y, drawn={}, visible=true}, class) end
function ISUIElement:initialise() end
function ISUIElement:addToUIManager()
    ui[self] = true
    local element = self
    self.javaObject = {setConsumeMouseEvents=function(_, v) element.consumes = v end}
end
function ISUIElement:removeFromUIManager() ui[self] = nil end
function ISUIElement:backMost() self.back = true end
function ISUIElement:setX(x) self.x = x end
function ISUIElement:setY(y) self.y = y end
function ISUIElement:drawTextureScaled(t, x, y, w, h, a) self.drawn[#self.drawn+1] = {t=t.name, x=x, y=y, w=w, h=h, a=a} end

function states(visit)
    local t = {}
    for _, bird in ipairs(visit.birds) do t[#t+1] = bird.state end
    return table.concat(t, ",")
end
'''


class Birds(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(FIXTURE)
        for path in ("shared/BackyardBirds.lua", "client/BackyardBirdsClient.lua", "server/BackyardBirdsServer.lua"):
            self.lua.execute((LUA / path).read_text())
        self.run_lua = self.lua.execute

    def ids(self, expression):
        return self.run_lua(f"local t = {{}} for _, s in ipairs({expression}) do t[#t+1] = s.id end return table.concat(t, ',')")

    def sent(self):
        return self.run_lua("local t = {} for _, s in ipairs(sent) do t[#t+1] = s.player .. ':' .. tostring(s.args.boosted) .. ':' .. s.args.species .. ':' .. s.args.count .. ':' .. s.args.minutes end return table.concat(t, ',')")

    def test_species_follow_the_kentucky_calendar(self):
        self.assertEqual(self.ids("BackyardBirds.speciesFor(0, false)"), "cardinal,bluejay,chickadee")
        self.assertEqual(self.ids("BackyardBirds.speciesFor(5, false)"), "cardinal,bluejay,chickadee,robin,goldfinch")
        self.assertEqual(self.ids("BackyardBirds.speciesFor(0, true)"), "bluebird")

    def test_every_species_has_every_frame_both_ways(self):
        for species in self.ids("BackyardBirds.SPECIES").split(","):
            for frame in ("perch", "peck", "flap", "bathe"):
                for facing in ("l", "r"):
                    self.assertTrue((MOD / f"textures/BackyardBirds/{species}_{frame}_{facing}.png").is_file(), (species, frame, facing))

    def test_busy_mornings_quiet_middays_and_no_birds_at_night(self):
        chance = self.run_lua("return function(h, r, t, s) return BackyardBirds.visitChance(h, r, t, s) end")
        self.assertEqual([chance(h, 0, 20, 99) for h in (5, 6, 8, 9, 14, 15, 19, 20)], [0, 30, 30, 8, 8, 18, 18, 0])

    def test_rain_and_frozen_water_keep_birds_away_and_heat_or_fresh_rain_bring_them(self):
        chance = self.run_lua("return function(h, r, t, s) return BackyardBirds.visitChance(h, r, t, s) end")
        self.assertEqual(chance(8, 0.2, 20, 99), 0)
        self.assertEqual(chance(8, 0, 0, 99), 0)
        self.assertEqual(chance(8, 0, 27, 99), 45)
        self.assertEqual(chance(12, 0, 20, 1.5), 12)
        self.assertEqual(chance(16, 0, 30, 0.5), 40)

    def test_visit_text_reads_naturally(self):
        text = self.run_lua("return function(s, n) return BackyardBirds.visitText({species=s, count=n}) end")
        self.assertEqual(text("robin", 1), "An American Robin visits the bird bath")
        self.assertEqual(text("cardinal", 1), "A Northern Cardinal visits the bird bath")
        self.assertEqual(text("bluejay", 3), "3 Blue Jays visit the bird bath")
        self.assertEqual(text("bluebird", 1), "A rare Eastern Bluebird visits the bird bath")
        self.assertEqual(text("bluebird", 2), "2 rare Eastern Bluebirds visit the bird bath")

    def test_only_outdoor_bird_baths_on_the_players_level_count(self):
        self.run_lua('''
            addSquare(105, 100, 0, {bath("Bird Bath")})
            addSquare(100, 105, 0, {bath("Bird Bath")}, false)
            addSquare(100, 95, 0, {bath("The Gnome")})
            addSquare(95, 100, 1, {bath("Bird Bath")})
            addSquare(111, 100, 0, {bath("Bird Bath")})
            addSquare(101, 100, 0, {{getSprite=function() return nil end}})
        ''')
        found = self.run_lua("local t = {} for _, s in ipairs(BackyardBirds.bathsNear(makePlayer('a', 100.5, 100.5))) do t[#t+1] = BackyardBirds.key(s:getX(), s:getY(), s:getZ()) end return table.concat(t, ';')")
        self.assertEqual(found, "105,100,0")

    def test_server_shares_one_visit_and_boosts_nearby_players_once(self):
        # Rolls: visit chance, minutes, rare check, species, flock size.
        self.run_lua('''
            addSquare(105, 100, 0, {bath("Bird Bath")})
            online = {makePlayer("near", 100.5, 100.5), makePlayer("also", 108.5, 100.5), makePlayer("far", 125.5, 100.5),
                makePlayer("away", 160.5, 100.5), makePlayer("upstairs", 105.5, 100.5, 1)}
            rolls = {7, 8, 99, 1, 1}
            BackyardBirds.tick()
        ''')
        self.assertEqual(self.sent(), "near:true:bluejay:2:8,also:true:bluejay:2:8,far:false:bluejay:2:8")
        self.assertEqual(self.run_lua("return online[1].stat.boredom .. ',' .. online[1].stat.unhappiness .. ',' .. online[3].stat.boredom"), "45,47,50")
        self.assertEqual(self.run_lua("local t = {} for _, s in ipairs(synced) do t[#t+1] = s.player .. s.mask end return table.concat(t, ',')"), "near8,near16,also8,also16")
        self.assertEqual(self.run_lua("return sent[1].module .. '/' .. sent[1].command"), "BackyardBirds/visit")

    def test_one_visit_at_a_time_and_one_boost_per_hour(self):
        self.run_lua('''
            addSquare(105, 100, 0, {bath("Bird Bath")})
            online = {makePlayer("near", 100.5, 100.5)}
            rolls = {0, 12, 99, 0, 0}
            BackyardBirds.tick()
            clock.age = 100.1
            rolls = {0, 12, 99, 0, 0}
            BackyardBirds.tick()
        ''')
        self.assertEqual(self.run_lua("return #sent"), 1, "a second visit started while the first was still there")
        self.run_lua("clock.age = 100.5; rolls = {0, 12, 99, 0, 0}; BackyardBirds.tick()")
        self.assertEqual(self.run_lua("return #sent .. ':' .. tostring(sent[2].args.boosted) .. ':' .. online[1].stat.boredom"), "2:false:45")
        self.run_lua("clock.age = 101.1; rolls = {0, 12, 99, 0, 0}; BackyardBirds.tick()")
        self.assertEqual(self.run_lua("return tostring(sent[3].args.boosted) .. ':' .. online[1].stat.boredom"), "true:40")

    def test_no_visit_at_night_in_rain_on_ice_near_zombies_or_on_a_missed_roll(self):
        self.run_lua('''
            addSquare(105, 100, 0, {bath("Bird Bath")})
            addSquare(108, 103, 0).moving = {{kind="IsoZombie"}}
            online = {makePlayer("near", 100.5, 100.5)}
            BackyardBirds.tick()
            squares["108,103,0"].moving = {}
            clock.hour = 21; BackyardBirds.tick()
            clock.hour = 12; rain = 0.5; BackyardBirds.tick()
            rain = 0; temperature = -2; clock.age = 103; BackyardBirds.tick()
            temperature = 20; rolls = {8}; BackyardBirds.tick()
        ''')
        self.assertEqual(self.run_lua("return #sent"), 0)

    def test_birds_come_out_after_the_rain(self):
        self.run_lua('''
            addSquare(105, 100, 0, {bath("Bird Bath")})
            online = {makePlayer("near", 100.5, 100.5)}
            rain = 0.5; BackyardBirds.tick()
            rain = 0; clock.age = 101; rolls = {11, 4, 99, 0, 0}; BackyardBirds.tick()
            clock.age = 103; rolls = {11}; BackyardBirds.tick()
        ''')
        self.assertEqual(self.run_lua("return #sent"), 1, "midday chance is 8, or 12 within two hours of rain")

    def test_a_rare_bluebird_sometimes_comes(self):
        self.run_lua('''
            addSquare(105, 100, 0, {bath("Bird Bath")})
            online = {makePlayer("near", 100.5, 100.5)}
            rolls = {0, 4, 4, 0, 0}
            BackyardBirds.tick()
        ''')
        self.assertEqual(self.sent(), "near:true:bluebird:1:4")

    def test_single_player_shows_the_visit_without_networking(self):
        self.run_lua('''
            server = false
            addSquare(105, 100, 0, {bath("Bird Bath")})
            online = {makePlayer("solo", 100.5, 100.5)}
            rolls = {0, 6, 99, 0, 2}
            BackyardBirds.tick()
        ''')
        self.assertEqual(self.run_lua("return #sent .. ':' .. #synced .. ':' .. online[1].stat.boredom .. ':' .. #emitter.played"), "0:0:45:1")
        self.assertEqual(self.run_lua("local v = BackyardBirds.visits['105,100,0#0'] return #v.birds .. v.args.species"), "3cardinal")

    def test_multiplayer_client_never_runs_the_scheduler(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(FIXTURE)
        lua.execute("server, client = false, true")
        lua.execute((LUA / "shared/BackyardBirds.lua").read_text())
        lua.execute((LUA / "server/BackyardBirdsServer.lua").read_text())
        self.assertIsNone(lua.execute("return BackyardBirds.tick"))
        self.assertEqual(lua.execute("return #Events.EveryTenMinutes.handlers"), 0)

    def test_birds_land_one_by_one_and_leave_one_by_one(self):
        # Rolls per bird: second-bird delay (game seconds), facing, early leave (game seconds).
        self.run_lua('''
            addSquare(105, 100, 0, {bath("Bird Bath")})
            online = {makePlayer("me", 100.5, 100.5)}
            rolls = {0, 0, 60, 1, 120}
            visit = BackyardBirds.showVisit(online[1], {x=105, y=100, z=0, species="robin", count=2, minutes=10, boosted=false})
            first = visit.birds[2]
            visit:update()
        ''')
        self.assertEqual(self.run_lua("return states(visit)"), "waiting,arriving")
        self.run_lua("now = 1400; visit:prerender(); visit:render()")
        self.assertEqual(self.run_lua("return #visit.drawn .. ':' .. visit.drawn[1].a .. ':' .. visit.drawn[1].t"), "1:0.5:media/textures/BackyardBirds/robin_flap_l.png")
        self.run_lua("now = 1800; visit:update(); clock.age = 100 + 61 / 3600; visit:update(); now = 2600; visit:update()")
        self.assertEqual(self.run_lua("return states(visit) .. ':' .. #emitter.stopped"), "present,present:0")
        self.run_lua("clock.age = 100 + 10 / 60 - 100 / 3600; now = 3000; visit:update(); now = 4300; visit:update()")
        self.assertEqual(self.run_lua("return states(visit) .. ':' .. #emitter.stopped"), "gone,present:0", "the song stops early")
        self.run_lua("clock.age = 100 + 10 / 60; now = 4400; visit:update(); now = 5700; visit:update()")
        self.assertEqual(self.run_lua("return states(visit) .. ':' .. emitter.stopped[1] .. ':' .. tostring(ui[visit]) .. ':' .. tostring(BackyardBirds.visits['105,100,0#0'])"),
                         "gone,gone:1:nil:nil")

    def test_the_song_repeats_with_pauses_while_birds_stay(self):
        self.run_lua('''
            addSquare(105, 100, 0, {bath("Bird Bath")})
            online = {makePlayer("me", 100.5, 100.5)}
            visit = BackyardBirds.showVisit(online[1], {x=105, y=100, z=0, species="cardinal", count=1, minutes=30, boosted=false})
            visit:update()
            emitter.ended[1] = true
            rolls = {700, 1500} -- the landed bird's next move, then the pause before the next burst
            now = 2000; visit:update()
            now = 3400; visit:update()
            first = #emitter.played
            now = 3500; visit:update()
        ''')
        self.assertEqual(self.run_lua("return first .. ':' .. #emitter.played .. ':' .. emitter.played[2] .. ':' .. visit.songs .. ':' .. visit.sound"),
                         "1:2:BirdInTree:2:2", "a new burst starts 1.5 s after the last one ended")

    def test_present_birds_sit_on_the_rim_and_clicks_pass_through(self):
        self.run_lua('''
            addSquare(105, 100, 0, {bath("Bird Bath")})
            online = {makePlayer("me", 100.5, 100.5)}
            rolls = {0, 0, 30, 1, 0}
            visit = BackyardBirds.showVisit(online[1], {x=105, y=100, z=0, species="robin", count=2, minutes=30, boosted=true})
            for _, bird in ipairs(visit.birds) do bird.state, bird.frame = "present", "perch" end
            zoom = 2
            visit:prerender(); visit:render()
        ''')
        self.assertEqual(self.run_lua("return tostring(visit.consumes) .. ':' .. tostring(visit.back) .. ':' .. emitter.played[1]"), "false:true:BirdInTree")
        self.assertEqual(list(self.run_lua("return {visit.x, visit.y}").values()), [1055, 977])
        drawn = [(d.t, [d.x, d.y, d.w, d.h]) for d in self.run_lua("return visit.drawn").values()]
        # Back-rim bird first, so the front bird overlaps it.
        self.assertEqual(drawn, [("media/textures/BackyardBirds/robin_perch_r.png", [3, -21, 16, 14]),
                                 ("media/textures/BackyardBirds/robin_perch_l.png", [-12, -15, 16, 14])])

    def test_text_only_for_a_mood_lift_or_a_rare_bird_in_view(self):
        self.run_lua('''
            addSquare(105, 100, 0, {bath("Bird Bath")})
            online = {makePlayer("me", 100.5, 100.5)}
            function show(species, boosted) return BackyardBirds.showVisit(online[1], {x=105, y=100, z=0, species=species, count=1, minutes=30, boosted=boosted}) end
            first = show("cardinal", false)
            show("cardinal", true)
            squares["105,100,0"].seen = false
            show("bluebird", false)
            squares["105,100,0"].seen = true
            show("bluebird", false)
        ''')
        self.assertEqual(self.run_lua("local t = {} for _, h in ipairs(halos) do t[#t+1] = h.text .. '/' .. tostring(h.arrow) end return table.concat(t, ';')"),
                         "A Northern Cardinal visits the bird bath/true;A rare Eastern Bluebird visits the bird bath/nil")
        self.assertEqual(self.run_lua("return tostring(ui[first]) .. ':' .. emitter.stopped[1]"), "nil:1", "a repeat visit replaces the old one and its song")

    def test_hidden_bath_draws_nothing(self):
        self.run_lua('''
            addSquare(105, 100, 0, {bath("Bird Bath")}).seen = false
            online = {makePlayer("me", 100.5, 100.5)}
            visit = BackyardBirds.showVisit(online[1], {x=105, y=100, z=0, species="cardinal", count=1, minutes=30, boosted=false})
            visit:update(); now = 2000; visit:update()
            visit:prerender(); visit:render()
        ''')
        self.assertEqual(self.run_lua("return states(visit) .. ':' .. #visit.drawn"), "present:0")

    def test_sneak_close_walk_and_run_scare_them_off(self):
        scared = self.run_lua('''
            return function(gait, distance)
                squares = {}
                addSquare(105, 100, 0, {bath("Bird Bath")})
                online = {makePlayer("me", 95.5, 100.5)}
                local visit = BackyardBirds.showVisit(online[1], {x=105, y=100, z=0, species="cardinal", count=3, minutes=30, boosted=false})
                visit:update()
                online[1].x, online[1].gait = 105.5 - distance, gait
                visit:update()
                return states(visit)
            end
        ''')
        self.assertEqual(scared("walk", 3.5), "waiting,waiting,arriving")
        self.assertEqual(scared("walk", 2.9), "gone,gone,leaving")
        self.assertEqual(scared("sneak", 2), "waiting,waiting,arriving")
        self.assertEqual(scared("sneak", 1.4), "gone,gone,leaving")
        self.assertEqual(scared("run", 4.5), "gone,gone,leaving")
        self.assertEqual(scared("sprint", 4.5), "gone,gone,leaving")

    def test_a_zombie_scares_them_off(self):
        self.run_lua('''
            addSquare(105, 100, 0, {bath("Bird Bath")})
            addSquare(108, 100, 0)
            online = {makePlayer("me", 100.5, 100.5)}
            visit = BackyardBirds.showVisit(online[1], {x=105, y=100, z=0, species="cardinal", count=1, minutes=30, boosted=false})
            visit:update()
            squares["108,100,0"].moving = {{kind="IsoZombie"}}
            now = 2000; visit:update()
        ''')
        self.assertEqual(self.run_lua("return states(visit) .. ':' .. emitter.stopped[1]"), "leaving:1")

    def test_server_message_reaches_the_local_player(self):
        self.run_lua('''
            addSquare(105, 100, 0, {bath("Bird Bath")})
            online = {makePlayer("me", 100.5, 100.5)}
            for _, handler in ipairs(Events.OnServerCommand.handlers) do
                handler("BackyardBirds", "visit", {x=105, y=100, z=0, species="chickadee", count=1, minutes=30, boosted=false})
                handler("OtherMod", "visit", {})
            end
        ''')
        self.assertEqual(self.run_lua("return BackyardBirds.visits['105,100,0#0'].args.species"), "chickadee")


if __name__ == "__main__":
    unittest.main()

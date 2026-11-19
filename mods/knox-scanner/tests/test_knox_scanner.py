"""Portable boundaries for the event feed. No native game check has run yet."""
from pathlib import Path
import json
import unittest
from lupa.lua51 import LuaRuntime

SOURCE = Path(__file__).resolve().parents[1] / "KnoxScanner/42/media/lua/client/KnoxScanner.lua"
FIXTURE = r'''
written = {}
function getFileWriter(name, create, append)
    assert(name == "KnoxScanner.jsonl" and create and append)
    return {write=function(_, text) written[#written+1] = text end, close=function() end}
end
opts = {}
local function option(id, value)
    opts[id] = value
    return {getValue=function() return opts[id] end}
end
PZAPI = {ModOptions={create=function(_, id, name)
    local made = {}
    return {addDescription=function() end,
        addTickBox=function(_, id, name, value) made[id] = option(id, value); return made[id] end,
        addKeyBind=function(_, id, name, key) made[id] = option(id, key); return made[id] end,
        getOption=function(_, id) return made[id] end}
end}}
handlers = {}
Events = setmetatable({}, {__index=function(t, k)
    local e = {Add=function(fn) handlers[k] = fn end}
    rawset(t, k, e); return e
end})
clock = {age=24*11+14, hour=14, nights=11, heliDay=-1, heliStart=9, heliEnd=19}
function getGameTime() return {
    getWorldAgeHours=function() return clock.age end, getHour=function() return clock.hour end,
    getTimeOfDay=function() return clock.hour end, getNightsSurvived=function() return clock.nights end,
    getHelicopterDay1=function() return clock.heliDay end,
    getHelicopterStartHour=function() return clock.heliStart end, getHelicopterEndHour=function() return clock.heliEnd end} end
power = true
function getWorld() return {isHydroPowerOn=function() return power end} end
zombies = {}
function getCell() return {getZombieList=function()
    return {size=function() return #zombies end, get=function(_, i) return zombies[i+1] end} end} end
function zombieAt(x, y) return {getX=function() return x end, getY=function() return y end} end
me = {x=9000, y=9000, dead=false, room=nil, bites=0, health=100, kills=0, hours=24*11, localPlayer=true}
function me:getX() return self.x end
function me:getY() return self.y end
function me:isDead() return self.dead end
function me:isLocalPlayer() return self.localPlayer end
function me:getZombieKills() return self.kills end
function me:getHoursSurvived() return self.hours end
function me:getCurrentSquare() return {getRoom=function() return me.room and {getName=function() return me.room end} end} end
function me:getBodyDamage() return {getNumPartsBitten=function() return me.bites end,
    getOverallBodyHealth=function() return me.health end} end
function getSpecificPlayer(i) return i == 0 and me or nil end
'''


class Scanner(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime()
        self.lua.execute(FIXTURE)
        self.lua.execute(SOURCE.read_text())
        self.g = self.lua.globals()

    def poll(self):
        self.g.handlers.EveryOneMinute()

    def lines(self):
        return [json.loads(line)["content"] for line in self.g.written.values()]

    def test_first_poll_reports_nothing(self):
        self.g.me.x, self.g.me.y, self.g.me.bites = 10800, 9900, 1
        self.poll()
        self.assertEqual(self.lines(), [])

    def test_town_arrival_is_one_discord_ready_line(self):
        self.poll()
        self.g.me.x, self.g.me.y = 10800, 9900
        self.poll()
        self.poll()
        raw = list(self.g.written.values())
        self.assertEqual(len(raw), 1)
        self.assertTrue(raw[0].endswith("\n") and raw[0].isascii())
        self.assertEqual(json.loads(raw[0]), {"username": "Knox Scanner",
            "content": "\U0001F4E1 town | Muldraugh | day 12, 14:00 | A survivor reached Muldraugh."})

    def test_leaving_and_returning_to_the_same_town_is_silent(self):
        self.poll()
        for x in (10800, 9000, 10800):
            self.g.me.x, self.g.me.y = x, 9900
            self.poll()
        self.assertEqual(len(self.lines()), 1)

    def test_a_toggle_and_the_master_switch_silence_events(self):
        self.poll()
        self.g.opts.bitten = False
        self.g.me.bites = 1
        self.poll()
        self.g.opts.enabled = False
        self.g.power = False
        self.poll()
        self.assertEqual(self.lines(), [])

    def test_bite_injury_kills_power_and_landmark(self):
        self.poll()
        me = self.g.me
        me.bites, me.health, me.kills, me.room = 1, 40, 205, "policestorage"
        self.g.power = False
        self.poll()
        self.poll()
        kinds = [line.split(" | ")[0].split(" ")[1] for line in self.lines()]
        self.assertEqual(kinds, ["landmark", "bitten", "hurt", "kills", "power"])
        self.assertIn("killed 200 zombies", self.lines()[3])
        self.assertTrue(all(" | the countryside | " in line for line in self.lines()))

    def test_injury_needs_recovery_before_it_reports_again(self):
        self.poll()
        for health in (40, 60, 40, 80, 40):
            self.g.me.health = health
            self.poll()
        self.assertEqual(len(self.lines()), 2)

    def test_helicopter_reports_once_inside_its_window(self):
        self.poll()
        self.g.clock.heliDay = 11
        self.poll()
        self.poll()
        self.g.clock.hour = 20
        self.poll()
        self.assertEqual(len(self.lines()), 1)
        self.assertIn("helicopter", self.lines()[0])

    def test_horde_counts_nearby_zombies_and_cools_down(self):
        self.poll()
        self.lua.execute("for i = 1, 39 do zombies[i] = zombieAt(9005, 9005) end zombies[40] = zombieAt(9100, 9000)")
        self.poll()
        self.assertEqual(self.lines(), [])
        self.lua.execute("zombies[40] = zombieAt(9020, 8980)")
        self.poll()
        self.poll()
        self.assertEqual(len(self.lines()), 1)
        self.g.clock.age += 6
        self.poll()
        self.assertEqual(len(self.lines()), 2)

    def test_death_reports_the_local_player_only_and_resets_the_baseline(self):
        self.poll()
        self.g.me.localPlayer = False
        self.g.handlers.OnPlayerDeath(self.g.me)
        self.assertEqual(self.lines(), [])
        self.g.me.localPlayer, self.g.me.kills = True, 37
        self.g.handlers.OnPlayerDeath(self.g.me)
        self.assertIn("died after 11 days and 37 zombie kills", self.lines()[0])
        self.g.me.x, self.g.me.y = 10800, 9900
        self.poll()
        self.assertEqual(len(self.lines()), 1)

    def test_dead_player_is_not_polled(self):
        self.poll()
        self.g.me.dead, self.g.me.bites = True, 3
        self.poll()
        self.assertEqual(self.lines(), [])

    def test_storms_days_and_request_key(self):
        period = self.lua.eval("function(kind) return {isBlizzard=function() return kind == 'b' end,"
                               "isTropicalStorm=function() return false end, isThunderStorm=function() return kind == 't' end} end")
        self.g.handlers.OnWeatherPeriodStart(period("rain"))
        self.g.handlers.OnWeatherPeriodStart(period("t"))
        self.g.handlers.EveryDays()
        self.g.me.hours = 24 * 14
        self.g.handlers.EveryDays()
        self.g.handlers.OnKeyPressed(0)
        self.g.handlers.OnKeyPressed(33)
        self.g.opts.requestKey = 33
        self.g.handlers.OnKeyPressed(33)
        self.assertEqual([line.split(" | ")[3] for line in self.lines()], [
            "A thunderstorm is rolling in.", "A survivor has lasted 14 days.", "A survivor is asking for a broadcast."])


if __name__ == "__main__":
    unittest.main()

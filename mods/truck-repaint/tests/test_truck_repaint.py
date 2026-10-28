"""Portable behaviour tests with Lua, separate from the native engine gate."""
from pathlib import Path
import unittest
from lupa import LuaRuntime

ROOT = Path(__file__).resolve().parents[1] / "TruckRepaint/42/media/lua"

FIXTURE = r'''
Events = setmetatable({}, {__index=function(t,k)
    local handlers = {}
    local e = {Add=function(fn) handlers[#handlers+1]=fn end, handlers=handlers}
    rawset(t,k,e); return e
end})
server = false
function isServer() return server end
sent = {}
function sendServerCommand(module, command, args) sent[#sent+1] = {module=module, command=command, args=args} end
ItemTag = {PAINTBRUSH="base:paintbrush"}
Metabolics = {LightWork=1}
CharacterActionAnims = {Paint="Paint"}
ISBaseTimedAction = {}
ISBaseTimedAction.__index = ISBaseTimedAction
function ISBaseTimedAction:derive(name) local o = setmetatable({Type=name}, self); o.__index = o; return o end
function ISBaseTimedAction.new(class, character) return setmetatable({character=character}, class) end
package.preload["TimedActions/ISBaseTimedAction"] = function() end
package.preload["Vehicles/ISUI/ISVehicleMenu"] = function() end
function array(items) return {size=function() return #items end, get=function(_,i) return items[i+1] end} end
function bucket(kind, uses)
    local item = {kind=kind, uses=uses}
    function item:getCurrentUses() return self.uses end
    function item:UseAndSync() assert(self.uses > 0, "used an empty bucket"); self.uses = self.uses - 1 end
    return item
end
function makePlayer(items, brush)
    local p = {items=items, brush=brush}
    local inv = {}
    function inv:getAllTypeRecurse(kind)
        local found = {}
        for _, item in ipairs(p.items) do if item.kind == kind then found[#found+1] = item end end
        return array(found)
    end
    function inv:getFirstTagRecurse(tag) assert(tag == ItemTag.PAINTBRUSH); return p.brush and {} or nil end
    function p:getInventory() return inv end
    function p:getX() return 0 end
    function p:getY() return 0 end
    function p:isTimedActionInstant() return false end
    return p
end
function makeVehicle(script, skin)
    local v = {script=script, skin=skin, id=42, updated=0, transmitted=0, removed=false, skins=8, near=true}
    function v:getSkinCount() return self.skins end
    function v:getAreaCenter(area)
        assert(area == "SeatFrontLeft")
        local x = v.near and 1.5 or 4
        return {getX=function() return x end, getY=function() return 0 end}
    end
    function v:getScript() return {getName=function() return v.script end} end
    function v:getSkinIndex() return self.skin end
    function v:setSkinIndex(i) self.skin = i end
    function v:updateSkin() self.updated = self.updated + 1 end
    function v:transmitSkinIndex() self.transmitted = self.transmitted + 1 end
    function v:getId() return self.id end
    function v:isRemovedFromWorld() return self.removed end
    function v:getSquare() return {} end
    return v
end
'''

MENU_FIXTURE = r'''
function getSpecificPlayer() return player end
function getItemNameFromFullType(t) return t end
ISVehicleMenu = {FillMenuOutsideVehicle=function() return "vanilla" end}
local function newMenu()
    local m = {options={}, subMenus={}}
    function m:addOption(name, target, fn, a, b)
        local o = {name=name, target=target, fn=fn, a=a, b=b}
        self.options[#self.options+1] = o
        return o
    end
    function m:addSubMenu(option, sub) option.subMenu = sub end
    return m
end
ISContextMenu = {getNew=function() return newMenu() end}
ISWorldObjectContextMenu = {addToolTip=function() return {setName=function(self, n) self.name = n end} end}
queued = {}
ISTimedActionQueue = {add=function(a) queued[#queued+1] = a end}
ISPathFindAction = {pathToVehicleArea=function(_, p, v, area) return {path=area, vehicle=v} end}
function openMenu(v) local c = newMenu(); local r = ISVehicleMenu.FillMenuOutsideVehicle(0, c, v, false); return c, r end
'''


class TruckRepaintTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(f"package.path = {repr(str(ROOT / 'shared/?.lua'))} .. ';' .. package.path")
        self.lua.execute(FIXTURE)
        self.lua.execute('require "TruckRepaint"')

    def check(self, code):
        self.lua.execute(code)

    def load_menu(self):
        self.lua.execute(MENU_FIXTURE)
        self.lua.execute((ROOT / "client/TruckRepaint_Menu.lua").read_text())

    def test_complete_spends_paint_across_buckets_and_repaints(self):
        self.check('''local red1, red2, white = bucket("PaintRed", 3), bucket("PaintRed", 10), bucket("PaintWhite", 10)
        player = makePlayer({red1, red2, white}, true); local v = makeVehicle("87fordF700box", 3)
        local action = ISRepaintTruck:new(player, v, 7)
        assert(action:isValid() and action.maxTime == TruckRepaint.DURATION)
        assert(action:complete())
        assert(red1.uses == 0 and red2.uses == 8 and white.uses == 5, "paint not spent exactly")
        assert(v.skin == 7 and v.updated == 1 and v.transmitted == 0 and #sent == 0)''')

    def test_server_complete_transmits_to_clients(self):
        self.check('''server = true; player = makePlayer({bucket("PaintBlack", 10)}, true); local v = makeVehicle("87fordF700swat", 3)
        assert(ISRepaintTruck:new(player, v, 0):complete())
        assert(v.skin == 0 and v.transmitted == 1 and v.updated == 0)
        assert(sent[1].module == "TruckRepaint" and sent[1].command == "updateSkin" and sent[1].args.vehicle == 42 and sent[1].args.index == 0)''')

    def test_server_complete_rechecks_everything(self):
        self.check('''server = true; local white = bucket("PaintWhite", 3); local v = makeVehicle("87fordF700box", 3)
        assert(ISRepaintTruck:new(makePlayer({white}, true), v, 5):complete() == false, "short paint completed")
        assert(white.uses == 3 and v.skin == 3 and #sent == 0, "failed repaint spent paint or changed the truck")
        v.near = false
        assert(ISRepaintTruck:new(makePlayer({bucket("PaintWhite", 10)}, true), v, 5):complete() == false, "remote repaint completed")
        assert(ISRepaintTruck:new(makePlayer({bucket("PaintWhite", 10)}, false), v, 5):complete() == false, "brushless repaint completed")
        assert(v.skin == 3 and v.transmitted == 0)''')

    def test_bus_camo_appends_once_and_loads_client_textures(self):
        self.check('''local scripts, loads = {}, {}
        for _, n in ipairs({"87fordB700school", "87fordB700prison"}) do
            local s = {skins={"base"}, name=n}
            function s:getSkinCount() return #self.skins end
            function s:Load(name, body) assert(name == self.name); table.insert(self.skins, body) end
            scripts["Base." .. n] = s
        end
        function getScriptManager() return {getVehicle=function(_, full) return scripts[full] end} end
        BaseVehicle = {LoadVehicleTextures=function(s) loads[#loads+1] = s end}
        assert(#Events.OnInitWorld.handlers == 1)
        Events.OnInitWorld.handlers[1]()
        TruckRepaint.addBusCamo()
        local school = scripts["Base.87fordB700school"]
        assert(school:getSkinCount() == 2 and school.skins[2]:find("Vehicles_87fordB700military_Shell_redneckCamo", 1, true))
        assert(#loads == 2, "textures must load once per appended bus on the client")
        server = true; scripts["Base.87fordB700prison"].skins = {"base"}; TruckRepaint.addBusCamo()
        assert(#loads == 2, "server must not load textures")''')

    def test_menu_offers_camo_on_school_bus_and_oshkosh_colors(self):
        self.load_menu()
        self.check('''player = makePlayer({}, true)
        local bus = makeVehicle("87fordB700school", 0); bus.skins = 2
        local sub = openMenu(bus).options[1].subMenu.options
        assert(#sub == 1 and sub[1].name == "Redneck Camo")
        local fire = makeVehicle("86oshkoshKYFD", 0); fire.skins = 3
        local names = {}
        for i, o in ipairs(openMenu(fire).options[1].subMenu.options) do names[i] = o.name end
        assert(table.concat(names, ",") == "Yellow,Red and White", table.concat(names, ","))''')

    def test_invalid_without_brush_paint_or_known_skin(self):
        self.check('''local v = makeVehicle("87fordF700box", 3)
        assert(not ISRepaintTruck:new(makePlayer({bucket("PaintWhite", 10)}, false), v, 5):isValid(), "no brush")
        assert(not ISRepaintTruck:new(makePlayer({bucket("PaintWhite", 9)}, true), v, 5):isValid(), "short paint")
        assert(not ISRepaintTruck:new(makePlayer({bucket("PaintWhite", 10)}, true), v, 3):isValid(), "livery target")
        assert(ISRepaintTruck:new(makePlayer({bucket("PaintWhite", 4), bucket("PaintWhite", 6)}, true), v, 5):isValid())
        v.near = false
        assert(not ISRepaintTruck:new(makePlayer({bucket("PaintWhite", 10)}, true), v, 5):isValid(), "painter left the door")
        v.near = true; v.skins = 5
        assert(not ISRepaintTruck:new(makePlayer({bucket("PaintWhite", 10)}, true), v, 5):isValid(), "KI5 dropped the skin")
        v.skins = 8; v.removed = true
        assert(not ISRepaintTruck:new(makePlayer({bucket("PaintWhite", 10)}, true), v, 5):isValid(), "removed truck")''')

    def test_menu_offers_one_entry_with_other_plain_skins(self):
        self.load_menu()
        self.check('''player = makePlayer({bucket("PaintWhite", 10)}, true)
        local c, r = openMenu(makeVehicle("87fordF700box", 5))
        assert(r == "vanilla" and #c.options == 1 and c.options[1].name == "Repaint Truck")
        local sub = c.options[1].subMenu.options
        local names = {}
        for i, o in ipairs(sub) do names[i] = o.name end
        assert(table.concat(names, ",") == "Blue and White,Red and Black,Yellow,Red and White", table.concat(names, ","))
        for _, o in ipairs(sub) do assert(o.notAvailable, o.name .. " should need more paint") end
        sub[1].fn(sub[1].target, sub[1].a, sub[1].b)
        assert(queued[1].path == "SeatFrontLeft" and queued[1].vehicle == sub[1].a)
        assert(getmetatable(queued[2]) == ISRepaintTruck and queued[2].skinIndex == 0 and queued[2].vehicle == sub[1].a)''')

    def test_menu_marks_affordable_skin_available(self):
        self.load_menu()
        self.check('''player = makePlayer({bucket("PaintWhite", 10)}, true)
        local sub = openMenu(makeVehicle("87fordF700box", 3)).options[1].subMenu.options
        for _, o in ipairs(sub) do assert(o.notAvailable == (o.name ~= "White"), o.name) end''')

    def test_menu_skips_other_vehicles_and_finished_trucks(self):
        self.load_menu()
        self.check('''player = makePlayer({}, true)
        assert(#openMenu(makeVehicle("PickUpTruck", 0)).options == 0)
        assert(#openMenu(makeVehicle("87fordF700swat", 0)).options == 0)
        assert(#openMenu(makeVehicle("87fordF700swat", 2)).options == 1)
        local shrunk = makeVehicle("87fordF700box", 3); shrunk.skins = 6
        local names = {}
        for i, o in ipairs(openMenu(shrunk).options[1].subMenu.options) do names[i] = o.name end
        assert(table.concat(names, ",") == "Blue and White,Red and Black,White", table.concat(names, ","))''')

    def test_server_command_rebuilds_client_model(self):
        self.load_menu()
        self.check('''local v = makeVehicle("87fordF700box", 3)
        function getVehicleById(id) if id == 42 then return v end end
        local handler = Events.OnServerCommand.handlers[1]
        handler("Other", "updateSkin", {vehicle=42, index=5}); assert(v.skin == 3)
        handler("TruckRepaint", "updateSkin", {vehicle=42, index=5}); assert(v.skin == 5 and v.updated == 1)
        handler("TruckRepaint", "updateSkin", {vehicle=7, index=5})''')


if __name__ == "__main__":
    unittest.main()

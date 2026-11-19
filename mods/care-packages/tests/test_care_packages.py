"""Portable boundaries for native parcel mutations and timed actions."""
from pathlib import Path
import unittest

from lupa.lua51 import LuaError, LuaRuntime


LUA = Path(__file__).resolve().parents[1] / "CarePackages/42/media/lua/shared"
FIXTURE = r"""
role = "local"
network = 0
redraw = 0
function isServer() return role == "server" end
function isClient() return role == "client" end
function syncItemModData(p, item)
    assert(p:getInventory():contains(item))
    network = network + 1
end
function sendServerCommand(p, module, action)
    assert(module == "ui" and action == "dirtyUI")
    network = network + 1
end
ISInventoryPage = { dirtyUI = function() redraw = redraw + 1 end }
function makeContainer(item, empty)
    local items = { isEmpty = function() return empty end }
    local container = { item = item }
    function container:getContainingItem() return self.item end
    function container:getItems() return items end
    function container:contains(item) return self.held == item end
    return container
end
function makeItem(kind, parent, empty)
    local item = { data = {}, parent = parent }
    local inventory = makeContainer(item, empty)
    function item:getModData() return self.data end
    function item:getContainer() return self.parent end
    function item:getInventory() return inventory end
    function item:getFullType() return kind end
    return item
end
pack = makeContainer()
strangerPack = makeContainer()
player = { getInventory = function() return pack end, isTimedActionInstant = function() return false end }
stranger = { getInventory = function() return strangerPack end }
parcel = makeItem("CarePackages.Parcel", pack, false)
pack.held = parcel
contents = parcel:getInventory()
nested = makeItem("Base.Bag_Schoolbag", contents, false):getInventory()
function seal() return ISCareParcelAction:new(player, parcel, "seal", CarePackages.revision(parcel), "Beth", "Alice", "For you.") end
function open() return ISCareParcelAction:new(player, parcel, "open", CarePackages.revision(parcel)) end
package.preload["CarePackages"] = function() return CarePackages end
package.preload["TimedActions/ISBaseTimedAction"] = function() end
ISBaseTimedAction = {
    derive = function() return {} end,
    new = function(class, character) return setmetatable({ character = character }, { __index = class }) end,
    stop = function() stopped = true end,
}
function assertSeal()
    assert(seal():complete() and CarePackages.isSealed(parcel), "seal had no effect")
end
"""


class CarePackagesTest(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime()
        self.lua.execute(FIXTURE)
        self.lua.execute((LUA / "CarePackages.lua").read_text())
        self.lua.execute((LUA / "TimedActions/ISCareParcelAction.lua").read_text())

    def test_metadata_limits(self):
        self.lua.execute(r"""
            local C = CarePackages
            local label = assert(C.validate("  Beth ", "Éloïse", "  Yes.\r\nAgain.  "))
            assert(label.toName == "Beth" and label.fromName == "Éloïse" and label.note == "Yes.\nAgain.")
            assert(C.validate("Beth", "Alice", ""))
            assert(C.validate(string.rep("x",48), "Alice", string.rep("x",500)))
            assert(not C.validate("", "Alice", "note"))
            assert(not C.validate("Beth", " ", "note"))
            assert(not C.validate("Beth\nother", "Alice", "note"))
            assert(not C.validate("Beth", "Alice", "a\000b"))
            assert(not C.validate("Beth", "Alice", {"not text"}))
            assert(not C.validate(string.rep("x",49), "Alice", "note"))
            assert(not C.validate("Beth", "Alice", string.rep("x",501)))
        """)

    def test_seal_and_open_keep_container_and_other_mod_data_intact(self):
        self.lua.execute(r"""
            local C = CarePackages
            parcel:getModData().other = { value = 5 }
            assertSeal()
            assert(C.insideSeal(contents) and C.insideSeal(nested) and not C.insideSeal(pack))
            assert(not C.acceptItem(contents) and not C.acceptItem(nested))
            assert(open():complete() and not C.isSealed(parcel))
            assert(not C.insideSeal(nested) and C.acceptItem(contents))
            assert(C.label(parcel).note == "For you." and parcel:getModData().other.value == 5)
            assert(parcel:getInventory() == contents and pack:contains(parcel) and redraw == 2 and network == 0)
        """)

    def test_empty_nested_or_other_player_cannot_change_seal(self):
        self.lua.execute(r"""
            local C = CarePackages
            local empty = makeItem("CarePackages.Parcel", pack, true)
            pack.held = empty
            assert(not C.canHandle(player, empty, "seal"))
            pack.held = parcel
            assert(not C.canHandle(stranger, parcel, "seal"))
            assert(not C.canHandle(player, parcel, "drop"))
            assert(not C.canHandle(player, parcel, "open"))
            parcel.parent = nested
            assert(not C.canHandle(player, parcel, "seal") and not C.label(parcel))
        """)

    def test_stale_and_repeated_operations_are_no_ops(self):
        self.lua.execute(r"""
            role = "server"
            local C = CarePackages
            local firstSeal, staleSeal = seal(), seal()
            assert(firstSeal:complete() and not firstSeal:complete())
            local firstOpen, staleOpen = open(), open()
            assert(firstOpen:complete() and not firstOpen:complete())
            assert(not staleSeal:isValid() and not staleSeal:complete())
            assert(seal():complete() and not staleOpen:complete())
            assert(C.revision(parcel) == 3 and C.isSealed(parcel) and network == 6)
        """)

    def test_cancel_and_invalid_input_do_not_sync(self):
        self.lua.execute(r"""
            role = "server"
            local action = seal()
            action:stop()
            assert(stopped and action.stopOnRun and action.stopOnWalk)
            action.fromName = ""
            assert(not action:complete() and not CarePackages.label(parcel) and network == 0)
        """)

    def test_negative_control_detects_noop_seal(self):
        self.lua.execute("CarePackages.change = function() return true end")
        with self.assertRaisesRegex(LuaError, "seal had no effect"):
            self.lua.execute("assertSeal()")


if __name__ == "__main__":
    unittest.main()

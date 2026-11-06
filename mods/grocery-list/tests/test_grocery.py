"""Portable boundaries. Native probes separately verify these engine interfaces."""
from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = '''
client=false; server=true; now=100; persisted={}; notices={}; synced={}; itemSyncs=0; minute=nil
function isClient() return client end
function isServer() return server end
function getGameTime() return {getWorldAgeHours=function() return now end} end
function getText(k,a) if a then return k..'|'..a end return k end
ModData={getOrCreate=function() return persisted end}
CharacterStat={BOREDOM='b',UNHAPPINESS='u'}
SyncPlayerStatsPacket={getBitMaskForStat=function(s) return s end}
function syncPlayerStats(p,s) synced[#synced+1]=s end
function syncItemFields(p,item) itemSyncs=itemSyncs+1 end
function sendServerCommand(p,m,c,a) notices[#notices+1]=p.name..':'..c..(a.text and (':'..a.text) or '') end
HaloTextHelper={addGoodText=function(p,t) notices[#notices+1]=p.name..':'..t end}
Events={OnServerCommand={Add=function(f) command=f end},EveryOneMinute={Add=function(f) minute=f end}}
function jlist(t) return {size=function() return #t end,get=function(_,i) return t[i+1] end,isEmpty=function() return #t==0 end} end
online={}
function getOnlinePlayers() return jlist(online) end
function getNumActivePlayers() return #online end
function getSpecificPlayer(i) return online[i+1] end
function item(name,kind) return {name=name,kind=kind or 'Base.Thing',
 getFullType=function(s) return s.kind end,getDisplayName=function(s) return s.name end} end
function newlist(text)
 local l=item('Grocery List','SharedGroceryList.GroceryList'); l.page=text; l.mod={}
 function l:seePage(i) return self.page end
 function l:addPage(i,t) self.page=t end
 function l:getModData() return self.mod end
 return l
end
function player(name,slot)
 local p={name=name,slot=slot or 0,items={},dead=false,values={b=50,u=50}}
 function p:getUsername() return self.name end
 function p:getPlayerNum() return self.slot end
 function p:isDead() return self.dead end
 function p:getDescriptor() return {getForename=function() return p.name end} end
 function p:getStats() return {remove=function(_,k,n) p.values[k]=math.max(0,p.values[k]-n) end} end
 function p:getInventory() return {
  getAllTypeRecurse=function(_,t) local r={} for _,i in ipairs(p.items) do if i.kind==t then r[#r+1]=i end end return jlist(r) end,
  getAllEvalRecurse=function(_,f) for _,i in ipairs(p.items) do f(i) end return jlist({}) end} end
 function p:give(i) self.items[#self.items+1]=i; return i end
 function p:take(i) for n,v in ipairs(self.items) do if v==i then table.remove(self.items,n) return i end end end
 online[#online+1]=p
 return p
end
a=player('Alice'); b=player('Beth',1)
function count(prefix) local n=0 for _,v in ipairs(notices) do if v:sub(1,#prefix)==prefix then n=n+1 end end return n end
'''


class Grocery(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime()
        self.lua.execute(FIXTURE)
        self.load_mod()

    def load_mod(self):
        self.lua.execute((ROOT / 'SharedGroceryList/42/media/lua/shared/SharedGroceryList.lua').read_text())

    def check(self, code):
        self.lua.execute(code)

    def test_parse_strips_bullets_quantities_and_marks(self):
        self.check('''local lines=SharedGroceryList.parse("- beans\\n2 x Apples\\n[x] bread\\n\\nab\\n~ note")
        assert(lines[1].key=="beans" and lines[2].key=="apples" and lines[3].key=="bread")
        assert(lines[4].key==nil and lines[5].key==nil and lines[6].key==nil)''')

    def test_plural_and_case_match_display_names(self):
        self.check('''local names="can of beans\\napple\\nbattery"
        assert(SharedGroceryList.matches("beans",names) and SharedGroceryList.matches("apples",names))
        assert(SharedGroceryList.matches("batteries",names) and not SharedGroceryList.matches("rice",names))''')

    def test_carried_items_cross_off_lines_and_mark_the_page(self):
        self.check('''local l=a:give(newlist("beans\\nApples\\nrice")); a:give(item("Can of Beans")); a:give(item("Apple"))
        minute()
        assert(l.page=="[x] beans\\n[x] Apples\\nrice", l.page)
        assert(count("Alice:got")==2 and itemSyncs==1 and not l.mod.done and a.values.b==50)''')

    def test_list_in_a_box_or_another_player_does_not_check(self):
        self.check('''local l=newlist("beans\\napples\\nrice"); b:give(item("Beans")); minute()
        assert(l.page=="beans\\napples\\nrice" and #notices==0)''')

    def test_finishing_the_list_rewards_the_shopper_once(self):
        self.check('''local l=a:give(newlist("beans\\napples\\nrice")); a:give(item("Beans")); a:give(item("Apple")); a:give(item("Rice"))
        minute(); minute()
        assert(l.mod.done and count("Alice:done")==1 and a.values.b==40 and a.values.u==45, a.values.b)
        assert(itemSyncs==1, "Finished list resynced every minute: "..itemSyncs)''')

    def test_short_lists_never_finish(self):
        self.check('''local l=a:give(newlist("beans\\napples")); a:give(item("Beans")); a:give(item("Apple"))
        minute(); assert(not l.mod.done and count("Alice:done")==0)''')

    def test_items_not_carried_stay_open(self):
        self.check('''local l=a:give(newlist("beans\\napples\\nrice")); a:give(item("Beans")); minute()
        assert(not l.mod.done and l.page=="[x] beans\\napples\\nrice")''')

    def test_crossed_off_items_stay_crossed_after_use(self):
        self.check('''local l=a:give(newlist("beans\\napples\\nrice")); local beans=a:give(item("Beans")); minute()
        a:take(beans); a:give(item("Apple")); a:give(item("Rice")); minute()
        assert(l.mod.done and count("Alice:got")==3)''')

    def test_lists_themselves_do_not_satisfy_lines(self):
        self.check('''local l=a:give(newlist("grocery\\nlist\\nnotepad")); a:give(newlist("")); minute()
        assert(count("Alice:got")==0)''')

    def test_shopper_brings_list_home_and_both_are_thanked(self):
        self.check('''local l=a:give(newlist("beans\\napples\\nrice")); minute()
        assert(l.mod.author=="Alice")
        a:take(l); b:give(l); b:give(item("Beans")); b:give(item("Apple")); b:give(item("Rice")); minute()
        assert(l.mod.done and l.mod.shopper=="Beth" and count("Beth:done")==1)
        minute(); assert(count("Beth:delivered")==0, "Delivered before hand-back")
        b:take(l); a:give(l); minute()
        assert(count("Alice:thanks:Beth")==1 and count("Beth:delivered")==1)
        assert(a.values.u==40 and b.values.u==35 and b.values.b==40, a.values.u..","..b.values.u)
        assert(l.page:sub(-9)=="~ Beth <3", l.page)
        minute(); assert(count("Alice:thanks")==1, "Delivered twice")''')

    def test_own_list_is_not_a_delivery(self):
        self.check('''local l=a:give(newlist("beans\\napples\\nrice")); a:give(item("Beans")); a:give(item("Apple")); a:give(item("Rice"))
        minute(); minute(); assert(l.mod.done and not l.mod.delivered and count("Alice:thanks")==0)''')

    def test_offline_shopper_misses_delivery_bonus_only(self):
        self.check('''local l=a:give(newlist("beans\\napples\\nrice")); minute()
        a:take(l); b:give(l); b:give(item("Beans")); b:give(item("Apple")); b:give(item("Rice")); minute()
        b:take(l); table.remove(online,2); a:give(l); minute()
        assert(count("Alice:thanks")==1 and count("Beth:delivered")==0 and l.mod.delivered)''')

    def test_cooldown_keeps_notice_but_skips_stats(self):
        self.check('''for i=1,2 do
          local l=a:give(newlist("beans\\napples\\nrice")); a:give(item("Beans")); a:give(item("Apple")); a:give(item("Rice")); minute()
        end
        assert(count("Alice:done")==2 and a.values.b==40)
        now=124; local l=a:give(newlist("milk\\neggs\\nflour")); a:give(item("Milk")); a:give(item("Eggs")); a:give(item("Flour")); minute()
        assert(a.values.b==30)''')

    def test_reload_keeps_cooldown(self):
        self.check('''local l=a:give(newlist("beans\\napples\\nrice")); a:give(item("Beans")); a:give(item("Apple")); a:give(item("Rice")); minute()''')
        self.load_mod()
        self.check('''local l=a:give(newlist("milk\\neggs\\nflour")); a:give(item("Milk")); a:give(item("Eggs")); a:give(item("Flour")); minute()
        assert(a.values.b==40)''')

    def test_reedited_page_is_marked_again_without_new_notices(self):
        self.check('''local l=a:give(newlist("beans\\napples\\nrice")); a:give(item("Beans")); minute()
        l.page="beans\\napples\\nrice\\nmilk"; minute()
        assert(l.page=="[x] beans\\napples\\nrice\\nmilk" and count("Alice:got")==1)''')

    def test_dead_holder_is_skipped(self):
        self.check('''local l=a:give(newlist("beans\\napples\\nrice")); a:give(item("Beans")); a.dead=true; minute()
        assert(#notices==0)''')

    def test_split_screen_slots_are_separate_people(self):
        self.check('''server=false''')
        self.load_mod()
        self.check('''local l=a:give(newlist("beans\\napples\\nrice")); minute()
        a:take(l); b:give(l); b:give(item("Beans")); b:give(item("Apple")); b:give(item("Rice")); minute()
        b:take(l); a:give(l); minute()
        assert(l.mod.author=="local:0" and l.mod.shopper=="local:1")
        assert(count("Alice:IGUI_SharedGroceryList_thanks|Beth")==1 and itemSyncs==0 and #synced==0)''')

    def test_client_has_no_authority(self):
        self.check('client=true; server=false; minute=nil')
        self.load_mod()
        self.check('''assert(minute==nil)
        command("SharedGroceryList","done",nil); command("SharedGroceryList","got",{text="beans"})
        command("SharedGroceryList","forged",{}); command("Other","done",{})
        assert(#notices==2 and notices[2]=="Alice:IGUI_SharedGroceryList_got|beans" and a.values.b==50)''')


if __name__ == '__main__':
    unittest.main()

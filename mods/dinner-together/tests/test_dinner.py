"""Portable boundaries. Native probes separately verify these engine interfaces."""
from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = '''
client=false; server=true; now=100; persisted={}; notices={}; synced={}; clear=true
function isClient() return client end
function isServer() return server end
function getGameTime() return {getWorldAgeHours=function() return now end} end
function getCell() return {} end
function getSpecificPlayer() return a end
function getOnlinePlayers()
 local players={a,b,c}
 return {size=function() return #players end,get=function(_,i) return players[i+1] end}
end
ModData={getOrCreate=function() return persisted end}
CharacterStat={HUNGER='h',BOREDOM='b',UNHAPPINESS='u'}
SyncPlayerStatsPacket={getBitMaskForStat=function(s) return s end}
function syncPlayerStats(p,s) synced[#synced+1]=s end
function sendServerCommand(p,m,c,a) notices[#notices+1]=p.name end
function getText(k) return k end
HaloTextHelper={addGoodText=function(p,t) notices[#notices+1]=p.name end}
Events={OnServerCommand={Add=function(f) command=f end}}
LosUtil={lineClear=function() return clear and 'Clear' or 'Blocked' end}
function instanceof(o,t) return o.kind==t end
package.preload['TimedActions/ISEatFoodAction']=function() end
function player(name,x,y,z)
 local p={name=name,x=x or 0,y=y or 0,z=z or 0,dead=false,values={h=0.8,b=50,u=50}}
 function p:getX() return self.x end
 function p:getY() return self.y end
 function p:getZ() return self.z end
 function p:isDead() return self.dead end
 function p:getUsername() return self.name end
 function p:getPlayerNum() return self.slot or 0 end
 function p:getStats() return {get=function(_,k) return p.values[k] end,
 remove=function(_,k,n) p.values[k]=math.max(0,p.values[k]-n) end} end
 function p:Eat(food,portion) self.values.h=self.values.h-food.amount*portion end
 return p
end
ISEatFoodAction={complete=function(self) self.character:Eat(self.item,self.percentage); return true end}
function eat(p,n)
 local f={kind='Food',amount=n or 0.1}
 return ISEatFoodAction.complete({character=p,item=f,percentage=1})
end
a=player('Alice'); b=player('Beth',2,0,0)
'''


class Dinner(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime()
        self.lua.execute(FIXTURE)
        self.load_mod()

    def load_mod(self):
        self.lua.execute((ROOT / 'DinnerTogether/42/media/lua/shared/DinnerTogether.lua').read_text())

    def check(self, code):
        self.lua.execute(code)

    def test_solitary_meal_has_no_reward(self):
        self.check('assert(eat(a)); assert(a.values.b==50 and #notices==0)')

    def test_sequential_nearby_meals_reward_both(self):
        self.check('eat(a); now=now+0.05; eat(b); assert(a.values.b==45 and b.values.u==47); assert(#notices==2 and #synced==4)')

    def test_tiny_bites_do_not_qualify(self):
        self.check('eat(a,0.001); eat(b); assert(#notices==0)')

    def test_distant_floor_wall_and_expired_meals_do_not_pair(self):
        for change in ('b.x=5', 'b.z=1', 'clear=false', 'now=101'):
            with self.subTest(change=change):
                self.setUp()
                self.check(f'eat(a); {change}; eat(b); assert(#notices==0)')

    def test_moving_to_someone_after_eating_elsewhere_does_not_pair(self):
        self.check('a.x=20; eat(a); a.x=0; eat(b); assert(#notices==0)')

    def test_disconnected_partner_does_not_qualify(self):
        self.check("eat(a); a=player('Replacement',20); eat(b); assert(#notices==0)")

    def test_dead_partner_does_not_qualify(self):
        self.check('eat(a); a.dead=true; eat(b); assert(#notices==0)')

    def test_repeat_meals_and_reconnect_do_not_repeat_reward(self):
        self.check("eat(a); eat(b); a=player('Alice'); b=player('Beth',2); eat(a); eat(b); assert(#notices==2)")

    def test_reload_keeps_cooldown_then_next_day_can_reward(self):
        self.check('eat(a); eat(b)')
        self.check('ISEatFoodAction.complete=function(self) self.character:Eat(self.item,self.percentage); return true end')
        self.load_mod()
        self.check('eat(a); eat(b); assert(#notices==2); now=124; eat(a); eat(b); assert(#notices==4)')

    def test_player_on_cooldown_can_share_with_new_friend(self):
        self.check("eat(a); eat(b); c=player('Charlie',1); eat(c); assert(#notices==3 and c.values.b==45)")

    def test_local_split_screen_uses_distinct_slots(self):
        self.check('server=false; b.slot=1; eat(a); eat(b); assert(#notices==2 and #synced==0)')

    def test_client_cannot_award_stats(self):
        self.setUp()
        self.check('client=true; server=false')
        self.load_mod()
        self.check("eat(a); eat(b); assert(#notices==0); command('DinnerTogether','sharedMeal',{}); assert(#notices==1 and a.values.b==50)")


if __name__ == '__main__':
    unittest.main()

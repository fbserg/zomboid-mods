import se.krka.kahlua.vm.JavaFunction;
import zombie.CombatManager;
import zombie.Lua.LuaManager;
import zombie.characters.IsoPlayer;
import zombie.characters.IsoZombie;
import zombie.inventory.types.HandWeapon;

public class RangeWorld {
    public static void main(String[] args) throws Exception {
        Thread bridge = new Thread(() -> {
            try {
                Thread.sleep(30000);
                while (LuaManager.env == null) Thread.sleep(100);
                LuaManager.env.rawset("rangeWorldDamage", (JavaFunction) (frame, count) -> {
                    var player = (IsoPlayer) frame.get(0);
                    var weapon = (HandWeapon) frame.get(1);
                    var target = (IsoZombie) frame.get(2);
                    int chance = ((Number) frame.get(3)).intValue();
                    int damaging = 0;
                    var combat = CombatManager.getInstance();
                    for (int i = 0; i < 512; i++) {
                        var hit = combat.getHitData(player, weapon, target, chance);
                        if (hit == null) continue;
                        target.setHealth(100);
                        target.Hit(weapon, player, count > 4 ? weapon.getMinDamage() : 1f, hit.isIgnoreDamage(), 1f);
                        if (target.getHealth() < 100) damaging++;
                    }
                    frame.push((double) damaging);
                    return 1;
                });
                LuaManager.env.rawset("rangeWorldChance", (JavaFunction) (frame, count) -> {
                    var player = (IsoPlayer) frame.get(0);
                    var weapon = (HandWeapon) frame.get(1);
                    var target = (IsoZombie) frame.get(2);
                    float distance = ((Number) frame.get(3)).floatValue();
                    var combat = CombatManager.getInstance();
                    float chance = combat.calculateHitChanceData(player, weapon, target, distance).hitChance();
                    frame.push((double)chance);
                    return 1;
                });
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        });
        bridge.setDaemon(true);
        bridge.start();
        FarmEngineMain.main(args);
    }
}

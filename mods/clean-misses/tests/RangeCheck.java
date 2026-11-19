import java.lang.reflect.Field;
import java.nio.file.Path;
import sun.misc.Unsafe;
import zombie.CombatManager;
import zombie.SandboxOptions;
import zombie.ZomboidFileSystem;
import zombie.Lua.LuaEventManager;
import zombie.Lua.LuaManager;
import zombie.characters.IsoGameCharacter;
import zombie.characters.IsoPlayer;
import zombie.characters.IsoZombie;
import zombie.combat.CombatConfigKey;
import zombie.core.random.RandLua;
import zombie.core.random.RandStandard;
import zombie.inventory.types.HandWeapon;
import zombie.iso.Vector2;
import zombie.network.GameServer;
import zombie.sandbox.CustomSandboxOptions;

class RangeCheck {
    public static void main(String[] args) throws Exception {
        Path media = Path.of(args[0]);
        ZomboidFileSystem.instance.setCacheDir(args[1]);
        RandStandard.INSTANCE.init();
        RandLua.INSTANCE.init();
        ZomboidFileSystem.instance.init();
        LuaManager.init();
        var custom = CustomSandboxOptions.instance;
        var read = CustomSandboxOptions.class.getDeclaredMethod("readFile", String.class);
        read.setAccessible(true);
        check((boolean) read.invoke(custom, media.resolve("sandbox-options.txt").toString()), "option file");
        var options = SandboxOptions.instance;
        if (options.getOptionByName("CleanMisses.GentlerRangePenalty") == null) custom.initInstance(options);
        var option = (SandboxOptions.BooleanSandboxOption) options.getOptionByName("CleanMisses.GentlerRangePenalty");
        check(!option.getValue(), "default off");
        LuaManager.RunLua(media.resolve("lua/shared/CleanMisses.lua").toString());
        LuaManager.RunLua(media.resolve("lua/shared/CleanMissesRange.lua").toString());

        // Isolated native actors exercise the hit resolver without a graphical client.
        Field field = Unsafe.class.getDeclaredField("theUnsafe");
        field.setAccessible(true);
        var allocator = (Unsafe) field.get(null);
        var player = (IsoPlayer) allocator.allocateInstance(IsoPlayer.class);
        var weapon = (HandWeapon) allocator.allocateInstance(HandWeapon.class);
        var zombie = (IsoZombie) allocator.allocateInstance(IsoZombie.class);
        weapon.setRanged(true);
        var direction = IsoGameCharacter.class.getDeclaredField("forwardDirection");
        direction.setAccessible(true);
        direction.set(player, new Vector2(1,0));
        direction.set(zombie, new Vector2(1,0));
        GameServer.server = true;

        var combat = CombatManager.getInstance();
        var config = combat.getCombatConfig();
        var increment = CombatConfigKey.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY_INCREMENT;
        var slope = CombatConfigKey.OPTIMAL_RANGE_DROP_OFF_TO_HIT_PENALTY;
        float originalIncrement = config.get(increment), originalSlope = config.get(slope);
        for (boolean enabled : new boolean[]{false,true}) {
            option.setValue(enabled);
            LuaEventManager.triggerEvent("OnServerStarted");
            LuaEventManager.triggerEvent("OnGameStart");
            int[] distances = {5,10,15,20,30};
            int[] expected = enabled ? new int[]{63,51,41,31,11} : new int[]{63,51,23,6,6};
            for (int i=0; i<distances.length; i++) {
                // Hunting Rifle, base chance 50, sights 2–10, upright target and no other penalties.
                int distance = distances[i];
                float modifier = Math.max(combat.getDistanceModifierSightless(distance,false),
                                          combat.getDistanceModifier(distance,2,10,false));
                int chance = (int)Math.clamp(50 + modifier,5,95);
                check(chance + 1 == expected[i], "distance calculation " + distance);
                int hits = 0;
                for (int shot=0; shot<10000; shot++) {
                    var hit = combat.getHitData(player,weapon,zombie,chance);
                    if (hit != null && !hit.isIgnoreDamage()) hits++;
                }
                check(Math.abs(hits / 100.0 - expected[i]) < 3, "native damage rolls " + distance);
                System.out.printf("enabled=%s distance=%d damage-eligible=%d/10000%n",enabled,distance,hits);
            }
        }
        for (int stage=0; stage<3; stage++) {
            option.setValue(stage==2);
            LuaEventManager.triggerEvent("OnGameStart");
            options.firearmUseDamageChance.setValue(stage==0 ? 2 : 1);
            for (int base : new int[]{75,80}) {
                float min = stage==0 ? 0 : 3, max = stage==0 ? 0 : 14;
                float modifier = Math.max(combat.getDistanceModifierSightless(15,false),
                                          combat.getDistanceModifier(15,min,max,false));
                int chance = (int)Math.clamp(base+modifier,5,95);
                int expected = stage==0 ? 6 : (base==75 ? 71 : 76) + (stage==2 ? 3 : 0);
                check(chance+1==expected,"bow threshold");
                int eligible=0;
                for (int shot=0; shot<10000; shot++) {
                    var hit=combat.getHitData(player,weapon,zombie,chance);
                    if (hit!=null && !hit.isIgnoreDamage()) eligible++;
                }
                check(Math.abs(eligible/100.0-expected)<3,"bow damage rolls");
                System.out.printf("bow base=%d stage=%d expected=%d%% eligible=%d/10000%n",base,stage,expected,eligible);
            }
        }
        LuaEventManager.triggerEvent("OnMainMenuEnter");
        check(config.get(increment)==originalIncrement && config.get(slope)==originalSlope,"restore");
    }

    static void check(boolean condition, String label) {
        if (!condition) throw new AssertionError(label);
    }
}

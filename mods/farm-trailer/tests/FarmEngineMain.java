import zombie.Lua.LuaManager;
import zombie.network.GameServer;
import zombie.network.ServerMap;
import se.krka.kahlua.vm.JavaFunction;

// Test-only chunk loader. Production mod files contain no Java or loader patches.
public final class FarmEngineMain {
    public static void main(String[] args) throws Exception {
        Thread bridge = new Thread(() -> {
            try {
                // Let the game initialize its filesystem before touching LuaManager.
                Thread.sleep(30000);
                while (LuaManager.env == null) Thread.sleep(10);
                LuaManager.env.rawset("farmTestKeepLoaded", (JavaFunction) (frame, count) -> {
                    ServerMap map = ServerMap.instance;
                    int x = ((Number) frame.get(0)).intValue();
                    int y = ((Number) frame.get(1)).intValue();
                    map.loadOrKeepRelevent(map.worldSquareToServerCellXY(x) - map.getMinX(),
                        map.worldSquareToServerCellXY(y) - map.getMinY());
                    return 0;
                });
            } catch (InterruptedException exception) {
                Thread.currentThread().interrupt();
            }
        });
        bridge.setDaemon(true);
        bridge.start();
        GameServer.main(args);
    }
}

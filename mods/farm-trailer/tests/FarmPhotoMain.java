import zombie.GameWindow;
import zombie.gameStates.GameLoadingState;
import zombie.gameStates.MainScreenState;
import java.lang.reflect.Field;

/** Test-only native loader continuation for the disposable photo world. */
public final class FarmPhotoMain {
    public static void agentmain(String args) throws Exception {
        Field ready = GameLoadingState.class.getDeclaredField("showedClickToSkip");
        Field proceed = GameLoadingState.class.getDeclaredField("forceDone");
        ready.setAccessible(true);
        proceed.setAccessible(true);
        if (!(GameWindow.states.current instanceof GameLoadingState) || !ready.getBoolean(null)) {
            throw new IllegalStateException("Photo world is not ready");
        }
        proceed.setBoolean(GameWindow.states.current, true);
        System.out.println("FARM_PHOTO_NATIVE_WORLD_READY");
    }
    public static void main(String[] args) throws Exception {
        Thread continuation = new Thread(() -> {
            try {
                Field ready = GameLoadingState.class.getDeclaredField("showedClickToSkip");
                ready.setAccessible(true);
                while (!(GameWindow.states.current instanceof GameLoadingState) || !ready.getBoolean(null)) Thread.sleep(500);
                agentmain("");
            } catch (Exception failure) {
                failure.printStackTrace();
                System.exit(1);
            }
        });
        continuation.setDaemon(true);
        continuation.start();
        MainScreenState.main(args);
    }
}

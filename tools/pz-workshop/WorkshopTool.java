import java.nio.file.Files;
import java.nio.file.Path;
import zombie.ZomboidFileSystem;
import zombie.Lua.LuaEventManager;
import zombie.Lua.LuaManager;
import se.krka.kahlua.luaj.compiler.LuaCompiler;
import zombie.core.znet.SteamUtils;
import zombie.core.znet.SteamUser;
import zombie.core.znet.SteamFriends;
import zombie.core.znet.SteamWorkshopItem;
import zombie.core.znet.SteamWorkshop;

/** Uses the installed game's validator, uploader and signed-in Steam client. Driven by pz-workshop. */
public final class WorkshopTool {
    private static void observeResults() throws Exception {
        zombie.core.random.RandStandard.INSTANCE.init();
        zombie.core.random.RandLua.INSTANCE.init();
        LuaManager.init();
        for (String name : new String[]{"Created", "NotCreated", "Updated", "NotUpdated"}) {
            LuaEventManager.AddEvent("OnSteamWorkshopItem" + name);
        }
        String lua = "Events.OnSteamWorkshopItemCreated.Add(function(id,legal) WCreated=id; WLegal=legal end)\n"
            + "Events.OnSteamWorkshopItemNotCreated.Add(function(code) WError=code end)\n"
            + "Events.OnSteamWorkshopItemUpdated.Add(function(legal) WUpdated=true; WLegal=legal end)\n"
            + "Events.OnSteamWorkshopItemNotUpdated.Add(function(code) WError=code end)";
        Object[] result = LuaManager.caller.pcall(LuaManager.thread,
            LuaCompiler.loadstring(lua, "workshop-publisher", LuaManager.env));
        if (!Boolean.TRUE.equals(result[0])) throw new IllegalStateException("Cannot observe upload result: " + result[1]);
    }

    private static void await(String key, int seconds) throws Exception {
        long deadline = System.nanoTime() + seconds * 1_000_000_000L;
        while (LuaManager.env.rawget(key) == null) {
            SteamUtils.runLoop();
            Object error = LuaManager.env.rawget("WError");
            if (error != null) throw new IllegalStateException("Steam Workshop error " + error);
            if (System.nanoTime() > deadline) throw new IllegalStateException("Timed out waiting for " + key);
            Thread.sleep(100);
        }
    }

    private static void updateCall(String name, Class<?> type, Object value) throws Exception {
        var method = SteamWorkshop.class.getDeclaredMethod(name, type);
        method.setAccessible(true);
        if (!Boolean.TRUE.equals(method.invoke(SteamWorkshop.instance, value))) throw new IllegalStateException("Steam rejected " + name);
    }

    private static void requireAgreement() {
        if (Boolean.TRUE.equals(LuaManager.env.rawget("WLegal"))) throw new IllegalStateException("Workshop agreement acceptance is required");
    }

    /** Modes: status, validate, publish, description. Args: MODE STAGE CACHE [OWNER_STEAM_ID EXPECTED_ITEM_ID]. */
    public static void main(String[] args) throws Exception {
        String mode = args[0];
        if (!java.util.List.of("status", "validate", "publish", "description", "preview").contains(mode)) {
            throw new IllegalArgumentException("Unknown mode " + mode);
        }
        boolean metadata = mode.equals("description") || mode.equals("preview");
        boolean writes = mode.equals("publish") || metadata;
        if (writes && args.length != 5) throw new IllegalArgumentException("Writes need the owner Steam ID and the expected item ID");
        ZomboidFileSystem.instance.setCacheDir(args[2]);
        ZomboidFileSystem.instance.init();
        Path stage = Path.of(args[1]).toAbsolutePath();
        // The vanilla getter appends a visible Workshop/Mod ID footer. Publish the authored copy exactly.
        String description = Files.readAllLines(stage.resolve("workshop.txt")).stream()
            .filter(line -> line.startsWith("description="))
            .map(line -> line.substring("description=".length()))
            .collect(java.util.stream.Collectors.joining("\n"));
        SteamWorkshopItem item = new SteamWorkshopItem(stage.toString()) {
            @Override public String getDescription() { return description; }
        };
        if (!item.readWorkshopTxt()) throw new IllegalStateException("Cannot read workshop.txt");
        String error = item.validateContents();
        if (error != null) throw new IllegalStateException(error + ": " + item.getExtendedErrorInfo(error));
        System.out.println("VALID title=" + item.getTitle() + " id=" + item.getID() + " visibility=" + item.getVisibility() + " tags=" + item.getTags());
        if (writes) {
            // "new" creates an item. Anything else must match workshop.txt, so a lost id= line never forks a listing.
            String expected = args[4].equals("new") ? null : args[4];
            String actual = item.getID() == null || item.getID().isEmpty() ? null : item.getID();
            if (!java.util.Objects.equals(expected, actual)) throw new IllegalStateException("Stage item " + actual + " is not " + args[4]);
            if (metadata && actual == null) throw new IllegalStateException("Metadata updates need a published item");
        }
        if (mode.equals("validate")) {
            observeResults();
            System.out.println("UPLOAD_CALLBACKS_READY");
            return;
        }
        SteamUtils.init();
        try {
            if (!SteamUtils.isSteamModeEnabled()) throw new IllegalStateException("Steam client session unavailable. Start Steam.");
            String account = SteamUser.GetSteamIDString();
            System.out.println("STEAM_ACCOUNT " + account + " " + SteamFriends.GetPersonaName());
            if (mode.equals("status")) return;
            if (!account.equals(args[3])) throw new IllegalStateException("The active Steam account differs from the approved owner");
            observeResults();
            SteamWorkshop.init();
            if (metadata) {
                // The public submit wrapper always uploads Content. These native calls send one metadata field only.
                updateCall("n_StartItemUpdate", long.class, Long.parseLong(item.getID()));
                if (mode.equals("preview")) {
                    updateCall("n_SetItemPreview", String.class, item.getPreviewImage());
                } else {
                    updateCall("n_SetItemDescription", String.class, item.getDescription());
                }
                updateCall("n_SubmitItemUpdate", String.class, Files.readString(stage.resolve("changenote.txt")).strip());
                await("WUpdated", 180);
                requireAgreement();
                System.out.println(mode.toUpperCase() + "_UPDATED " + item.getID());
                return;
            }
            if (item.getID() == null || item.getID().isEmpty()) {
                if (!item.create()) throw new IllegalStateException("Steam refused item creation");
                await("WCreated", 60);
                item.setID((String) LuaManager.env.rawget("WCreated"));
                if (!item.writeWorkshopTxt()) throw new IllegalStateException("Cannot preserve Workshop ID " + item.getID());
                System.out.println("CREATED " + item.getID());
                requireAgreement();
            }
            item.setChangeNote(Files.readString(stage.resolve("changenote.txt")).strip());
            if (!SteamWorkshop.instance.SubmitWorkshopItem(item)) throw new IllegalStateException("Steam refused the upload request");
            await("WUpdated", 180);
            requireAgreement();
            System.out.println("PUBLISHED https://steamcommunity.com/sharedfiles/filedetails/?id=" + item.getID());
        } finally {
            SteamUtils.shutdown();
        }
    }
}

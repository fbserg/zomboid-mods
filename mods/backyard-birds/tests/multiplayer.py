"""Loopback multiplayer: a headless server and a native client on this Mac. Run through project-test --local --suite birds-multiplayer."""
from pathlib import Path
import plistlib
import shutil
import subprocess
import time

GAME = Path.home() / "Library/Application Support/Steam/steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java"
HERE = Path(__file__).resolve().parent
JAVAC = "/opt/homebrew/opt/openjdk/bin/javac"
ROOT = Path.cwd() / ".birds-mp-cache"


def stage_mods(mods: Path) -> None:
    mods.mkdir(parents=True)
    shutil.copytree(HERE.parent / "BackyardBirds", mods / "BackyardBirds")
    probe = mods / "BirdsMP/42"
    (probe / "media/lua/server").mkdir(parents=True)
    (probe / "mod.info").write_text("name=BirdsMP\nid=BirdsMP\nrequire=\\BackyardBirds\n")
    shutil.copy(HERE / "mp-server.lua", probe / "media/lua/server/ZZBirdsMP.lua")


# Server: the game's own dedicated server with the test-only cell bridge. The client's game clone carries
# extra Lua, so the server skips the Lua checksum. Open lets the admin account join.
server_cache = ROOT / "server"
(server_cache / "Server").mkdir(parents=True)
stage_mods(server_cache / "mods")
(server_cache / "Server/birds-mp.ini").write_text("Public=false\nOpen=true\nDefaultPort=16491\nUDPPort=16492\nSteamVAC=false\nBackupsOnStart=false\n"
                                                 "Map=Muldraugh, KY\nMods=BackyardBirds;BirdsMP\nWorkshopItems=\nPauseEmpty=false\nDoLuaChecksum=false\n")
classes = ROOT / "classes"
classes.mkdir()
subprocess.run([JAVAC, "--release", "25", "-cp", str(GAME / "projectzomboid.jar"), "-d", str(classes),
                str(HERE.parents[1] / "farm-trailer/tests/FarmEngineMain.java")], check=True)
java = GAME.parent / "PlugIns/jre-aarch64/Contents/Home/bin/java"
server_command = [str(java), "-Xms256m", "-Xmx2g", "-Djava.awt.headless=true", "-Djava.library.path=.", "--enable-native-access=ALL-UNNAMED",
                  "--add-exports=java.base/jdk.internal.misc=ALL-UNNAMED", "-Dzomboid.steam=0", "-classpath", ".:projectzomboid.jar:" + str(classes),
                  "FarmEngineMain", "-nosteam", "-cachedir=" + str(server_cache), "-servername", "birds-mp", "-adminpassword", "birds-test-local-only", "-ip", "127.0.0.1"]

# Client: a disposable app clone with audio on, every volume at 0, no Dock icon and no focus.
client_cache = ROOT / "client"
stage_mods(client_cache / "mods")
options = dict(line.split("=", 1) for line in (Path.home() / "Zomboid/options.ini").read_text().splitlines() if "=" in line)
options.update(width="1440", height="900", fullScreen="false", borderless="false", frameRate="60", vsync="true", texture2x="true", soundVolume="0", musicVolume="0", ambientVolume="0", voiceVolume="0", focusloss="false", tutorialDone="true", showSurvivalGuide="false", zoomLevels2x="250;225;200;175;150;125;100;75;50")
(client_cache / "options.ini").write_text("\n".join(f"{key}={value}" for key, value in options.items()) + "\n")
contents = client_cache / "Backyard Birds MP.app/Contents"
contents.mkdir(parents=True)
shutil.copytree(GAME.parent / "MacOS", contents / "MacOS")
subprocess.run(["cp", "-cR", str(GAME), str(contents / "Java")], check=True)
for name in ["PlugIns", "Resources"]:
    (contents / name).symlink_to(GAME.parent / name)
shutil.copy(HERE / "mp-bootstrap.lua", contents / "Java/media/lua/client/ZZBirdsMPBootstrap.lua")
shutil.copy(HERE / "mp-client.lua", contents / "Java/media/lua/client/ZZBirdsMPClient.lua")
subprocess.run([JAVAC, "--release", "25", "-cp", str(GAME / "projectzomboid.jar"), "-d", str(contents / "Java"),
                str(HERE.parents[1] / "farm-trailer/tests/FarmPhotoMain.java")], check=True)
info = plistlib.loads((GAME.parent / "Info.plist").read_bytes())
info.update(CFBundleIdentifier="lol.serg.backyardbirds.mp", CFBundleName="Backyard Birds MP", CFBundleDisplayName="Backyard Birds MP",
            JVMMainClassName="FarmPhotoMain", JVMArguments=["-nosteam", "-cachedir=" + str(client_cache)], LSUIElement=True)
info["JVMOptions"] = [value for value in info["JVMOptions"] if not value.startswith(("-Xmx", "-Dzomboid.steam="))] + ["-Xmx3g", "-Dzomboid.steam=0"]
(contents / "Info.plist").write_bytes(plistlib.dumps(info))


def markers(text: str, seen: set[str]) -> None:
    for line in text.splitlines():
        if "BIRDS_MP" in line and line not in seen:
            print(line, flush=True)
            seen.add(line)


server_log, client_log = ROOT / "server.log", ROOT / "client.log"
seen: set[str] = set()
with server_log.open("w") as server_out, client_log.open("w") as client_out:
    server = subprocess.Popen(server_command, cwd=GAME, stdin=subprocess.PIPE, stdout=server_out, stderr=subprocess.STDOUT, text=True)
    client = None
    try:
        deadline = time.monotonic() + 180
        while "BIRDS_MP_SERVER_UP" not in server_log.read_text(errors="replace"):
            if server.poll() is not None or time.monotonic() > deadline:
                raise SystemExit("Server did not start\n" + server_log.read_text(errors="replace")[-5000:])
            time.sleep(1)
        client = subprocess.Popen([str(contents / "MacOS/JavaAppLauncher")], cwd=contents / "Java", stdout=client_out, stderr=subprocess.STDOUT)
        deadline = time.monotonic() + 600
        while True:
            server_text, client_text = server_log.read_text(errors="replace"), client_log.read_text(errors="replace")
            markers(server_text + "\n" + client_text, seen)
            errors = [line for line in (server_text + client_text).splitlines() if "MOD:BirdsMP" in line or "MOD:Backyard" in line]
            if errors or "BIRDS_MP_CLIENT_FAIL" in client_text or "BIRDS_MP_SERVER_FAIL" in server_text:
                raise SystemExit("Multiplayer probe failed\n" + "\n".join(errors) + "\nSERVER\n" + server_text[-4000:] + "\nCLIENT\n" + client_text[-6000:])
            if "BIRDS_MP_CLIENT_PASS" in client_text:
                break
            if server.poll() is not None or client.poll() is not None or time.monotonic() > deadline:
                raise SystemExit("Multiplayer probe did not finish\nSERVER\n" + server_text[-4000:] + "\nCLIENT\n" + client_text[-6000:])
            time.sleep(2)
        print("BIRDS_MP_PASS a real server visit reached a real client, with synced stats and song", flush=True)
    finally:
        if client and client.poll() is None:
            client.terminate()
            try:
                client.wait(timeout=15)
            except subprocess.TimeoutExpired:
                client.kill()
                client.wait(timeout=5)
        if server.poll() is None:
            try:
                server.communicate("quit\n", timeout=20)
            except subprocess.TimeoutExpired:
                server.kill()
                server.communicate(timeout=5)
shutil.rmtree(ROOT)

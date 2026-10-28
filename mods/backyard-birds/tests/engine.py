"""Host-bound PZ server probe. Run through project-test --local --suite birds-engine."""
from pathlib import Path
import re
import shutil
import subprocess
import time

GAME = Path.home() / "Library/Application Support/Steam/steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java"
HERE = Path(__file__).resolve().parent

# The game breaks on a cache under /var (a symlink). Keep it in the disposable workspace.
cache = Path.cwd() / ".birds-engine-cache"
cache.mkdir()
(cache / "Server").mkdir()
mods = cache / "mods"
mods.mkdir()
shutil.copytree(HERE.parent / "BackyardBirds", mods / "BackyardBirds")
probe = mods / "BirdsProbe/42"
(probe / "media/lua/server").mkdir(parents=True)
(probe / "mod.info").write_text("name=BirdsProbe\nid=BirdsProbe\nrequire=\\BackyardBirds\n")
shutil.copy(HERE / "engine.lua", probe / "media/lua/server/ZZBirdsProbe.lua")
active = ["BackyardBirds", "BirdsProbe"]
(cache / "Server/birds-test.ini").write_text("Public=false\nOpen=false\nDefaultPort=16481\nUDPPort=16482\nSteamVAC=false\nBackupsOnStart=false\nMap=Muldraugh, KY\nMods=" + ";".join(active) + "\nWorkshopItems=\nPauseEmpty=false\nDoLuaChecksum=true\n")

# Reuse the farm probe's test-only cell loader.
classes = cache / "classes"
classes.mkdir()
subprocess.run(["/opt/homebrew/opt/openjdk/bin/javac", "--release", "25", "-cp", str(GAME / "projectzomboid.jar"), "-d", str(classes),
                str(HERE.parents[1] / "farm-trailer/tests/FarmEngineMain.java")], check=True)
java = GAME.parent / "PlugIns/jre-aarch64/Contents/Home/bin/java"
if not java.exists(): java = Path("/opt/homebrew/opt/openjdk/bin/java")
command = [str(java), "-Xms256m", "-Xmx2g", "-Djava.awt.headless=true", "-Djava.library.path=.", "--enable-native-access=ALL-UNNAMED",
           "--add-exports=java.base/jdk.internal.misc=ALL-UNNAMED", "-Dzomboid.steam=0", "-classpath", ".:projectzomboid.jar:" + str(classes),
           "FarmEngineMain", "-nosteam", "-cachedir=" + str(cache), "-servername", "birds-test", "-adminpassword", "birds-test-local-only", "-ip", "127.0.0.1"]
log = cache / "server.log"
with log.open("w") as output:
    process = subprocess.Popen(command, cwd=GAME, stdin=subprocess.PIPE, stdout=output, stderr=subprocess.STDOUT, text=True)
    try:
        deadline = time.monotonic() + 150
        while process.poll() is None and time.monotonic() < deadline:
            content = log.read_text(errors="replace")
            if "BIRDS_ENGINE_PASS" in content or "BIRDS_ENGINE_FAIL" in content or "Server Terminated." in content:
                break
            time.sleep(1)
        content = log.read_text(errors="replace")
        loaded = {name.rstrip(".") for name in re.findall(r"LOG\s+: Mod\s+.*?> loading (\S+)", content)}
        lua_errors = [line for line in content.splitlines() if "MOD:Birds" in line or "MOD:Backyard" in line]
        print("\n".join(line for line in content.splitlines() if "BIRDS_" in line), flush=True)
        if "BIRDS_ENGINE_PASS" not in content or set(active) - loaded or lua_errors:
            raise SystemExit(f"Birds engine failed. Missing mods: {sorted(set(active) - loaded)}\n" + "\n".join(lua_errors) + "\n" + content[-6000:])
    finally:
        if process.poll() is None:
            try:
                process.communicate("quit\n", timeout=15)
            except subprocess.TimeoutExpired:
                process.kill()
                process.communicate(timeout=5)
shutil.rmtree(cache)

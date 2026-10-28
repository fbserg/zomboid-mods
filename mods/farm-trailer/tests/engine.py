"""Host-bound PZ server probe. Run through project-test --local --suite farm-engine."""
from pathlib import Path
import shutil
import subprocess
import time
import argparse
from stack import stage_dependencies, verify_loaded

parser = argparse.ArgumentParser()
parser.add_argument("--full-stack", action="store_true")
args = parser.parse_args()

GAME = Path.home() / "Library/Application Support/Steam/steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java"
CACHE = Path.cwd() / ".farm-engine-cache"
CACHE.mkdir()
(CACHE / "Server").mkdir()
mods = CACHE / "mods"
mods.mkdir()
active = stage_dependencies(mods, args.full_stack) + ["FarmTrailer", "FarmProbe"]
(CACHE / "Server/farm-test.ini").write_text("Public=false\nOpen=false\nDefaultPort=16461\nUDPPort=16462\nSteamVAC=false\nBackupsOnStart=false\nMap=map_distanciado;Muldraugh, KY\nMods=" + ";".join(active) + "\nWorkshopItems=\nPauseEmpty=false\nDoLuaChecksum=true\n")
shutil.copytree(Path.cwd() / "mods/farm-trailer/FarmTrailer", mods / "FarmTrailer")
probe = mods / "FarmProbe/42"
(probe / "media/lua/server").mkdir(parents=True)
(probe / "mod.info").write_text("name=FarmProbe\nid=FarmProbe\nrequire=\\FarmTrailer\n")
(probe / "media/lua/server/ZZFarmProbe.lua").write_text((Path.cwd() / "mods/farm-trailer/tests/engine.lua").read_text())
java = GAME.parent / "PlugIns/jre-aarch64/Contents/Home/bin/java"
if not java.exists(): java = Path("/opt/homebrew/opt/openjdk/bin/java")
classes = CACHE / "classes"
classes.mkdir()
subprocess.run(["/opt/homebrew/opt/openjdk/bin/javac", "--release", "25", "-cp", str(GAME / "projectzomboid.jar"), "-d", str(classes), "mods/farm-trailer/tests/FarmEngineMain.java"], check=True)
command = [str(java), "-Xms256m", "-Xmx3g" if args.full_stack else "-Xmx2g", "-Djava.awt.headless=true", "-Djava.library.path=.", "--enable-native-access=ALL-UNNAMED", "--add-exports=java.base/jdk.internal.misc=ALL-UNNAMED", "-Dzomboid.steam=0", "-classpath", ".:projectzomboid.jar:" + str(classes), "FarmEngineMain", "-nosteam", "-cachedir=" + str(CACHE), "-servername", "farm-test", "-adminpassword", "farm-test-local-only", "-ip", "127.0.0.1"]
log = CACHE / "server.log"
for phase in ("create", "reload"):
    with log.open("w") as output:
        process = subprocess.Popen(command, cwd=GAME, stdin=subprocess.PIPE, stdout=output, stderr=subprocess.STDOUT, text=True)
        try:
            deadline = time.monotonic() + (240 if args.full_stack else 100)
            while process.poll() is None and time.monotonic() < deadline:
                content = log.read_text(errors="replace")
                if "FARM_ENGINE_PASS" in content:
                    if any(marker in content for marker in ("Lua((MOD:Farm Trailer)).", "Lua((MOD:FarmTrailer)).")):
                        raise RuntimeError("Runtime Lua error during native check\n" + content[-9000:])
                    verify_loaded(content, active)
                    print(phase, "\n".join(line for line in content.splitlines() if "FARM_" in line), flush=True)
                    break
                if "FARM_ENGINE_FAIL" in content or "Server Terminated." in content:
                    raise RuntimeError("\n".join(line for line in content.splitlines() if "FARM_" in line or "Lua(" in line)[-9000:])
                time.sleep(1)
            else:
                raise RuntimeError("Engine did not finish\n" + log.read_text(errors="replace")[-9000:])
        finally:
            if process.poll() is None:
                try:
                    process.communicate("quit\n", timeout=15)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.communicate(timeout=5)

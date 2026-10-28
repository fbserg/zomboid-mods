"""Host-bound PZ server probe. Run through project-test --local --suite truck-engine."""
from pathlib import Path
import re
import shutil
import subprocess
import time

GAME = Path.home() / "Library/Application Support/Steam/steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java"
WORKSHOP = Path.home() / "Library/Application Support/Steam/steamapps/workshop/content/108600"
DAMNLIB = WORKSHOP / "3171167894/mods/damnlib"
TRUCKS = WORKSHOP / "3110911330/mods/87fordB700"
OSHKOSH = WORKSHOP / "2566953935/mods/86oshkoshP19A"
HERE = Path(__file__).resolve().parent

# The Lua table keys skins by index. Pin each index to the KI5 texture it must name.
# None marks the camo skin this mod appends to a one-skin bus.
EXPECTED = {
    "87fordF700box": {0: "blueWhite", 2: "redBlack", 5: "white", 6: "yellow", 7: "redWhite"},
    "87fordF700bank": {0: "redBlack", 1: "silverBlack"},
    "87fordF700swat": {0: "black"},
    "87fordB700military": {1: "redneckCamo"},
    "87fordB700school": {1: None},
    "87fordB700prison": {1: None},
    "86oshkoshUSMC": {0: "USMCGreen", 1: "NATOGreen", 2: "desertTan", 3: "camo"},
    "86oshkoshFRTR55": {0: "NATOGreen", 1: "USMCGreen", 2: "desertTan", 3: "camo"},
    "86oshkoshKYFD": {0: "red", 1: "yellow", 2: "red2"},
}


def version_folder(mod: Path) -> Path:
    versions = [p for p in mod.iterdir() if re.fullmatch(r"42(\.\d+)?", p.name)]
    return max(versions, key=lambda p: tuple(int(n) for n in p.name.split(".")))


def check_skin_order() -> None:
    sources = {}
    for mod in (TRUCKS, OSHKOSH):
        for script in (version_folder(mod) / "media/scripts").rglob("*.txt"):
            for name in re.findall(r"^\s*vehicle\s+(\w+)", script.read_text(errors="ignore"), re.M):
                sources[name] = script
    for name, skins in EXPECTED.items():
        text = sources[name].read_text(errors="ignore")
        body = text.split(f"vehicle {name}", 1)[1]
        textures = re.findall(r"skin\s*\{\s*texture\s*=\s*([^,\s]+)", body.split("\nvehicle ", 1)[0])
        for index, suffix in skins.items():
            if suffix is None:
                assert len(textures) == index, f"{name} now ships {len(textures)} skins"
            else:
                assert textures[index] == f"Vehicles/Vehicles_{name}_Shell_{suffix}", f"{name} skin {index} is {textures[index]}"
    print("TRUCK_PASS skin indices name the expected KI5 textures", flush=True)


def check_lua_keys(log: str) -> None:
    keys = dict(re.findall(r"TRUCK_KEYS (\w+) ([\d,]+)", log))
    assert {name: sorted(int(i) for i in value.split(",")) for name, value in keys.items()} == \
        {name: sorted(skins) for name, skins in EXPECTED.items()}, keys
    print("TRUCK_PASS Lua skin table matches the pinned texture list", flush=True)


check_skin_order()
# The game breaks on a cache under /var (a symlink). Keep it in the disposable workspace.
cache = Path.cwd() / ".truck-engine-cache"
cache.mkdir()
(cache / "Server").mkdir()
mods = cache / "mods"
mods.mkdir()
for source in (DAMNLIB, TRUCKS, OSHKOSH):
    subprocess.run(["cp", "-cR", str(source), str(mods / source.name)], check=True)
shutil.copytree(HERE.parent / "TruckRepaint", mods / "TruckRepaint")
probe = mods / "TruckProbe/42"
(probe / "media/lua/server").mkdir(parents=True)
(probe / "mod.info").write_text("name=TruckProbe\nid=TruckProbe\nrequire=\\TruckRepaint\n")
shutil.copy(HERE / "engine.lua", probe / "media/lua/server/ZZTruckProbe.lua")
active = ["damnlib", "87fordB700", "86oshkoshP19A", "TruckRepaint", "TruckProbe"]
(cache / "Server/truck-test.ini").write_text("Public=false\nOpen=false\nDefaultPort=16471\nUDPPort=16472\nSteamVAC=false\nBackupsOnStart=false\nMap=Muldraugh, KY\nMods=" + ";".join(active) + "\nWorkshopItems=\nPauseEmpty=false\nDoLuaChecksum=true\n")

# Reuse the farm probe's test-only cell loader.
classes = cache / "classes"
classes.mkdir()
subprocess.run(["/opt/homebrew/opt/openjdk/bin/javac", "--release", "25", "-cp", str(GAME / "projectzomboid.jar"), "-d", str(classes),
                str(HERE.parents[1] / "farm-trailer/tests/FarmEngineMain.java")], check=True)
java = GAME.parent / "PlugIns/jre-aarch64/Contents/Home/bin/java"
if not java.exists(): java = Path("/opt/homebrew/opt/openjdk/bin/java")
command = [str(java), "-Xms256m", "-Xmx2g", "-Djava.awt.headless=true", "-Djava.library.path=.", "--enable-native-access=ALL-UNNAMED",
           "--add-exports=java.base/jdk.internal.misc=ALL-UNNAMED", "-Dzomboid.steam=0", "-classpath", ".:projectzomboid.jar:" + str(classes),
           "FarmEngineMain", "-nosteam", "-cachedir=" + str(cache), "-servername", "truck-test", "-adminpassword", "truck-test-local-only", "-ip", "127.0.0.1"]
log = cache / "server.log"
with log.open("w") as output:
    process = subprocess.Popen(command, cwd=GAME, stdin=subprocess.PIPE, stdout=output, stderr=subprocess.STDOUT, text=True)
    try:
        deadline = time.monotonic() + 150
        while process.poll() is None and time.monotonic() < deadline:
            content = log.read_text(errors="replace")
            if "TRUCK_ENGINE_PASS" in content or "TRUCK_ENGINE_FAIL" in content or "Server Terminated." in content:
                break
            time.sleep(1)
        content = log.read_text(errors="replace")
        loaded = {name.rstrip(".") for name in re.findall(r"LOG\s+: Mod\s+.*?> loading (\S+)", content)}
        lua_errors = [line for line in content.splitlines() if "MOD:Truck" in line]
        print("\n".join(line for line in content.splitlines() if "TRUCK_" in line), flush=True)
        if "TRUCK_ENGINE_PASS" not in content or set(active) - loaded or lua_errors:
            raise SystemExit(f"Truck engine failed. Missing mods: {sorted(set(active) - loaded)}\n" + "\n".join(lua_errors) + "\n" + content[-6000:])
        check_lua_keys(content)
    finally:
        if process.poll() is None:
            try:
                process.communicate("quit\n", timeout=15)
            except subprocess.TimeoutExpired:
                process.kill()
                process.communicate(timeout=5)
shutil.rmtree(cache)

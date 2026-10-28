"""Launch an isolated native graphical client for real Workshop photographs."""
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[3]/"tools/pz-test"))
from window import build_policy, assert_hidden
import shutil
import plistlib
import subprocess
import time
import argparse
import json
from stack import stage_dependencies, verify_loaded, write_error_report

parser = argparse.ArgumentParser()
parser.add_argument("--full-stack", action="store_true")
parser.add_argument("--baseline", action="store_true")
args = parser.parse_args()

GAME = Path.home() / "Library/Application Support/Steam/steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java"
CACHE = Path.cwd() / ".farm-photo-cache"
CACHE.mkdir()
mods = CACHE / "mods"
mods.mkdir()
active = stage_dependencies(mods, args.full_stack) + ([] if args.baseline else ["FarmTrailer"]) + ["FarmPhotos"]
if not args.baseline:
    shutil.copytree("mods/farm-trailer/FarmTrailer", mods / "FarmTrailer")
probe = mods / "FarmPhotos/42"
(probe / "media/lua/client").mkdir(parents=True)
(probe / "mod.info").write_text("name=FarmPhotos\nid=FarmPhotos\nrequire=\\" + ("PROJECTRVInterior42" if args.baseline else "FarmTrailer") + "\n")
fixture = Path("mods/farm-trailer/tests/photos.lua").read_text()
if args.baseline:
    fixture = fixture.replace('local F = require "FarmTrailer"', 'local F = {rooms={{x=22560,y=12500,z=0}}}')
(probe / "media/lua/client/ZZFarmPhotos.lua").write_text(fixture)
(mods / "default.txt").write_text("VERSION = 1,\nmods {\n" + "".join(f"mod = {name},\n" for name in active) + "}\nmaps {\nmap = map_distanciado,\nmap = Muldraugh, KY,\n}\n")
options = dict(line.split("=", 1) for line in (Path.home() / "Zomboid/options.ini").read_text().splitlines() if "=" in line)
options.update(width="1440", height="900", fullScreen="false", borderless="false", frameRate="60", vsync="true", texture2x="true", soundVolume="0", musicVolume="0", ambientVolume="0", focusloss="false", tutorialDone="true", showSurvivalGuide="false", zoomLevels2x="250;225;200;175;150;125;100;75;50")
(CACHE / "options.ini").write_text("\n".join(f"{key}={value}" for key, value in options.items()) + "\n")
app = CACHE / "Farm Trailer Photos.app"
contents = app / "Contents"
contents.mkdir(parents=True)
original = GAME.parent
shutil.copytree(original / "MacOS", contents / "MacOS")
subprocess.run(["cp", "-cR", str(original / "Java"), str(contents / "Java")], check=True)
for name in ["PlugIns", "Resources"]:
    (contents / name).symlink_to(original / name)
bootstrap = contents / "Java/media/lua/client/ZZFarmPhotoBootstrap.lua"
bootstrap_source = Path("mods/farm-trailer/tests/photo-bootstrap.lua").read_text()
bootstrap_source = bootstrap_source.replace('{"damnlib", "KI5trailers", "PROJECTRVInterior42", "FarmTrailer", "FarmPhotos"}', "{" + ", ".join(json.dumps(name) for name in active) + "}")
bootstrap.write_text(bootstrap_source)
info = plistlib.loads((original / "Info.plist").read_bytes())
info["CFBundleIdentifier"] = "lol.serg.farmtrailer.photos"
info["CFBundleName"] = "Farm Trailer Photos"
info["CFBundleDisplayName"] = "Farm Trailer Photos"
subprocess.run(["/opt/homebrew/opt/openjdk/bin/javac", "--release", "25", "-cp", str(GAME / "projectzomboid.jar"), "-d", str(contents / "Java"), "mods/farm-trailer/tests/FarmPhotoMain.java"], check=True)
info["JVMMainClassName"] = "FarmPhotoMain"
info["JVMArguments"] = ["-nosteam", "-nosound", "-cachedir=" + str(CACHE)]
agent,auditor=build_policy(CACHE)
info["LSUIElement"] = True
info["JVMOptions"] = [value for value in info["JVMOptions"] if not value.startswith(("-Xmx", "-Dzomboid.steam="))] + ["-Xmx4g" if args.full_stack else "-Xmx3g", "-Dzomboid.steam=0"]
info["JVMOptions"].append("-javaagent:"+str(agent))
(contents / "Info.plist").write_bytes(plistlib.dumps(info))
command = [str(contents / "MacOS/JavaAppLauncher")]

output = Path("mods/farm-trailer/workshop/screenshots")
output.mkdir(exist_ok=True)
print("FARM_PHOTO_CACHE " + str(CACHE), flush=True)
with (CACHE / "client.log").open("w") as log:
    process = subprocess.Popen(command, cwd=contents / "Java", stdout=log, stderr=subprocess.STDOUT)
    try:
        deadline = time.monotonic() + 900
        seen = set()
        while process.poll() is None and time.monotonic() < deadline:
            assert_hidden(auditor,[process.pid])
            text = (CACHE / "client.log").read_text(errors="replace")
            if "PZ_TEST_FAIL" in text or any(marker in text for marker in ("Lua((MOD:FarmPhotos)).", "Lua((MOD:Farm Trailer)).", "Lua((MOD:FarmTrailer)).")):
                raise RuntimeError("Photo fixture failed\n" + text[-6000:])
            for line in text.splitlines():
                if "FARM_PHOTO" in line and line not in seen:
                    print(line, flush=True)
                    seen.add(line)
            captures = list((CACHE / "Screenshots").glob("farm-*.png"))
            if len(captures) == 3:
                assert "PZ_TEST_HIDDEN_WINDOW_PASS" in text, "Window policy not observed"
                verify_loaded(text, active)
                write_error_report(text, Path("mods/farm-trailer/tests/last-client-errors.json"), args.baseline)
                for capture in captures:
                    destination = output / (capture.stem + ".jpg")
                    # ceiling: 320 KB per photo, keep all three within the runner's 1 MiB export.
                    for quality in (90, 80, 70, 60, 50, 40):
                        subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", str(quality), str(capture), "--out", str(destination)], check=True, capture_output=True)
                        if destination.stat().st_size <= 320_000:
                            break
                    else:
                        raise RuntimeError("Photo exceeds artifact budget: " + str(destination))
                print("FARM_PHOTOS_PASS three real native-client captures", flush=True)
                break
            time.sleep(2)
        else:
            raise RuntimeError("Photo client did not finish\n" + (CACHE / "client.log").read_text(errors="replace")[-7000:])
    finally:
        process.terminate()
        try: process.wait(timeout=15)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)

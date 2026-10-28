"""Native graphical client: real bird visits and Workshop captures. Run through project-test --local --suite birds-photos."""
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[3]/"tools/pz-test"))
from window import build_policy, assert_hidden
import plistlib
import shutil
import subprocess
import time

GAME = Path.home() / "Library/Application Support/Steam/steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java"
HERE = Path(__file__).resolve().parent
PHOTOS = ["birds-halo.png", "birds-yard.png", "birds-close.png"]
CACHE = Path.cwd() / ".birds-photo-cache"
CACHE.mkdir()
mods = CACHE / "mods"
mods.mkdir()
shutil.copytree(HERE.parent / "BackyardBirds", mods / "BackyardBirds")
probe = mods / "BirdPhotos/42"
(probe / "media/lua/client").mkdir(parents=True)
(probe / "mod.info").write_text("name=BirdPhotos\nid=BirdPhotos\nrequire=\\BackyardBirds\n")
shutil.copy(HERE / "photos.lua", probe / "media/lua/client/ZZBirdPhotos.lua")
(mods / "default.txt").write_text("VERSION = 1,\nmods {\nmod = BackyardBirds,\nmod = BirdPhotos,\n}\nmaps {\nmap = Muldraugh, KY,\n}\n")
options = dict(line.split("=", 1) for line in (Path.home() / "Zomboid/options.ini").read_text().splitlines() if "=" in line)
options.update(width="1440", height="900", fullScreen="false", borderless="false", frameRate="60", vsync="true", texture2x="true", soundVolume="0", musicVolume="0", ambientVolume="0", focusloss="false", tutorialDone="true", showSurvivalGuide="false", zoomLevels2x="250;225;200;175;150;125;100;75;50")
(CACHE / "options.ini").write_text("\n".join(f"{key}={value}" for key, value in options.items()) + "\n")

# A disposable app clone, so the bootstrap never touches the installed game.
contents = CACHE / "Backyard Birds Photos.app/Contents"
contents.mkdir(parents=True)
shutil.copytree(GAME.parent / "MacOS", contents / "MacOS")
subprocess.run(["cp", "-cR", str(GAME), str(contents / "Java")], check=True)
for name in ["PlugIns", "Resources"]:
    (contents / name).symlink_to(GAME.parent / name)
shutil.copy(HERE / "photo-bootstrap.lua", contents / "Java/media/lua/client/ZZBirdPhotoBootstrap.lua")
# Reuse the farm harness's loader continuation.
subprocess.run(["/opt/homebrew/opt/openjdk/bin/javac", "--release", "25", "-cp", str(GAME / "projectzomboid.jar"), "-d", str(contents / "Java"),
                str(HERE.parents[1] / "farm-trailer/tests/FarmPhotoMain.java")], check=True)
info = plistlib.loads((GAME.parent / "Info.plist").read_bytes())
info.update(CFBundleIdentifier="lol.serg.backyardbirds.photos", CFBundleName="Backyard Birds Photos", CFBundleDisplayName="Backyard Birds Photos",
            JVMMainClassName="FarmPhotoMain", JVMArguments=["-nosteam", "-cachedir=" + str(CACHE)],
            # Sound stays on for the song checks. Every volume is 0. A UI-element app has no Dock icon and does not take focus.
            LSUIElement=True)
agent,auditor=build_policy(CACHE)
info["LSUIElement"] = True
info["JVMOptions"] = [value for value in info["JVMOptions"] if not value.startswith(("-Xmx", "-Dzomboid.steam="))] + ["-Xmx3g", "-Dzomboid.steam=0"]
info["JVMOptions"].append("-javaagent:"+str(agent))
(contents / "Info.plist").write_bytes(plistlib.dumps(info))

output = HERE.parent / "workshop/screenshots"
output.mkdir(parents=True, exist_ok=True)
log_path = CACHE / "client.log"
with log_path.open("w") as log:
    process = subprocess.Popen([str(contents / "MacOS/JavaAppLauncher")], cwd=contents / "Java", stdout=log, stderr=subprocess.STDOUT)
    try:
        deadline = time.monotonic() + 600
        seen = set()
        while True:
            assert_hidden(auditor,[process.pid])
            text = log_path.read_text(errors="replace")
            for line in text.splitlines():
                if "BIRDS_" in line and line not in seen:
                    print(line, flush=True)
                    seen.add(line)
            if "PZ_TEST_FAIL" in text or "Lua((MOD:BirdPhotos))." in text or "Lua((MOD:Backyard Birds))." in text or "Lua((MOD:BackyardBirds))." in text:
                raise SystemExit("Photo fixture failed\n" + text[-6000:])
            if "BIRDS_PHOTOS_DONE" in text:
                assert "PZ_TEST_HIDDEN_WINDOW_PASS" in text, "Window policy not observed"
                break
            if process.poll() is not None or time.monotonic() > deadline:
                raise SystemExit("Photo client did not finish\n" + text[-7000:])
            time.sleep(2)
        for name in PHOTOS:
            capture = CACHE / "Screenshots" / name
            destination = output / (capture.stem + ".jpg")
            # ceiling: 320 KB per photo, keep the set within the runner's 1 MiB export.
            for quality in (90, 80, 70, 60, 50):
                subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", str(quality), str(capture), "--out", str(destination)], check=True, capture_output=True)
                if destination.stat().st_size <= 320_000:
                    break
            else:
                raise SystemExit("Photo exceeds artifact budget: " + str(destination))
        print("BIRDS_PHOTOS_PASS three native-client captures", flush=True)
    finally:
        process.terminate()
        try:
            process.wait(timeout=15)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)
shutil.rmtree(CACHE)

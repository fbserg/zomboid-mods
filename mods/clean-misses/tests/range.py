from pathlib import Path
import subprocess
import tempfile

game = Path.home() / "Library/Application Support/Steam/steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java"
tests = Path(__file__).resolve().parent
with tempfile.TemporaryDirectory() as cache:
    subprocess.run([
        "/opt/homebrew/opt/openjdk/bin/java", "--add-exports=java.base/jdk.internal.misc=ALL-UNNAMED",
        "-Djava.library.path=.", "-cp", "projectzomboid.jar", str(tests / "RangeCheck.java"),
        str(tests.parent / "CleanMisses/42/media"), cache
    ], cwd=game, check=True)

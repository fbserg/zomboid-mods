"""Install the local add-on into ~/Zomboid/mods, replacing an older copy of this mod only."""
from pathlib import Path
import hashlib
import json
import shutil

source = Path(__file__).resolve().parent / "BackyardBirds"
destination = Path.home() / "Zomboid/mods/BackyardBirds"


def manifest(root: Path) -> dict[str, str]:
    return {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(root.rglob("*")) if p.is_file() and p.name != ".DS_Store"}


if destination.exists():
    assert (destination / "42/mod.info").read_text().splitlines()[1] == "id=BackyardBirds", f"Not this mod: {destination}"
    shutil.rmtree(destination)
shutil.copytree(source, destination)
assert manifest(destination) == manifest(source), "Installed files differ from source"
print(json.dumps({"installed": str(destination), "files": len(manifest(source)), "verified": True}))

"""Stage installed dependencies in the disposable project-test workspace."""
from pathlib import Path
import hashlib
import json
import re
import subprocess

WORKSHOP = Path.home() / "Library/Application Support/Steam/steamapps/workshop/content/108600"
MANIFEST = Path(__file__).with_name("server-stack.json")


def stage_dependencies(destination: Path, full_stack: bool) -> list[str]:
    manifest = json.loads(MANIFEST.read_text())
    entries = manifest["mods"]
    if not full_stack:
        entries = [next(entry for entry in entries if entry["id"] == name)
                   for name in ("damnlib", "KI5trailers", "PROJECTRVInterior42")]
    copied = set()
    for entry in entries:
        source = WORKSHOP / entry["workshop"] / "mods" / entry["folder"]
        info = source / entry["info"]
        if hashlib.sha256(info.read_bytes()).hexdigest() != entry["info_sha256"]:
            raise RuntimeError("Installed mod metadata changed: " + entry["id"])
        if "content_sha256" in entry:
            digest = hashlib.sha256()
            for file in sorted(source.rglob("*")):
                if file.is_file() and file.name != ".DS_Store":
                    digest.update(file.relative_to(source).as_posix().encode() + b"\0"
                                  + hashlib.sha256(file.read_bytes()).digest())
            if digest.hexdigest() != entry["content_sha256"]:
                raise RuntimeError("Installed mod content changed: " + entry["id"])
        if source not in copied:
            subprocess.run(["cp", "-cR", str(source), str(destination / source.name)], check=True)
            copied.add(source)
    print(f"FARM_STACK {len(entries)} mod IDs, {len(copied)} installed folders", flush=True)
    return [entry["id"] for entry in entries]


def verify_loaded(log: str, expected: list[str]) -> None:
    loaded = {name.rstrip(".") for name in re.findall(r"LOG\s+: Mod\s+.*?> loading (\S+)", log)}
    missing = set(expected) - loaded
    if missing:
        raise RuntimeError("Configured mods were not loaded: " + ", ".join(sorted(missing)))
    print(f"FARM_STACK_LOADED all {len(expected)} requested mod IDs", flush=True)


def write_error_report(log: str, destination: Path, baseline: bool) -> None:
    frames = sorted(set(re.findall(r"Lua\(\(MOD:([^)]*)\)\)\.([^\n]+)", log)))
    report = {
        "farm_trailer_enabled": not baseline,
        "native_error_line_count": sum(line.startswith("ERROR:") for line in log.splitlines()),
        "native_error_lines": [re.sub(r" /.*?/Contents/Java/", " <game>/", line.partition(">")[2].strip()) for line in log.splitlines() if line.startswith("ERROR:")][:60],
        "mod_lua_frames": frames,
    }
    destination.write_text(json.dumps(report, indent=2) + "\n")
    print("FARM_STACK_ERRORS " + json.dumps(report), flush=True)

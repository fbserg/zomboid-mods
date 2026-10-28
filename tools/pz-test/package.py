"""Package only runtime files. Optional fresh install, with no overwrites."""
from pathlib import Path
import argparse
import hashlib
import json
import shutil
import zipfile


def main() -> None:
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('mod', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--install', action='store_true')
    args = parser.parse_args()
    runtime, = [p.parents[1] for p in args.mod.glob('*/42/mod.info')]
    files = sorted(p for p in runtime.rglob('*') if p.is_file() and p.name != '.DS_Store')
    manifest = {str(p.relative_to(runtime)): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}
    with zipfile.ZipFile(args.output, 'x', compression=zipfile.ZIP_DEFLATED) as archive:
        archive.writestr(f'{runtime.name}/common/', '')
        for path in files:
            archive.write(path, str(path.relative_to(runtime.parent)))
    if args.install:
        target = Path.home() / 'Zomboid/mods' / runtime.name
        shutil.copytree(runtime, target)  # Refuse an existing destination, never delete a personal mod.
        (target / 'common').mkdir(exist_ok=True)
        actual = {str(p.relative_to(target)): hashlib.sha256(p.read_bytes()).hexdigest()
                  for p in target.rglob('*') if p.is_file()}
        assert actual == manifest, 'Install differs from packaged source'
    print(json.dumps({'package': str(args.output), 'runtime_files': len(files), 'sha256': manifest,
                      'installed': args.install}, indent=2))


if __name__ == '__main__':
    main()

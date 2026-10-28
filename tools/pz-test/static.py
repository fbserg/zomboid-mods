"""Pinned upstream static checker. Runs inside project-test, without booting a world."""
from pathlib import Path
import argparse
import hashlib
import io
import shutil
import subprocess
import tarfile
import time
import urllib.request

PIN = '2a23ec6ddb0cb7d90bab43a14017e0edf6d28480'
SHA256 = '5ded2642de08dd5fddeb272218634f7684c2def4f0aa402bda6f6046e28c9b5c'
GAME = Path.home() / 'Library/Application Support/Steam/steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java'


def main() -> None:
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('mod', type=Path)
    parser.add_argument('--prove', action='store_true')
    args = parser.parse_args()
    root = Path.cwd() / '.pz-static'
    root.mkdir()
    data = urllib.request.urlopen(f'https://api.github.com/repos/CalebFenton/PZ_DevHarness/tarball/{PIN}', timeout=30).read()
    assert hashlib.sha256(data).hexdigest() == SHA256, 'Upstream archive checksum changed'
    with tarfile.open(fileobj=io.BytesIO(data)) as archive:
        archive.extractall(root, filter='data')
    upstream, = root.glob('CalebFenton-*')
    classes = root / 'classes'
    classes.mkdir()
    subprocess.run(['/opt/homebrew/opt/openjdk/bin/javac','--release','8','-Xlint:-options','-d',str(classes),str(upstream/'check/GameProbe.java')], check=True)
    runtime, = [p.parent for p in args.mod.resolve().glob('*/42/mod.info')]
    api, listing = root/'api.txt', root/'lua-files.txt'
    listing.write_text(''.join(f'{p}\t{p.name}\n' for p in runtime.rglob('*.lua')))
    subprocess.run([str(GAME.parent/'PlugIns/jre-aarch64/Contents/Home/bin/java'),'-cp',f'{classes}:{GAME}/projectzomboid.jar',
                    'GameProbe','--api',str(GAME/'projectzomboid.jar'),str(api),'@'+str(listing)],cwd=GAME,check=True)

    def check(path: Path, expected: str = '') -> None:
        start = time.monotonic()
        run = subprocess.run(['python3',str(upstream/'check/check.py'),'--game',str(GAME),'--api',str(api),
                              '--cache',str(root),'--name',runtime.parent.name,str(path)],capture_output=True,text=True)
        output = run.stdout+run.stderr
        print(output, end='', flush=True)
        print(f'PZ_STATIC seconds={time.monotonic()-start:.3f} expected={expected or "pass"}',flush=True)
        if expected:
            assert run.returncode != 0 and expected in output, 'Negative control was not detected'
        elif run.returncode:
            raise SystemExit(run.returncode)

    check(runtime)
    # ceiling: negative fixtures target Dinner Together; add mod-owned cases before --prove for another mod.
    if args.prove:
        broken = root/'wrong-translation'
        shutil.copytree(runtime,broken)
        translation=broken/'media/lua/shared/Translate/EN/IG_UI.json'
        translation.rename(translation.with_name('Wrong.json'))
        check(broken,'translation')
        invalid = root/'invalid-api'
        shutil.copytree(runtime,invalid)
        with (invalid/'media/lua/shared/DinnerTogether.lua').open('a') as output:
            output.write('\ngetPlayer():PZDefinitelyMissingMethod()\n')
        check(invalid,'method-name')
        check(runtime)
        print('PZ_STATIC_PROOF_PASS two negative controls and restored mod')


if __name__ == '__main__':
    main()

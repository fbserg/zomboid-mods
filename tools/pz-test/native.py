"""Run mod-specific Lua probes in disposable B42 server/client copies via project-test."""
from pathlib import Path
import argparse
import json
import hashlib
import fcntl
import plistlib
import re
import zipfile
import shutil
import subprocess
import time

GAME = Path.home() / 'Library/Application Support/Steam/steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java'
REPO = Path(__file__).resolve().parents[2]
JAVAC = '/opt/homebrew/opt/openjdk/bin/javac'


def main() -> None:
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('mod', type=Path)
    parser.add_argument('--multiplayer', action='store_true')
    parser.add_argument('--workshop', action='store_true', help='Verify and test the downloaded published runtime')
    parser.add_argument('--photos', action='store_true', help='Capture the multiplayer fixture on Alice')
    parser.add_argument('--legacy-copy', action='store_true')
    parser.add_argument('--rounds', type=int, choices=(1,2), default=1)
    args = parser.parse_args()
    if args.photos and not args.multiplayer:
        parser.error('--photos requires --multiplayer')
    mod = args.mod.resolve()
    runtime, = [p.parents[1] for p in mod.glob('*/42/mod.info')]
    if args.workshop:
        item = re.search(r'^id=(\d+)$',(mod/'workshop/workshop.txt').read_text(),re.M)
        assert item, 'Published Workshop ID required'
        installed = GAME.parents[4]/'workshop/content/108600'/item.group(1)/'mods'/runtime.name
        def hashes(folder: Path) -> dict[str,str]:
            return {str(p.relative_to(folder)):hashlib.sha256(p.read_bytes()).hexdigest()
                    for p in folder.rglob('*') if p.is_file() and p.name!='.DS_Store'}
        assert installed.is_dir() and hashes(installed)==hashes(runtime), 'Downloaded runtime differs from release source'
        runtime = installed
        print('PZ_TEST_WORKSHOP_HASHES_PASS '+str(installed),flush=True)
    root = Path.cwd() / '.pz-native-cache'
    root.mkdir()
    mode = 'mp' if args.multiplayer else 'engine'
    processes: list[subprocess.Popen] = []
    logs: list[Path] = []
    handles = []

    def stage(cache: Path) -> None:
        mods = cache / 'mods'
        mods.mkdir(parents=True)
        shutil.copytree(runtime, mods / runtime.name)
        probe = mods / 'PZProbe/42'
        (probe / 'media/lua/server').mkdir(parents=True)
        (probe / 'mod.info').write_text(f'name=PZProbe\nid=PZProbe\nrequire=\\{runtime.name}\n')
        (probe / 'media/lua/server/ZZPZProbe.lua').write_text('PZ_TEST_PHOTOS = '+str(args.photos).lower()+'\nPZ_TEST_ROUNDS = '+str(args.rounds)+'\n'+(mod / f'tests/{mode}.lua').read_text())

    def launch(command: list[str], cwd: Path, name: str) -> subprocess.Popen:
        log = root / f'{name}.log'
        logs.append(log)
        output = log.open('w')
        handles.append(output)
        process = subprocess.Popen(command, cwd=cwd, stdin=subprocess.PIPE, stdout=output,
                                   stderr=subprocess.STDOUT, text=True)
        processes.append(process)
        return process

    seen: set[str] = set()

    def wait_for(markers: list[str], timeout: int) -> None:
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline:
            text = '\n'.join(log.read_text(errors='replace') for log in logs if log.exists())
            for line in text.splitlines():
                if 'PZ_TEST_' in line and line not in seen:
                    print(line, flush=True)
                    seen.add(line)
            if 'PZ_TEST_FAIL' in text or 'ZZPZProbe.lua:' in text or any(f'MOD:{runtime.name}' in s or 'MOD:PZProbe' in s for s in text.splitlines()):
                lines = text.splitlines()
                failures = '\n'.join('\n'.join(lines[max(0,i-8):i+8]) for i,line in enumerate(lines)
                                     if 'PZ_TEST_FAIL' in line or 'ZZPZProbe.lua:' in line or f'MOD:{runtime.name}' in line or 'MOD:PZProbe' in line)
                raise RuntimeError('Native probe failed\n' + failures[-10000:])
            if args.multiplayer:
                front = subprocess.check_output(['lsappinfo','front'],text=True).strip()
                info = subprocess.check_output(['lsappinfo','info','-only','pid',front],text=True)
                pid = re.search(r'"pid"=(\d+)',info)
                if pid and int(pid.group(1)) in {p.pid for p in processes}:
                    raise RuntimeError('Test client took window focus')
            if all(marker in text for marker in markers):
                return
            if any(process.poll() is not None for process in processes):
                raise RuntimeError('Game exited: ' + str([p.poll() for p in processes]) + '\n' + '\n'.join(str(log)+'\n'+log.read_text(errors='replace')[-2500:] for log in logs if log.exists()))
            time.sleep(1)
        raise TimeoutError('Native probe timed out\n' + text[-6000:])

    # One native run across worktrees. The lock never changes the personal game cache.
    with (Path.home() / '.cache/pz-social-tests.lock').open('w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            cache = root / 'server'
            stage(cache)
            (cache / 'Server').mkdir()
            (cache / 'Server/pz-test.ini').write_text(
                'Public=false\nOpen=true\nDefaultPort=16511\nUDPPort=16512\nSteamVAC=false\n'
                'BackupsOnStart=false\nMap=Muldraugh, KY\nWorkshopItems=\nPauseEmpty=false\n'
                f'Mods={runtime.name};PZProbe\nDoLuaChecksum=false\nSpawnPoint=10628,10658,0\n')
            classes = root / 'classes'
            classes.mkdir()
            subprocess.run([JAVAC, '--release', '25', '-cp', str(GAME / 'projectzomboid.jar'), '-d', str(classes),
                            str(REPO / 'mods/farm-trailer/tests/FarmEngineMain.java')], check=True)
            java = GAME.parent / 'PlugIns/jre-aarch64/Contents/Home/bin/java'
            server_command = [str(java), '-Xms256m', '-Xmx2g', '-Djava.awt.headless=true', '-Djava.library.path=.',
                    '--enable-native-access=ALL-UNNAMED', '--add-exports=java.base/jdk.internal.misc=ALL-UNNAMED',
                    '-Dzomboid.steam=0', '-classpath', f'.:projectzomboid.jar:{classes}', 'FarmEngineMain',
                    '-nosteam', f'-cachedir={cache}', '-servername', 'pz-test', '-adminpassword',
                    'test-only', '-ip', '127.0.0.1']
            if args.multiplayer:
                subprocess.run([JAVAC,'--release','25',
                                '-d',str(classes),str(REPO/'tools/pz-test/FocusAgent.java')],check=True)
                agent=root/'focus-agent.jar'
                with zipfile.ZipFile(agent,'w') as archive:
                    archive.writestr('META-INF/MANIFEST.MF','Manifest-Version: 1.0\nPremain-Class: FocusAgent\n\n')
                    for file in classes.glob('FocusAgent*.class'): archive.write(file,file.name)
            server = launch(server_command, GAME, 'server')
            if not args.multiplayer:
                wait_for(['PZ_TEST_ENGINE_PASS'], 180)
                server.communicate('quit\n', timeout=30)
                processes.remove(server)
                launch(server_command, GAME, 'restart')
                wait_for(['PZ_TEST_RESTART_PASS'], 180)
                return
            wait_for(['PZ_TEST_SERVER_UP'], 180)
            for role in ('Alice', 'Beth'):
                cache = root / role
                stage(cache)
                contents = cache / 'Probe.app/Contents'
                contents.mkdir(parents=True)
                shutil.copytree(GAME.parent / 'MacOS', contents / 'MacOS')
                if args.legacy_copy:
                    subprocess.run(['cp', '-cR', str(GAME), str(contents / 'Java')], check=True)
                else:
                    (contents / 'Java').mkdir()
                for name in ('PlugIns', 'Resources'):
                    (contents / name).symlink_to(GAME.parent / name)
                bootstrap = (mod / 'tests/mp-client.lua').read_text().replace('@ROLE@', role)
                if args.photos:
                    bootstrap += '\nPZ_PHOTO_ROLE = '+repr(role)+'\n'+(mod / 'tests/photos.lua').read_text()
                if args.legacy_copy:
                    (contents / 'Java/media/lua/client/ZZPZProbe.lua').write_text(bootstrap)
                else:
                    client_lua = cache / 'mods/PZProbe/42/media/lua/client'
                    client_lua.mkdir()
                    (client_lua / 'ZZPZProbe.lua').write_text(bootstrap)
                    (cache / 'mods/reset-mods-42_00.txt').write_text('Disposable dev mod list initialized\n')
                    (cache / 'mods/default.txt').write_text('VERSION = 1,\nmods\n{\n    mod = '+runtime.name+',\n    mod = PZProbe,\n}\nmaps\n{\n}\n')
                subprocess.run([JAVAC, '--release', '25', '-cp', str(GAME / 'projectzomboid.jar'),
                                '-d', str(contents / 'Java') if args.legacy_copy else str(classes), str(REPO / 'mods/farm-trailer/tests/FarmPhotoMain.java')], check=True)
                info = plistlib.loads((GAME.parent / 'Info.plist').read_bytes())
                info.update(CFBundleIdentifier=f'lol.serg.pztest.{role}', JVMMainClassName='FarmPhotoMain',
                            JVMArguments=['-nosteam', f'-cachedir={cache}'], LSUIElement=True)
                info['JVMOptions'] = [v for v in info['JVMOptions'] if not v.startswith(('-Xmx', '-Dzomboid.steam='))] + ['-Xmx2g', '-Dzomboid.steam=0']
                if not args.legacy_copy:
                    info['JVMOptions'].append(f'-Djava.class.path={classes}:{GAME}:{GAME}/projectzomboid.jar')
                info['JVMOptions'].append(f'-javaagent:{agent}')
                (contents / 'Info.plist').write_bytes(plistlib.dumps(info))
                options = dict(line.split('=',1) for line in (Path.home() / 'Zomboid/options.ini').read_text().splitlines() if '=' in line)
                options.update(width='1440' if args.photos else '800', height='900' if args.photos else '600', fullScreen='false', borderless='false', frameRate='60',
                               vsync='true', texture2x='true', soundVolume='0', musicVolume='0', ambientVolume='0',
                               voiceVolume='0', focusloss='false', tutorialDone='true', showSurvivalGuide='false')
                (cache / 'options.ini').write_text('\n'.join(f'{k}={v}' for k,v in options.items())+'\n')
                if args.legacy_copy:
                    launch([str(contents / 'MacOS/JavaAppLauncher')],contents / 'Java',role)
                else:
                    launch([str(java),'-XstartOnFirstThread','-Xmx2g','-Djava.awt.headless=true',
                            '-Dapple.awt.UIElement=true','-Djava.library.path=.','-javaagent:'+str(agent),
                            '--enable-native-access=ALL-UNNAMED','--add-exports=java.base/jdk.internal.misc=ALL-UNNAMED',
                            '-Dzomboid.steam=0','-cp',f'{classes}:{GAME}:{GAME}/projectzomboid.jar',
                            'FarmPhotoMain','-nosteam',f'-cachedir={cache}'],GAME,role)
                logs.append(cache / 'console.txt')
            wait_for(['PZ_TEST_CLIENT_PASS Alice', 'PZ_TEST_CLIENT_PASS Beth', 'PZ_TEST_SERVER_PASS'] + (['PZ_TEST_PHOTOS_PASS'] if args.photos else []), 480)
            if args.photos:
                output = mod / 'workshop/screenshots'
                output.mkdir(parents=True, exist_ok=True)
                for name in json.loads((mod/'tests/photos.json').read_text()):
                    capture = root/'Alice/Screenshots'/name
                    assert capture.is_file(), 'Missing native capture: '+name
                    destination = output/(capture.stem+'.jpg')
                    # ceiling: 320 KB per native photo, reduce quality to fit the executor artifact budget.
                    for quality in (90,80,70,60,50):
                        subprocess.run(['sips','-s','format','jpeg','-s','formatOptions',str(quality),str(capture),'--out',str(destination)],check=True,capture_output=True)
                        if destination.stat().st_size <= 320_000: break
                    else: raise RuntimeError('Photo exceeds artifact budget: '+str(destination))
        finally:
            for process in reversed(processes):
                if process.poll() is None:
                    try:
                        if process is not server:
                            process.terminate()
                        process.communicate('quit\n', timeout=5)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.communicate(timeout=5)
            for handle in handles:
                handle.close()


if __name__ == '__main__':
    main()

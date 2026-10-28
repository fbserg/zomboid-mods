"""Run a mod's required checks through project-test, then validate its package and visual evidence."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import subprocess
import sys
import time
import zipfile
from static import GAME

REQUIRED = ('portable','static','native','multiplayer','persistence','performance')


def validate_gates(gates: dict, suites: dict) -> None:
    for gate in REQUIRED:
        entry=gates[gate]  # A missing requirement is an error, never a skipped pass.
        assert entry['suite'] in suites, f'Unknown {gate} suite: {entry["suite"]}'


def validate_receipt(receipt: dict, suite: str) -> None:
    assert receipt['suite']==suite and receipt['outcome']=='passed' and receipt['exit_code']==0 and receipt['cleanup'] is True, 'Test receipt is not a clean pass'


def fingerprint(mod: Path, repo: Path) -> str:
    files=[repo/'.project-tests.json',*mod.rglob('*'),*(repo/'tools').rglob('*')]
    digest=hashlib.sha256()
    for file in sorted(set(p for p in files if p.is_file() and '__pycache__' not in p.parts and p.name!='.DS_Store')):
        digest.update(str(file.relative_to(repo)).encode());digest.update(file.read_bytes())
    return digest.hexdigest()


def visual_review(mod: Path) -> None:
    review=json.loads((mod/'workshop/visual-review.json').read_text())
    assert review['scene'] and review['capture_snapshot'] and review['criteria'], 'Visual review has no evidence'
    for name,digest in review['files'].items():
        assert hashlib.sha256((mod/name).read_bytes()).hexdigest()==digest, f'Visual asset changed since review: {name}'
    info,=mod.glob('*/42/mod.info')
    panels={str((info.parent/line.partition('=')[2]).relative_to(mod)) for line in info.read_text().splitlines() if line.startswith(('icon=','poster='))}
    required={'workshop/preview.png',*panels,*review['art_sources'],*('workshop/screenshots/'+p for p in review['screenshots'])}
    assert all(review['criteria'][name] is True for name in ('feature_visible','scene_matches_benefit','no_clutter','text_readable','honest_staging')), 'Visual review did not accept every criterion'
    assert required.issubset(review['files']) and len(review['screenshots'])>=2, 'Visual review omits required assets'


def main() -> None:
    parser=argparse.ArgumentParser(__doc__)
    parser.add_argument('mod',type=Path)
    parser.add_argument('--fast',action='store_true',help='Portable and static checks only. This is not release qualification.')
    parser.add_argument('--published',action='store_true',help='Qualify the downloaded published runtime in the configured MP gate')
    args=parser.parse_args()
    assert not (args.fast and args.published),'Published qualification requires the full checks'
    repo=Path.cwd();mod=args.mod.resolve()
    policy=json.loads((mod/'tests/checks.json').read_text())
    suites=json.loads((repo/'.project-tests.json').read_text())['suites']
    gates=dict(policy['gates'])
    if args.published: gates['multiplayer']={'suite':policy['published_multiplayer_suite']}
    validate_gates(gates,suites)
    game_hash=hashlib.sha256((GAME/'projectzomboid.jar').read_bytes()).hexdigest()
    assert game_hash==policy['game_jar_sha256'],'Installed game changed. Recheck the build and update the declared engine pin.'
    stamp=fingerprint(mod,repo)
    output=repo/'output/checks'/f'{mod.name}-{time.time_ns()}'
    output.mkdir(parents=True)
    results={};completed={}
    report={'mod':mod.name,'build':policy['build'],'game_jar_sha256':game_hash,'support_limits':policy['limits'],'mode':'fast' if args.fast else ('published' if args.published else 'release'),'source_fingerprint':stamp,'gates':results,'outcome':'incomplete'}
    (output/'report.json').write_text(json.dumps(report,indent=2)+'\n')
    for gate in (('portable','static') if args.fast else REQUIRED):
        entry=gates[gate];suite=entry['suite']
        if suite not in completed:
            assert fingerprint(mod,repo)==stamp,'Source changed between check phases'
            command=['project-test']
            if suites[suite].get('platform')=='darwin': command.append('--local')
            command+=['--suite',suite]
            if 'artifact' in entry:
                command+=['--artifact',entry['artifact'],str(output/(gate+'.json'))]
            print(f'MOD_CHECK_START {gate} {suite}',flush=True)
            process=subprocess.Popen(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
            receipt_path=None
            try:
                for line in process.stdout:
                    print(line,end='',flush=True)
                    match=re.search(r'receipt (.+/result.json)',line)
                    if match: receipt_path=Path(match.group(1))
                code=process.wait()
            finally:
                if process.poll() is None:
                    process.terminate()
                    try: process.wait(timeout=60)
                    except subprocess.TimeoutExpired:
                        process.kill();process.wait(timeout=5)
            if code:
                report['outcome']='failed'
                results[gate]={'outcome':'failed','exit_code':code}
                (output/'report.json').write_text(json.dumps(report,indent=2)+'\n')
                raise SystemExit(code)
            assert receipt_path,'Executor did not return a receipt'
            receipt=json.loads(receipt_path.read_text());validate_receipt(receipt,suite)
            completed[suite]={k:receipt[k] for k in ('id','suite','executor','source_commit','commit','tree','outcome','cleanup','seconds')}
        results[gate]=completed[suite]
        (output/'report.json').write_text(json.dumps(report,indent=2)+'\n')
    assert fingerprint(mod,repo)==stamp,'Source changed during checks'
    if not args.fast:
        visual_review(mod);results['visual']={'outcome':'reviewed','evidence':'workshop/visual-review.json'}
        package=output/(policy['runtime']+'.zip')
        subprocess.run([sys.executable,str(repo/'tools/pz-test/package.py'),str(mod),str(package)],check=True,stdout=subprocess.DEVNULL)
        with zipfile.ZipFile(package) as archive:
            assert not any(Path(name).suffix in ('.java','.class','.jar','.py') for name in archive.namelist()),'Development files in runtime package'
            for name in archive.namelist():
                if name.endswith('/'): continue
                assert archive.read(name)==(mod/name).read_bytes(),f'Packaged file differs: {name}'
        subprocess.run([str(repo/'tools/pz-workshop/pz-workshop'),'validate',str(mod)],check=True)
        results['package']={'outcome':'passed','sha256':hashlib.sha256(package.read_bytes()).hexdigest()}
    report['outcome']='passed'
    (output/'report.json').write_text(json.dumps(report,indent=2)+'\n')
    print(f'MOD_CHECK_PASS {report["mode"]} {output/"report.json"}',flush=True)


if __name__=='__main__':
    main()

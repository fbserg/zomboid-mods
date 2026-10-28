"""Build the test-only hidden-window policy and audit only owned native client PIDs."""
from pathlib import Path
import subprocess
import zipfile

HERE = Path(__file__).resolve().parent
GAME = Path.home()/'Library/Application Support/Steam/steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java'


def build_policy(root: Path) -> tuple[Path, Path]:
    classes = root/'window-classes'
    classes.mkdir()
    subprocess.run(['/opt/homebrew/opt/openjdk/bin/javac','--release','25','-cp',str(GAME/'projectzomboid.jar'),
                    '-d',str(classes),str(HERE/'FocusAgent.java')],check=True)
    agent = root/'window-policy.jar'
    with zipfile.ZipFile(agent,'w') as archive:
        archive.writestr('META-INF/MANIFEST.MF','Manifest-Version: 1.0\nPremain-Class: FocusAgent\n\n')
        for file in classes.glob('FocusAgent*.class'):
            archive.write(file,file.name)
    auditor = root/'window-audit'
    subprocess.run(['swiftc',str(HERE/'window-audit.swift'),'-o',str(auditor)],check=True)
    return agent,auditor


def assert_hidden(auditor: Path, pids: list[int]) -> None:
    if pids:
        result=subprocess.run([str(auditor),*map(str,pids)],capture_output=True,text=True)
        if result.returncode:
            raise RuntimeError(result.stderr.strip() or 'OS window audit failed')

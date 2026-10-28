"""Run the four independent portable suites inside one project-test lease."""
from pathlib import Path
import subprocess
import sys

for mod in ('farm-trailer', 'truck-repaint', 'backyard-birds', 'dinner-together'):
    print(f'Portable suite: {mod}', flush=True)
    subprocess.run([sys.executable, '-m', 'unittest', 'discover', '-s',
                    str(Path('mods')/mod/'tests'), '-p', 'test_*.py', '-v'], check=True)

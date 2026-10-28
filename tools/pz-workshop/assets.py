#!/usr/bin/env python3
"""Export one selected avatar, gallery illustration and ordered native captures with macOS sips."""
from pathlib import Path
import argparse
import struct
import subprocess


def export(source: Path, destination: Path, size: int, jpeg: bool = False) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    command = ['sips', '-Z', str(size), '-s', 'format', 'jpeg' if jpeg else 'png']
    if jpeg:
        command += ['-s', 'formatOptions', '75']
    subprocess.run([*command, str(source), '--out', str(destination)], check=True, capture_output=True)


def main() -> None:
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('mod', type=Path)
    parser.add_argument('--avatar', type=Path, required=True)
    parser.add_argument('--hero', type=Path, required=True)
    parser.add_argument('--screenshots', type=Path, nargs='*', default=[])
    args = parser.parse_args()
    runtime, = [p.parent for p in args.mod.glob('*/42/mod.info')]
    raw = args.avatar.read_bytes()
    assert raw[:8] == b'\x89PNG\r\n\x1a\n', 'Avatar must be PNG'
    width, height = struct.unpack('>II', raw[16:24])
    assert width == height, 'Avatar must be square'
    sources = [args.hero, *args.screenshots]
    for source in sources:
        assert source.is_file(), source
    export(args.avatar, args.mod/'workshop/preview.png', 512)
    export(args.avatar, runtime/'icon.png', 256)
    export(args.hero, args.hero.with_suffix('.jpg'), 1280, jpeg=True)
    # The game reads multiple poster= lines in their declared order.
    for index, source in enumerate(sources):
        export(source, runtime/('poster'+('_'+str(index) if index else '')+'.png'), 1440)
    preview = args.mod/'workshop/preview.png'
    assert preview.stat().st_size < 1_000_000, 'Workshop preview exceeds 1 MB'
    for size in (128,268):
        export(args.avatar, Path('output')/args.mod.name/f'preview-{size}.png', size)
    print(f'Exported {preview}, icon, {len(sources)} posters and 128/268 pixel review copies')


if __name__ == '__main__':
    main()

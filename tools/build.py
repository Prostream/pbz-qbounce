"""Build a public mod-only release; optionally stage the loader for local use."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = '0.1.0'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--with-loader', action='store_true',
                        help='also create a full local development bundle')
    args = parser.parse_args()
    out = ROOT / 'dist'
    out.mkdir(exist_ok=True)
    public_zip = out / f'PBZ-QBounce-{VERSION}-mod-only.zip'
    # Explicit allowlist: never include logs, local receipts, music or game files.
    with zipfile.ZipFile(public_zip, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name in ('main.lua', 'bounce.lua', 'config.lua'):
            archive.write(ROOT / 'mod/Scripts' / name,
                          'PBZ_QBounce/Scripts/' + name)
        archive.write(ROOT / 'README.md', 'README.md')
    digest = hashlib.sha256(public_zip.read_bytes()).hexdigest()
    (out / 'SHA256SUMS.txt').write_text(
        f'{digest}  {public_zip.name}\n', encoding='utf-8')
    print(f'Public release: {public_zip.name} ({public_zip.stat().st_size} bytes)')

    if not args.with_loader:
        return
    loader = ROOT / 'vendor/loader'
    if not (loader / 'dwmapi.dll').is_file():
        raise SystemExit('Run python tools/fetch_sources.py first.')
    build = ROOT / 'build'
    build.mkdir(exist_ok=True)
    # Temporary data stays within this project's build directory. The bundle is
    # assembled from fresh inputs so old files cannot leak into the archive.
    with tempfile.TemporaryDirectory(prefix='qbounce-', dir=build) as temp:
        stage = Path(temp) / 'platform/steam'
        shutil.copytree(loader, stage)
        shutil.copytree(ROOT / 'mod', stage / 'ue4ss/Mods/PBZ_QBounce')
        (stage / 'ue4ss/Mods/mods.txt').write_text(
            'PBZ_QBounce : 1\nKeybinds : 1\n', encoding='utf-8')
        files = {p.relative_to(stage).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
                 for p in sorted(stage.rglob('*')) if p.is_file()}
        manifest = json.dumps(files, indent=2)
        (build / 'manifest.json').write_text(manifest, encoding='utf-8')
        # install.ps1 copies only the files listed in this fresh manifest.
        shutil.copytree(stage, build / 'platform/steam', dirs_exist_ok=True)
        with zipfile.ZipFile(out / f'PBZ-QBounce-{VERSION}-local-test.zip',
                             'w', zipfile.ZIP_DEFLATED) as archive:
            for name in files:
                archive.write(stage / name, 'build/platform/steam/' + name)
            archive.writestr('build/manifest.json', manifest)
            archive.write(ROOT / 'install.ps1', 'install.ps1')
            archive.write(ROOT / 'README.md', 'README.md')
        print(f'Local development bundle: {len(files)} loader/mod files')


if __name__ == '__main__':
    main()

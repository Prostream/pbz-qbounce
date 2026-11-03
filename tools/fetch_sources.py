"""Fetch the exact tested PBZ loader, verify SHA-256, and stage it locally."""
import hashlib
import io
from pathlib import Path
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TAG = 'v3.0.1-1183-gcdbc0b66'
NAME = f'phantombladezero_ue4ss_{TAG}.zip'
URL = f'https://github.com/KintaroModding/ue4ss/releases/download/{TAG}/{NAME}'
SHA256 = '5328f91d13bd93f080fafae9e7c07790ae838d65e94545831d6676c4c1870d4d'


def main():
    dest = ROOT / 'vendor'
    dest.mkdir(exist_ok=True)
    cached = dest / NAME
    if cached.is_file():
        data = cached.read_bytes()
    else:
        request = urllib.request.Request(URL, headers={'User-Agent': 'PBZ-QBounce'})
        with urllib.request.urlopen(request, timeout=60) as response:
            data = response.read()
    if hashlib.sha256(data).hexdigest() != SHA256:
        raise SystemExit('Loader SHA-256 mismatch; no files extracted.')
    target = dest / 'loader'
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        for name in archive.namelist():
            if not (target / name).resolve().is_relative_to(target.resolve()):
                raise ValueError('Unsafe archive path')
        archive.extractall(target)
    cached.write_bytes(data)
    print(f'Verified and extracted {NAME}; no downloaded code was executed.')


if __name__ == '__main__':
    main()

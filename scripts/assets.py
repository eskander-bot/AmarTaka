"""Bundle openly licensed Noto Sans Bengali at build time; no runtime download."""
import hashlib
from pathlib import Path
import urllib.request

assets = Path(__file__).resolve().parents[1] / '.build/amartaka/assets/fonts'
assets.mkdir(parents=True,exist_ok=True)
noto = 'https://raw.githubusercontent.com/notofonts/notofonts.github.io/main/fonts/NotoSansBengali/full/ttf/'
blobs = {
    'NotoSansBengali-Regular.ttf':(noto,'2545f7208995d4adbe24e51d26c75082bedf2e2a'),
    'NotoSansBengali-Medium.ttf':(noto,'f52ccdd96492ad1b13af79f1219e5d301f6cea96'),
    'NotoSansBengali-SemiBold.ttf':(noto,'d9139b7e16e26fc540fe23ed0a94d245ec5e0c5d'),
    'NotoSansBengali-Bold.ttf':(noto,'e1bea1d2a96e0f16f7d9092d4a3ce1f392d58959'),
    'OFL.txt':('https://raw.githubusercontent.com/google/fonts/main/ofl/notosansbengali/','d11cac69316ec3d80e5aff86e4a2dba4114cca2b'),
}
for name, (base, expected) in blobs.items():
    path = assets / name
    data = path.read_bytes() if path.exists() else urllib.request.urlopen(base+name,timeout=60).read()
    digest = hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
    if digest != expected:
        raise SystemExit('Font content changed; review upstream before updating the pinned hash: '+name)
    path.write_bytes(data)
print('Verified Noto Sans Bengali fonts and OFL license are bundled for offline use.')

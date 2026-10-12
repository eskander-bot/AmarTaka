"""Bundle openly licensed Bengali fonts at build time; no runtime download."""
import hashlib
from pathlib import Path
import urllib.request

assets = Path(__file__).resolve().parents[1] / '.build/amartaka/assets/fonts'
assets.mkdir(parents=True,exist_ok=True)
blobs = {
    'HindSiliguri-Regular.ttf':'21f6ec51cace61d40644d275e66b6a82f57906a3',
    'HindSiliguri-SemiBold.ttf':'ec9a3602dd901e480bc9d7c196a6205484c1629d',
    'OFL.txt':'ccd22d7afee4a45d0007489e9232ed51fb3c3f4a',
}
for name, expected in blobs.items():
    path = assets / name
    data = path.read_bytes() if path.exists() else urllib.request.urlopen('https://raw.githubusercontent.com/google/fonts/main/ofl/hindsiliguri/'+name,timeout=60).read()
    digest = hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
    if digest != expected:
        raise SystemExit('Font content changed; review upstream before updating the pinned hash: '+name)
    path.write_bytes(data)
print('Verified Hind Siliguri fonts and OFL license are bundled for offline use.')

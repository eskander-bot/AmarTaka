"""Restore the owner's permanent signing key; never generate a fallback key."""
import base64
import hashlib
import os
from pathlib import Path
import re
import subprocess
import sys

android = Path(__file__).resolve().parents[1] / '.build/amartaka/android'
keystore = android / 'app/upload.jks'
properties = android / 'key.properties'
fingerprint = android / 'signing-cert.sha256'

def clean():
    for path in (keystore, properties, fingerprint):
        path.unlink(missing_ok=True)

def escape(text):
    # Java Properties uses UTF-16 code units, including surrogate pairs.
    units = text.encode('utf-16-be')
    return ''.join(chr(n) if 33 <= n <= 126 and chr(n) not in '\\:=#!'
                   else '\\u%04x' % n
                   for n in (int.from_bytes(units[i:i+2], 'big') for i in range(0, len(units), 2)))

if '--clean' in sys.argv:
    clean()
    raise SystemExit

if '--verify-apk' in sys.argv:
    index = sys.argv.index('--verify-apk')
    apk = Path(sys.argv[index+1])
    sdk = os.environ.get('ANDROID_SDK_ROOT') or os.environ.get('ANDROID_HOME')
    candidates = list((Path(sdk) / 'build-tools').glob('*/apksigner')) if sdk else []
    if not candidates or not fingerprint.exists():
        raise SystemExit('Cannot verify APK certificate; refusing to publish artifact.')
    signer = max(candidates, key=lambda p: tuple(int(n) for n in re.findall(r'\d+', p.parent.name)))
    result = subprocess.run([str(signer), 'verify', '--print-certs', str(apk)], capture_output=True, text=True)
    certs = re.findall(r'Signer #\d+ certificate SHA-256 digest: ([0-9a-fA-F]+)', result.stdout)
    expected = fingerprint.read_text().strip()
        if result.returncode or [c.lower() for c in certs] != [expected]:
        print('Verifier:', signer, flush=True)
        print('Exit code:', result.returncode, flush=True)
        print('Expected certificate:', expected, flush=True)
        print('Detected certificates:', certs, flush=True)
        print('Details:', result.stdout, flush=True)
        print('Errors:', result.stderr, flush=True)
        raise SystemExit('Certificate check failed; see details above.')
    print('Verified permanent signing certificate SHA-256:', expected)
    raise SystemExit

names = ['KEYSTORE_BASE64', 'STORE_PASSWORD', 'KEY_ALIAS', 'KEY_PASSWORD']
if any(not os.environ.get(n) for n in names):
    clean()
    raise SystemExit('Missing Android signing secrets; refusing to build an installable APK/AAB.')
try:
    data = base64.b64decode(''.join(os.environ['KEYSTORE_BASE64'].split()), validate=True)
    if not data:
        raise ValueError('empty key')
    keystore.parent.mkdir(parents=True, exist_ok=True)
    clean()
    fd = os.open(keystore, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'wb') as out:
        out.write(data)
    # Only the public certificate is returned; passwords are passed via env.
    result = subprocess.run(['keytool', '-exportcert', '-keystore', str(keystore),
        '-alias', os.environ['KEY_ALIAS'], '-storepass:env', 'STORE_PASSWORD'], capture_output=True)
    if result.returncode or not result.stdout:
        raise ValueError('invalid keystore/password/alias')
    digest = hashlib.sha256(result.stdout).hexdigest()
    content = 'storeFile=upload.jks\n' + '\n'.join(k+'='+escape(os.environ[v]) for k,v in [
        ('storePassword','STORE_PASSWORD'), ('keyAlias','KEY_ALIAS'), ('keyPassword','KEY_PASSWORD')])+'\n'
    fd = os.open(properties, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as out:
        out.write(content)
    fingerprint.write_text(digest+'\n')
    print('Permanent key restored. Certificate SHA-256:', digest)
except Exception:
    clean()
    raise SystemExit('Signing setup failed. Check keystore Base64, alias and passwords; no fallback key will be used.') from None

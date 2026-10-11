"""Decode an owner-provided upload key, never generate/commit credentials."""
import base64
import os
from pathlib import Path
import sys

android = Path(__file__).resolve().parents[1] / '.build/amartaka/android'
keystore = android / 'app/upload.jks'
properties = android / 'key.properties'
if '--clean' in sys.argv:
    keystore.unlink(missing_ok=True)
    properties.unlink(missing_ok=True)
    raise SystemExit
names = ['KEYSTORE_BASE64','STORE_PASSWORD','KEY_ALIAS','KEY_PASSWORD']
if any(not os.environ.get(n) for n in names):
    raise SystemExit('Missing Android signing secrets; refusing to make a release bundle.')
# Java .properties escaping, including punctuation and Unicode.
def escape(text):
    return ''.join('\\u%04x' % ord(c) if ord(c) > 126 or c in '\\:=#! \n\r\t' else c for c in text)
keystore.write_bytes(base64.b64decode(os.environ[names[0]], validate=True))
properties.write_text('storeFile=upload.jks\n' + '\n'.join(k+'='+escape(os.environ[v]) for k,v in [('storePassword','STORE_PASSWORD'),('keyAlias','KEY_ALIAS'),('keyPassword','KEY_PASSWORD')])+'\n')
keystore.chmod(0o600)
properties.chmod(0o600)

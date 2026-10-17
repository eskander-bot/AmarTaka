"""Host-side checks runnable without Flutter; these do not compile Dart/Android."""
from pathlib import Path
import os
import runpy
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]

class BuildConfigTest(unittest.TestCase):
    def test_generated_manifest_signing_and_source_copy(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            shutil.copytree(ROOT / 'scripts', root / 'scripts')
            shutil.copytree(ROOT / 'source', root / 'source')
            shutil.copytree(ROOT / 'icons', root / 'icons')
            app = root / '.build/amartaka'
            def fake_flutter(args, **kwargs):
                self.assertIn('--no-pub', args)
                (app / 'android/app/src/main/kotlin/com/meskander/amartaka').mkdir(parents=True)
                (app / 'android/app/src/main/res').mkdir()
                (app / 'android/app/build.gradle.kts').write_text('''plugins { id("com.android.application") }
android {
compileSdk = flutter.compileSdkVersion
compileOptions { sourceCompatibility = JavaVersion.VERSION_11 }
defaultConfig { minSdk = flutter.minSdkVersion; targetSdk = flutter.targetSdkVersion }
buildTypes { release { signingConfig = signingConfigs.getByName("debug") } }
}''')
            with patch('subprocess.run', side_effect=fake_flutter):
                runpy.run_path(str(root / 'scripts/bootstrap.py'))
            res = app / 'android/app/src/main/res'
            self.assertEqual((res / 'drawable-nodpi/amar_taka_logo.png').read_bytes(), (root / 'icons/app_logo.png').read_bytes())
            adaptive = ET.parse(res / 'mipmap-anydpi-v26/ic_launcher.xml').getroot()
            android_ns = '{http://schemas.android.com/apk/res/android}'
            self.assertEqual(adaptive.find('foreground').get(android_ns+'drawable'), '@drawable/amar_taka_icon_foreground')
            foreground = ET.parse(res / 'drawable/amar_taka_icon_foreground.xml').getroot()
            inset = foreground.find('item/inset')
            for side in ('Left', 'Top', 'Right', 'Bottom'):
                self.assertEqual(inset.get(android_ns+'inset'+side), '18%')
            self.assertFalse(list(res.glob('mipmap-*/ic_launcher_foreground.png')))
            gradle = (app / 'android/app/build.gradle.kts').read_text()
            self.assertIn('targetSdk = 36', gradle)
            self.assertIn('compileSdk = 36', gradle)
            self.assertIn('else null', gradle)
            self.assertNotIn('signingConfigs.getByName("debug")', gradle)
            self.assertIn('applicationIdSuffix = ".preview"', gradle)
            self.assertIn('JavaVersion.VERSION_17', gradle)
            for path in (app / 'android/app/src/main/res').rglob('*.xml'):
                ET.parse(path)
            manifest = ET.parse(app / 'android/app/src/main/AndroidManifest.xml').getroot()
            android = '{http://schemas.android.com/apk/res/android}'
            tools = '{http://schemas.android.com/tools}'
            self.assertEqual(manifest.find('application').get(android+'allowBackup'), 'false')
            permission = next(p for p in manifest.findall('uses-permission') if p.get(android+'name') == 'android.permission.INTERNET')
            self.assertEqual(permission.get(tools+'node'), 'remove')
            self.assertEqual((app / 'lib/main.dart').read_bytes(), (root / 'source/lib/main.dart').read_bytes())

    def test_release_signing_fails_closed_without_secrets(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / 'scripts').mkdir()
            shutil.copy2(ROOT / 'scripts/signing.py', root / 'scripts/signing.py')
            env = {k:v for k,v in os.environ.items() if k not in ['KEYSTORE_BASE64','STORE_PASSWORD','KEY_ALIAS','KEY_PASSWORD']}
            result = subprocess.run(['python3',str(root / 'scripts/signing.py')],env=env,capture_output=True,text=True)
            self.assertNotEqual(result.returncode,0)
            self.assertIn('refusing',result.stderr)
            self.assertFalse(list(root.rglob('*.jks')))

    def test_sql_migration_statements_preserve_fractional_records(self):
        import re
        import sqlite3
        source = (ROOT / 'source/lib/database/db_helper.dart').read_text()
        migration = source.split('static Future<void> upgrade')[1].split('static Future<void> _features')[0]
        statements = re.findall(r"await d.execute\('([^']*)'\);", migration)
        self.assertEqual(len(statements),4)
        db = sqlite3.connect(':memory:')
        db.execute('CREATE TABLE transactions(id INTEGER PRIMARY KEY, amount REAL, category TEXT, note TEXT, date TEXT, type TEXT)')
        db.execute('INSERT INTO transactions VALUES(42,125.50,"Bazar",NULL,"2026-10-11","expense")')
        for sql in statements:
            db.execute(sql)
        self.assertEqual(db.execute('SELECT id,amount_minor,note FROM transactions').fetchone(),(42,12550,''))
        db.close()

if __name__ == '__main__':
    unittest.main()

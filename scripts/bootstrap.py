#!/usr/bin/env python3
"""Create the pinned Flutter Android shell without overwriting source files."""
from pathlib import Path
import shutil
import subprocess

root = Path(__file__).resolve().parents[1]
app = root / '.build' / 'amartaka'
app.mkdir(parents=True, exist_ok=True)
subprocess.run(['flutter', 'create', '--no-pub', '--empty', '--org', 'com.meskander', '--project-name', 'amartaka', '--platforms', 'android', str(app)], check=True)
for folder in ['lib', 'test']:
    shutil.rmtree(app / folder, ignore_errors=True)
    shutil.copytree(root / 'source' / folder, app / folder)
shutil.copy2(root / 'source' / 'pubspec.yaml', app / 'pubspec.yaml')
(app / 'analysis_options.yaml').write_text('analyzer:\n  errors:\n    deprecated_member_use: ignore\n')
lock = root / 'source' / 'pubspec.lock'
if lock.exists():
    shutil.copy2(lock, app / 'pubspec.lock')

gradle = app / 'android/app/build.gradle.kts'
s = gradle.read_text()
s = 'import java.util.Properties\nimport java.io.FileInputStream\n' + s
s = s.replace('android {', '''val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) keyProperties.load(FileInputStream(keyPropertiesFile))

android {''', 1)
s = s.replace('compileSdk = flutter.compileSdkVersion', 'compileSdk = 36')
s = s.replace('targetSdk = flutter.targetSdkVersion', 'targetSdk = 36')
s = s.replace('minSdk = flutter.minSdkVersion', 'minSdk = 24')
s = s.replace('JavaVersion.VERSION_11', 'JavaVersion.VERSION_17')
s = s.replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true')
s = s.replace('buildTypes {', '''signingConfigs {
        if (keyPropertiesFile.exists()) {
            create("upload") {
                keyAlias = keyProperties["keyAlias"] as String
                keyPassword = keyProperties["keyPassword"] as String
                storeFile = file(keyProperties["storeFile"] as String)
                storePassword = keyProperties["storePassword"] as String
            }
        }
    }
    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".preview"
            signingConfig = if (keyPropertiesFile.exists()) signingConfigs.getByName("upload") else null
        }
''')
s = s.replace('signingConfig = signingConfigs.getByName("debug")', 'signingConfig = if (keyPropertiesFile.exists()) signingConfigs.getByName("upload") else null')
s += '\ndependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }\n'
gradle.write_text(s)
main = app / 'android/app/src/main'
(main / 'AndroidManifest.xml').write_text('''<manifest xmlns:android="http://schemas.android.com/apk/res/android" xmlns:tools="http://schemas.android.com/tools">
    <uses-permission android:name="android.permission.INTERNET" tools:node="remove"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <application android:label="Amar Taka" android:name="${applicationName}" android:icon="@mipmap/ic_launcher"
        android:allowBackup="false" android:fullBackupContent="false" android:dataExtractionRules="@xml/data_extraction_rules">
        <activity android:name=".MainActivity" android:exported="true" android:launchMode="singleTop" android:taskAffinity=""
            android:theme="@style/LaunchTheme" android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true" android:windowSoftInputMode="adjustResize">
            <meta-data android:name="io.flutter.embedding.android.NormalTheme" android:resource="@style/NormalTheme"/>
            <intent-filter><action android:name="android.intent.action.MAIN"/><category android:name="android.intent.category.LAUNCHER"/></intent-filter>
        </activity>
        <meta-data android:name="flutterEmbedding" android:value="2"/>
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter><action android:name="android.intent.action.BOOT_COMPLETED"/><action android:name="android.intent.action.MY_PACKAGE_REPLACED"/><action android:name="android.intent.action.QUICKBOOT_POWERON"/><action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/></intent-filter>
        </receiver>
    </application>
    <queries><intent><action android:name="android.intent.action.PROCESS_TEXT"/><data android:mimeType="text/plain"/></intent></queries>
</manifest>''')
res = main / 'res'
(res / 'xml').mkdir(exist_ok=True)
(res / 'xml/data_extraction_rules.xml').write_text('''<data-extraction-rules><cloud-backup><exclude domain="root" path="."/><exclude domain="database" path="."/><exclude domain="sharedpref" path="."/><exclude domain="file" path="."/></cloud-backup><device-transfer><exclude domain="root" path="."/><exclude domain="database" path="."/><exclude domain="sharedpref" path="."/><exclude domain="file" path="."/></device-transfer></data-extraction-rules>''')
(res / 'drawable').mkdir(exist_ok=True)
(res / 'drawable/ic_stat_taka.xml').write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp" android:viewportWidth="24" android:viewportHeight="24"><path android:fillColor="#FFFFFFFF" android:pathData="M3,5h18v14H3z M15,9v6h6V9z" android:fillType="evenOdd"/></vector>''')
# Reuse the clean original logo, not the damaged foreground PNGs.
# Keep the full logo tile inside the adaptive viewport with 18% padding.
# Bitmap gravity="fill" scales correctly at every screen density.
logo = root / 'icons/app_logo.png'
if not logo.is_file():
    raise SystemExit('Missing icons/app_logo.png; keep the original logo file.')
for folder in res.glob('mipmap-*'):
    for name in ('ic_launcher.png', 'ic_launcher_foreground.png', 'ic_launcher_background.png', 'ic_launcher.xml', 'ic_launcher_round.xml'):
        (folder / name).unlink(missing_ok=True)
(res / 'drawable-nodpi').mkdir(exist_ok=True)
shutil.copy2(logo, res / 'drawable-nodpi/amar_taka_logo.png')
(res / 'drawable/amar_taka_icon_background.xml').write_text('''<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
    <gradient android:startColor="#20B992" android:endColor="#075542" android:angle="315"/>
</shape>''')
(res / 'drawable/amar_taka_icon_foreground.xml').write_text('''<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <inset android:insetLeft="18%" android:insetTop="18%" android:insetRight="18%" android:insetBottom="18%">
            <bitmap android:src="@drawable/amar_taka_logo" android:gravity="fill" android:filter="true"/>
        </inset>
    </item>
</layer-list>''')
# Android 7 uses the original full icon without adaptive zoom.
(res / 'mipmap-anydpi').mkdir(exist_ok=True)
(res / 'mipmap-anydpi/ic_launcher.xml').write_text('''<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <inset android:insetLeft="2dp" android:insetTop="2dp" android:insetRight="2dp" android:insetBottom="2dp">
            <bitmap android:src="@drawable/amar_taka_logo" android:gravity="fill" android:filter="true"/>
        </inset>
    </item>
</layer-list>''')
(res / 'mipmap-anydpi-v26').mkdir(exist_ok=True)
(res / 'mipmap-anydpi-v26/ic_launcher.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/amar_taka_icon_background"/>
    <foreground android:drawable="@drawable/amar_taka_icon_foreground"/>
</adaptive-icon>''')
# In-app logo (lock screen), listed under assets in pubspec.yaml.
logo = root / 'icons' / 'app_logo.png'
if logo.exists():
    (app / 'assets/logo').mkdir(parents=True, exist_ok=True)
    shutil.copy2(logo, app / 'assets/logo/app_logo.png')
activity = main / 'kotlin/com/meskander/amartaka/MainActivity.kt'
activity.write_text('''package com.meskander.amartaka
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
class MainActivity: FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Screenshots and screen recording are allowed.
    }
}
''')
# local_auth requires an AppCompat launch theme on Android 8 and earlier.
for style in res.glob('values*/styles.xml'):
    value = style.read_text().replace('@android:style/Theme.Light.NoTitleBar', 'Theme.AppCompat.DayNight.NoActionBar').replace('@android:style/Theme.Black.NoTitleBar', 'Theme.AppCompat.DayNight.NoActionBar')
    style.write_text(value)
print('Project ready:', app)

# A separate test package keeps the user's existing installation/data untouched.
debug_manifest = app / 'android/app/src/debug/AndroidManifest.xml'
debug_manifest.parent.mkdir(parents=True,exist_ok=True)
debug_manifest.write_text('<manifest xmlns:android="http://schemas.android.com/apk/res/android" xmlns:tools="http://schemas.android.com/tools"><application android:label="Amar Taka Preview" tools:replace="android:label"/></manifest>')

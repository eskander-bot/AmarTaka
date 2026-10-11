# Amar Taka — by MEskander

An independently implemented, Bangla-first Android personal ledger. Flutter + on-device SQLite. No login, server, banking integration or analytics.

This branch is a **development build**, not a Play Store release. See `docs/RELEASE.md` for remaining device checks and publishing requirements.

## Implemented

- Income/expense creation, edit, delete, custom categories, date, note, monthly search/filter.
- Exact integer-paisa accounting, Bangla decimal input/display, version-1 database migration.
- All-record balance, monthly totals, monthly budgets and overspending indication.
- Savings/wishlist goals with manually recorded progress (not linked ledger transfers).
- Expense category proportions, six-month comparisons and last-seven-day totals.
- Notebook with create, edit and delete.
- Persistent system/light/dark/AMOLED themes.
- Six-digit app PIN, PBKDF2 hashing and Android secure storage; locks on background.
- Daily or first-of-month reminders at a chosen **Bangladesh time** (inexact scheduling).
- Validated, atomic JSON backup/restore; CSV transaction report export.
- Independent vector launcher icon and original cream/forest interface.

PIN controls UI access; it is **not database encryption**. Exported backups are plaintext and exclude the PIN and settings. There is no PIN recovery. App uninstall removes local records. Android cloud/device backup is disabled; keep your own JSON backups.

## Run locally (Windows, macOS or Linux)

Install Flutter **3.35.7**, Android Studio/SDK and Java 17. Android SDK 36 is required; Android 7+ devices are supported by this configuration.

```sh
flutter doctor
python scripts/bootstrap.py
cd .build/amartaka
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter run
```

On Windows use `py scripts/bootstrap.py` if `python` is unavailable.

Edit **source/lib/**, not the generated `.build/amartaka/lib/`. Re-run bootstrap after source changes. App code uses Dart: the variables, conditions, functions and classes will feel familiar from PHP/JS, while widgets and async state are the main new concepts.

## APK through GitHub

Pushes on `main` or `codex/**` and pull requests run analysis, tests and debug APK build. Download the **Amar-Taka-test-APK** artifact from the successful Actions run. Extract its ZIP and install `app-debug.apk` on your test phone. This is not a store-signed release.

Dependency versions are pinned directly in `source/pubspec.yaml`. The build artifact includes the resolved `pubspec.lock`; check it into `source/` after the first successful build to also lock transitive versions.

The earlier workflow rebuilt a release with a disposable debug signing key. Android may refuse an in-place update if that APK's signing key differs. **Do not uninstall a copy containing important data.** Export or migrate its database before changing signing keys.

## Project map

| Folder | Responsibility |
|---|---|
| source/lib/models | Transaction data |
| source/lib/database | SQLite and schema migration |
| source/lib/screens | Bangla screens and validation |
| source/lib/services | Backup, PIN and reminders |
| source/lib/utils | Exact money/date formatting |
| source/test | Money, migration, backup and widget checks |
| scripts | Android generation and explicit signing |

## Independent implementation

The public TakaTrack store feature list was used as a functional reference only. No TakaTrack source, binary, logo, screenshot, text assets or other resources are included. The work extends MEskander's existing repository and uses licensed Flutter/open-source dependencies; it is not a claim that all dependencies were authored here. In-app open-source licenses remain available.

Functional parity with unobserved TakaTrack behavior is not established. CSV is a report, not a restorable full backup. Reminders currently offer daily or the first day of each month, in Bangladesh time only.

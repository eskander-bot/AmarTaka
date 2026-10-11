# Release preparation

Status: development implementation; device validation and owner-controlled release signing remain required. Do not claim Play approval or complete reference-app parity.

## Validate before release

- Run the Actions analysis/tests/build. Download the resolved pubspec.lock and commit to source/.
- Install the test APK on a physical Android phone. Use airplane mode to create/edit/delete records, restart the app and verify persistence.
- Test on a small screen, large text, light/dark themes and Bengali keyboards. Check Bengali font shaping on the actual phone.
- Upgrade a v1 database without uninstalling; verify IDs, totals, fractional money and notes.
- Export a JSON backup, restore it, and compare all transactions/categories/budgets/goals/notes. Reject truncated/foreign files without losing current data. Verify cancelled pickers do not change records. CSV is export-only.
- Test PIN creation/confirmation, restart/background lock, wrong-PIN throttling, removing PIN and secure-storage failures. A PIN is not encryption; rooted devices are out of scope. Production blocks screenshots/app-switcher snapshots.
- Test daily/monthly reminders with permission allowed/denied, reboot and app update. Inexact Android schedules may be delayed; force-stopped apps cannot guarantee reminders. Schedule labels explicitly use UTC+6.
- Test generated native libraries on a 16 KB page-size Android emulator/device and run Play pre-launch reports. A debug build is not proof of release compatibility.

## Signed AAB

Package identity remains `com.meskander.amartaka`. Keep the same upload key for future releases and keep its offline backup. Keys/passwords never belong in source control.

Owner creates an upload keystore and sets repository Actions secrets:

- `ANDROID_KEYSTORE_BASE64` — base64 encoded keystore
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Run workflow manually with `play_bundle=true`. It refuses to create the release bundle if secrets are absent. The resulting artifact is `Amar-Taka-Play-AAB`. Nothing auto-uploads to Play and nothing auto-publishes a GitHub Release. Build numbers use GitHub run numbers; verify each upload exceeds the last Play versionCode.

The Android configuration targets API 36. Google's current official requirement (checked 2026-10-11) is API 36 for new mobile apps/updates from 2026-08-31: https://support.google.com/googleplay/android-developer/answer/11926878?hl=en . Recheck at submission time.

Complete the Play Console developer account, app access/declarations, applicable testing requirements, Data safety answers, privacy policy URL, support contact, icon, feature graphic and genuine screenshots. Test a store-signed internal build before production. Approval is Google's decision.

## Privacy policy text — owner review needed

Amar Taka by MEskander keeps income, expenses, budgets, goals and notes on the user's phone. This build contains no server integration, advertising or analytics. It does not link to bank accounts. Notification permission is used only for user-selected local reminders. Users may export data to a location they choose via Android's system picker. Exported files are not encrypted by the app. If users select a cloud document provider, that provider handles the chosen file under its own terms. PIN credentials are stored through Android secure storage; financial records use the app's local SQLite database. Uninstalling removes local app records; externally saved backups remain until the user deletes them.

Before publishing this text: add the owner's support email, effective date and public policy URL. Confirm final dependency/runtime behavior before answering Data safety. Do not substitute the app's current draft text for a completed Play review.

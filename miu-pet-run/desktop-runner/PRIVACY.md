# 猫小伴 Privacy Notes

猫小伴 is a local desktop companion for macOS.

Local signals used:

- Frontmost app name and bundle identifier.
- Front window geometry from macOS window metadata.
- User idle time from macOS event timing.
- Current screen visible frame, used for Dock/menu bar/window avoidance.

Local data stored:

- Settings: `~/Library/Application Support/MaoXiaoBan/settings.json`
- Reminder config and history: `~/Library/Application Support/MaoXiaoBan/reminders.json`
- App classification overrides: `~/Library/Application Support/MaoXiaoBan/app-classifications.json`

Not collected:

- No screen image capture.
- No file content reading.
- No keyboard input content.
- No network upload.
- No analytics.

Notes:

- Legacy data from `~/Library/Application Support/Miu` is copied into the new folder on first launch if the new folder does not exist.
- Users can reset settings from the app settings window.

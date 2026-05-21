# 猫小伴 Uninstall

Quit the app:

```bash
miu-pet-run/desktop-runner/stop-miu.sh
```

Remove the app:

```bash
rm -rf /Applications/猫小伴.app
```

Optional: remove local data:

```bash
rm -rf "$HOME/Library/Application Support/MaoXiaoBan"
```

Optional: remove legacy Miu data:

```bash
rm -rf "$HOME/Library/Application Support/Miu"
```

Notes:

- Removing local data deletes settings, reminder history, and custom app classification rules.
- If Launch at Login was enabled, turn it off in 猫小伴 settings before uninstalling when possible.
- If the app has already been removed, also check System Settings -> General -> Login Items and remove stale 猫小伴 entries if any remain.
- Before reporting uninstall or upgrade issues, check the settings overview version so the test build can be identified accurately.

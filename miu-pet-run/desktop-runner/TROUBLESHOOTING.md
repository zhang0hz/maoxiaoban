# 猫小伴 Troubleshooting

猫小伴 does not appear:

- Check the menu bar for `猫小伴`.
- Quit and reopen `/Applications/猫小伴.app`.
- Reset position from the menu bar item if the pet was dragged off to another display.

猫小伴 disappears during work:

- This is expected for fullscreen or presentation-sized windows.
- 猫小伴 hides to avoid covering active work.

Reminders do not show immediately:

- Fullscreen and quiet work states defer reminders.
- Deferred reminders replay when the blocked state clears.

Settings look old after upgrade:

- New data is stored in `~/Library/Application Support/MaoXiaoBan`.
- Legacy data is copied from `~/Library/Application Support/Miu` only if the new folder does not already exist.

Public release cannot open:

- Public builds must be signed with Developer ID and notarized.
- Local development builds use ad-hoc signing and may not pass Gatekeeper on another Mac.

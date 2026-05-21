# 猫小伴 Installation

Recommended package:

```text
猫小伴.dmg
```

Install:

1. Open `猫小伴.dmg`.
2. Drag `猫小伴.app` into `Applications`.
3. Open `Applications/猫小伴.app`.
4. If Gatekeeper blocks first launch before Developer ID signing and notarization are complete, open System Settings -> Privacy & Security and approve the app explicitly.

Public releases should be signed with Developer ID and notarized so the Gatekeeper approval step is normally unnecessary.

Local development install:

```bash
miu-pet-run/desktop-runner/install-to-applications.sh
```

Data directory:

```text
~/Library/Application Support/MaoXiaoBan
```

Upgrade from Miu:

- The installer removes old `/Applications/Miu.app`.
- On first launch, 猫小伴 copies legacy data from `~/Library/Application Support/Miu` into `~/Library/Application Support/MaoXiaoBan` if the new folder does not exist.

# 猫小伴 V1.0 Release Checklist

Product:

- [x] Product name finalized: 猫小伴
- [x] Bundle ID set: `com.zhanghz.maoxiaoban`
- [x] Version set: `1.0.0`
- [x] Build set: `100`
- [x] App icon added
- [ ] User screenshots prepared

Build:

- [x] Build `猫小伴.app`
- [x] Build `猫小伴.zip`
- [x] Install to `/Applications/猫小伴.app`
- [x] Build `猫小伴.dmg`

Signing:

- [ ] Developer ID Application certificate available
- [x] Hardened Runtime enabled during signing script
- [x] Local ad-hoc `codesign --verify` passes
- [ ] Developer ID `codesign --verify` passes
- [ ] `spctl --assess` passes
- [ ] Apple notarization succeeds
- [ ] Stapled ticket verified

QA:

- [ ] Clean install
- [ ] Upgrade from old `Miu.app`
- [ ] Legacy data migration
- [ ] Login-at-start toggle
- [ ] Reminder queue
- [ ] Work/leisure/night behavior
- [ ] Drag/pin/reset position
- [ ] Multi-display placement
- [ ] Uninstall notes verified

Docs:

- [x] Privacy notes
- [x] Release signing script notes
- [x] User installation guide
- [x] Uninstall guide
- [x] Troubleshooting guide

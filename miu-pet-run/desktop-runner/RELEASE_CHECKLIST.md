# 猫小伴 V1.0 Release Checklist

Product:

- [x] Product name finalized: 猫小伴
- [x] Bundle ID set: `com.zhanghz.maoxiaoban`
- [x] Version set: `1.0.1`
- [x] Build set: `101`
- [x] Settings overview displays version and build information from `Info.plist`
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
- [ ] Developer ID release handoff completed with `release.env`

QA:

- [x] Smoke test script available: `smoke-test.sh`
- [x] Roadmap static checks included in smoke test
- [x] App bundle build passes
- [x] Behavior-layer tests pass
- [x] Color audit passes
- [x] Shell script syntax passes
- [x] Python helper compile passes
- [x] Dist app verification passes with ad-hoc signature
- [ ] Clean install manual pass
- [ ] Upgrade from old `Miu.app` manual pass
- [ ] Legacy data migration manual pass
- [ ] Login-at-start toggle manual pass
- [ ] Reminder queue manual pass
- [ ] Work/leisure/night behavior manual pass
- [ ] Drag/pin/reset position manual pass
- [ ] Multi-display placement manual pass
- [ ] Uninstall notes manual pass

Docs:

- [x] Privacy notes
- [x] Release signing script notes
- [x] User installation guide
- [x] Uninstall guide
- [x] Troubleshooting guide
- [x] V1.0 experience QA guide
- [x] V1.3 distribution readiness handoff
- [x] Internal GitHub upload notes documented for unstable terminal network

GitHub Release:

- [ ] Create release tag after final signed build
- [ ] Upload `猫小伴.dmg`
- [ ] Upload `猫小伴.zip`
- [ ] Include install, uninstall, privacy, and troubleshooting links
- [ ] Mark release notes with Developer ID / notarization status
- [ ] If terminal network is unstable, publish code through GitHub Desktop first, then push tags later with `git push origin --tags`

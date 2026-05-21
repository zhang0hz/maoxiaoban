# GitHub Release Draft

Use this draft when publishing the next internal or public package.

## Title

猫小伴 v1.0.1 Internal

## Summary

猫小伴是本地运行的 macOS 桌面宠物。本版本以内部测试为主，重点收口行为安静度、视觉动作自然度、设置体验、安装和分发说明。

## Package

Upload:

- `miu-pet-run/dist/猫小伴.dmg`
- `miu-pet-run/dist/猫小伴.zip`

## Install

1. Download `猫小伴.dmg`.
2. Open the DMG and drag `猫小伴.app` into Applications.
3. If macOS blocks the first launch for an internal build, approve it in System Settings -> Privacy & Security.

## Notes

- Internal builds may use ad-hoc signing.
- Developer ID signing and notarization are required before public distribution.
- Version and build number are visible in the settings overview.

## Verification Before Release

Run locally before uploading packages:

```bash
miu-pet-run/desktop-runner/smoke-test.sh
miu-pet-run/desktop-runner/build-release.sh
miu-pet-run/desktop-runner/verify-release.sh miu-pet-run/dist/猫小伴.app
miu-pet-run/desktop-runner/verify-dmg.sh miu-pet-run/dist/猫小伴.dmg
```

## GitHub Upload

When terminal Git cannot reach GitHub, use GitHub Desktop to push `main`. After the network is stable, push local tags:

```bash
git push origin --tags
```

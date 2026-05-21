# 猫小伴

猫小伴是一个 macOS 桌面电子宠物 App。它以蓝双布偶猫为原型，会根据北京时间、前台应用、窗口覆盖率和用户空闲状态，选择安静陪伴、睡觉、散步、提醒等行为。

## 当前能力

- macOS 原生桌面浮窗。
- 可拖动、右键菜单、菜单栏控制。
- 自动贴边和窗口避让，尽量不挡工作窗口。
- 工作 / 休闲 / 睡觉 / 空闲状态判断。
- 前台应用分类，可手动覆盖工作、休闲、沟通/会议、中性。
- 喝水、休息、久坐、睡觉提醒。
- 提醒气泡支持完成、稍后、跳过、关闭。
- 设置持久化和登录时启动开关。
- 行为调试面板，可查看状态机、动作、窗口覆盖率、提醒队列等内部状态。
- 独立 App、zip、DMG 打包脚本。

## 目录

```text
miu-pet-run/
  desktop-runner/      macOS 原生运行器、设置页、打包脚本
  behavior-layer/      行为层测试和早期行为逻辑说明
  phase1-actions/      宠物动作帧和视觉资产
  prompts/             早期宠物资产生成提示词
```

## 构建

构建本地 App：

```bash
miu-pet-run/desktop-runner/build-app.sh
```

构建发布版 App 和 zip：

```bash
miu-pet-run/desktop-runner/build-dist.sh
```

构建发布包和 DMG：

```bash
miu-pet-run/desktop-runner/build-release.sh
```

## 运行

运行开发版 App：

```bash
open miu-pet-run/desktop-runner/猫小伴.app
```

运行发布版 App：

```bash
open miu-pet-run/dist/猫小伴.app
```

## 安装

发布包生成后在这里：

```text
miu-pet-run/dist/猫小伴.dmg
miu-pet-run/dist/猫小伴.zip
```

也可以用安装脚本复制到 `/Applications`：

```bash
miu-pet-run/desktop-runner/install-to-applications.sh
```

## 隐私

猫小伴本地读取：

- 前台应用名称和 Bundle ID。
- 前台窗口几何信息。
- 用户空闲时间。
- 本地提醒和设置文件。

当前版本不上传屏幕内容，不读取窗口正文内容，不联网同步数据。更多说明见：

```text
miu-pet-run/desktop-runner/PRIVACY.md
```

## 文档

- `miu-pet-run/desktop-runner/README.md`
- `miu-pet-run/desktop-runner/INSTALL.md`
- `miu-pet-run/desktop-runner/RELEASE_CHECKLIST.md`
- `miu-pet-run/desktop-runner/V0.18_BEHAVIOR_DEBUG_PANEL.md`
- `INTERNAL_QA_NOTES.md`

## 发布状态

当前发布包使用本地 ad-hoc 签名，定位为自用 / 小范围内测版。公开分发前建议配置 Apple Developer ID 签名和 notarization。

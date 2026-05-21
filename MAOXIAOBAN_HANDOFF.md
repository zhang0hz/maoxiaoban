# 猫小伴项目迁移交接

更新时间：2026-05-16  
当前工作区：`/Users/zhanghz/Documents/Codex/2026-05-12/new-chat`  
GitHub：`https://github.com/zhang0hz/maoxiaoban`  
产品名：猫小伴  
Bundle ID：`com.zhanghz.maoxiaoban`  
版本：`1.0.0` / build `100`

## 迁移目标

把本对话里的电子宠物项目迁移到新的 Codex 项目下继续开发。新项目需要继承：

- 产品设定
- 已完成能力
- 代码状态
- 构建/验证方式
- 当前风险
- 下一步开发流程

## 产品设定

猫小伴是 macOS 桌面电子宠物 App。

宠物形象：

- 蓝双布偶猫
- 温顺、可爱、安静陪伴
- 像素风电子宠物
- 参考用户提供的布偶猫照片：大蓝眼、浅色毛、粉鼻子、柔和表情

核心使用场景：

- 用户工作时，猫安静待在一边，不挡工作窗口。
- 用户休闲时，猫可以在窗口边缘活动和散步。
- 根据北京时间切换日夜节律，晚上睡觉。
- 提供轻提醒：喝水、休息、久坐、睡觉。
- 所有判断尽量本地完成，不上传屏幕内容。

## 当前产品状态

状态判断：

```text
V1.0 候选版 / 展示可用 / 日常使用还需体验打磨
```

已能独立运行：

- `miu-pet-run/desktop-runner/猫小伴.app`
- `miu-pet-run/dist/猫小伴.app`
- `miu-pet-run/dist/猫小伴.zip`
- `miu-pet-run/dist/猫小伴.dmg`

注意：最近一轮改动后没有重打 DMG。`dist app/zip` 已更新，DMG 可能不是最新代码。

## 已完成能力

基础运行：

- macOS 原生透明浮窗。
- 菜单栏入口。
- 右键菜单。
- 点击拖动移动。
- 拖动后固定位置。
- 重置位置。
- 自动贴边。
- 大小：小 / 中 / 大。
- 暂停 / 继续动画。

行为：

- 自动 / 工作 / 休闲 / 睡觉模式。
- 北京时间日夜节律：
  - `23:30 - 07:30`：睡觉
  - `07:30 - 09:00`：醒来 / 伸懒腰
  - `09:00 - 18:30`：工作陪伴
  - `18:30 - 22:30`：休闲活动
  - `22:30 - 23:30`：睡前安静
- 前台应用识别。
- 前台窗口覆盖率判断。
- 用户空闲时间判断。
- 全屏 / 演示窗口低打扰。
- 工作应用、休闲应用、沟通/会议应用分类。
- 当前应用分类覆盖：工作 / 休闲 / 沟通会议 / 中性 / 清除。
- 明确状态机：`fullscreen`、`temporaryReaction`、`night`、`morning`、`sleepy`、`work`、`leisure`、`idle`。

视觉动作：

- `loaf`
- `sleep`
- `wake`
- `stretch`
- `peek`
- `edge-walk`
- `groom`
- `purr`
- `sit-watch` runtime alias 到 `purr`，避免色偏
- `celebrate`
- `comfort`
- `walk-right`
- `walk-left`
- `blink`
- `ear-twitch`
- `tail-sway`
- `yawn`
- `paw-wave`

已修视觉问题：

- 猫倒着走：使用 `walk-right` / `walk-left` 区分方向。
- 走路四肢不协调：已用方向专属帧改善。
- 动作色偏：加 `color_audit.py`，并保护 `sit-watch`。

提醒：

- 默认提醒：
  - 喝水：90 分钟，09:00-22:00。
  - 休息：60 分钟，09:00-22:30。
  - 久坐：90 分钟，09:00-22:00。
  - 睡觉：23:30 固定时间。
- 自定义提醒。
- 提醒气泡。
- 完成 / 稍后 10 分钟 / 跳过今天 / 关闭。
- 菜单中可稍后 10 / 30 / 60 分钟。
- 自动消失：10 秒 / 30 秒 / 60 秒 / 不自动。
- 全屏 / 安静工作状态下延后提醒。
- 延后队列恢复后重放。
- 今日完成 / 跳过 / 历史统计。

设置：

- 设置窗口 Tabs：
  - 概览
  - 行为
  - 提醒
  - 分类
  - 调试
- 设置持久化。
- 登录时启动开关。
- 数据目录：

```text
~/Library/Application Support/MaoXiaoBan
```

调试：

- `设置...` -> `调试`
- 显示：
  - 当前状态机
  - 当前动作
  - 前台应用
  - Bundle ID
  - 应用分类
  - 勿扰 flag
  - 行为原因
  - 前台窗口覆盖率
  - 空闲时间
  - 贴边状态
  - 提醒队列
  - 北京时间
  - 最近行为日志
- 可复制诊断信息。

打包：

- `build-app.sh`
- `build-dist.sh`
- `build-dmg.sh`
- `build-release.sh`
- `verify-release.sh`
- `verify-dmg.sh`
- ad-hoc signing 已可用。
- Developer ID / notarization 未完成。

GitHub：

- 已推送初始仓库到 `zhang0hz/maoxiaoban`。
- 仓库曾改 Public 做检查，后改回 Private。
- 用户曾生成 token 并粘贴到对话中，后来已删除 / revoke。
- 不要在任何新文档里记录旧 token。

## 当前代码结构

主要目录：

```text
miu-pet-run/
  desktop-runner/      macOS App 源码、脚本、文档
  behavior-layer/      行为层 JS 测试
  phase1-actions/      正式动作帧
  frames/              早期帧
  decoded/             早期解码图
  final/               spritesheet
  references/          参考图
  qa/                  早期 QA 图
```

Swift 文件：

```text
AppSupport.swift                    app identity / config / settings storage
BehaviorModels.swift                pet mode / placement / behavior decision / behavior log model
MiuDesktopRunner.swift              app delegate / lifecycle / window / settings persistence
MiuRunner+Behavior.swift            timers / action switch / behavior decision / behavior log
MiuRunner+Commands.swift            menu/settings/reminder command handlers
MiuRunner+Menu.swift                status bar item and menu
MiuRunner+Placement.swift           placement / window geometry / walking edge movement
MiuRunner+ReminderBubble.swift      reminder bubble panel
MiuRunner+Settings.swift            settings UI / reminder editor / debug panel
PetView.swift                       transparent draggable pet view
ReminderScheduler.swift             reminder config / queue / scheduler / history
SystemActivityClassifier.swift      app classification / system activity snapshot
main.swift                          entrypoint and asset root
```

当前行数：

```text
MiuRunner+Settings.swift        660
ReminderScheduler.swift         431
MiuRunner+Commands.swift        330
MiuDesktopRunner.swift          282
MiuRunner+Behavior.swift        265
SystemActivityClassifier.swift  262
MiuRunner+Menu.swift            185
MiuRunner+Placement.swift       176
AppSupport.swift                139
BehaviorModels.swift             84
MiuRunner+ReminderBubble.swift   84
PetView.swift                    74
main.swift                       23
```

## 当前 Git 状态

远端初始提交：

```text
61ccb3b Initial release of MaoXiaoBan
```

当前本地还有未提交改动：

```text
M  miu-pet-run/desktop-runner/BehaviorModels.swift
M  miu-pet-run/desktop-runner/MiuDesktopRunner.swift
M  miu-pet-run/desktop-runner/MiuRunner+Behavior.swift
M  miu-pet-run/desktop-runner/MiuRunner+Settings.swift
M  miu-pet-run/desktop-runner/README.md
M  miu-pet-run/desktop-runner/RELEASE_CHECKLIST.md
M  miu-pet-run/desktop-runner/V0.18_BEHAVIOR_DEBUG_PANEL.md
M  miu-pet-run/desktop-runner/V1.0.5_CODE_SPLIT.md
?? miu-pet-run/desktop-runner/MiuRunner+Commands.swift
?? miu-pet-run/desktop-runner/V1.0_EXPERIENCE_QA.md
?? miu-pet-run/desktop-runner/smoke-test.sh
```

这些未提交改动包含：

- V0.18 调试面板增强。
- 最近 20 条行为日志。
- 复制诊断信息。
- `MiuRunner+Commands.swift` 命令拆分。
- 主 runner 从 604 行降到 282 行。
- `V1.0_EXPERIENCE_QA.md`。
- `smoke-test.sh`。
- README / release checklist 更新。

建议新项目第一步先 commit：

```bash
git add .
git commit -m "Polish V1.0 diagnostics and experience QA"
```

注意：当前环境原生 `.git` 目录创建被拦，用的是临时 git dir：

```bash
GIT_DIR=/private/tmp/maoxiaoban.git
GIT_WORK_TREE=/Users/zhanghz/Documents/Codex/2026-05-12/new-chat
```

如果新项目从 GitHub clone，则会有正常 `.git`，不用这个临时配置。

## 构建和验证命令

开发 App：

```bash
miu-pet-run/desktop-runner/build-app.sh
open miu-pet-run/desktop-runner/猫小伴.app
```

Smoke test：

```bash
miu-pet-run/desktop-runner/smoke-test.sh
```

行为层测试：

```bash
node miu-pet-run/behavior-layer/test/behavior.test.mjs
```

颜色审计：

```bash
python3 miu-pet-run/desktop-runner/color_audit.py --frames-root miu-pet-run/desktop-runner/猫小伴.app/Contents/Resources/frames
```

发布 app/zip：

```bash
miu-pet-run/desktop-runner/build-dist.sh
miu-pet-run/desktop-runner/verify-release.sh miu-pet-run/dist/猫小伴.app
```

DMG：

```bash
miu-pet-run/desktop-runner/build-release.sh
```

DMG 会调用 `hdiutil`，在 Codex 里可能需要权限审批。

最近一次验证通过：

- `smoke-test.sh`
- `build-dist.sh`
- `verify-release.sh`
- dist 色偏审计
- shell `bash -n`
- Python `py_compile`

## 已有文档索引

核心文档：

```text
README.md
miu-pet-run/desktop-runner/README.md
miu-pet-run/desktop-runner/RELEASE_CHECKLIST.md
miu-pet-run/desktop-runner/INSTALL.md
miu-pet-run/desktop-runner/UNINSTALL.md
miu-pet-run/desktop-runner/PRIVACY.md
miu-pet-run/desktop-runner/TROUBLESHOOTING.md
miu-pet-run/desktop-runner/V1.0_EXPERIENCE_QA.md
```

开发阶段文档：

```text
V0.3_SYSTEM_ACTIVITY.md
V0.4_STANDALONE_APP.md
V0.4.1_SETTINGS_PERSISTENCE.md
V0.5_REMINDERS.md
V0.6_SETTINGS_UI.md
V0.7_BEHAVIOR_INTELLIGENCE.md
V0.8_VISUAL_ACTIONS.md
V0.8_COLOR_QA.md
V0.8.1_VISUAL_ASSET_REWORK.md
V0.9_SYSTEM_SMARTNESS.md
V0.10_SETTINGS_POLISH.md
V0.11_VISUAL_ASSET_EXPANSION.md
V0.11.1_TRUE_REDRAW.md
V0.12_SMART_CLASSIFICATION_REMINDERS.md
V0.13_PRODUCT_DETAILS.md
V0.14_SAFE_PLACEMENT.md
V0.15_PLACEMENT_REFINEMENT.md
V0.16_REMINDER_QUEUE.md
V0.17_BEHAVIOR_STATE_MACHINE.md
V0.18_BEHAVIOR_DEBUG_PANEL.md
V1.0_RELEASE_PREP.md
V1.0.4_ICON_POLISH.md
V1.0.5_CODE_SPLIT.md
```

## 已明确的后续流程

当前任务应走：

```text
稳定化 / 体验收口流程
```

不是继续堆新功能。

每项开发流程：

```text
定义验收标准 -> 小改动 -> build -> smoke-test -> 手工验证 -> commit
```

Bug 走诊断流程：

```text
复现 -> 最小化 -> 假设 -> 插桩/观察 -> 修复 -> 回归测试
```

设置/UI 走产品化流程：

```text
信息架构 -> 控件密度 -> resize/scroll -> 长文案/错误态 -> 手工截图检查
```

每轮结束跑：

```bash
miu-pet-run/desktop-runner/smoke-test.sh
miu-pet-run/desktop-runner/build-dist.sh
miu-pet-run/desktop-runner/verify-release.sh miu-pet-run/dist/猫小伴.app
```

## 下一步推荐开发

优先级：

1. P0：透明区域 alpha hit-test。
2. P1：设置页 resizable，去掉硬编码 scroll frame。
3. P1：提醒编辑输入校验和错误提示。
4. P2：多窗口避让 scoring。
5. P2：菜单长文案截断。

### P0：透明区域 alpha hit-test

问题：

- `PetView` 当前整个 bounds 都接收鼠标。
- 透明边缘也会挡后面窗口。

相关文件：

```text
miu-pet-run/desktop-runner/PetView.swift
```

验收：

- 猫身体可点、可拖、可右键。
- 透明区域点击应尽量穿透，不挡背后窗口。
- 不影响 mouse enter / leave 动作。

可选实现：

- 在 `hitTest(_:)` 中根据当前 image alpha 判断。
- 或收窄 window bounds 到 sprite 实际可见区域。

### P1：设置页 resizable

问题：

- `makeSettingsWindow()` 固定 `650x500`。
- `wrapSettingsStack()` scroll content 固定 `600x460`。

相关文件：

```text
miu-pet-run/desktop-runner/MiuRunner+Settings.swift
```

验收：

- 设置窗口可 resize。
- 最小尺寸合理。
- 调试日志和提醒编辑不挤。
- 文字不截断。

### P1：提醒编辑校验

问题：

- 时间非法会 silent fallback。
- 间隔非法会 fallback/clamp。
- 用户不知道保存失败或被改值。

相关文件：

```text
miu-pet-run/desktop-runner/MiuRunner+Settings.swift
```

验收：

- 时间必须 `HH:mm`。
- 间隔必须 5-720。
- 错误显示在 `reminderEditStatusLabel`。
- 错误时不保存，或明确提示已自动修正。

### P2：多窗口避让

问题：

- 当前只避让一个前台窗口。
- 多窗口工作时可能挡参考窗口。

相关文件：

```text
miu-pet-run/desktop-runner/MiuRunner+Placement.swift
```

验收：

- 收集当前屏幕主要可见窗口。
- placement score 按所有窗口 overlap 惩罚。
- 保持 Dock/menu bar safe area。

### P2：菜单长文案截断

问题：

- 菜单中原因、提醒文案可能过长，撑宽菜单。

相关文件：

```text
miu-pet-run/desktop-runner/MiuRunner+Menu.swift
```

验收：

- 菜单使用短文案。
- 完整信息仍可在调试面板 / 复制诊断中获取。

## 发布/展示状态

当前适合：

- 私有仓库展示。
- 本机运行演示。
- 代码结构演示。
- 产品原型演示。

暂不适合：

- 公开分发给普通用户。
- GitHub Release 正式发布。
- 未说明 Gatekeeper 限制就发 DMG。

发布前还缺：

- Developer ID Application 证书。
- Notarization。
- 用户截图。
- 多小时真实使用 soak test。
- 手工 QA 全项通过。

## 安全/隐私状态

已检查：

- 无 `.env` 上传。
- 无 `release.env` 上传。
- 无 token / GitHub PAT 上传。
- 无 `.p12 / .pem / .key / .mobileprovision` 上传。
- `.dmg / .zip / .app` 被 `.gitignore` 忽略。
- 日志和 pid 被忽略。

注意：

- 旧 GitHub token 曾出现在对话中，但用户已删除。
- 新项目/新文档不要记录任何 token。

隐私说明：

- App 本地读取前台应用、Bundle ID、窗口几何和空闲时间。
- 不上传屏幕内容。
- 不读取窗口正文。
- 不联网同步。

## 对话偏好

用户当前偏好：

- 默认 caveman full 风格。
- 中文。
- 高密度、少废话。
- 开发前可先沟通规划；明确执行后再动手。
- 需要权限审批时必须提醒。
- DMG / hdiutil 会要权限，需提前说。

开发偏好：

- 做真实可用产品，不只 demo。
- 功能先能用，再 polish。
- 重视不打扰工作窗口。
- 重视桌面宠物的生动感。
- 重视提醒系统。
- 后续倾向稳定化，不再盲目堆功能。

## 新项目承接建议

新项目启动后，先做：

1. 从 GitHub clone `zhang0hz/maoxiaoban`，或拷贝当前工作区。
2. 把本地未提交改动迁移进去。
3. 运行：

```bash
miu-pet-run/desktop-runner/smoke-test.sh
```

4. commit 当前收口成果：

```bash
git add .
git commit -m "Polish V1.0 diagnostics and experience QA"
```

5. 开始 P0：透明区域 alpha hit-test。


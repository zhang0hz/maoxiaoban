# 猫小伴 Internal QA Notes

更新时间：2026-05-21

## 当前内测基线

- 内测版本：`v1.0-internal`
- App 路径：`/Applications/猫小伴.app`
- 构建产物：
  - `miu-pet-run/dist/猫小伴.app`
  - `miu-pet-run/dist/猫小伴.zip`
  - `miu-pet-run/dist/猫小伴.dmg`
- 签名状态：本地 ad-hoc 签名
- 分发策略：仅自用 / 小范围内测，暂跳过 Developer ID 和 Notarization

## 本轮基线状态

- `/Applications/猫小伴.app` 已覆盖为最新 `dist` 版本。
- DMG 已在本机终端通过 `verify-dmg.sh` 校验。
- `build-release.sh` 已加入发布后自动同步 `/Applications/猫小伴.app` 的步骤。
- `install-to-applications.sh` 支持 `OPEN_AFTER_INSTALL=0` 静默安装。

## 内测观察记录模板

每次记录建议保留这些字段：

```text
日期：
场景：工作 / 休闲 / 提醒 / 设置 / 安装 / 多屏 / 其他
现象：
期望：
严重程度：P0 / P1 / P2 / P3
是否可复现：
后续处理：
```

## 当前重点观察项

### 行为

- 工作时是否足够安静。
- 动作切换是否仍然显得频繁。
- 休闲散步是否太早、太频繁或太抢注意力。
- 夜间 / 睡前 / 早晨状态切换是否自然。

### 视觉

- `blink`、`ear-twitch`、`tail-sway` 是否足够轻微。
- `walk-left` / `walk-right` 是否还有倒走或滑步。
- `groom`、`yawn`、`wake` 作为过渡动作是否自然。
- 是否存在明显色偏、跳帧或尺寸不一致。

### 提醒

- 提醒出现前的小动作是否自然。
- 提醒气泡是否遮挡工作内容。
- 稍后、跳过、完成后的动作反馈是否合适。
- 安静工作 / 全屏时延后提醒是否符合预期。

### 设置

- 设置窗口 resize 后布局是否稳定。
- “高级”标签是否足够清楚。
- 提醒时间 / 间隔输入错误时提示是否好懂。
- 首次启动引导是否能解释清楚本地隐私和用途。

### 分发

- Launchpad 打开的是否总是最新 `/Applications/猫小伴.app`。
- DMG 拖拽安装是否顺畅。
- Zip 解压后启动是否正常。
- Gatekeeper 拦截文案是否需要在内测说明里进一步解释。

## 功能迭代灵感记录同步区

来源：Codex 中名为“功能迭代灵感记录”的对话窗口。

当前同步状态：

- 2026-05-21：本会话无法直接读取另一个 Codex 对话窗口；Computer Use 工具禁止访问 `com.openai.codex` 窗口内容。
- 等用户从该对话窗口粘贴或导出内容后，将在本区合并整理为可执行条目。

待同步条目：

- 暂无。等待“功能迭代灵感记录”内容。

## 后续版本候选

### V1.0.1 Internal

- 修复内测期间发现的稳定性 / 遮挡 / 安装问题。
- 优先处理透明区域点击穿透、菜单长文案、多窗口避让、提醒编辑细节。
- 不新增大功能。

### V1.1 Visual Quality

- 提升正式动作帧质量。
- 补齐微表情和过渡动作的 GIF 预览。
- 做动作资产总览图。
- 保持猫的蓝双布偶身份一致。

### V1.2 Product Experience

- 进一步精简设置。
- 补“恢复推荐设置”。
- 优化首次启动引导。
- 固化内测 release note 模板。

### V1.3 Public Release

- 需要公开分发时再补 Developer ID、Notarization、正式 GitHub Release。
- 当前内测阶段不阻塞。

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

## 版本更新记录

### v1.0.2 Internal Patch

本轮是内测稳定性更新，重点不是新增大功能，而是让当前版本更适合持续自用和小范围测试。

- 修复 P1 点击拦截：全屏/大窗口隐藏时同步关闭鼠标事件；宠物窗口被前方窗口覆盖时不再继续接收点击。
- 勿扰不抢操作：安静工作状态会减少动作和延后提醒，但猫小伴本体仍可拖拽、点击和打开右键菜单。
- 多屏更稳：前台窗口坐标换算会同时评估 raw、单屏转换和桌面总区域转换，减少外接屏判断错位。
- 命中检测更轻：透明像素检测缓存 alpha bitmap，避免每次 `hitTest` 重建图片位图。
- 边界更稳：拖动位置会限制在当前屏幕可见范围内，提醒气泡会自动贴边或改放到猫小伴下方。
- 行为更安静：工作模式动作停留时间延长，减少频繁切换；休闲散步延后到更长空闲后才出现。
- 视觉更自然：微表情频率降低，`blink`、`ear-twitch`、`tail-sway` 更偏轻量点缀；提醒前动作更柔和。
- 设置更像产品：概览页展示版本号、Build 号、Bundle ID 和内测分发状态。
- 新增“恢复推荐设置”：只恢复模式、位置、动画和大小，不清空提醒和应用分类。
- 分发准备增强：补充 GitHub Release 草稿、安装/卸载说明、内测签名说明和 GitHub 上传注意事项。
- 验证已覆盖：`smoke-test.sh` 现在包含 V1.0.2 hotfix 检查和路线图静态检查，确保 P1-P4 相关文档和代码不脱节。
- QA 记录已补：`V1.0.2_QA_RECORD.md` 记录自动验证和桌面交互复核清单。

## 目录

```text
miu-pet-run/
  desktop-runner/      macOS 原生运行器、设置页、打包脚本
  behavior-layer/      行为层测试和早期行为逻辑说明
  phase1-actions/      宠物动作帧和视觉资产
  prompts/             早期宠物资产生成提示词
investor-demo/         本地投资方演示材料，不属于 App 发布包
```

`investor-demo/` 只用于本地路演、录屏和产品叙事展示；它不会进入 `build-app.sh`、`build-dist.sh` 或 DMG 发布包。`investor-demo/maoxiaoban-demo.html` 是可重新生成的单文件打包产物，默认不入库。

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

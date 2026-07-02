# 猫小伴投资方互动 Demo

这是一个本地静态 Demo，用来录制约 3 分钟的投资方演示视频。页面包含动画宠物、工作低打扰场景、休闲动作预览、轻提醒互动、桌面状态感知流程、隐私边界和投资亮点。

本目录是演示材料源码，不属于 macOS App 发布包。`maoxiaoban-demo.html` 是由 `package-standalone.mjs` 生成的单文件打包产物，默认不入库；需要外发单文件时再在本地生成。

## 打开方式

直接打开本地文件：

```bash
open investor-demo/index.html
```

如果浏览器对本地文件权限有限，可以启动一个本地静态服务：

```bash
python3 -m http.server 4173 --directory investor-demo
```

然后打开：

```text
http://localhost:4173
```

## 录屏方式

1. 打开页面。
2. 点击“开始 3 分钟演示”。
3. 录制桌面浏览器窗口。
4. 按 `Space` 可以暂停或继续。
5. 按左右方向键可以切换上一段或下一段。

建议录制范围只包含浏览器内容区域，避免菜单栏、通知和其他窗口进入画面。录制前可先完整播放一次，确认每段画面和旁白节奏匹配。

## 手机展示

页面已按 360px 宽度做移动端适配。手机展示时建议用竖屏，一屏看一个重点。

如果在电脑上模拟手机效果，可打开浏览器开发者工具，切换到移动端视图，选择约 360px 宽度，再刷新页面并点击“开始 3 分钟演示”。

如果要在真实手机上打开：

1. 让电脑和手机连接同一个 Wi-Fi。
2. 在电脑上启动局域网可访问的本地服务：

```bash
python3 -m http.server 4173 --bind 0.0.0.0 --directory investor-demo
```

3. 在电脑上查看 Wi-Fi IP：

```bash
ipconfig getifaddr en0
```

4. 在手机浏览器打开：

```text
http://电脑IP:4173
```

例如电脑 IP 是 `192.168.1.23`，手机打开：

```text
http://192.168.1.23:4173
```

## 素材来源

本 demo 使用当前项目已有素材：

- `miu-pet-run/phase1-actions/gifs/`
- `miu-pet-run/phase1-actions/qa/phase1-contact-sheet.png`
- `miu-pet-run/desktop-runner/Assets/app-icon-1024.png`

本 demo 不移动、不改名原产品素材，只复制演示所需文件到 `investor-demo/assets/`。

## 验证

```bash
node investor-demo/validate-demo.mjs
```

预期输出：

```text
Investor demo validation passed.
```

## 生成单文件演示

```bash
node investor-demo/package-standalone.mjs
```

输出文件：

```text
investor-demo/maoxiaoban-demo.html
```

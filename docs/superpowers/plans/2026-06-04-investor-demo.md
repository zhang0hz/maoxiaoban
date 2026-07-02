# 猫小伴 Investor Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a mobile-friendly, animated, local investor demo page for 猫小伴, plus a 3-minute recording script.

**Current status:** Implemented locally and validated. This file is kept as the historical implementation plan; do not treat unchecked boxes below as permission to re-run the plan automatically.

**Architecture:** The demo is a static microsite under `investor-demo/` with no build system. `index.html` owns content structure, `styles.css` owns responsive layout and visual animation, `script.js` owns interactions and recording-mode progression, and `validate-demo.mjs` checks required files, content markers, and asset references.

**Tech Stack:** Native HTML, CSS, JavaScript, local GIF/PNG assets copied from the current project, Node.js for validation.

---

## File Structure

- Create: `investor-demo/index.html`
  - Responsible for the interactive investor demo page structure, section content, demo controls, and asset references.
- Create: `investor-demo/styles.css`
  - Responsible for visual design, desktop/mobile responsive layout, motion, animated desktop mockups, reminder bubble states, and recording-mode presentation.
- Create: `investor-demo/script.js`
  - Responsible for section navigation, recording mode, demo playback, reminder interactions, and state-flow highlighting.
- Create: `investor-demo/validate-demo.mjs`
  - Responsible for static validation of files, assets, required sections, animation hooks, mobile viewport metadata, and recording-mode controls.
- Create: `investor-demo/recording-script.md`
  - Responsible for the 3-minute voiceover and screen action script.
- Create: `investor-demo/README.md`
  - Responsible for local open instructions, recording guidance, and source asset notes.
- Create: `investor-demo/assets/`
  - Contains only demo-needed copies of existing visual assets.

Use these source assets:

- `miu-pet-run/phase1-actions/gifs/miu-loaf.gif`
- `miu-pet-run/phase1-actions/gifs/miu-peek.gif`
- `miu-pet-run/phase1-actions/gifs/miu-edge-walk.gif`
- `miu-pet-run/phase1-actions/gifs/miu-stretch.gif`
- `miu-pet-run/phase1-actions/gifs/miu-sleep.gif`
- `miu-pet-run/phase1-actions/gifs/miu-celebrate.gif`
- `miu-pet-run/phase1-actions/qa/phase1-contact-sheet.png`
- `miu-pet-run/desktop-runner/Assets/app-icon-1024.png`

---

### Task 1: Create Asset Pack And Failing Validator

**Files:**

- Create: `investor-demo/assets/`
- Create: `investor-demo/validate-demo.mjs`

- [ ] **Step 1: Create the demo asset directory**

Run:

```bash
mkdir -p investor-demo/assets
```

Expected: directory exists at `investor-demo/assets`.

- [ ] **Step 2: Copy the required existing assets**

Run:

```bash
cp miu-pet-run/phase1-actions/gifs/miu-loaf.gif investor-demo/assets/miu-loaf.gif
cp miu-pet-run/phase1-actions/gifs/miu-peek.gif investor-demo/assets/miu-peek.gif
cp miu-pet-run/phase1-actions/gifs/miu-edge-walk.gif investor-demo/assets/miu-edge-walk.gif
cp miu-pet-run/phase1-actions/gifs/miu-stretch.gif investor-demo/assets/miu-stretch.gif
cp miu-pet-run/phase1-actions/gifs/miu-sleep.gif investor-demo/assets/miu-sleep.gif
cp miu-pet-run/phase1-actions/gifs/miu-celebrate.gif investor-demo/assets/miu-celebrate.gif
cp miu-pet-run/phase1-actions/qa/phase1-contact-sheet.png investor-demo/assets/phase1-contact-sheet.png
cp miu-pet-run/desktop-runner/Assets/app-icon-1024.png investor-demo/assets/app-icon-1024.png
```

Expected: the eight files exist under `investor-demo/assets/`.

- [ ] **Step 3: Write the validator before the page exists**

Create `investor-demo/validate-demo.mjs`:

```js
import fs from "node:fs";
import path from "node:path";

const root = new URL(".", import.meta.url).pathname;

const requiredFiles = [
  "index.html",
  "styles.css",
  "script.js",
  "recording-script.md",
  "README.md",
  "assets/miu-loaf.gif",
  "assets/miu-peek.gif",
  "assets/miu-edge-walk.gif",
  "assets/miu-stretch.gif",
  "assets/miu-sleep.gif",
  "assets/miu-celebrate.gif",
  "assets/phase1-contact-sheet.png",
  "assets/app-icon-1024.png"
];

const requiredHtmlMarkers = [
  "viewport",
  "data-section=\"hero\"",
  "data-section=\"work\"",
  "data-section=\"leisure\"",
  "data-section=\"reminders\"",
  "data-section=\"signals\"",
  "data-section=\"privacy\"",
  "data-section=\"investor\"",
  "data-demo-step",
  "id=\"startDemo\"",
  "id=\"nextStep\"",
  "id=\"prevStep\"",
  "id=\"pauseDemo\"",
  "assets/miu-loaf.gif",
  "assets/miu-peek.gif",
  "assets/miu-edge-walk.gif",
  "assets/miu-stretch.gif",
  "assets/miu-sleep.gif",
  "assets/miu-celebrate.gif"
];

const requiredCssMarkers = [
  "@media (max-width: 720px)",
  "@keyframes",
  "prefers-reduced-motion",
  ".desktop-mock",
  ".pet-stage",
  ".recording-active",
  ".reminder-bubble"
];

const requiredJsMarkers = [
  "const demoSteps",
  "function startDemo",
  "function showStep",
  "function handleReminderAction",
  "function setFlowStep",
  "addEventListener"
];

function read(file) {
  return fs.readFileSync(path.join(root, file), "utf8");
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

for (const file of requiredFiles) {
  assert(fs.existsSync(path.join(root, file)), `Missing required file: ${file}`);
}

const html = read("index.html");
const css = read("styles.css");
const js = read("script.js");
const script = read("recording-script.md");
const readme = read("README.md");

for (const marker of requiredHtmlMarkers) {
  assert(html.includes(marker), `index.html missing marker: ${marker}`);
}

for (const marker of requiredCssMarkers) {
  assert(css.includes(marker), `styles.css missing marker: ${marker}`);
}

for (const marker of requiredJsMarkers) {
  assert(js.includes(marker), `script.js missing marker: ${marker}`);
}

assert((html.match(/data-section=/g) || []).length >= 7, "index.html must include at least seven demo sections");
assert((html.match(/<img /g) || []).length >= 6, "index.html must include at least six image or GIF visuals");
assert((html.match(/data-demo-step=/g) || []).length >= 6, "index.html must include at least six recording demo steps");
assert(script.includes("0:00-0:20"), "recording script missing opening timestamp");
assert(script.includes("2:35-3:00"), "recording script missing closing timestamp");
assert(readme.includes("open investor-demo/index.html"), "README missing direct-open instruction");

console.log("Investor demo validation passed.");
```

- [ ] **Step 4: Run validator and confirm it fails**

Run:

```bash
node investor-demo/validate-demo.mjs
```

Expected: fails with `Missing required file: index.html`.

- [ ] **Step 5: Commit**

Run:

```bash
git add investor-demo/assets investor-demo/validate-demo.mjs
git commit -m "test: add investor demo validation"
```

Expected: commit succeeds with only `investor-demo/assets/*` and `investor-demo/validate-demo.mjs`.

---

### Task 2: Build The Animated Demo Page Structure

**Files:**

- Create: `investor-demo/index.html`

- [ ] **Step 1: Create the HTML page with all demo sections and controls**

Create `investor-demo/index.html`:

```html
<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>猫小伴投资方 Demo</title>
    <meta name="description" content="猫小伴是一个懂工作状态、低打扰、本地隐私优先的 macOS 桌面电子宠物。">
    <link rel="stylesheet" href="styles.css">
  </head>
  <body>
    <header class="topbar" aria-label="Demo navigation">
      <a class="brand" href="#hero" aria-label="回到猫小伴 Demo 首页">
        <img src="assets/app-icon-1024.png" alt="" class="brand-icon">
        <span>猫小伴 Demo</span>
      </a>
      <nav class="chapter-nav" aria-label="章节">
        <a href="#work">工作</a>
        <a href="#reminders">提醒</a>
        <a href="#signals">能力</a>
        <a href="#investor">亮点</a>
      </nav>
    </header>

    <main>
      <section class="hero section-panel" id="hero" data-section="hero" data-demo-step="0">
        <div class="copy">
          <p class="eyebrow">macOS 桌面电子宠物</p>
          <h1>猫小伴</h1>
          <p class="lead">懂工作状态、低打扰、本地隐私优先的桌面陪伴 App。</p>
          <div class="actions">
            <button class="primary-action" id="startDemo" type="button">开始 3 分钟演示</button>
            <a class="secondary-action" href="#work">查看功能亮点</a>
          </div>
        </div>
        <div class="desktop-mock hero-demo" aria-label="猫小伴桌面演示">
          <div class="mock-menubar">
            <span></span>
            <strong>工作窗口</strong>
            <span>09:42</span>
          </div>
          <div class="mock-window window-main">
            <div class="window-lines"></div>
            <div class="window-lines short"></div>
            <div class="window-grid"></div>
          </div>
          <div class="pet-stage edge-right">
            <img src="assets/miu-loaf.gif" alt="猫小伴安静趴在桌面边缘" class="pet-gif pet-breathe">
            <span class="pet-shadow"></span>
          </div>
          <div class="status-chip">工作中：安静陪伴</div>
        </div>
      </section>

      <section class="section-panel split-panel" id="work" data-section="work" data-demo-step="1">
        <div class="copy">
          <p class="eyebrow">场景 1</p>
          <h2>工作时，它在旁边，不抢你的注意力</h2>
          <p>猫小伴会根据前台应用、窗口覆盖率和空闲状态，选择更安静的动作，并尽量待在安全边缘。</p>
        </div>
        <div class="desktop-mock work-demo">
          <div class="mock-window moving-window">
            <span class="window-title">文档 / 会议 / 浏览器</span>
            <div class="window-lines"></div>
            <div class="window-lines"></div>
          </div>
          <div class="pet-stage work-pet">
            <img src="assets/miu-loaf.gif" alt="猫小伴工作模式安静陪伴" class="pet-gif">
          </div>
          <div class="demo-caption">窗口靠近时，小猫保持在边缘，降低打扰。</div>
        </div>
      </section>

      <section class="section-panel" id="leisure" data-section="leisure" data-demo-step="2">
        <div class="section-heading">
          <p class="eyebrow">场景 2</p>
          <h2>休闲和空闲时，它会活起来</h2>
          <p>散步、探头、伸懒腰、睡觉都来自当前项目里的真实动作资产。</p>
        </div>
        <div class="motion-strip" aria-label="猫小伴动作预览">
          <article><img src="assets/miu-peek.gif" alt="探头"><strong>探头</strong></article>
          <article><img src="assets/miu-edge-walk.gif" alt="边缘散步"><strong>散步</strong></article>
          <article><img src="assets/miu-stretch.gif" alt="伸懒腰"><strong>伸懒腰</strong></article>
          <article><img src="assets/miu-sleep.gif" alt="睡觉"><strong>夜晚睡觉</strong></article>
        </div>
      </section>

      <section class="section-panel split-panel" id="reminders" data-section="reminders" data-demo-step="3">
        <div class="copy">
          <p class="eyebrow">场景 3</p>
          <h2>提醒不是闹钟，是轻轻碰你一下</h2>
          <p>喝水、休息、久坐、睡觉提醒会在安静工作和全屏状态下延后，不把提醒变成新的干扰源。</p>
        </div>
        <div class="reminder-demo">
          <img src="assets/miu-peek.gif" alt="猫小伴提醒前探头" class="pet-gif reminder-pet">
          <div class="reminder-bubble" id="reminderBubble" aria-live="polite">
            <strong>喝口水吧</strong>
            <span id="reminderStatus">当前状态：可以提醒</span>
            <div class="reminder-actions">
              <button type="button" data-reminder-action="done">完成</button>
              <button type="button" data-reminder-action="later">稍后</button>
              <button type="button" data-reminder-action="skip">跳过</button>
            </div>
          </div>
        </div>
      </section>

      <section class="section-panel split-panel" id="signals" data-section="signals" data-demo-step="4">
        <div class="copy">
          <p class="eyebrow">核心能力</p>
          <h2>它不是普通桌宠，而是桌面行为感知系统</h2>
          <p>猫小伴把本地桌面信号转成低打扰的陪伴动作：知道你在工作、休闲、会议、全屏或空闲。</p>
        </div>
        <div class="signal-demo">
          <ol class="flow" aria-label="桌面信号到宠物行为流程">
            <li data-flow-step="0">前台应用</li>
            <li data-flow-step="1">窗口覆盖率</li>
            <li data-flow-step="2">行为判断</li>
            <li data-flow-step="3">小猫动作</li>
          </ol>
          <div class="debug-card">
            <span>状态：工作</span>
            <span>动作：loaf</span>
            <span>提醒队列：延后 1 条</span>
            <span>原因：低打扰</span>
          </div>
        </div>
      </section>

      <section class="section-panel" id="privacy" data-section="privacy" data-demo-step="5">
        <div class="section-heading">
          <p class="eyebrow">隐私边界</p>
          <h2>本地优先，不上传屏幕内容</h2>
          <p>当前版本读取前台应用、窗口几何和空闲时间；不读取窗口正文内容，不联网同步数据。</p>
        </div>
        <div class="privacy-grid">
          <article><strong>读取</strong><span>应用名称、Bundle ID、窗口几何、空闲时间</span></article>
          <article><strong>本地保存</strong><span>设置、提醒、应用分类</span></article>
          <article><strong>不上传</strong><span>屏幕内容、窗口正文、个人数据</span></article>
        </div>
      </section>

      <section class="section-panel" id="investor" data-section="investor" data-demo-step="6">
        <div class="section-heading">
          <p class="eyebrow">投资亮点</p>
          <h2>从桌面挂件，走向日常陪伴入口</h2>
          <p>当前版本已经验证桌面陪伴、低打扰提醒和本地行为感知；后续可扩展到皮肤、动作包、AI 对话和办公健康陪伴。</p>
        </div>
        <div class="value-grid">
          <article><img src="assets/miu-celebrate.gif" alt=""><strong>情绪陪伴</strong><span>从工具软件进入日常情绪场景。</span></article>
          <article><img src="assets/miu-edge-walk.gif" alt=""><strong>桌面入口</strong><span>长期停留在用户工作流边缘。</span></article>
          <article><img src="assets/phase1-contact-sheet.png" alt=""><strong>资产扩展</strong><span>宠物、动作、皮肤都可体系化增长。</span></article>
          <article><img src="assets/app-icon-1024.png" alt=""><strong>商业路径</strong><span>订阅、联名、企业陪伴和高级能力。</span></article>
        </div>
      </section>
    </main>

    <aside class="demo-controller" aria-label="录屏模式控制">
      <span id="demoProgress">演示未开始</span>
      <button id="prevStep" type="button">上一段</button>
      <button id="pauseDemo" type="button">暂停</button>
      <button id="nextStep" type="button">下一段</button>
    </aside>

    <script src="script.js"></script>
  </body>
</html>
```

- [ ] **Step 2: Run validator and confirm missing style/script failure**

Run:

```bash
node investor-demo/validate-demo.mjs
```

Expected: fails with `Missing required file: styles.css`.

- [ ] **Step 3: Commit**

Run:

```bash
git add investor-demo/index.html
git commit -m "feat: add investor demo page structure"
```

Expected: commit includes only `investor-demo/index.html`.

---

### Task 3: Add Responsive Visual Design And Animation

**Files:**

- Create: `investor-demo/styles.css`

- [ ] **Step 1: Write the responsive CSS and animation system**

Create `investor-demo/styles.css`:

```css
:root {
  color-scheme: light;
  --ink: #1d2433;
  --muted: #5e6675;
  --line: #d8dee8;
  --paper: #fbfaf7;
  --panel: #ffffff;
  --blue: #5f8cc8;
  --green: #5d9f7a;
  --coral: #dc7968;
  --gold: #c99740;
  --shadow: 0 18px 50px rgba(29, 36, 51, 0.14);
  --radius: 8px;
}

* {
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
}

body {
  margin: 0;
  color: var(--ink);
  background: linear-gradient(180deg, #f8fbff 0%, var(--paper) 42%, #f4f1ec 100%);
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "PingFang SC", "Microsoft YaHei", sans-serif;
  letter-spacing: 0;
}

img {
  display: block;
  max-width: 100%;
}

button,
a {
  font: inherit;
}

.topbar {
  position: sticky;
  top: 0;
  z-index: 20;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  min-height: 64px;
  padding: 10px clamp(16px, 4vw, 56px);
  background: rgba(251, 250, 247, 0.84);
  border-bottom: 1px solid rgba(216, 222, 232, 0.7);
  backdrop-filter: blur(18px);
}

.brand,
.chapter-nav a,
.secondary-action {
  color: var(--ink);
  text-decoration: none;
}

.brand {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  font-weight: 700;
}

.brand-icon {
  width: 34px;
  height: 34px;
  border-radius: 7px;
}

.chapter-nav {
  display: flex;
  gap: 18px;
  color: var(--muted);
  font-size: 14px;
}

.section-panel {
  min-height: calc(100vh - 48px);
  padding: clamp(52px, 8vw, 108px) clamp(18px, 5vw, 72px);
}

.hero,
.split-panel {
  display: grid;
  grid-template-columns: minmax(0, 0.92fr) minmax(340px, 1.08fr);
  align-items: center;
  gap: clamp(28px, 6vw, 72px);
}

.copy,
.section-heading {
  max-width: 680px;
}

.eyebrow {
  margin: 0 0 12px;
  color: var(--blue);
  font-size: 14px;
  font-weight: 700;
}

h1,
h2 {
  margin: 0;
  letter-spacing: 0;
  line-height: 1.05;
}

h1 {
  font-size: clamp(48px, 8vw, 96px);
}

h2 {
  font-size: clamp(30px, 5vw, 56px);
}

.lead,
.copy p:not(.eyebrow),
.section-heading p:not(.eyebrow) {
  color: var(--muted);
  font-size: clamp(17px, 2vw, 22px);
  line-height: 1.7;
}

.actions {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-top: 28px;
}

.primary-action,
.secondary-action,
.demo-controller button,
.reminder-actions button {
  min-height: 42px;
  padding: 0 18px;
  border: 1px solid var(--line);
  border-radius: var(--radius);
  cursor: pointer;
}

.primary-action {
  color: #fff;
  background: var(--ink);
  border-color: var(--ink);
}

.secondary-action,
.demo-controller button,
.reminder-actions button {
  background: rgba(255, 255, 255, 0.78);
}

.desktop-mock,
.reminder-demo,
.signal-demo {
  position: relative;
  min-height: 420px;
  overflow: hidden;
  background: linear-gradient(135deg, #eef5fb, #fff7ee);
  border: 1px solid rgba(216, 222, 232, 0.9);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
}

.mock-menubar {
  display: flex;
  justify-content: space-between;
  padding: 14px 18px;
  color: var(--muted);
  background: rgba(255, 255, 255, 0.72);
  border-bottom: 1px solid var(--line);
}

.mock-window {
  position: absolute;
  left: 9%;
  top: 22%;
  width: 64%;
  min-height: 190px;
  padding: 26px;
  background: rgba(255, 255, 255, 0.9);
  border: 1px solid rgba(216, 222, 232, 0.9);
  border-radius: var(--radius);
}

.window-main {
  animation: windowFloat 7s ease-in-out infinite;
}

.moving-window {
  animation: windowAvoidance 7s ease-in-out infinite;
}

.window-title {
  display: inline-block;
  margin-bottom: 18px;
  font-weight: 700;
}

.window-lines,
.window-grid {
  height: 14px;
  margin-bottom: 14px;
  background: #dfe7f1;
  border-radius: 6px;
}

.window-lines.short {
  width: 62%;
}

.window-grid {
  height: 64px;
  background: repeating-linear-gradient(90deg, #e6edf5 0 22px, #d7e0eb 22px 24px);
}

.pet-stage {
  position: absolute;
  right: 3%;
  bottom: 10%;
  width: clamp(116px, 18vw, 178px);
  animation: petIdle 4s ease-in-out infinite;
}

.work-pet {
  right: 5%;
  bottom: 9%;
}

.pet-gif {
  width: 100%;
  filter: drop-shadow(0 16px 18px rgba(49, 59, 75, 0.18));
}

.pet-shadow {
  display: block;
  width: 70%;
  height: 12px;
  margin: -8px auto 0;
  background: rgba(29, 36, 51, 0.13);
  border-radius: 999px;
}

.status-chip,
.demo-caption {
  position: absolute;
  left: 18px;
  bottom: 18px;
  padding: 8px 12px;
  color: var(--ink);
  background: rgba(255, 255, 255, 0.82);
  border: 1px solid var(--line);
  border-radius: 999px;
}

.motion-strip,
.privacy-grid,
.value-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
  margin-top: 34px;
}

.motion-strip article,
.privacy-grid article,
.value-grid article {
  min-height: 180px;
  padding: 18px;
  background: rgba(255, 255, 255, 0.82);
  border: 1px solid var(--line);
  border-radius: var(--radius);
}

.motion-strip img,
.value-grid img {
  width: min(150px, 80%);
  height: 150px;
  object-fit: contain;
  margin: 0 auto 12px;
}

.value-grid img[src$="contact-sheet.png"] {
  object-fit: cover;
  border-radius: 6px;
}

.reminder-demo {
  display: grid;
  place-items: center;
}

.reminder-pet {
  width: 160px;
  transform: translateX(-86px);
}

.reminder-bubble {
  position: absolute;
  left: 48%;
  top: 30%;
  width: min(320px, 78%);
  padding: 18px;
  background: #fff;
  border: 1px solid var(--line);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  animation: bubbleIn 3s ease-in-out infinite;
}

.reminder-bubble strong,
.reminder-bubble span {
  display: block;
}

.reminder-bubble span {
  margin: 8px 0 14px;
  color: var(--muted);
}

.reminder-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.flow {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
  padding: 42px 28px 0;
  list-style: none;
}

.flow li {
  padding: 16px 12px;
  text-align: center;
  background: rgba(255, 255, 255, 0.72);
  border: 1px solid var(--line);
  border-radius: var(--radius);
  transition: transform 0.25s ease, background 0.25s ease, border-color 0.25s ease;
}

.flow li.active {
  transform: translateY(-6px);
  background: #fff8dc;
  border-color: var(--gold);
}

.debug-card {
  position: absolute;
  left: 28px;
  right: 28px;
  bottom: 28px;
  display: grid;
  gap: 10px;
  padding: 18px;
  background: rgba(29, 36, 51, 0.88);
  color: #fff;
  border-radius: var(--radius);
}

.privacy-grid {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.privacy-grid strong,
.value-grid strong,
.motion-strip strong {
  display: block;
  margin-bottom: 8px;
  font-size: 18px;
}

.privacy-grid span,
.value-grid span {
  color: var(--muted);
  line-height: 1.55;
}

.demo-controller {
  position: fixed;
  right: 18px;
  bottom: 18px;
  z-index: 30;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px;
  background: rgba(255, 255, 255, 0.88);
  border: 1px solid var(--line);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  backdrop-filter: blur(16px);
}

.demo-controller span {
  min-width: 100px;
  color: var(--muted);
  font-size: 13px;
}

body.recording-active [data-demo-step].active-step {
  outline: 3px solid rgba(95, 140, 200, 0.34);
  outline-offset: -8px;
}

@keyframes petIdle {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

@keyframes windowFloat {
  0%, 100% { transform: translate(0, 0); }
  50% { transform: translate(18px, -8px); }
}

@keyframes windowAvoidance {
  0%, 100% { transform: translateX(0); width: 58%; }
  50% { transform: translateX(52px); width: 68%; }
}

@keyframes bubbleIn {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-8px); }
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.001ms !important;
    animation-iteration-count: 1 !important;
    scroll-behavior: auto !important;
  }
}

@media (max-width: 980px) {
  .hero,
  .split-panel {
    grid-template-columns: 1fr;
  }

  .motion-strip,
  .value-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 720px) {
  .topbar {
    min-height: 58px;
  }

  .chapter-nav {
    display: none;
  }

  .section-panel {
    min-height: auto;
    padding: 44px 16px;
  }

  .desktop-mock,
  .reminder-demo,
  .signal-demo {
    min-height: 360px;
  }

  .mock-window {
    left: 7%;
    top: 24%;
    width: 76%;
    min-height: 150px;
    padding: 18px;
  }

  .pet-stage {
    width: 122px;
    right: 0;
    bottom: 12%;
  }

  .motion-strip {
    display: flex;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
    padding-bottom: 10px;
  }

  .motion-strip article {
    flex: 0 0 72%;
    scroll-snap-align: start;
  }

  .privacy-grid,
  .value-grid {
    grid-template-columns: 1fr;
  }

  .flow {
    grid-template-columns: 1fr 1fr;
    padding: 24px 16px 0;
  }

  .demo-controller {
    left: 8px;
    right: 8px;
    bottom: 8px;
    justify-content: space-between;
  }

  .demo-controller span {
    min-width: 72px;
  }

  .demo-controller button {
    padding: 0 10px;
  }
}
```

- [ ] **Step 2: Run validator and confirm missing script failure**

Run:

```bash
node investor-demo/validate-demo.mjs
```

Expected: fails with `Missing required file: script.js`.

- [ ] **Step 3: Commit**

Run:

```bash
git add investor-demo/styles.css
git commit -m "feat: style animated investor demo"
```

Expected: commit includes only `investor-demo/styles.css`.

---

### Task 4: Add Interactions And Recording Mode

**Files:**

- Create: `investor-demo/script.js`

- [ ] **Step 1: Write the demo controller**

Create `investor-demo/script.js`:

```js
const demoSteps = [
  { id: "hero", label: "1/7 产品定位", duration: 20000 },
  { id: "work", label: "2/7 工作陪伴", duration: 30000 },
  { id: "leisure", label: "3/7 休闲动作", duration: 25000 },
  { id: "reminders", label: "4/7 轻提醒", duration: 30000 },
  { id: "signals", label: "5/7 状态感知", duration: 30000 },
  { id: "privacy", label: "6/7 本地隐私", duration: 25000 },
  { id: "investor", label: "7/7 投资亮点", duration: 30000 }
];

let currentStep = 0;
let timer = null;
let paused = false;
let flowStep = 0;

const body = document.body;
const progress = document.querySelector("#demoProgress");
const startButton = document.querySelector("#startDemo");
const pauseButton = document.querySelector("#pauseDemo");
const nextButton = document.querySelector("#nextStep");
const prevButton = document.querySelector("#prevStep");
const reminderStatus = document.querySelector("#reminderStatus");
const reminderBubble = document.querySelector("#reminderBubble");

function clearTimer() {
  if (timer) {
    window.clearTimeout(timer);
    timer = null;
  }
}

function updateActiveStep(index) {
  document.querySelectorAll("[data-demo-step]").forEach((section) => {
    section.classList.toggle("active-step", Number(section.dataset.demoStep) === index);
  });
}

function showStep(index, shouldAutoAdvance = true) {
  clearTimer();
  currentStep = (index + demoSteps.length) % demoSteps.length;
  const step = demoSteps[currentStep];
  const section = document.querySelector(`#${step.id}`);
  body.classList.add("recording-active");
  updateActiveStep(currentStep);
  progress.textContent = step.label;
  section.scrollIntoView({ behavior: "smooth", block: "start" });

  if (step.id === "signals") {
    flowStep = 0;
    setFlowStep(flowStep);
  }

  if (shouldAutoAdvance && !paused) {
    timer = window.setTimeout(() => showStep(currentStep + 1), step.duration);
  }
}

function startDemo() {
  paused = false;
  pauseButton.textContent = "暂停";
  showStep(0);
}

function pauseDemo() {
  paused = !paused;
  pauseButton.textContent = paused ? "继续" : "暂停";
  if (paused) {
    clearTimer();
  } else {
    showStep(currentStep);
  }
}

function handleReminderAction(action) {
  const labels = {
    done: "已完成：小猫给你一个轻微正反馈",
    later: "已延后：提醒进入队列，等安静状态结束后再出现",
    skip: "已跳过：今天不再打扰"
  };
  reminderStatus.textContent = labels[action];
  reminderBubble.dataset.state = action;
  if (action === "done") {
    document.querySelector(".reminder-pet").src = "assets/miu-celebrate.gif";
  }
}

function setFlowStep(step) {
  const items = [...document.querySelectorAll("[data-flow-step]")];
  items.forEach((item) => {
    item.classList.toggle("active", Number(item.dataset.flowStep) === step);
  });
}

function advanceFlow() {
  flowStep = (flowStep + 1) % 4;
  setFlowStep(flowStep);
}

startButton.addEventListener("click", startDemo);
pauseButton.addEventListener("click", pauseDemo);
nextButton.addEventListener("click", () => showStep(currentStep + 1, !paused));
prevButton.addEventListener("click", () => showStep(currentStep - 1, !paused));

document.querySelectorAll("[data-reminder-action]").forEach((button) => {
  button.addEventListener("click", () => handleReminderAction(button.dataset.reminderAction));
});

window.setInterval(advanceFlow, 1600);

document.addEventListener("keydown", (event) => {
  if (event.key === "ArrowRight") {
    showStep(currentStep + 1, !paused);
  }
  if (event.key === "ArrowLeft") {
    showStep(currentStep - 1, !paused);
  }
  if (event.key === " ") {
    event.preventDefault();
    pauseDemo();
  }
});

setFlowStep(0);
```

- [ ] **Step 2: Run validator and confirm missing docs failure**

Run:

```bash
node investor-demo/validate-demo.mjs
```

Expected: fails with `Missing required file: recording-script.md`.

- [ ] **Step 3: Commit**

Run:

```bash
git add investor-demo/script.js
git commit -m "feat: add investor demo interactions"
```

Expected: commit includes only `investor-demo/script.js`.

---

### Task 5: Add Recording Script And Local Usage Notes

**Files:**

- Create: `investor-demo/recording-script.md`
- Create: `investor-demo/README.md`

- [ ] **Step 1: Write the 3-minute recording script**

Create `investor-demo/recording-script.md`:

````markdown
# 猫小伴投资方 Demo 录屏脚本

目标时长：约 3 分钟
录制方式：打开 `investor-demo/index.html`，点击“开始 3 分钟演示”，按页面自动推进录制。

## 0:00-0:20 产品定位

画面：Hero 首屏，猫小伴在模拟桌面边缘轻微呼吸。

旁白：猫小伴是一个 macOS 桌面电子宠物。它不是单纯会动的小猫，而是一个懂工作状态、低打扰、本地隐私优先的桌面陪伴 App。

## 0:20-0:55 工作陪伴

画面：进入工作场景，模拟窗口轻微移动，小猫保持在桌面边缘。

旁白：用户工作时，猫小伴会安静待在一边。它会结合前台应用、窗口覆盖率和空闲状态，尽量避开工作窗口，降低动作频率，不把陪伴变成打扰。

## 0:55-1:25 休闲动作

画面：展示探头、散步、伸懒腰、睡觉等真实动作 GIF。

旁白：当用户休闲或空闲时，它会更活跃。散步、探头、伸懒腰、睡觉这些动作来自当前项目里的真实资产，后续也可以继续扩展成宠物、动作包和皮肤体系。

## 1:25-1:55 轻提醒

画面：提醒气泡出现，依次点击“稍后”和“完成”。

旁白：猫小伴也承担轻提醒角色。喝水、休息、久坐、睡觉提醒都可以配置。重点是低打扰：安静工作、会议或全屏时，提醒会延后，不会强行打断用户。

## 1:55-2:25 状态感知

画面：流程图从前台应用、高窗口覆盖率、行为判断推进到小猫动作，调试面板显示状态。

旁白：它的底层不是随机动画，而是一套轻量的桌面行为感知系统。应用分类、窗口覆盖、空闲时间、北京时间节律，都会影响它下一步做什么。

## 2:25-2:35 本地隐私

画面：隐私边界三栏。

旁白：当前版本本地读取应用名称、窗口几何和空闲时间，本地保存设置与提醒。不上传屏幕内容，不读取窗口正文，也不联网同步数据。

## 2:35-3:00 投资亮点

画面：投资亮点卡片。

旁白：猫小伴验证的是一个长期停留在桌面边缘的陪伴入口。它可以从桌面宠物扩展到情绪陪伴、办公健康提醒、个性化皮肤、AI 对话和品牌联名。当前版本已经能跑，下一步是把体验打磨成可规模化的消费级产品。
````

- [ ] **Step 2: Write usage notes**

Create `investor-demo/README.md`:

````markdown
# 猫小伴投资方互动 Demo

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

## 手机展示

页面已按 360px 宽度做移动端适配。手机展示时建议用竖屏，一屏看一个重点。

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
````

- [ ] **Step 3: Run validator and confirm pass**

Run:

```bash
node investor-demo/validate-demo.mjs
```

Expected: `Investor demo validation passed.`

- [ ] **Step 4: Commit**

Run:

```bash
git add investor-demo/recording-script.md investor-demo/README.md
git commit -m "docs: add investor demo recording guide"
```

Expected: commit includes only `investor-demo/recording-script.md` and `investor-demo/README.md`.

---

### Task 6: Visual Verification And Polish

**Files:**

- Modify: `investor-demo/index.html`
- Modify: `investor-demo/styles.css`
- Modify: `investor-demo/script.js`

- [ ] **Step 1: Start local preview server**

Run:

```bash
python3 -m http.server 4173 --directory investor-demo
```

Expected: terminal shows `Serving HTTP on :: port 4173` or `Serving HTTP on 0.0.0.0 port 4173`.

- [ ] **Step 2: Open and inspect desktop viewport**

Open:

```text
http://localhost:4173
```

Check at desktop width:

- Hero shows product name, animated pet, simulated desktop window, and clear positioning.
- Work section shows moving window and pet edge placement.
- Leisure section shows multiple real GIF actions.
- Reminder buttons update the bubble status.
- Recording controls advance sections.

- [ ] **Step 3: Open and inspect mobile viewport**

Use browser responsive mode or a phone-width viewport of 390 x 844.

Check:

- No text overlaps or button overflow.
- Hero remains understandable without reading long paragraphs.
- Motion strip scrolls horizontally.
- Demo controller does not cover important text.
- Recording mode can advance manually.

- [ ] **Step 4: Fix any visual issues with targeted CSS changes**

Use these exact adjustment patterns only when the check reveals the issue:

```css
@media (max-width: 720px) {
  .lead,
  .copy p:not(.eyebrow),
  .section-heading p:not(.eyebrow) {
    font-size: 16px;
    line-height: 1.62;
  }

  .demo-controller {
    transform: none;
  }
}
```

If the controller covers content on mobile, add bottom padding:

```css
@media (max-width: 720px) {
  body {
    padding-bottom: 86px;
  }
}
```

- [ ] **Step 5: Re-run validator**

Run:

```bash
node investor-demo/validate-demo.mjs
```

Expected: `Investor demo validation passed.`

- [ ] **Step 6: Commit**

Run:

```bash
git add investor-demo/index.html investor-demo/styles.css investor-demo/script.js investor-demo/recording-script.md investor-demo/README.md
git commit -m "fix: polish investor demo responsive behavior"
```

Expected: commit includes only files changed during visual polish.

---

## Self-Review Checklist

- Spec coverage: the plan covers animated hero, work avoidance demo, leisure GIF previews, reminder interaction, state-flow animation, privacy section, investor value section, recording mode, mobile adaptation, script, README, and validation.
- Placeholder scan: no plan step uses open-ended placeholders; each created file has concrete content.
- Type consistency: `demoSteps`, `startDemo`, `showStep`, `handleReminderAction`, and `setFlowStep` are defined in `script.js` and checked by `validate-demo.mjs`.
- Asset consistency: all HTML asset references match files copied in Task 1.
- Verification: `node investor-demo/validate-demo.mjs` is required before visual QA and after polish.

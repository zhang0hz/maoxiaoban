# 猫小伴 Desktop Runner

Native macOS runner for 猫小伴.

Release identity:

- Product name: 猫小伴
- Bundle ID: `com.zhanghz.maoxiaoban`
- Version: `1.0.1`
- App bundle: `猫小伴.app`
- Data directory: `~/Library/Application Support/MaoXiaoBan`

Features:

- Transparent borderless floating window.
- Click and drag 猫小伴 to move it.
- After manual drag, 猫小伴 keeps that position until `猫小伴` -> `重置位置`.
- Right-click 猫小伴 to open the same control menu as the menu bar item.
- Chinese menu.
- Manual mode switch: 自动 / 工作 / 休闲 / 睡觉.
- 自动贴边 toggle.
- 暂停动画 toggle.
- Size switch: 小 / 中 / 大.
- System-wide work/leisure detection in Auto mode.
- Menu shows current detected status and reason.
- Current app classification override: 工作 / 休闲 / 沟通/会议 / 中性 / 清除.
- Light reminder system for water, rest, standing, and sleep.
- Reminder bubble actions: 完成 / 稍后10 / 跳过 / 关闭.
- Configurable reminder bubble auto-dismiss: 10秒 / 30秒 / 60秒 / 不自动.
- Reminder editor in settings: enable switch, interval/fixed time, active time range, and message.
- Reminder queue defers and replays reminders during fullscreen / quiet states.
- Settings overview shows version, build number, Bundle ID, and internal distribution status.
- Behavior settings include `恢复推荐设置` for non-destructive return to recommended mode, placement, animation, and size.
- Behavior decisions use an explicit state-machine layer.
- Behavior debug panel in settings shows state, action, app classification, window coverage, placement, reminder queue, recent behavior log, and copyable diagnostics.
- Leisure walking uses direction-specific `walk-right` / `walk-left` frames, so Miu does not moonwalk.
- Reads Phase 1 action frames from `phase1-actions/frames`.
- Uses Beijing-time behavior:
  - `23:30 - 07:30`: sleep
  - `07:30 - 09:00`: wake/stretch
  - `09:00 - 18:30`: quiet work companion
  - `18:30 - 22:30`: leisure peek / edge walk
  - `22:30 - 23:30`: sleepy groom
- Hides when a fullscreen/presentation-sized window is detected.

Roadmap:

- See `STANDALONE_APP_ROADMAP.md` for the independent app and system-wide work/leisure detection plan.
- See `V0.4_STANDALONE_APP.md` for standalone app build notes.
- See `V0.4.1_SETTINGS_PERSISTENCE.md` for settings persistence and login-start notes.
- See `V0.5_REMINDERS.md` for reminder behavior and config notes.
- See `V0.18_BEHAVIOR_DEBUG_PANEL.md` for behavior debug panel notes.
- See `V1.0_EXPERIENCE_QA.md` for final experience QA notes.
- See `V1.0.2_INTERNAL_PATCH.md` for the current internal patch boundary.
- See `V0.19_BEHAVIOR_TUNING.md` for quieter work behavior and slower action switching.
- See `V0.20_VISUAL_MOTION.md` for transition, micro-expression, and breathing-idle notes.
- See `V1.2_SETTINGS_EXPERIENCE.md` for settings simplification and reminder validation.
- See `V1.3_DISTRIBUTION_READY.md` for public release handoff notes.
- See `GITHUB_RELEASE_DRAFT.md` for release-note copy and upload checklist.

Build:

```bash
swiftc -O -framework AppKit -framework CoreGraphics -framework ServiceManagement \
  miu-pet-run/desktop-runner/*.swift \
  -o miu-pet-run/desktop-runner/MiuDesktopRunner
```

Build app bundle:

```bash
miu-pet-run/desktop-runner/build-app.sh
```

Run V1.0 smoke test:

```bash
miu-pet-run/desktop-runner/smoke-test.sh
```

Build app icon:

```bash
miu-pet-run/desktop-runner/build-icon.sh
```

Build standalone distribution:

```bash
miu-pet-run/desktop-runner/build-dist.sh
```

Build release package:

```bash
miu-pet-run/desktop-runner/build-release.sh
```

Build DMG only:

```bash
miu-pet-run/desktop-runner/build-dmg.sh
```

Release signing:

- Local builds use ad-hoc signing by default.
- Copy `miu-pet-run/desktop-runner/release.env.example` to `release.env`.
- Set `SIGN_IDENTITY` to a Developer ID Application identity for public release.
- Set `NOTARIZE=1` after configuring `xcrun notarytool store-credentials`.
- Verify with:

```bash
miu-pet-run/desktop-runner/verify-release.sh
```

Run:

```bash
miu-pet-run/desktop-runner/MiuDesktopRunner \
  --asset-root miu-pet-run/phase1-actions/frames
```

Run standalone distribution:

```bash
open miu-pet-run/dist/猫小伴.app
```

Open DMG installer:

```bash
open miu-pet-run/dist/猫小伴.dmg
```

Install standalone app to `/Applications`:

```bash
miu-pet-run/desktop-runner/install-to-applications.sh
```

Run app bundle:

```bash
open miu-pet-run/desktop-runner/猫小伴.app
```

Quit:

- Use the macOS menu bar item `猫小伴` -> `退出猫小伴`.
- Or stop the terminal process with `Ctrl+C`.
- Or run:

```bash
miu-pet-run/desktop-runner/stop-miu.sh
```

V0.2 controls:

- `模式 > 自动`: use Beijing-time behavior.
- `模式 > 工作`: force quiet work companion behavior.
- `模式 > 休闲`: force peek / walk behavior.
- `模式 > 睡觉`: force sleep behavior.
- `自动贴边`: let Miu place itself at a safe edge/corner.
- `重置位置`: re-enable auto positioning and move Miu back to its safe corner.
- `暂停动画` / `继续动画`: freeze or resume the current animation.
- `大小`: switch display scale.

V0.3 system activity detection:

- Reads frontmost app with `NSWorkspace.frontmostApplication`.
- Watches active app changes with `NSWorkspace.didActivateApplicationNotification`.
- Reads front window geometry with `CGWindowListCopyWindowInfo`.
- Reads user idle time with `CGEventSource.secondsSinceLastEventType`.
- Classifies apps locally:
  - work: IDE, terminal, documents, spreadsheets, design tools
  - communication: Zoom, Teams, Slack, WeChat
  - leisure: music, TV, Steam, media apps
  - browser: work during work hours or large focused window, leisure otherwise
- No screen upload. No network. No title/content reading yet.

V0.3.1 app classification overrides:

- Open menu from menu bar or right-click Miu.
- Use `当前应用分类`.
- Choices:
  - `设为工作`
  - `设为休闲`
  - `设为沟通/会议`
  - `设为中性`
  - `清除自定义分类`
- Overrides persist at:

```text
~/Library/Application Support/MaoXiaoBan/app-classifications.json
```

V0.4 standalone app:

- Distribution app: `miu-pet-run/dist/猫小伴.app`
- Zip package: `miu-pet-run/dist/猫小伴.zip`
- Frames bundled in app resources.
- Settings window: menu `设置...`.

V0.4.1 settings persistence:

- Settings file:

```text
~/Library/Application Support/MaoXiaoBan/settings.json
```

- Persists mode, size, auto-position, pause state, pinned position.
- Settings window includes `登录时自动启动猫小伴`.

V0.5 reminders:

- Local reminder file:

```text
~/Library/Application Support/MaoXiaoBan/reminders.json
```

- Default reminders:
  - 喝水: every 90 minutes, 09:00-22:00.
  - 休息: every 60 minutes, 09:00-22:30.
  - 久坐: every 90 minutes, 09:00-22:00.
  - 睡觉: fixed 23:30.
- Reminder bubble avoids fullscreen / quiet-work states.
- Bubble supports 完成, 稍后10, 跳过, 关闭.
- Menu supports 稍后 10 / 30 / 60 分钟 and shows today's completed/skipped count.
- Settings window includes `提醒气泡自动消失`: 10秒 / 30秒 / 60秒 / 不自动.
- Settings window includes reminder editing rows:
  - `启用`: turn a reminder on/off.
  - `间隔/时间`: interval minutes for 喝水/休息/久坐; fixed `HH:mm` time for 睡觉.
  - `开始` / `结束`: active time range in `HH:mm`.
  - `文案`: bubble text.

V0.18 behavior debug panel:

- Open `设置...` -> `调试`.
- Shows current state-machine result, resolved action, frontmost app classification, quiet flag, window coverage, idle time, placement mode, reminder queue, and Beijing-time day/night mode.
- Use `刷新调试信息` to force one behavior tick and refresh the panel.
- Use `复制诊断信息` to copy current state plus recent behavior log.

V1.0 experience QA:

- Run `smoke-test.sh` before handoff.
- Use `V1.0_EXPERIENCE_QA.md` for manual work, leisure, reminder, placement, night, and settings checks.

V0.19 behavior tuning:

- Work mode now stays quieter for longer and prefers `loaf` over frequent animation.
- Leisure walking starts only after longer idle time.
- Reminder motion uses a small lead-in action before the bubble appears.
- State changes use existing transition actions where available.

V0.20 visual motion:

- Calm states can use low-frequency micro-expressions such as `blink` or `ear-twitch`.
- Leisure idle can use `tail-sway` as a breathing-like loop before walking.
- Direction-specific walking remains mandatory for left/right edge movement.

V0.5 reminder editor:

  - `新增自定义提醒`: add a custom interval reminder.
  - `删除`: remove a reminder row.
  - `保存提醒设置`: write changes to local JSON.
  - `恢复默认提醒`: restore default reminder timing and text.

V0.6 settings UI:

- Settings window uses tabs:
  - `概览`: current status, next reminder, today summary, data path.
  - `行为`: mode, auto-position, pause, login start, size.
  - `提醒`: auto-dismiss, reminder editor.
  - `分类`: current app classification info and config path.

V0.7 behavior intelligence:

- Work mode picks calmer actions for meetings, deep work, large windows, and idle periods.
- Leisure mode walks only after longer idle time, peeks during relaxed idle, and purrs during active leisure.
- Idle mode shifts through sit-watch, groom, stretch, and sleep based on idle time.
- Action stability guard reduces rapid action flicker.

V0.8 visual action reactions:

- Mouse enter: purr.
- Mouse leave: purr.
- Drag end: stretch.
- Reminder complete: celebrate.
- Reminder snooze: comfort.
- Reminder skip: groom.
- Reminder close: peek.
- Color QA: `sit-watch` was replaced/aliased to `purr` to prevent gray-blue identity shift.

V0.8.1 visual asset rework:

- Added `color_audit.py` to scan all action frames for color drift.
- Keeps `sit-watch` protected through both asset replacement and runtime aliasing.
- App bundle frames are audited after packaging.

V0.9 system smartness:

- Meeting/communication apps suppress reminders.
- Presentation/fullscreen states stay low-distraction.
- Deep work windows suppress reminders.
- Large media/leisure windows reduce interruptions.
- Browser classification is quieter for large focused windows.
- Settings window height reduced and tab contents scroll to reduce empty lower space.

V0.16 reminder queue:

- Fullscreen / quiet-work states defer due reminders instead of showing bubbles.
- Deferred reminders replay first after the blocked state clears.
- Reminder menu and Overview show queue status and today's history count.
- `reminders.json` stores `deferredIds` and recent `history`.

V0.17 behavior state machine:

- Behavior flow now uses `BehaviorState` and `BehaviorDecision`.
- `updateBehavior()` collects context, checks reminders, computes a decision, then applies it.
- Fullscreen hiding, temporary reactions, work/leisure/idle/night behavior share one application path.
- Existing action timing and walking behavior stay stable.

V1.0.5 code split:

- Swift code is split into focused files:
  - `AppSupport.swift`
  - `BehaviorModels.swift`
  - `ReminderScheduler.swift`
  - `SystemActivityClassifier.swift`
  - `PetView.swift`
  - `MiuRunner+Placement.swift`
  - `MiuRunner+Settings.swift`
  - `MiuRunner+Menu.swift`
  - `MiuRunner+ReminderBubble.swift`
  - `MiuDesktopRunner.swift`
  - `main.swift`
- `build-app.sh` compiles all top-level Swift files.

V0.10 settings polish:

- Settings window height reduced to 500.
- Short tabs no longer use fixed-height scrolling, reducing lower blank space.
- Overview and Classification tabs include `打开数据目录` and `重置全部设置`.
- Classification tab can set current app as 工作 / 休闲 / 沟通会议 / 中性 / 清除.

V0.11 visual asset expansion:

- Runtime now loads `blink`, `paw-wave`, `tail-sway`, `yawn`, `ear-twitch`.
- New action folders exist under `phase1-actions/frames`.
- Current V0.11 action folders use color-audited source frames for identity-safe runtime behavior.
- Future generated replacements must pass `color_audit.py`.

V0.11.1 true redraw prep:

- Added redraw job manifest for blink, paw-wave, tail-sway, yawn, ear-twitch.
- True generated replacements must be installed one action at a time after visual review and color QA.

V0.12 smart classification/reminders:

- Classification tab lists saved app overrides.
- Overview tab shows deferred reminder state.
- Quiet work / meeting / fullscreen / media suppression defers reminders instead of completing/skipping them.

V0.13 product details:

- First-launch onboarding explains local signals and privacy.
- Reset-all now asks for confirmation.
- Data folder button exposed in Settings.

V0.14 safe placement:

- Auto-position now uses visible screen geometry, avoiding Dock and menu bar.
- Miu chooses among multiple safe positions instead of always using lower-right.
- Active window geometry is converted and used to avoid covering the front window.
- Space/display changes trigger repositioning.

V0.15 placement refinement:

- Settings > Behavior includes placement preference: Auto / Lower right / Lower left / Upper right / Upper left.
- Auto placement keeps Miu on the current display.
- Auto mode avoids unnecessary repositioning when current placement is already safe.
- Fixed corner preferences still fall back to a safer candidate if the chosen corner would cover the active window.

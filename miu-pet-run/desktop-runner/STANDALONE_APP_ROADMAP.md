# Miu Standalone App Roadmap

Goal: turn Miu from a Codex-local desktop runner into an independent macOS app that can classify system-wide work/leisure context.

## App Packaging

- Ship as `Miu.app`, independent of Codex folders.
- Bundle all action frames in `Contents/Resources`.
- Add settings UI for position, sleep schedule, animation intensity, and behavior mode.
- Add Launch at Login. (basic toggle done; formal product hardening remains)
- Add local config storage in `Application Support/Miu`.
- Sign and notarize for normal macOS distribution.

## System-Wide Activity Model

Miu should infer work/leisure from the whole computer, not Codex-only events.

Signals:

- Foreground app changes via `NSWorkspace.didActivateApplicationNotification`.
- Active window geometry via `CGWindowListCopyWindowInfo`.
- Fullscreen / presentation detection from front-window coverage.
- User idle time via `CGEventSource.secondsSinceLastEventType`.
- Optional Accessibility permission for window title, document title, browser tab title, and richer app context.
- Optional process/app categories: IDE, terminal, browser docs, design tools, meetings, media players, games.
- Optional keyboard/mouse activity rate, computed locally.

Privacy rules:

- Local classification only.
- No screen content upload.
- Ask for Accessibility permission only when richer classification is enabled.
- Let the user disable title reading and rely only on app/process/geometry/idle signals.

## Work/Leisure Classifier

Initial rule-based classifier:

- Work: IDE, terminal, docs, spreadsheets, design tools, meeting apps, large focused window, high typing activity.
- Leisure: media apps, games, casual browsing, long idle after work hours.
- Quiet mode: fullscreen, presentation, meeting, heavy typing.
- Night: Beijing-time sleep schedule overrides normal activity unless disabled.

Later upgrade path:

- User-configurable app lists.
- Per-app behavior profiles.
- Local history only for simple daily patterns.
- Reminder system plugs in after behavior is stable.

## Current Runner Gap

Current `MiuDesktopRunner` already has:

- Transparent floating window.
- Click/drag movement.
- Right-click and menu-bar controls.
- Chinese menu labels.
- Manual mode switch: Auto / Work / Leisure / Sleep.
- Auto-position toggle.
- Pause animation toggle.
- Small / Medium / Large size switch.
- Direction-specific walking frames.
- Beijing-time rhythm.
- System-wide activity classifier.
- User-configurable current-app classification overrides.
- Frontmost app detection via `NSWorkspace`.
- Active app change observer.
- Front-window coverage detection via `CGWindowListCopyWindowInfo`.
- Idle-time detection via `CGEventSource`.
- Local app category rules for work / communication / leisure / browser.
- Phase 1 action playback.
- Standalone `dist/Miu.app`.
- Bundled resources under `Contents/Resources/frames`.
- Native settings window.
- Settings persistence.
- Login-at-startup toggle.
- Zip distribution package.

Still missing for standalone app:

- Full app-classification settings editor.
- Accessibility permission flow.
- Window/title/browser-tab classifier.
- Formal Developer ID signing.
- Notarization.

## Post-V1.0 Backlog From DockCat Review

These are useful ideas, but should wait until after V1.0 packaging/publishing work:

- `MiuPacks` resource pack system with manifest-based custom cats.
- State machine extraction from the current runner.
- Reminder queue with priorities and richer deferred delivery.
- Outing / collectable light-play system.
- Local usage statistics panel.
- Dynamic app icon states.

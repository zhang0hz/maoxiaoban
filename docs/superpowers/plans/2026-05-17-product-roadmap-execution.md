# Product Roadmap Execution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Execute the six-stage 猫小伴 roadmap from baseline freeze through distribution readiness.

**Architecture:** Keep the Swift desktop runner as the product surface, with behavior tuning in `MiuRunner+Behavior.swift`, visual action selection in the existing action loader and pet view, asset governance in `phase1-actions`, settings polish in `MiuRunner+Settings.swift`, and release readiness in the existing scripts and docs. External account work such as Developer ID certificates, notarization credentials, and GitHub release upload is prepared and documented but cannot be completed without user credentials.

**Tech Stack:** Swift/AppKit, shell release scripts, Node-based behavior-layer tests, Python asset/color QA helpers, Git.

---

### Task 1: Freeze Baseline

**Files:**
- Modify: `README.md`
- Modify: `miu-pet-run/desktop-runner/RELEASE_CHECKLIST.md`
- Verify: `miu-pet-run/desktop-runner/smoke-test.sh`
- Verify: `node miu-pet-run/behavior-layer/test/behavior.test.mjs`

- [ ] Run baseline smoke and behavior tests.
- [ ] Build the local app bundle.
- [ ] Record known blockers: Git history state, Developer ID credentials, notarization credentials.
- [ ] Commit or stage the baseline if verification succeeds.

### Task 2: V0.19 Behavior Tuning

**Files:**
- Modify: `miu-pet-run/desktop-runner/MiuRunner+Behavior.swift`
- Modify: `miu-pet-run/desktop-runner/BehaviorModels.swift`
- Modify: `miu-pet-run/desktop-runner/README.md`
- Create: `miu-pet-run/desktop-runner/V0.19_BEHAVIOR_TUNING.md`

- [ ] Add tests or scriptable checks for quieter work behavior, slower action switching, less frequent leisure walking, and reminder-adjacent motion.
- [ ] Implement conservative state/action timing changes.
- [ ] Verify smoke tests and behavior tests.
- [ ] Document the tuning intent and manual QA checklist.

### Task 3: V0.20 Visual Motion Enhancement

**Files:**
- Modify: `miu-pet-run/desktop-runner/MiuRunner+Behavior.swift`
- Modify: `miu-pet-run/desktop-runner/PetView.swift`
- Modify: `miu-pet-run/phase1-actions/action-manifest.json`
- Create: `miu-pet-run/desktop-runner/V0.20_VISUAL_MOTION.md`

- [ ] Add random micro-expression and breathing-idle selection without interrupting main states.
- [ ] Prefer direction-specific walking loops and preserve existing walk placement behavior.
- [ ] Document transition-action rules and visual QA.
- [ ] Verify build and smoke test.

### Task 4: V1.1 Asset Library Cleanup

**Files:**
- Modify: `miu-pet-run/phase1-actions/action-manifest.json`
- Create: `miu-pet-run/phase1-actions/ASSET_NAMING.md`
- Create: `miu-pet-run/phase1-actions/formal-assets.json`
- Modify: `miu-pet-run/phase1-actions/README.md`

- [ ] Establish naming, frame, direction, and runtime-use conventions.
- [ ] Mark formal assets and deprecated/experimental assets without deleting source material.
- [ ] Verify all runtime actions in Swift have corresponding assets or known fallbacks.

### Task 5: V1.2 Settings Experience

**Files:**
- Modify: `miu-pet-run/desktop-runner/MiuRunner+Settings.swift`
- Modify: `miu-pet-run/desktop-runner/MiuDesktopRunner.swift`
- Modify: `miu-pet-run/desktop-runner/README.md`
- Create: `miu-pet-run/desktop-runner/V1.2_SETTINGS_EXPERIENCE.md`

- [ ] Simplify primary settings.
- [ ] Move advanced/debug-heavy controls into advanced sections or tabs.
- [ ] Improve reminder editor validation and feedback.
- [ ] Clarify first-launch guidance.
- [ ] Verify build and smoke test.

### Task 6: V1.3 Distribution Readiness

**Files:**
- Modify: `miu-pet-run/desktop-runner/RELEASE_CHECKLIST.md`
- Modify: `miu-pet-run/desktop-runner/INSTALL.md`
- Modify: `miu-pet-run/desktop-runner/UNINSTALL.md`
- Modify: `miu-pet-run/desktop-runner/README.md`
- Create: `miu-pet-run/desktop-runner/V1.3_DISTRIBUTION_READY.md`

- [ ] Verify release scripts and docs describe Developer ID signing and notarization.
- [ ] Build release app/zip/DMG where local permissions allow.
- [ ] Record exact remaining external steps for Apple credentials and GitHub Release.
- [ ] Run final verification commands and summarize the result.

import AppKit
import CoreGraphics
import Foundation

extension MiuRunner {
    func startTimers() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: config.frameInterval, repeats: true) { [weak self] _ in
            self?.advanceFrame()
        }
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: config.behaviorInterval, repeats: true) { [weak self] _ in
            self?.updateBehavior()
        }
    }

    func advanceFrame() {
        if animationPaused { return }
        guard let frames = framesByAction[currentAction], !frames.isEmpty else { return }
        frameIndex = (frameIndex + 1) % frames.count
        petView.image = frames[frameIndex]
        if currentAction == "walk-right" || currentAction == "walk-left" {
            moveAlongSafeEdge()
        }
    }

    func setAction(_ action: String) {
        let safeAction = colorSafeAction(action)
        let resolved = framesByAction[safeAction] == nil ? "loaf" : safeAction
        if currentAction != resolved {
            currentAction = resolved
            frameIndex = 0
            petView.image = framesByAction[resolved]?.first
        }
    }

    func colorSafeAction(_ action: String) -> String {
        if action == "sit-watch" {
            return "purr"
        }
        return action
    }

    func preferredAction(_ actions: [String]) -> String {
        for action in actions where framesByAction[action] != nil {
            return action
        }
        return "loaf"
    }

    func setBehaviorAction(_ action: String, minimumSeconds: TimeInterval = 2.4) {
        let now = Date()
        if action != lastBehaviorAction,
           now.timeIntervalSince(behaviorActionChangedAt) < minimumSeconds {
            setAction(lastBehaviorAction.isEmpty ? action : lastBehaviorAction)
            return
        }
        if action != lastBehaviorAction {
            lastBehaviorAction = action
            behaviorActionChangedAt = now
        }
        setAction(action)
    }

    func setTemporaryAction(_ action: String, seconds: TimeInterval) {
        guard framesByAction[action] != nil else { return }
        temporaryAction = action
        temporaryActionUntil = Date().addingTimeInterval(seconds)
        setAction(action)
    }

    func activeTemporaryAction(now: Date = Date()) -> String? {
        guard let action = temporaryAction, let until = temporaryActionUntil else { return nil }
        if until > now { return action }
        temporaryAction = nil
        temporaryActionUntil = nil
        return nil
    }

    func updateBehavior() {
        let now = Date()
        let dayMode = dayNightMode()
        let anyInput = CGEventType(rawValue: ~0)!
        let idleSeconds = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: anyInput)
        let screen = placementVisibleFrame()
        let front = frontWindowRect(on: screen)
        let coverage = front.map { windowCoverage($0, screen) } ?? 0
        let snapshot = activityClassifier.snapshot(
            idleSeconds: idleSeconds,
            coverage: coverage,
            dayNightMode: dayMode,
            frontmostApp: NSWorkspace.shared.frontmostApplication
        )
        lastActivitySnapshot = snapshot
        statusItem?.button?.toolTip = "\(snapshot.menuTitle)\n行为：\(lastBehaviorState.chineseName)\n原因：\(snapshot.reason)\n应用：\(snapshot.bundleIdentifier)"
        let mode = manualMode ?? snapshot.mode
        lastDebugIdleSeconds = idleSeconds
        lastDebugCoverage = coverage
        lastDebugScreenFrame = screen
        lastDebugFrontWindowFrame = front
        lastDebugEvaluatedMode = mode

        if let reminder = reminderScheduler.check(now: now, dayMode: dayMode, coverage: coverage, quiet: snapshot.quiet) {
            let reminderMotion = prepareReminderMotion(for: reminder.action, now: now)
            lastDebugDecision = BehaviorDecision(
                state: .temporaryReaction,
                action: reminderMotion,
                minimumSeconds: 0,
                shouldHide: false,
                shouldPlace: true,
                keepWalkingPlacement: false
            )
            lastBehaviorState = .temporaryReaction
            window.alphaValue = 1.0
            setAction(reminderMotion)
            recordBehaviorLog(decision: lastDebugDecision)
            showReminderBubble(reminder)
            if !userPositionPinned { placeCorner(screen: screen, avoiding: front) }
            if settingsWindow?.isVisible == true { syncSettingsWindow() }
            refreshMenus()
            return
        }

        var decision = behaviorDecision(mode: mode, snapshot: snapshot, coverage: coverage, idleSeconds: idleSeconds)

        if decision.state != .fullscreen,
           let temporary = activeTemporaryAction(now: now) {
            decision = BehaviorDecision(
                state: .temporaryReaction,
                action: temporary,
                minimumSeconds: 0,
                shouldHide: false,
                shouldPlace: true,
                keepWalkingPlacement: false
            )
        }
        applyBehaviorDecision(decision, screen: screen, front: front)
        if settingsWindow?.isVisible == true { syncSettingsWindow() }
    }

    func behaviorDecision(
        mode: PetMode,
        snapshot: SystemActivitySnapshot,
        coverage: CGFloat,
        idleSeconds: CFTimeInterval
    ) -> BehaviorDecision {
        if coverage >= 0.92 {
            return BehaviorDecision(
                state: .fullscreen,
                action: "sleep",
                minimumSeconds: 0,
                shouldHide: true,
                shouldPlace: true,
                keepWalkingPlacement: false
            )
        }

        switch mode {
        case .night:
            return BehaviorDecision(state: .night, action: "sleep", minimumSeconds: 5.0, shouldHide: false, shouldPlace: true, keepWalkingPlacement: false)
        case .morning:
            return BehaviorDecision(state: .morning, action: idleSeconds > 60 ? "stretch" : "wake", minimumSeconds: 4.0, shouldHide: false, shouldPlace: true, keepWalkingPlacement: false)
        case .sleepy:
            return BehaviorDecision(state: .sleepy, action: idleSeconds > 240 ? "sleep" : "groom", minimumSeconds: 5.0, shouldHide: false, shouldPlace: true, keepWalkingPlacement: false)
        case .work:
            return BehaviorDecision(state: .work, action: workAction(snapshot: snapshot, coverage: coverage, idleSeconds: idleSeconds), minimumSeconds: 9.0, shouldHide: false, shouldPlace: true, keepWalkingPlacement: false)
        case .leisure:
            return BehaviorDecision(state: .leisure, action: leisureAction(coverage: coverage, idleSeconds: idleSeconds), minimumSeconds: 7.0, shouldHide: false, shouldPlace: true, keepWalkingPlacement: true)
        case .idle:
            return BehaviorDecision(state: .idle, action: idleAction(idleSeconds: idleSeconds), minimumSeconds: 7.0, shouldHide: false, shouldPlace: true, keepWalkingPlacement: false)
        }
    }

    func applyBehaviorDecision(_ decision: BehaviorDecision, screen: NSRect, front: NSRect?) {
        let previousState = lastBehaviorState
        var appliedDecision = decision
        if !decision.shouldHide && decision.state != .temporaryReaction {
            appliedDecision.action = transitionAction(
                from: previousState,
                to: decision.state,
                target: decision.action
            )
        }

        lastDebugDecision = appliedDecision
        lastBehaviorState = appliedDecision.state
        if appliedDecision.shouldHide {
            hideReminderBubble()
            setAction(appliedDecision.action)
            window.alphaValue = 0.0
        } else {
            window.alphaValue = 1.0
            if appliedDecision.state == .temporaryReaction {
                setAction(appliedDecision.action)
            } else {
                setBehaviorAction(appliedDecision.action, minimumSeconds: appliedDecision.minimumSeconds)
            }
        }
        recordBehaviorLog(decision: appliedDecision)
        guard appliedDecision.shouldPlace && !userPositionPinned else { return }
        if appliedDecision.keepWalkingPlacement && (currentAction == "walk-right" || currentAction == "walk-left") {
            return
        }
        placeCorner(screen: screen, avoiding: front)
    }

    func recordBehaviorLog(decision: BehaviorDecision?) {
        guard let decision else { return }
        let coverageBucket = Int((lastDebugCoverage * 100).rounded())
        let signature = [
            decision.state.rawValue,
            currentAction,
            lastActivitySnapshot.bundleIdentifier,
            lastActivitySnapshot.reason,
            String(coverageBucket),
        ].joined(separator: "|")
        guard signature != lastBehaviorLogSignature else { return }

        lastBehaviorLogSignature = signature
        behaviorLog.insert(
            BehaviorLogEntry(
                date: Date(),
                state: decision.state,
                action: currentAction,
                appName: lastActivitySnapshot.appName,
                bundleIdentifier: lastActivitySnapshot.bundleIdentifier,
                reason: lastActivitySnapshot.reason,
                coverage: lastDebugCoverage,
                idleSeconds: lastDebugIdleSeconds
            ),
            at: 0
        )
        if behaviorLog.count > 20 {
            behaviorLog.removeLast(behaviorLog.count - 20)
        }
    }

    func dayNightMode(date: Date = Date()) -> PetMode {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = config.timezone
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        let minutes = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
        let wake = 7 * 60 + 30
        let work = 9 * 60
        let leisure = 18 * 60 + 30
        let sleepy = 22 * 60 + 30
        let sleep = 23 * 60 + 30

        if minutes >= sleep || minutes < wake { return .night }
        if minutes >= wake && minutes < work { return .morning }
        if minutes >= work && minutes < leisure { return .work }
        if minutes >= leisure && minutes < sleepy { return .leisure }
        if minutes >= sleepy && minutes < sleep { return .sleepy }
        return .idle
    }

    func workAction(snapshot: SystemActivitySnapshot, coverage: CGFloat, idleSeconds: CFTimeInterval) -> String {
        if snapshot.kind == .communication { return "loaf" }
        if coverage >= 0.78 { return "sleep" }
        if snapshot.quiet || coverage >= 0.55 { return idleSeconds > 600 ? "groom" : "loaf" }
        if idleSeconds > 420 { return "stretch" }
        return subtleCompanionAction(base: "loaf", idleSeconds: idleSeconds)
    }

    func leisureAction(coverage: CGFloat, idleSeconds: CFTimeInterval) -> String {
        if coverage >= 0.78 { return "loaf" }
        if idleSeconds > 480 { return walkAction() }
        if idleSeconds > 180 { return "peek" }
        return subtleCompanionAction(base: preferredAction(["tail-sway", "purr"]), idleSeconds: idleSeconds)
    }

    func idleAction(idleSeconds: CFTimeInterval) -> String {
        if idleSeconds > 900 { return "sleep" }
        if idleSeconds > 540 { return preferredAction(["yawn", "stretch"]) }
        if idleSeconds > 180 { return "groom" }
        return subtleCompanionAction(base: "purr", idleSeconds: idleSeconds)
    }

    func prepareReminderMotion(for action: String, now: Date) -> String {
        guard now.timeIntervalSince(lastReminderMotionAt) > 4.0 else { return action }
        lastReminderMotionAt = now
        if action == "sleep" { return preferredAction(["yawn", "groom", action]) }
        if action == "stretch" { return preferredAction(["paw-wave", "blink", action]) }
        return preferredAction(["paw-wave", "blink", action])
    }

    func transitionAction(from previous: BehaviorState, to next: BehaviorState, target: String) -> String {
        guard previous != next else { return target }
        switch next {
        case .morning:
            return preferredAction(["wake", "stretch", target])
        case .sleepy:
            return preferredAction(["groom", "yawn", target])
        case .night:
            return previous == .sleepy ? target : preferredAction(["groom", "yawn", target])
        case .work:
            return preferredAction(["loaf", target])
        case .leisure:
            return preferredAction(["peek", "tail-sway", target])
        case .idle:
            return preferredAction(["groom", "purr", target])
        case .fullscreen, .temporaryReaction:
            return target
        }
    }

    func subtleCompanionAction(base: String, idleSeconds: CFTimeInterval) -> String {
        let now = Date()
        guard idleSeconds < 180,
              now.timeIntervalSince(lastMicroExpressionAt) > 32
        else {
            return base
        }
        lastMicroExpressionAt = now
        return preferredAction(["blink", "ear-twitch", base])
    }
}

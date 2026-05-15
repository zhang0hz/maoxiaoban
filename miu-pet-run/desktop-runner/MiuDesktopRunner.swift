import AppKit
import CoreGraphics
import Foundation
import ServiceManagement


struct ReminderEditorControls {
    let enabledButton: NSButton
    let timingField: NSTextField
    let startField: NSTextField
    let endField: NSTextField
    let messageField: NSTextField
}

final class MiuRunner: NSObject, NSApplicationDelegate {
    let config: RunnerConfig
    var window: NSPanel!
    var petView: PetView!
    var animationTimer: Timer?
    var behaviorTimer: Timer?
    var statusItem: NSStatusItem?
    var framesByAction: [String: [NSImage]] = [:]
    var currentAction = "loaf"
    var frameIndex = 0
    var edgeDirection: CGFloat = 1
    var temporaryAction: String?
    var temporaryActionUntil: Date?
    var lastBehaviorAction = ""
    var lastBehaviorState: BehaviorState = .idle
    var behaviorActionChangedAt = Date()
    let placementMargin: CGFloat = 18
    let frontWindowAvoidanceMargin: CGFloat = 22
    var userPositionPinned = false
    var autoPositionEnabled = true
    var animationPaused = false
    var manualMode: PetMode?
    var placementPreference: PlacementPreference = .auto
    var sizeScale: CGFloat = 1.0
    let activityClassifier = SystemActivityClassifier()
    let settingsStore = SettingsStore()
    let reminderScheduler = ReminderScheduler()
    var settingsWindow: NSWindow?
    var reminderBubble: NSPanel?
    var reminderBubbleTimer: Timer?
    var statusLabel: NSTextField?
    var reasonLabel: NSTextField?
    var modeControl: NSSegmentedControl?
    var sizeControl: NSSegmentedControl?
    var placementControl: NSSegmentedControl?
    var reminderDismissControl: NSSegmentedControl?
    var reminderEditorControls: [String: ReminderEditorControls] = [:]
    var reminderEditStatusLabel: NSTextField?
    var reminderEditorNeedsSync = true
    var currentAppLabel: NSTextField?
    var currentBundleLabel: NSTextField?
    var classificationStatusLabel: NSTextField?
    var classificationListLabel: NSTextField?
    var deferredReminderLabel: NSTextField?
    var autoPositionButton: NSButton?
    var pauseButton: NSButton?
    var launchAtLoginButton: NSButton?
    var debugStateLabel: NSTextField?
    var debugActionLabel: NSTextField?
    var debugActivityLabel: NSTextField?
    var debugWindowLabel: NSTextField?
    var debugPlacementLabel: NSTextField?
    var debugReminderLabel: NSTextField?
    var debugTimingLabel: NSTextField?
    var lastDebugIdleSeconds: CFTimeInterval = 0
    var lastDebugCoverage: CGFloat = 0
    var lastDebugScreenFrame: NSRect = .zero
    var lastDebugFrontWindowFrame: NSRect?
    var lastDebugEvaluatedMode: PetMode = .idle
    var lastDebugDecision: BehaviorDecision?
    var hasCompletedOnboarding = false
    var restoredWindowOrigin: NSPoint?
    var lastActivitySnapshot = SystemActivitySnapshot(
        mode: .idle,
        kind: .neutral,
        appName: "未知应用",
        bundleIdentifier: "unknown",
        reason: "尚未检测",
        quiet: false
    )

    var displaySize: CGSize {
        CGSize(
            width: round(config.displaySize.width * sizeScale),
            height: round(config.displaySize.height * sizeScale)
        )
    }

    init(config: RunnerConfig) {
        self.config = config
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        loadSettings()
        loadFrames()
        createStatusItem()
        createWindow()
        observeSystemActivity()
        updateBehavior()
        startTimers()
        showOnboardingIfNeeded()
    }

    func loadFrames() {
        let actions = [
            "loaf", "sleep", "wake", "stretch", "peek", "edge-walk",
            "groom", "purr", "sit-watch", "celebrate", "comfort",
            "walk-right", "walk-left",
            "blink", "ear-twitch", "tail-sway", "yawn", "paw-wave",
        ]
        for action in actions {
            let dir = config.assetRoot.appendingPathComponent(action, isDirectory: true)
            var frames: [NSImage] = []
            for index in 0..<12 {
                let url = dir.appendingPathComponent(String(format: "%02d.png", index))
                guard FileManager.default.fileExists(atPath: url.path) else { continue }
                if let image = NSImage(contentsOf: url) {
                    image.size = config.displaySize
                    frames.append(image)
                }
            }
            if !frames.isEmpty {
                framesByAction[action] = frames
            }
        }
    }

    @objc func resetPosition() {
        autoPositionEnabled = true
        userPositionPinned = false
        updateBehavior()
        saveSettings()
        refreshMenus()
    }

    @objc func setModeFromMenu(_ sender: NSMenuItem) {
        switch sender.representedObject as? String {
        case "work":
            manualMode = .work
        case "leisure":
            manualMode = .leisure
        case "sleep":
            manualMode = .night
        default:
            manualMode = nil
        }
        updateBehavior()
        saveSettings()
        refreshMenus()
    }

    @objc func toggleAutoPosition() {
        if autoPositionEnabled && !userPositionPinned {
            autoPositionEnabled = false
            userPositionPinned = true
        } else {
            autoPositionEnabled = true
            userPositionPinned = false
            updateBehavior()
        }
        saveSettings()
        refreshMenus()
    }

    @objc func toggleAnimationPaused() {
        animationPaused.toggle()
        saveSettings()
        refreshMenus()
    }

    @objc func setSizeFromMenu(_ sender: NSMenuItem) {
        switch sender.representedObject as? String {
        case "small":
            sizeScale = 0.8
        case "large":
            sizeScale = 1.25
        default:
            sizeScale = 1.0
        }
        applyPetSize()
        saveSettings()
        refreshMenus()
    }

    @objc func setCurrentAppClassification(_ sender: NSMenuItem) {
        let bundleId = lastActivitySnapshot.bundleIdentifier
        switch sender.representedObject as? String {
        case "work":
            activityClassifier.setOverride(.work, for: bundleId)
        case "leisure":
            activityClassifier.setOverride(.leisure, for: bundleId)
        case "communication":
            activityClassifier.setOverride(.communication, for: bundleId)
        case "neutral":
            activityClassifier.setOverride(.neutral, for: bundleId)
        default:
            activityClassifier.setOverride(nil, for: bundleId)
        }
        updateBehavior()
        refreshMenus()
    }

    @objc func openSettings() {
        if settingsWindow == nil {
            settingsWindow = makeSettingsWindow()
        }
        reminderEditorNeedsSync = true
        syncSettingsWindow()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func settingsModeChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 1:
            manualMode = .work
        case 2:
            manualMode = .leisure
        case 3:
            manualMode = .night
        default:
            manualMode = nil
        }
        updateBehavior()
        saveSettings()
        refreshMenus()
        syncSettingsWindow()
    }

    @objc func settingsSizeChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            sizeScale = 0.8
        case 2:
            sizeScale = 1.25
        default:
            sizeScale = 1.0
        }
        applyPetSize()
        saveSettings()
        refreshMenus()
        syncSettingsWindow()
    }

    @objc func settingsPlacementChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 1:
            placementPreference = .lowerRight
        case 2:
            placementPreference = .lowerLeft
        case 3:
            placementPreference = .upperRight
        case 4:
            placementPreference = .upperLeft
        default:
            placementPreference = .auto
        }
        autoPositionEnabled = true
        userPositionPinned = false
        let screen = placementVisibleFrame()
        placeCorner(screen: screen, avoiding: frontWindowRect(on: screen), force: true)
        saveSettings()
        refreshMenus()
        syncSettingsWindow()
    }

    @objc func settingsAutoPositionChanged(_ sender: NSButton) {
        autoPositionEnabled = sender.state == .on
        userPositionPinned = !autoPositionEnabled
        if autoPositionEnabled { updateBehavior() }
        saveSettings()
        refreshMenus()
        syncSettingsWindow()
    }

    @objc func settingsPauseChanged(_ sender: NSButton) {
        animationPaused = sender.state == .on
        saveSettings()
        refreshMenus()
        syncSettingsWindow()
    }

    @objc func settingsLaunchAtLoginChanged(_ sender: NSButton) {
        setLaunchAtLoginEnabled(sender.state == .on)
        syncSettingsWindow()
    }

    @objc func settingsClassifyCurrentApp(_ sender: NSButton) {
        let bundleId = lastActivitySnapshot.bundleIdentifier
        switch sender.identifier?.rawValue {
        case "work":
            activityClassifier.setOverride(.work, for: bundleId)
        case "leisure":
            activityClassifier.setOverride(.leisure, for: bundleId)
        case "communication":
            activityClassifier.setOverride(.communication, for: bundleId)
        case "neutral":
            activityClassifier.setOverride(.neutral, for: bundleId)
        default:
            activityClassifier.setOverride(nil, for: bundleId)
        }
        classificationStatusLabel?.stringValue = "已更新当前应用分类"
        updateBehavior()
        refreshMenus()
        syncSettingsWindow()
    }

    @objc func openDataFolder() {
        NSWorkspace.shared.open(AppIdentity.applicationSupportDirectory())
    }

    @objc func resetAllSettings() {
        let alert = NSAlert()
        alert.messageText = "重置\(AppIdentity.displayName)设置？"
        alert.informativeText = "会重置行为设置、提醒、应用分类和位置。此操作会立刻生效。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "重置")
        alert.addButton(withTitle: "取消")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        manualMode = nil
        autoPositionEnabled = true
        animationPaused = false
        placementPreference = .auto
        sizeScale = 1.0
        userPositionPinned = false
        hasCompletedOnboarding = true
        restoredWindowOrigin = nil
        activityClassifier.clearOverrides()
        reminderScheduler.resetReminders()
        hideReminderBubble()
        applyPetSize()
        saveSettings()
        classificationStatusLabel?.stringValue = "已重置设置、提醒、应用分类"
        reminderEditorNeedsSync = true
        refreshMenus()
        syncSettingsWindow()
    }

    @objc func settingsReminderDismissChanged(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0:
            reminderScheduler.setBubbleAutoDismissSeconds(10)
        case 1:
            reminderScheduler.setBubbleAutoDismissSeconds(30)
        case 2:
            reminderScheduler.setBubbleAutoDismissSeconds(60)
        default:
            reminderScheduler.setBubbleAutoDismissSeconds(nil)
        }
        syncSettingsWindow()
    }

    @objc func saveReminderEdits() {
        reminderScheduler.replaceReminders(collectReminderEdits())
        reminderEditStatusLabel?.stringValue = "已保存提醒设置"
        setTemporaryAction("celebrate", seconds: 2.2)
        reminderEditorNeedsSync = true
        refreshMenus()
        syncSettingsWindow()
    }

    @objc func resetReminderEdits() {
        reminderScheduler.resetReminders()
        hideReminderBubble()
        reminderEditStatusLabel?.stringValue = "已恢复默认提醒"
        reminderEditorNeedsSync = true
        refreshMenus()
        syncSettingsWindow()
    }

    @objc func addCustomReminder() {
        var updated = collectReminderEdits()
        let now = Int(Date().timeIntervalSince1970)
        updated.append(ReminderConfig(
            id: "custom-\(now)",
            kind: .custom,
            enabled: true,
            intervalMinutes: 60,
            fixedTime: nil,
            activeStart: "09:00",
            activeEnd: "22:00",
            message: "自定义提醒",
            action: "purr",
            lastTriggeredAt: nil,
            lastCompletedAt: Date().timeIntervalSince1970,
            snoozedUntil: nil,
            skipDate: nil
        ))
        reminderScheduler.replaceReminders(updated)
        rebuildSettingsWindow()
        refreshMenus()
    }

    @objc func deleteReminderFromEditor(_ sender: NSButton) {
        guard let id = sender.identifier?.rawValue else { return }
        let updated = collectReminderEdits().filter { $0.id != id }
        reminderScheduler.replaceReminders(updated)
        rebuildSettingsWindow()
        refreshMenus()
    }

    @objc func completeReminder() {
        reminderScheduler.completeActive()
        hideReminderBubble()
        setTemporaryAction("celebrate", seconds: 2.4)
        updateBehavior()
        refreshMenus()
    }

    @objc func snoozeReminder10() {
        reminderScheduler.snoozeActive(minutes: 10)
        hideReminderBubble()
        setTemporaryAction("comfort", seconds: 2.0)
        refreshMenus()
    }

    @objc func snoozeReminder30() {
        reminderScheduler.snoozeActive(minutes: 30)
        hideReminderBubble()
        setTemporaryAction("comfort", seconds: 2.0)
        refreshMenus()
    }

    @objc func snoozeReminder60() {
        reminderScheduler.snoozeActive(minutes: 60)
        hideReminderBubble()
        setTemporaryAction("comfort", seconds: 2.0)
        refreshMenus()
    }

    @objc func skipReminderToday() {
        reminderScheduler.skipActiveToday()
        hideReminderBubble()
        setTemporaryAction("groom", seconds: 2.0)
        refreshMenus()
    }

    @objc func dismissReminderBubble() {
        reminderScheduler.dismissActive()
        hideReminderBubble()
        setTemporaryAction("peek", seconds: 1.6)
        refreshMenus()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    @objc func activeApplicationChanged(_ notification: Notification) {
        updateBehavior()
        refreshMenus()
    }

    func observeSystemActivity() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeApplicationChanged(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeApplicationChanged(_:)),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(activeApplicationChanged(_:)),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func createWindow() {
        let screen = NSScreen.main?.visibleFrame ?? NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        let origin = restoredWindowOrigin ?? NSPoint(
            x: screen.maxX - displaySize.width - config.margin,
            y: screen.minY + config.margin
        )
        let start = NSRect(
            x: origin.x,
            y: origin.y,
            width: displaySize.width,
            height: displaySize.height
        )
        window = NSPanel(
            contentRect: start,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.ignoresMouseEvents = false
        window.hidesOnDeactivate = false

        petView = PetView(frame: NSRect(origin: .zero, size: displaySize))
        petView.onUserDragged = { [weak self] in
            self?.userPositionPinned = true
            self?.autoPositionEnabled = false
            self?.refreshMenus()
        }
        petView.onUserDragEnded = { [weak self] in
            self?.setTemporaryAction("stretch", seconds: 2.4)
            self?.saveSettings()
        }
        petView.onMouseEnteredPet = { [weak self] in
            self?.setTemporaryAction(self?.preferredAction(["paw-wave", "purr"]) ?? "purr", seconds: 1.8)
        }
        petView.onMouseExitedPet = { [weak self] in
            self?.setTemporaryAction(self?.preferredAction(["blink", "purr"]) ?? "purr", seconds: 1.4)
        }
        petView.contextMenuProvider = { [weak self] in
            self?.makeControlMenu() ?? NSMenu()
        }
        petView.wantsLayer = true
        petView.layer?.backgroundColor = NSColor.clear.cgColor
        window.contentView = petView
        window.orderFrontRegardless()
    }

    func loadSettings() {
        let settings = settingsStore.load()
        if let raw = settings.manualMode {
            manualMode = PetMode(rawValue: raw)
        } else {
            manualMode = nil
        }
        autoPositionEnabled = settings.autoPositionEnabled
        animationPaused = settings.animationPaused
        sizeScale = min(max(settings.sizeScale, 0.6), 1.6)
        placementPreference = PlacementPreference(rawValue: settings.placementPreference ?? "") ?? .auto
        userPositionPinned = settings.userPositionPinned
        hasCompletedOnboarding = settings.hasCompletedOnboarding
        if (settings.userPositionPinned || !settings.autoPositionEnabled),
           let x = settings.windowX,
           let y = settings.windowY {
            restoredWindowOrigin = NSPoint(x: x, y: y)
        }
    }

    func saveSettings() {
        let frame = window?.frame
        settingsStore.save(
            AppSettings(
                manualMode: manualMode?.rawValue,
                autoPositionEnabled: autoPositionEnabled,
                animationPaused: animationPaused,
                sizeScale: sizeScale,
                userPositionPinned: userPositionPinned,
                windowX: frame?.origin.x,
                windowY: frame?.origin.y,
                hasCompletedOnboarding: hasCompletedOnboarding,
                placementPreference: placementPreference.rawValue
            )
        )
    }

    func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("\(AppIdentity.displayName) failed to update launch-at-login: \(error)")
            }
        }
    }

    func showOnboardingIfNeeded() {
        guard !hasCompletedOnboarding else { return }
        let alert = NSAlert()
        alert.messageText = "欢迎使用\(AppIdentity.displayName)"
        alert.informativeText = "\(AppIdentity.displayName)会读取当前前台应用、窗口大小和空闲时间，用来判断工作、休闲、会议和提醒时机。不会上传屏幕内容。可在设置里管理提醒、应用分类和登录启动。"
        alert.addButton(withTitle: "打开设置")
        alert.addButton(withTitle: "知道了")
        hasCompletedOnboarding = true
        saveSettings()
        if alert.runModal() == .alertFirstButtonReturn {
            openSettings()
        }
    }

}

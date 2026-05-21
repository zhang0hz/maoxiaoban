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
    var lastMicroExpressionAt = Date()
    var lastReminderMotionAt = Date(timeIntervalSince1970: 0)
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
    var debugLogLabel: NSTextField?
    var debugCopyStatusLabel: NSTextField?
    var lastDebugIdleSeconds: CFTimeInterval = 0
    var lastDebugCoverage: CGFloat = 0
    var lastDebugScreenFrame: NSRect = .zero
    var lastDebugFrontWindowFrame: NSRect?
    var lastDebugEvaluatedMode: PetMode = .idle
    var lastDebugDecision: BehaviorDecision?
    var behaviorLog: [BehaviorLogEntry] = []
    var lastBehaviorLogSignature = ""
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

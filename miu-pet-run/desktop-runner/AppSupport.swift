
import AppKit
import CoreGraphics
import Foundation
import ServiceManagement

struct RunnerConfig {
    let assetRoot: URL
    let cellSize = CGSize(width: 192, height: 208)
    let displaySize = CGSize(width: 118, height: 128)
    let margin: CGFloat = 18
    let frameInterval: TimeInterval = 0.14
    let behaviorInterval: TimeInterval = 1.2
    let timezone = TimeZone(identifier: "Asia/Shanghai")!
}

enum AppIdentity {
    static let displayName = "猫小伴"
    static let legacyDisplayName = "Miu"
    static let supportFolderName = "MaoXiaoBan"
    static let legacySupportFolderName = "Miu"
    static let bundleIdentifier = "com.zhanghz.maoxiaoban"

    static var supportPathDescription: String {
        "~/Library/Application Support/\(supportFolderName)"
    }

    static func applicationSupportDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)
        migrateLegacySupportIfNeeded(base: appSupport)
        return appSupport.appendingPathComponent(supportFolderName, isDirectory: true)
    }

    private static func migrateLegacySupportIfNeeded(base: URL) {
        let current = base.appendingPathComponent(supportFolderName, isDirectory: true)
        let legacy = base.appendingPathComponent(legacySupportFolderName, isDirectory: true)
        guard !FileManager.default.fileExists(atPath: current.path),
              FileManager.default.fileExists(atPath: legacy.path)
        else { return }
        do {
            try FileManager.default.copyItem(at: legacy, to: current)
        } catch {
            NSLog("\(displayName) failed to migrate legacy support folder: \(error)")
        }
    }
}

struct AppSettings: Codable {
    var manualMode: String?
    var autoPositionEnabled: Bool
    var animationPaused: Bool
    var sizeScale: CGFloat
    var userPositionPinned: Bool
    var windowX: CGFloat?
    var windowY: CGFloat?
    var hasCompletedOnboarding: Bool
    var placementPreference: String?

    init(
        manualMode: String?,
        autoPositionEnabled: Bool,
        animationPaused: Bool,
        sizeScale: CGFloat,
        userPositionPinned: Bool,
        windowX: CGFloat?,
        windowY: CGFloat?,
        hasCompletedOnboarding: Bool = false,
        placementPreference: String? = nil
    ) {
        self.manualMode = manualMode
        self.autoPositionEnabled = autoPositionEnabled
        self.animationPaused = animationPaused
        self.sizeScale = sizeScale
        self.userPositionPinned = userPositionPinned
        self.windowX = windowX
        self.windowY = windowY
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.placementPreference = placementPreference
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        manualMode = try container.decodeIfPresent(String.self, forKey: .manualMode)
        autoPositionEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoPositionEnabled) ?? true
        animationPaused = try container.decodeIfPresent(Bool.self, forKey: .animationPaused) ?? false
        sizeScale = try container.decodeIfPresent(CGFloat.self, forKey: .sizeScale) ?? 1.0
        userPositionPinned = try container.decodeIfPresent(Bool.self, forKey: .userPositionPinned) ?? false
        windowX = try container.decodeIfPresent(CGFloat.self, forKey: .windowX)
        windowY = try container.decodeIfPresent(CGFloat.self, forKey: .windowY)
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? true
        placementPreference = try container.decodeIfPresent(String.self, forKey: .placementPreference)
    }
}

final class SettingsStore {
    private let settingsURL: URL

    init() {
        let dir = AppIdentity.applicationSupportDirectory()
        self.settingsURL = dir.appendingPathComponent("settings.json")
    }

    var path: String {
        settingsURL.path
    }

    func load() -> AppSettings {
        guard let data = try? Data(contentsOf: settingsURL),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return AppSettings(
                manualMode: nil,
                autoPositionEnabled: true,
                animationPaused: false,
                sizeScale: 1.0,
                userPositionPinned: false,
                windowX: nil,
                windowY: nil,
                hasCompletedOnboarding: false,
                placementPreference: nil
            )
        }
        return decoded
    }

    func save(_ settings: AppSettings) {
        do {
            try FileManager.default.createDirectory(
                at: settingsURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(settings)
            try data.write(to: settingsURL, options: [.atomic])
        } catch {
            NSLog("\(AppIdentity.displayName) failed to save settings: \(error)")
        }
    }
}

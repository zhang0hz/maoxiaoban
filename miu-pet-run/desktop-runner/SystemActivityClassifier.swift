import AppKit
import Foundation

enum ActivityKind: String, Codable {
    case work
    case leisure
    case communication
    case neutral
    case idle

    var chineseName: String {
        switch self {
        case .work: return "工作"
        case .leisure: return "休闲"
        case .communication: return "沟通"
        case .neutral: return "中性"
        case .idle: return "空闲"
        }
    }
}

struct SystemActivitySnapshot {
    let mode: PetMode
    let kind: ActivityKind
    let appName: String
    let bundleIdentifier: String
    let reason: String
    let quiet: Bool

    var menuTitle: String {
        let modeText: String
        switch mode {
        case .work: modeText = "工作"
        case .leisure: modeText = "休闲"
        case .night: modeText = "睡觉"
        case .morning: modeText = "早晨"
        case .sleepy: modeText = "困了"
        case .idle: modeText = "空闲"
        }
        return "状态：\(modeText) · \(appName)"
    }
}

final class SystemActivityClassifier {
    private var overrides: [String: ActivityKind] = [:]
    private let overridesURL: URL

    private let workBundleIds: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92",
        "com.apple.dt.Xcode",
        "com.openai.codex",
        "com.tinyspeck.slackmacgap",
        "com.microsoft.Word",
        "com.microsoft.Excel",
        "com.microsoft.Powerpoint",
        "com.apple.iWork.Pages",
        "com.apple.iWork.Numbers",
        "com.apple.iWork.Keynote",
        "com.figma.Desktop",
        "com.bohemiancoding.sketch3",
        "com.adobe.Photoshop",
        "com.adobe.Illustrator",
    ]

    private let communicationBundleIds: Set<String> = [
        "us.zoom.xos",
        "com.microsoft.teams2",
        "com.microsoft.teams",
        "com.tencent.xinWeChat",
        "com.tencent.WeWorkMac",
        "com.apple.FaceTime",
        "com.apple.MobileSMS",
        "com.hnc.Discord",
    ]

    private let leisureBundleIds: Set<String> = [
        "com.apple.Music",
        "com.apple.TV",
        "com.apple.QuickTimePlayerX",
        "com.spotify.client",
        "com.colliderli.iina",
        "org.videolan.vlc",
        "com.valvesoftware.steam",
        "com.blizzard.launcher",
        "com.apple.Photos",
        "com.apple.iMovieApp",
        "com.tencent.QQMusicMac",
        "com.netease.163music",
    ]

    private let browserBundleIds: Set<String> = [
        "com.google.Chrome",
        "com.apple.Safari",
        "com.microsoft.edgemac",
        "org.mozilla.firefox",
        "com.brave.Browser",
    ]

    private let presentationBundleIds: Set<String> = [
        "com.microsoft.Powerpoint",
        "com.apple.iWork.Keynote",
    ]

    init() {
        let dir = AppIdentity.applicationSupportDirectory()
        self.overridesURL = dir.appendingPathComponent("app-classifications.json")
        loadOverrides()
    }

    func snapshot(
        idleSeconds: CFTimeInterval,
        coverage: CGFloat,
        dayNightMode: PetMode,
        frontmostApp: NSRunningApplication?
    ) -> SystemActivitySnapshot {
        let bundleId = frontmostApp?.bundleIdentifier ?? "unknown"
        let appName = frontmostApp?.localizedName ?? "未知应用"
        let overrideKind = overrides[bundleId]
        let kind = overrideKind ?? classify(bundleId: bundleId, appName: appName)
        let customPrefix = overrideKind == nil ? "" : "自定义："

        if kind == .communication {
            return snapshot(.work, kind, appName, bundleId, "\(customPrefix)会议/沟通应用，暂停提醒", true)
        }

        if presentationBundleIds.contains(bundleId) || coverage >= 0.92 {
            return snapshot(.work, kind, appName, bundleId, "\(customPrefix)演示/全屏窗口，低干扰", true)
        }

        if idleSeconds > 900 {
            if dayNightMode == .night || dayNightMode == .sleepy {
                return snapshot(.night, .idle, appName, bundleId, "夜间长时间空闲", true)
            }
            return snapshot(.idle, .idle, appName, bundleId, "长时间空闲", false)
        }

        if kind == .work {
            if coverage >= 0.70 {
                return snapshot(.work, kind, appName, bundleId, "\(customPrefix)深度工作窗口，暂停提醒", true)
            }
            return snapshot(.work, kind, appName, bundleId, "\(customPrefix)工作类应用", coverage >= 0.55)
        }

        if kind == .leisure {
            if dayNightMode == .night {
                return snapshot(.night, kind, appName, bundleId, "\(customPrefix)夜间休闲应用", true)
            }
            if coverage >= 0.60 {
                return snapshot(.leisure, kind, appName, bundleId, "\(customPrefix)媒体/休闲大窗口，减少打扰", true)
            }
            return snapshot(.leisure, kind, appName, bundleId, "\(customPrefix)休闲应用", false)
        }

        if overrideKind == .neutral {
            return snapshot(dayNightMode, kind, appName, bundleId, "自定义：中性应用，按时间段", dayNightMode == .work)
        }

        if browserBundleIds.contains(bundleId) {
            if dayNightMode == .work || coverage >= 0.65 {
                let quiet = coverage >= 0.70
                return snapshot(.work, .neutral, appName, bundleId, quiet ? "浏览器深度工作窗口，暂停提醒" : "浏览器 + 工作时段/大窗口", coverage >= 0.55)
            }
            return snapshot(.leisure, .neutral, appName, bundleId, coverage >= 0.70 ? "浏览器休闲大窗口，减少打扰" : "浏览器 + 非工作时段", coverage >= 0.70)
        }

        if coverage >= 0.75 {
            return snapshot(.work, kind, appName, bundleId, "大前台窗口", true)
        }

        return snapshot(dayNightMode, kind, appName, bundleId, "时间段默认", dayNightMode == .work)
    }

    func overrideKind(for bundleId: String) -> ActivityKind? {
        overrides[bundleId]
    }

    var overrideSummary: String {
        if overrides.isEmpty { return "暂无自定义应用分类" }
        return overrides
            .sorted { $0.key < $1.key }
            .map { "\($0.key)：\($0.value.chineseName)" }
            .joined(separator: "\n")
    }

    func setOverride(_ kind: ActivityKind?, for bundleId: String) {
        guard bundleId != "unknown" else { return }
        if let kind {
            overrides[bundleId] = kind
        } else {
            overrides.removeValue(forKey: bundleId)
        }
        saveOverrides()
    }

    func clearOverrides() {
        overrides.removeAll()
        saveOverrides()
    }

    var configPath: String {
        overridesURL.path
    }

    private func classify(bundleId: String, appName: String) -> ActivityKind {
        if workBundleIds.contains(bundleId) { return .work }
        if communicationBundleIds.contains(bundleId) { return .communication }
        if leisureBundleIds.contains(bundleId) { return .leisure }

        let lowerName = appName.lowercased()
        if lowerName.contains("code") || lowerName.contains("terminal") || lowerName.contains("xcode") || lowerName.contains("figma") {
            return .work
        }
        if lowerName.contains("music") || lowerName.contains("tv") || lowerName.contains("steam") || lowerName.contains("spotify") {
            return .leisure
        }
        if lowerName.contains("zoom") || lowerName.contains("teams") || lowerName.contains("slack") || lowerName.contains("wechat") {
            return .communication
        }
        return .neutral
    }

    private func loadOverrides() {
        guard let data = try? Data(contentsOf: overridesURL) else { return }
        guard let decoded = try? JSONDecoder().decode([String: ActivityKind].self, from: data) else { return }
        overrides = decoded
    }

    private func saveOverrides() {
        do {
            try FileManager.default.createDirectory(
                at: overridesURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(overrides)
            try data.write(to: overridesURL, options: [.atomic])
        } catch {
            NSLog("\(AppIdentity.displayName) failed to save app classifications: \(error)")
        }
    }

    private func snapshot(
        _ mode: PetMode,
        _ kind: ActivityKind,
        _ appName: String,
        _ bundleId: String,
        _ reason: String,
        _ quiet: Bool
    ) -> SystemActivitySnapshot {
        SystemActivitySnapshot(
            mode: mode,
            kind: kind,
            appName: appName,
            bundleIdentifier: bundleId,
            reason: reason,
            quiet: quiet
        )
    }
}

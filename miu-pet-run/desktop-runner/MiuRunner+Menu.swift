import AppKit
import Foundation

extension MiuRunner {
    func createStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.title = ""
            button.toolTip = AppIdentity.displayName
            if let image = statusBarImage() {
                image.size = NSSize(width: 18, height: 18)
                image.isTemplate = false
                button.image = image
                button.imagePosition = .imageOnly
            } else {
                button.title = AppIdentity.displayName
            }
        }
        refreshMenus()
    }

    func statusBarImage() -> NSImage? {
        if let url = Bundle.main.url(forResource: "StatusIcon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        let local = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
            .appendingPathComponent("miu-pet-run/desktop-runner/Assets/StatusIcon.png")
        return NSImage(contentsOf: local)
    }


    func refreshMenus() {
        let menu = makeControlMenu()
        statusItem?.menu = menu
    }

    func makeControlMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(disabledInfoItem(lastActivitySnapshot.menuTitle))
        menu.addItem(disabledInfoItem("原因：\(lastActivitySnapshot.reason)"))
        menu.addItem(disabledInfoItem("分类配置：已保存本地"))
        menu.addItem(.separator())

        let modeMenu = NSMenu()
        modeMenu.addItem(modeItem(title: "自动", value: "auto", selected: manualMode == nil))
        modeMenu.addItem(modeItem(title: "工作", value: "work", selected: manualMode == .work))
        modeMenu.addItem(modeItem(title: "休闲", value: "leisure", selected: manualMode == .leisure))
        modeMenu.addItem(modeItem(title: "睡觉", value: "sleep", selected: manualMode == .night))
        let modeRoot = NSMenuItem(title: "模式", action: nil, keyEquivalent: "")
        menu.addItem(modeRoot)
        menu.setSubmenu(modeMenu, for: modeRoot)

        let autoPosition = NSMenuItem(title: "自动贴边", action: #selector(toggleAutoPosition), keyEquivalent: "a")
        autoPosition.target = self
        autoPosition.state = autoPositionEnabled && !userPositionPinned ? .on : .off
        menu.addItem(autoPosition)

        let reset = NSMenuItem(title: "重置位置", action: #selector(resetPosition), keyEquivalent: "r")
        reset.target = self
        menu.addItem(reset)

        let settings = NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let pauseTitle = animationPaused ? "继续动画" : "暂停动画"
        let pause = NSMenuItem(title: pauseTitle, action: #selector(toggleAnimationPaused), keyEquivalent: "p")
        pause.target = self
        pause.state = animationPaused ? .on : .off
        menu.addItem(pause)

        let classifyMenu = NSMenu()
        let currentOverride = activityClassifier.overrideKind(for: lastActivitySnapshot.bundleIdentifier)
        classifyMenu.addItem(classificationItem(title: "设为工作", value: "work", selected: currentOverride == .work))
        classifyMenu.addItem(classificationItem(title: "设为休闲", value: "leisure", selected: currentOverride == .leisure))
        classifyMenu.addItem(classificationItem(title: "设为沟通/会议", value: "communication", selected: currentOverride == .communication))
        classifyMenu.addItem(classificationItem(title: "设为中性", value: "neutral", selected: currentOverride == .neutral))
        classifyMenu.addItem(.separator())
        classifyMenu.addItem(classificationItem(title: "清除自定义分类", value: "clear", selected: currentOverride == nil))
        let classifyRoot = NSMenuItem(title: "当前应用分类", action: nil, keyEquivalent: "")
        menu.addItem(classifyRoot)
        menu.setSubmenu(classifyMenu, for: classifyRoot)

        let reminderMenu = NSMenu()
        if let active = reminderScheduler.activeReminder {
            reminderMenu.addItem(disabledInfoItem("当前：\(active.kind.chineseName) · \(active.message)"))
            reminderMenu.addItem(reminderActionItem("完成当前提醒", #selector(completeReminder)))
            reminderMenu.addItem(reminderActionItem("稍后 10 分钟", #selector(snoozeReminder10)))
            reminderMenu.addItem(reminderActionItem("稍后 30 分钟", #selector(snoozeReminder30)))
            reminderMenu.addItem(reminderActionItem("稍后 60 分钟", #selector(snoozeReminder60)))
            reminderMenu.addItem(reminderActionItem("今天跳过", #selector(skipReminderToday)))
            reminderMenu.addItem(reminderActionItem("关闭气泡", #selector(dismissReminderBubble)))
        } else {
            reminderMenu.addItem(disabledInfoItem("下一次：\(reminderScheduler.nextSummary())"))
        }
        reminderMenu.addItem(disabledInfoItem(reminderScheduler.todayCompletionSummary()))
        reminderMenu.addItem(disabledInfoItem(currentReminderQueueSummary()))
        reminderMenu.addItem(disabledInfoItem(reminderScheduler.historySummary()))
        reminderMenu.addItem(.separator())
        reminderMenu.addItem(disabledInfoItem(autoDismissMenuTitle()))
        let reminderRoot = NSMenuItem(title: "提醒", action: nil, keyEquivalent: "")
        menu.addItem(reminderRoot)
        menu.setSubmenu(reminderMenu, for: reminderRoot)

        let sizeMenu = NSMenu()
        sizeMenu.addItem(sizeItem(title: "小", value: "small", selected: sizeScale == 0.8))
        sizeMenu.addItem(sizeItem(title: "中", value: "medium", selected: sizeScale == 1.0))
        sizeMenu.addItem(sizeItem(title: "大", value: "large", selected: sizeScale == 1.25))
        let sizeRoot = NSMenuItem(title: "大小", action: nil, keyEquivalent: "")
        menu.addItem(sizeRoot)
        menu.setSubmenu(sizeMenu, for: sizeRoot)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "退出\(AppIdentity.displayName)", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        return menu
    }

    func disabledInfoItem(_ title: String, limit: Int = 46) -> NSMenuItem {
        let displayTitle = truncatedMenuTitle(title, limit: limit)
        let item = NSMenuItem(title: displayTitle, action: nil, keyEquivalent: "")
        item.isEnabled = false
        if displayTitle != title {
            item.toolTip = title
        }
        return item
    }

    func truncatedMenuTitle(_ title: String, limit: Int = 46) -> String {
        let normalized = title
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count > limit else { return normalized }
        return String(normalized.prefix(max(1, limit - 3))) + "..."
    }

    func modeItem(title: String, value: String, selected: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(setModeFromMenu(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = value
        item.state = selected ? .on : .off
        return item
    }

    func sizeItem(title: String, value: String, selected: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(setSizeFromMenu(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = value
        item.state = selected ? .on : .off
        return item
    }

    func classificationItem(title: String, value: String, selected: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(setCurrentAppClassification(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = value
        item.state = selected ? .on : .off
        return item
    }

    func reminderActionItem(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    func autoDismissMenuTitle() -> String {
        if let seconds = reminderScheduler.bubbleAutoDismissSeconds {
            return "气泡自动消失：\(seconds) 秒"
        }
        return "气泡自动消失：不自动"
    }

    func currentReminderQueueSummary() -> String {
        let screen = placementVisibleFrame()
        let coverage = frontWindowRects(on: screen).first.map { windowCoverage($0, screen) } ?? 0
        return reminderScheduler.queueSummary(
            dayMode: dayNightMode(),
            coverage: coverage,
            quiet: lastActivitySnapshot.quiet
        )
    }
}

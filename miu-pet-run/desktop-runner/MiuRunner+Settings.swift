import AppKit
import Foundation

extension MiuRunner {
    func collectReminderEdits() -> [ReminderConfig] {
        var updated: [ReminderConfig] = []
        for reminder in reminderScheduler.reminders {
            guard let controls = reminderEditorControls[reminder.id] else {
                updated.append(reminder)
                continue
            }

            var next = reminder
            next.enabled = controls.enabledButton.state == .on
            next.activeStart = normalizedClock(controls.startField.stringValue, fallback: reminder.activeStart)
            next.activeEnd = normalizedClock(controls.endField.stringValue, fallback: reminder.activeEnd)
            let message = controls.messageField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            next.message = message.isEmpty ? "\(reminder.kind.chineseName)提醒" : message

            if reminder.fixedTime != nil {
                next.fixedTime = normalizedClock(controls.timingField.stringValue, fallback: reminder.fixedTime ?? "23:30")
                next.intervalMinutes = nil
            } else {
                let interval = Int(controls.timingField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines))
                    ?? reminder.intervalMinutes
                    ?? 60
                next.intervalMinutes = min(max(interval, 5), 720)
                next.fixedTime = nil
            }
            updated.append(next)
        }
        return updated
    }

    func rebuildSettingsWindow() {
        let wasVisible = settingsWindow?.isVisible == true
        settingsWindow?.orderOut(nil)
        settingsWindow = nil
        reminderEditorNeedsSync = true
        if wasVisible {
            openSettings()
        }
    }

    func normalizedClock(_ raw: String, fallback: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              hour >= 0,
              hour <= 23,
              minute >= 0,
              minute <= 59
        else {
            return fallback
        }
        return String(format: "%02d:%02d", hour, minute)
    }

    func isValidClock(_ raw: String) -> Bool {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1])
        else {
            return false
        }
        return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59
    }

    func validateReminderEdits() -> String? {
        for reminder in reminderScheduler.reminders {
            guard let controls = reminderEditorControls[reminder.id] else { continue }
            let timing = controls.timingField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let start = controls.startField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let end = controls.endField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

            if !isValidClock(start) {
                return "\(reminder.kind.chineseName)的开始时间需要是 HH:mm"
            }
            if !isValidClock(end) {
                return "\(reminder.kind.chineseName)的结束时间需要是 HH:mm"
            }
            if reminder.fixedTime != nil {
                if !isValidClock(timing) {
                    return "\(reminder.kind.chineseName)的固定时间需要是 HH:mm"
                }
            } else if let interval = Int(timing) {
                if interval < 5 || interval > 720 {
                    return "\(reminder.kind.chineseName)的间隔需要在 5-720 分钟之间"
                }
            } else {
                return "\(reminder.kind.chineseName)的间隔需要是分钟数字"
            }
        }
        return nil
    }

    func makeReminderEditor() -> NSView {
        reminderEditorControls.removeAll()

        let wrapper = NSStackView()
        wrapper.orientation = .vertical
        wrapper.alignment = .leading
        wrapper.spacing = 8

        let title = NSTextField(labelWithString: "提醒设置")
        title.font = NSFont.boldSystemFont(ofSize: 14)
        wrapper.addArrangedSubview(title)

        wrapper.addArrangedSubview(reminderHeaderRow())
        for reminder in reminderScheduler.reminders {
            wrapper.addArrangedSubview(reminderEditorRow(for: reminder))
        }

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.addArrangedSubview(NSButton(title: "保存提醒设置", target: self, action: #selector(saveReminderEdits)))
        buttons.addArrangedSubview(NSButton(title: "新增自定义提醒", target: self, action: #selector(addCustomReminder)))
        buttons.addArrangedSubview(NSButton(title: "恢复默认提醒", target: self, action: #selector(resetReminderEdits)))
        wrapper.addArrangedSubview(buttons)

        let status = NSTextField(labelWithString: "")
        status.font = NSFont.systemFont(ofSize: 11)
        status.textColor = .secondaryLabelColor
        reminderEditStatusLabel = status
        wrapper.addArrangedSubview(status)

        return wrapper
    }

    func reminderHeaderRow() -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8
        row.addArrangedSubview(fixedLabel("启用", width: 44, bold: true))
        row.addArrangedSubview(fixedLabel("提醒", width: 48, bold: true))
        row.addArrangedSubview(fixedLabel("间隔/时间", width: 72, bold: true))
        row.addArrangedSubview(fixedLabel("开始", width: 58, bold: true))
        row.addArrangedSubview(fixedLabel("结束", width: 58, bold: true))
        row.addArrangedSubview(fixedLabel("文案", width: 200, bold: true))
        row.addArrangedSubview(fixedLabel("删除", width: 52, bold: true))
        return row
    }

    func reminderEditorRow(for reminder: ReminderConfig) -> NSView {
        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        let enabled = NSButton(checkboxWithTitle: "", target: nil, action: nil)
        enabled.widthAnchor.constraint(equalToConstant: 44).isActive = true

        let timing = configuredField(
            reminder.fixedTime ?? String(reminder.intervalMinutes ?? 60),
            width: 72
        )
        let start = configuredField(reminder.activeStart, width: 58)
        let end = configuredField(reminder.activeEnd, width: 58)
        let message = configuredField(reminder.message, width: 200)
        let delete = NSButton(title: "删除", target: self, action: #selector(deleteReminderFromEditor(_:)))
        delete.identifier = NSUserInterfaceItemIdentifier(reminder.id)
        delete.widthAnchor.constraint(equalToConstant: 52).isActive = true

        row.addArrangedSubview(enabled)
        row.addArrangedSubview(fixedLabel(reminder.kind.chineseName, width: 48))
        row.addArrangedSubview(timing)
        row.addArrangedSubview(start)
        row.addArrangedSubview(end)
        row.addArrangedSubview(message)
        row.addArrangedSubview(delete)

        reminderEditorControls[reminder.id] = ReminderEditorControls(
            enabledButton: enabled,
            timingField: timing,
            startField: start,
            endField: end,
            messageField: message
        )
        return row
    }

    func fixedLabel(_ text: String, width: CGFloat, bold: Bool = false) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = bold ? NSFont.boldSystemFont(ofSize: 12) : NSFont.systemFont(ofSize: 12)
        label.widthAnchor.constraint(equalToConstant: width).isActive = true
        return label
    }

    func configuredField(_ text: String, width: CGFloat) -> NSTextField {
        let field = NSTextField(string: text)
        field.font = NSFont.systemFont(ofSize: 12)
        field.widthAnchor.constraint(equalToConstant: width).isActive = true
        return field
    }

    func makeSettingsWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 650, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(AppIdentity.displayName)设置"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 620, height: 460)
        window.center()

        let tabView = NSTabView()
        tabView.translatesAutoresizingMaskIntoConstraints = false
        tabView.addTabViewItem(tabItem(title: "概览", view: makeOverviewSettingsView()))
        tabView.addTabViewItem(tabItem(title: "行为", view: makeBehaviorSettingsView()))
        tabView.addTabViewItem(tabItem(title: "提醒", view: makeReminderSettingsView()))
        tabView.addTabViewItem(tabItem(title: "高级", view: makeClassificationSettingsView()))
        tabView.addTabViewItem(tabItem(title: "调试", view: makeDebugSettingsView()))

        let content = NSView()
        content.addSubview(tabView)
        NSLayoutConstraint.activate([
            tabView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 12),
            tabView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -12),
            tabView.topAnchor.constraint(equalTo: content.topAnchor, constant: 12),
            tabView.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -12),
        ])
        window.contentView = content
        return window
    }

    func tabItem(title: String, view: NSView) -> NSTabViewItem {
        let item = NSTabViewItem(identifier: title)
        item.label = title
        item.view = view
        return item
    }

    func settingsStack() -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    func wrapSettingsStack(_ stack: NSStackView, scrollable: Bool = false) -> NSView {
        let content = NSView()
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor),
            stack.topAnchor.constraint(equalTo: content.topAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor),
        ])
        if !scrollable {
            return content
        }
        content.frame = NSRect(x: 0, y: 0, width: 600, height: 460)
        let scroll = NSScrollView()
        scroll.documentView = content
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        return scroll
    }

    func makeOverviewSettingsView() -> NSView {
        let stack = settingsStack()
        let title = NSTextField(labelWithString: "\(AppIdentity.displayName)桌面宠物")
        title.font = NSFont.boldSystemFont(ofSize: 18)
        stack.addArrangedSubview(title)

        let status = NSTextField(labelWithString: "")
        statusLabel = status
        stack.addArrangedSubview(status)

        let reason = NSTextField(labelWithString: "")
        reasonLabel = reason
        reason.lineBreakMode = .byWordWrapping
        reason.maximumNumberOfLines = 2
        stack.addArrangedSubview(reason)

        let next = NSTextField(labelWithString: "下一次提醒：\(reminderScheduler.nextSummary())")
        next.font = NSFont.systemFont(ofSize: 13)
        stack.addArrangedSubview(next)

        let today = NSTextField(labelWithString: reminderScheduler.todayCompletionSummary())
        today.font = NSFont.systemFont(ofSize: 13)
        today.textColor = .secondaryLabelColor
        stack.addArrangedSubview(today)

        let deferred = NSTextField(labelWithString: "")
        deferred.font = NSFont.systemFont(ofSize: 13)
        deferred.textColor = .secondaryLabelColor
        deferred.lineBreakMode = .byWordWrapping
        deferred.maximumNumberOfLines = 3
        deferredReminderLabel = deferred
        stack.addArrangedSubview(deferred)

        let config = NSTextField(labelWithString: "数据目录：\(AppIdentity.supportPathDescription)")
        config.font = NSFont.systemFont(ofSize: 11)
        config.textColor = .secondaryLabelColor
        stack.addArrangedSubview(config)

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.addArrangedSubview(NSButton(title: "打开数据目录", target: self, action: #selector(openDataFolder)))
        buttons.addArrangedSubview(NSButton(title: "重置全部设置", target: self, action: #selector(resetAllSettings)))
        stack.addArrangedSubview(buttons)

        return wrapSettingsStack(stack)
    }

    func makeBehaviorSettingsView() -> NSView {
        let stack = settingsStack()
        stack.addArrangedSubview(NSTextField(labelWithString: "模式"))
        let mode = NSSegmentedControl(labels: ["自动", "工作", "休闲", "睡觉"], trackingMode: .selectOne, target: self, action: #selector(settingsModeChanged(_:)))
        modeControl = mode
        stack.addArrangedSubview(mode)

        let auto = NSButton(checkboxWithTitle: "自动贴边", target: self, action: #selector(settingsAutoPositionChanged(_:)))
        autoPositionButton = auto
        stack.addArrangedSubview(auto)

        stack.addArrangedSubview(NSTextField(labelWithString: "位置偏好"))
        let placement = NSSegmentedControl(labels: ["自动", "右下", "左下", "右上", "左上"], trackingMode: .selectOne, target: self, action: #selector(settingsPlacementChanged(_:)))
        placementControl = placement
        stack.addArrangedSubview(placement)

        let pause = NSButton(checkboxWithTitle: "暂停动画", target: self, action: #selector(settingsPauseChanged(_:)))
        pauseButton = pause
        stack.addArrangedSubview(pause)

        let launch = NSButton(checkboxWithTitle: "登录时自动启动\(AppIdentity.displayName)", target: self, action: #selector(settingsLaunchAtLoginChanged(_:)))
        launchAtLoginButton = launch
        stack.addArrangedSubview(launch)

        stack.addArrangedSubview(NSTextField(labelWithString: "大小"))
        let size = NSSegmentedControl(labels: ["小", "中", "大"], trackingMode: .selectOne, target: self, action: #selector(settingsSizeChanged(_:)))
        sizeControl = size
        stack.addArrangedSubview(size)

        return wrapSettingsStack(stack)
    }

    func makeReminderSettingsView() -> NSView {
        let stack = settingsStack()
        stack.addArrangedSubview(NSTextField(labelWithString: "提醒气泡自动消失"))
        let dismiss = NSSegmentedControl(labels: ["10秒", "30秒", "60秒", "不自动"], trackingMode: .selectOne, target: self, action: #selector(settingsReminderDismissChanged(_:)))
        reminderDismissControl = dismiss
        stack.addArrangedSubview(dismiss)

        stack.addArrangedSubview(makeReminderEditor())

        let config = NSTextField(labelWithString: "提醒配置：\(AppIdentity.supportPathDescription)/reminders.json")
        config.font = NSFont.systemFont(ofSize: 11)
        config.textColor = .secondaryLabelColor
        stack.addArrangedSubview(config)

        return wrapSettingsStack(stack, scrollable: true)
    }

    func makeClassificationSettingsView() -> NSView {
        let stack = settingsStack()
        let title = NSTextField(labelWithString: "高级设置：应用分类")
        title.font = NSFont.boldSystemFont(ofSize: 14)
        stack.addArrangedSubview(title)
        let app = NSTextField(labelWithString: "")
        currentAppLabel = app
        stack.addArrangedSubview(app)
        let bundle = NSTextField(labelWithString: "")
        bundle.font = NSFont.systemFont(ofSize: 11)
        bundle.textColor = .secondaryLabelColor
        currentBundleLabel = bundle
        stack.addArrangedSubview(bundle)

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.addArrangedSubview(classificationButton("工作", id: "work"))
        buttons.addArrangedSubview(classificationButton("休闲", id: "leisure"))
        buttons.addArrangedSubview(classificationButton("沟通/会议", id: "communication"))
        buttons.addArrangedSubview(classificationButton("中性", id: "neutral"))
        buttons.addArrangedSubview(classificationButton("清除", id: "clear"))
        stack.addArrangedSubview(buttons)

        let status = NSTextField(labelWithString: "")
        status.font = NSFont.systemFont(ofSize: 11)
        status.textColor = .secondaryLabelColor
        classificationStatusLabel = status
        stack.addArrangedSubview(status)

        let listTitle = NSTextField(labelWithString: "已记录分类")
        listTitle.font = NSFont.boldSystemFont(ofSize: 12)
        stack.addArrangedSubview(listTitle)

        let list = NSTextField(labelWithString: "")
        list.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        list.textColor = .secondaryLabelColor
        list.lineBreakMode = .byWordWrapping
        list.maximumNumberOfLines = 8
        classificationListLabel = list
        stack.addArrangedSubview(list)

        let utilityButtons = NSStackView()
        utilityButtons.orientation = .horizontal
        utilityButtons.spacing = 8
        utilityButtons.addArrangedSubview(NSButton(title: "打开数据目录", target: self, action: #selector(openDataFolder)))
        utilityButtons.addArrangedSubview(NSButton(title: "重置全部设置", target: self, action: #selector(resetAllSettings)))
        stack.addArrangedSubview(utilityButtons)

        let config = NSTextField(labelWithString: "分类配置：\(AppIdentity.supportPathDescription)/app-classifications.json")
        config.font = NSFont.systemFont(ofSize: 11)
        config.textColor = .secondaryLabelColor
        stack.addArrangedSubview(config)

        return wrapSettingsStack(stack)
    }

    func makeDebugSettingsView() -> NSView {
        let stack = settingsStack()
        let title = NSTextField(labelWithString: "行为调试面板")
        title.font = NSFont.boldSystemFont(ofSize: 14)
        stack.addArrangedSubview(title)

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 8
        buttons.addArrangedSubview(NSButton(title: "刷新调试信息", target: self, action: #selector(refreshDebugPanel)))
        buttons.addArrangedSubview(NSButton(title: "复制诊断信息", target: self, action: #selector(copyDebugDiagnostics)))
        stack.addArrangedSubview(buttons)

        let copyStatus = NSTextField(labelWithString: "")
        copyStatus.font = NSFont.systemFont(ofSize: 11)
        copyStatus.textColor = .secondaryLabelColor
        debugCopyStatusLabel = copyStatus
        stack.addArrangedSubview(copyStatus)

        debugStateLabel = debugLabel()
        debugActionLabel = debugLabel()
        debugActivityLabel = debugLabel(lines: 4)
        debugWindowLabel = debugLabel(lines: 4)
        debugPlacementLabel = debugLabel(lines: 3)
        debugReminderLabel = debugLabel(lines: 5)
        debugTimingLabel = debugLabel(lines: 2)
        debugLogLabel = debugLabel(lines: 12)

        [
            debugSection("状态机", debugStateLabel),
            debugSection("动作", debugActionLabel),
            debugSection("前台应用", debugActivityLabel),
            debugSection("窗口避让", debugWindowLabel),
            debugSection("位置策略", debugPlacementLabel),
            debugSection("提醒队列", debugReminderLabel),
            debugSection("时间", debugTimingLabel),
            debugSection("最近行为日志", debugLogLabel),
        ].forEach { stack.addArrangedSubview($0) }

        syncDebugPanel()
        return wrapSettingsStack(stack, scrollable: true)
    }

    func debugSection(_ title: String, _ label: NSTextField?) -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 4

        let heading = NSTextField(labelWithString: title)
        heading.font = NSFont.boldSystemFont(ofSize: 12)
        stack.addArrangedSubview(heading)
        if let label {
            stack.addArrangedSubview(label)
        }
        return stack
    }

    func debugLabel(lines: Int = 2) -> NSTextField {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        label.textColor = .secondaryLabelColor
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = lines
        label.widthAnchor.constraint(equalToConstant: 560).isActive = true
        return label
    }

    func classificationButton(_ title: String, id: String) -> NSButton {
        let button = NSButton(title: title, target: self, action: #selector(settingsClassifyCurrentApp(_:)))
        button.identifier = NSUserInterfaceItemIdentifier(id)
        return button
    }

    @objc func refreshDebugPanel() {
        updateBehavior()
        syncDebugPanel()
    }

    @objc func copyDebugDiagnostics() {
        let diagnostics = makeDebugDiagnostics()
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(diagnostics, forType: .string)
        debugCopyStatusLabel?.stringValue = "已复制诊断信息"
    }

    func syncSettingsWindow() {
        statusLabel?.stringValue = lastActivitySnapshot.menuTitle
        reasonLabel?.stringValue = "原因：\(lastActivitySnapshot.reason)"
        currentAppLabel?.stringValue = "当前应用：\(lastActivitySnapshot.appName)"
        currentBundleLabel?.stringValue = "Bundle ID：\(lastActivitySnapshot.bundleIdentifier)"
        classificationListLabel?.stringValue = activityClassifier.overrideSummary
        let screen = placementVisibleFrame()
        let coverage = frontWindowRect(on: screen).map { windowCoverage($0, screen) } ?? 0
        let dayMode = dayNightMode()
        let reminderStatus = [
            reminderScheduler.queueSummary(
                dayMode: dayMode,
                coverage: coverage,
                quiet: lastActivitySnapshot.quiet
            ),
            reminderScheduler.deferredSummary(
                dayMode: dayMode,
                coverage: coverage,
                quiet: lastActivitySnapshot.quiet
            ),
            reminderScheduler.historySummary(),
        ].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        deferredReminderLabel?.stringValue = reminderStatus.isEmpty ? "队列：无待处理" : reminderStatus
        if manualMode == .work {
            modeControl?.selectedSegment = 1
        } else if manualMode == .leisure {
            modeControl?.selectedSegment = 2
        } else if manualMode == .night {
            modeControl?.selectedSegment = 3
        } else {
            modeControl?.selectedSegment = 0
        }
        autoPositionButton?.state = autoPositionEnabled && !userPositionPinned ? .on : .off
        switch placementPreference {
        case .lowerRight:
            placementControl?.selectedSegment = 1
        case .lowerLeft:
            placementControl?.selectedSegment = 2
        case .upperRight:
            placementControl?.selectedSegment = 3
        case .upperLeft:
            placementControl?.selectedSegment = 4
        default:
            placementControl?.selectedSegment = 0
        }
        pauseButton?.state = animationPaused ? .on : .off
        launchAtLoginButton?.state = isLaunchAtLoginEnabled() ? .on : .off
        if sizeScale == 0.8 {
            sizeControl?.selectedSegment = 0
        } else if sizeScale == 1.25 {
            sizeControl?.selectedSegment = 2
        } else {
            sizeControl?.selectedSegment = 1
        }
        switch reminderScheduler.bubbleAutoDismissSeconds {
        case 10:
            reminderDismissControl?.selectedSegment = 0
        case 30:
            reminderDismissControl?.selectedSegment = 1
        case 60:
            reminderDismissControl?.selectedSegment = 2
        default:
            reminderDismissControl?.selectedSegment = 3
        }
        if reminderEditorNeedsSync {
            syncReminderEditor()
            reminderEditorNeedsSync = false
        }
        syncDebugPanel()
    }

    func syncReminderEditor() {
        for reminder in reminderScheduler.reminders {
            guard let controls = reminderEditorControls[reminder.id] else { continue }
            controls.enabledButton.state = reminder.enabled ? .on : .off
            controls.timingField.stringValue = reminder.fixedTime ?? String(reminder.intervalMinutes ?? 60)
            controls.startField.stringValue = reminder.activeStart
            controls.endField.stringValue = reminder.activeEnd
            controls.messageField.stringValue = reminder.message
        }
    }

    func syncDebugPanel() {
        let decision = lastDebugDecision
        let decisionText = decision.map {
            "\($0.state.chineseName) / \($0.action) / hide=\($0.shouldHide ? "是" : "否") / place=\($0.shouldPlace ? "是" : "否")"
        } ?? "暂无"
        let temporaryText = activeTemporaryAction() ?? "无"
        let quietText = lastActivitySnapshot.quiet ? "是" : "否"
        let manualText = manualMode?.chineseName ?? "自动"
        let frontText = lastDebugFrontWindowFrame.map(formatDebugRect) ?? "无"
        let dayMode = dayNightMode()
        let reminderStatus = [
            reminderScheduler.queueSummary(
                dayMode: dayMode,
                coverage: lastDebugCoverage,
                quiet: lastActivitySnapshot.quiet
            ),
            reminderScheduler.deferredSummary(
                dayMode: dayMode,
                coverage: lastDebugCoverage,
                quiet: lastActivitySnapshot.quiet
            ),
            reminderScheduler.historySummary(),
        ].joined(separator: "\n")

        debugStateLabel?.stringValue = "当前：\(lastBehaviorState.chineseName)\n决策：\(decisionText)"
        debugActionLabel?.stringValue = "当前动作：\(currentAction)\n行为动作：\(lastBehaviorAction.isEmpty ? "无" : lastBehaviorAction) · 临时动作：\(temporaryText)"
        debugActivityLabel?.stringValue = [
            "应用：\(lastActivitySnapshot.appName)",
            "Bundle：\(lastActivitySnapshot.bundleIdentifier)",
            "分类：\(lastActivitySnapshot.kind.chineseName) · 模式：\(lastDebugEvaluatedMode.chineseName) · 手动：\(manualText) · 勿扰：\(quietText)",
            "原因：\(lastActivitySnapshot.reason)",
        ].joined(separator: "\n")
        debugWindowLabel?.stringValue = [
            "前台覆盖率：\(formatDebugPercent(lastDebugCoverage)) · 空闲：\(formatDebugSeconds(lastDebugIdleSeconds))",
            "可见区域：\(formatDebugRect(lastDebugScreenFrame))",
            "前台窗口：\(frontText)",
        ].joined(separator: "\n")
        debugPlacementLabel?.stringValue = [
            "自动贴边：\(autoPositionEnabled ? "开" : "关") · 手动固定：\(userPositionPinned ? "是" : "否")",
            "位置偏好：\(placementPreference.chineseName) · 方向：\(edgeDirection >= 0 ? "向右" : "向左")",
            "大小倍率：\(String(format: "%.2f", sizeScale))",
        ].joined(separator: "\n")
        debugReminderLabel?.stringValue = reminderStatus
        debugTimingLabel?.stringValue = "北京时间：\(formatDebugTime(Date()))\n日夜模式：\(dayMode.chineseName)"
        debugLogLabel?.stringValue = formatBehaviorLog()
    }

    func makeDebugDiagnostics() -> String {
        [
            "\(AppIdentity.displayName) 诊断信息",
            "生成时间：\(formatDebugTime(Date()))",
            "状态：\(lastBehaviorState.chineseName)",
            "动作：\(currentAction)",
            "模式：\(lastDebugEvaluatedMode.chineseName) / 手动：\(manualMode?.chineseName ?? "自动")",
            "应用：\(lastActivitySnapshot.appName)",
            "Bundle：\(lastActivitySnapshot.bundleIdentifier)",
            "分类：\(lastActivitySnapshot.kind.chineseName)",
            "勿扰：\(lastActivitySnapshot.quiet ? "是" : "否")",
            "原因：\(lastActivitySnapshot.reason)",
            "覆盖率：\(formatDebugPercent(lastDebugCoverage))",
            "空闲：\(formatDebugSeconds(lastDebugIdleSeconds))",
            "可见区域：\(formatDebugRect(lastDebugScreenFrame))",
            "前台窗口：\(lastDebugFrontWindowFrame.map(formatDebugRect) ?? "无")",
            "自动贴边：\(autoPositionEnabled ? "开" : "关")",
            "手动固定：\(userPositionPinned ? "是" : "否")",
            "位置偏好：\(placementPreference.chineseName)",
            "大小倍率：\(String(format: "%.2f", sizeScale))",
            "提醒：\(debugReminderLabel?.stringValue ?? "")",
            "最近行为日志：\n\(formatBehaviorLog())",
        ].joined(separator: "\n")
    }

    func formatBehaviorLog() -> String {
        if behaviorLog.isEmpty { return "暂无行为变化" }
        return behaviorLog.map { entry in
            [
                formatDebugTime(entry.date),
                entry.state.chineseName,
                entry.action,
                entry.appName,
                formatDebugPercent(entry.coverage),
                formatDebugSeconds(entry.idleSeconds),
                entry.reason,
            ].joined(separator: " · ")
        }.joined(separator: "\n")
    }

    func formatDebugPercent(_ value: CGFloat) -> String {
        String(format: "%.0f%%", value * 100)
    }

    func formatDebugSeconds(_ value: CFTimeInterval) -> String {
        if value >= 60 {
            return String(format: "%.1f 分钟", value / 60)
        }
        return String(format: "%.0f 秒", value)
    }

    func formatDebugRect(_ rect: NSRect) -> String {
        "x \(Int(rect.origin.x)), y \(Int(rect.origin.y)), w \(Int(rect.width)), h \(Int(rect.height))"
    }

    func formatDebugTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = config.timezone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

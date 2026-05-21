import AppKit
import Foundation

extension MiuRunner {
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
        if let error = validateReminderEdits() {
            reminderEditStatusLabel?.stringValue = error
            return
        }
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
        if let error = validateReminderEdits() {
            reminderEditStatusLabel?.stringValue = error
            return
        }
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
        if let error = validateReminderEdits() {
            reminderEditStatusLabel?.stringValue = error
            return
        }
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
}

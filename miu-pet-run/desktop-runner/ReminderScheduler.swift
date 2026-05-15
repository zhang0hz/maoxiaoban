import CoreGraphics
import Foundation

enum ReminderKind: String, Codable {
    case water
    case rest
    case stand
    case sleep
    case custom

    var chineseName: String {
        switch self {
        case .water: return "喝水"
        case .rest: return "休息"
        case .stand: return "久坐"
        case .sleep: return "睡觉"
        case .custom: return "自定义"
        }
    }
}

struct ReminderConfig: Codable {
    var id: String
    var kind: ReminderKind
    var enabled: Bool
    var intervalMinutes: Int?
    var fixedTime: String?
    var activeStart: String
    var activeEnd: String
    var message: String
    var action: String
    var lastTriggeredAt: Double?
    var lastCompletedAt: Double?
    var snoozedUntil: Double?
    var skipDate: String?
}

struct ReminderHistoryEntry: Codable {
    var reminderId: String
    var kind: ReminderKind
    var message: String
    var action: String
    var event: String
    var at: Double
}

struct ReminderFile: Codable {
    var bubbleAutoDismissSeconds: Int?
    var reminders: [ReminderConfig]
    var deferredIds: [String]?
    var history: [ReminderHistoryEntry]?
}

final class ReminderScheduler {
    private let storeURL: URL
    private(set) var file: ReminderFile
    private(set) var activeReminder: ReminderConfig?

    init() {
        let dir = AppIdentity.applicationSupportDirectory()
        self.storeURL = dir.appendingPathComponent("reminders.json")
        if let data = try? Data(contentsOf: storeURL),
           let decoded = try? JSONDecoder().decode(ReminderFile.self, from: data) {
            self.file = decoded
        } else {
            self.file = ReminderScheduler.defaultFile(now: Date())
            save()
        }
    }

    var configPath: String {
        storeURL.path
    }

    var bubbleAutoDismissSeconds: Int? {
        file.bubbleAutoDismissSeconds
    }

    var reminders: [ReminderConfig] {
        file.reminders
    }

    func setBubbleAutoDismissSeconds(_ seconds: Int?) {
        file.bubbleAutoDismissSeconds = seconds
        save()
    }

    func replaceReminders(_ reminders: [ReminderConfig], now: Date = Date()) {
        let timestamp = now.timeIntervalSince1970
        file.reminders = reminders.map { reminder in
            var next = reminder
            if next.intervalMinutes != nil,
               next.enabled,
               next.lastCompletedAt == nil,
               next.lastTriggeredAt == nil {
                next.lastCompletedAt = timestamp
            }
            return next
        }
        let validIds = Set(file.reminders.map(\.id))
        file.deferredIds = (file.deferredIds ?? []).filter { validIds.contains($0) }
        if let activeReminder,
           !file.reminders.contains(where: { $0.id == activeReminder.id && $0.enabled }) {
            self.activeReminder = nil
        }
        save()
    }

    func resetReminders(now: Date = Date()) {
        let autoDismiss = file.bubbleAutoDismissSeconds
        file = ReminderScheduler.defaultFile(now: now)
        file.bubbleAutoDismissSeconds = autoDismiss
        activeReminder = nil
        save()
    }

    func todayCompletionSummary(now: Date = Date()) -> String {
        let today = ReminderScheduler.dateKey(now)
        let completed = file.reminders.filter { reminder in
            guard let lastCompletedAt = reminder.lastCompletedAt else { return false }
            return ReminderScheduler.dateKey(Date(timeIntervalSince1970: lastCompletedAt)) == today
        }.count
        let skipped = file.reminders.filter { $0.skipDate == today }.count
        return "今日完成 \(completed) · 跳过 \(skipped)"
    }

    func deferredSummary(now: Date = Date(), dayMode: PetMode, coverage: CGFloat, quiet: Bool) -> String {
        let blocked = coverage >= 0.92 || quiet
        let due = dueReminders(now: now, dayMode: dayMode).map(\.reminder)
        let deferred = deferredReminders(now: now, dayMode: dayMode)
        let combined = uniqueReminders(deferred + (blocked ? due : []))
        guard !combined.isEmpty else { return "无延后提醒" }
        return "延后提醒 \(combined.count)：\(combined.map { $0.kind.chineseName }.joined(separator: "、"))"
    }

    func queueSummary(now: Date = Date(), dayMode: PetMode, coverage: CGFloat, quiet: Bool) -> String {
        let blocked = coverage >= 0.92 || quiet
        let dueCount = dueReminders(now: now, dayMode: dayMode).count
        let deferredCount = deferredReminders(now: now, dayMode: dayMode).count
        if blocked && dueCount > 0 {
            return "队列：延后 \(max(deferredCount, dueCount)) · 当前勿扰"
        }
        if deferredCount > 0 {
            return "队列：待重放 \(deferredCount)"
        }
        return "队列：无待处理"
    }

    func historySummary(now: Date = Date()) -> String {
        let today = ReminderScheduler.dateKey(now)
        let events = (file.history ?? []).filter {
            ReminderScheduler.dateKey(Date(timeIntervalSince1970: $0.at)) == today
        }
        guard !events.isEmpty else { return "今日提醒记录：无" }
        return "今日提醒记录：\(events.count) 条"
    }

    func check(now: Date, dayMode: PetMode, coverage: CGFloat, quiet: Bool) -> ReminderConfig? {
        let blocked = coverage >= 0.92 || quiet
        if let activeReminder {
            return blocked ? nil : activeReminder
        }
        let due = dueReminders(now: now, dayMode: dayMode)
        guard !due.isEmpty else { return nil }

        if blocked {
            rememberDeferred(due.map { $0.reminder })
            return nil
        }

        let deferredIds = file.deferredIds ?? []
        if let queued = due.first(where: { deferredIds.contains($0.reminder.id) }) {
            return activateReminder(at: queued.index, now: now, event: "deferred-fired")
        }
        return activateReminder(at: due[0].index, now: now, event: "triggered")
    }

    private func dueReminders(now: Date, dayMode: PetMode) -> [(index: Int, reminder: ReminderConfig)] {
        let today = ReminderScheduler.dateKey(now)
        var due: [(index: Int, reminder: ReminderConfig)] = []
        for index in file.reminders.indices {
            let reminder = file.reminders[index]
            guard reminder.enabled else { continue }
            guard reminder.skipDate != today else { continue }
            if let snoozedUntil = reminder.snoozedUntil,
               snoozedUntil > now.timeIntervalSince1970 {
                continue
            }
            if reminder.kind != .sleep && (dayMode == .night || dayMode == .sleepy) { continue }
            guard isWithinActiveHours(reminder, now: now) else { continue }
            if isDue(reminder, now: now, today: today) {
                due.append((index, reminder))
            }
        }
        return due
    }

    private func deferredReminders(now: Date, dayMode: PetMode) -> [ReminderConfig] {
        let ids = file.deferredIds ?? []
        guard !ids.isEmpty else { return [] }
        return dueReminders(now: now, dayMode: dayMode)
            .map(\.reminder)
            .filter { ids.contains($0.id) }
    }

    private func uniqueReminders(_ reminders: [ReminderConfig]) -> [ReminderConfig] {
        var seen: Set<String> = []
        var result: [ReminderConfig] = []
        for reminder in reminders where !seen.contains(reminder.id) {
            seen.insert(reminder.id)
            result.append(reminder)
        }
        return result
    }

    private func rememberDeferred(_ reminders: [ReminderConfig]) {
        var ids = file.deferredIds ?? []
        var changed = false
        for reminder in reminders where !ids.contains(reminder.id) {
            ids.append(reminder.id)
            appendHistory(reminder, event: "deferred", saveNow: false)
            changed = true
        }
        guard changed else { return }
        file.deferredIds = ids
        trimHistory()
        save()
    }

    private func activateReminder(at index: Int, now: Date, event: String) -> ReminderConfig {
        file.reminders[index].lastTriggeredAt = now.timeIntervalSince1970
        file.reminders[index].snoozedUntil = nil
        activeReminder = file.reminders[index]
        file.deferredIds = (file.deferredIds ?? []).filter { $0 != file.reminders[index].id }
        appendHistory(file.reminders[index], event: event, at: now, saveNow: false)
        trimHistory()
        save()
        return file.reminders[index]
    }

    func completeActive(now: Date = Date()) {
        let reminder = activeReminder
        updateActive(now: now) { reminder in
            reminder.lastCompletedAt = now.timeIntervalSince1970
            reminder.snoozedUntil = nil
        }
        if let reminder {
            appendHistory(reminder, event: "completed", at: now, saveNow: false)
        }
        activeReminder = nil
        save()
    }

    func snoozeActive(minutes: Int, now: Date = Date()) {
        let reminder = activeReminder
        updateActive(now: now) { reminder in
            reminder.snoozedUntil = now.addingTimeInterval(Double(minutes * 60)).timeIntervalSince1970
        }
        if let reminder {
            appendHistory(reminder, event: "snoozed-\(minutes)", at: now, saveNow: false)
        }
        activeReminder = nil
        save()
    }

    func skipActiveToday(now: Date = Date()) {
        let reminder = activeReminder
        updateActive(now: now) { reminder in
            reminder.skipDate = ReminderScheduler.dateKey(now)
        }
        if let reminder {
            appendHistory(reminder, event: "skipped-today", at: now, saveNow: false)
        }
        activeReminder = nil
        save()
    }

    func dismissActive(now: Date = Date()) {
        if let activeReminder {
            appendHistory(activeReminder, event: "dismissed", at: now, saveNow: false)
            save()
        }
        activeReminder = nil
    }

    func nextSummary(now: Date = Date()) -> String {
        let candidates = file.reminders.filter { $0.enabled }
        guard !candidates.isEmpty else { return "无启用提醒" }
        var best: (ReminderConfig, Date)?
        for reminder in candidates {
            if let date = nextDate(for: reminder, now: now) {
                if best == nil || date < best!.1 {
                    best = (reminder, date)
                }
            }
        }
        guard let best else { return "暂无下一次提醒" }
        return "\(best.0.kind.chineseName) \(ReminderScheduler.clockString(best.1))"
    }

    private func updateActive(now: Date, mutate: (inout ReminderConfig) -> Void) {
        guard let activeReminder,
              let index = file.reminders.firstIndex(where: { $0.id == activeReminder.id })
        else { return }
        mutate(&file.reminders[index])
    }

    private func appendHistory(
        _ reminder: ReminderConfig,
        event: String,
        at now: Date = Date(),
        saveNow: Bool = true
    ) {
        var history = file.history ?? []
        history.append(ReminderHistoryEntry(
            reminderId: reminder.id,
            kind: reminder.kind,
            message: reminder.message,
            action: reminder.action,
            event: event,
            at: now.timeIntervalSince1970
        ))
        file.history = history
        trimHistory()
        if saveNow { save() }
    }

    private func trimHistory(limit: Int = 120) {
        guard var history = file.history, history.count > limit else { return }
        history = Array(history.suffix(limit))
        file.history = history
    }

    private func isDue(_ reminder: ReminderConfig, now: Date, today: String) -> Bool {
        if let fixedTime = reminder.fixedTime {
            guard parseClock(fixedTime) <= minutesInDay(now) else { return false }
            if let lastTriggeredAt = reminder.lastTriggeredAt,
               ReminderScheduler.dateKey(Date(timeIntervalSince1970: lastTriggeredAt)) == today {
                return false
            }
            return true
        }

        guard let interval = reminder.intervalMinutes else { return false }
        let baseline = max(reminder.lastCompletedAt ?? 0, reminder.lastTriggeredAt ?? 0)
        guard baseline > 0 else { return true }
        return now.timeIntervalSince1970 - baseline >= Double(interval * 60)
    }

    private func nextDate(for reminder: ReminderConfig, now: Date) -> Date? {
        if let snoozedUntil = reminder.snoozedUntil {
            return Date(timeIntervalSince1970: snoozedUntil)
        }
        if let fixedTime = reminder.fixedTime {
            let targetMinutes = parseClock(fixedTime)
            let nowMinutes = minutesInDay(now)
            let delta = targetMinutes >= nowMinutes
                ? targetMinutes - nowMinutes
                : 24 * 60 - nowMinutes + targetMinutes
            return now.addingTimeInterval(Double(delta * 60))
        }
        guard let interval = reminder.intervalMinutes else { return nil }
        let baseline = max(reminder.lastCompletedAt ?? now.timeIntervalSince1970, reminder.lastTriggeredAt ?? now.timeIntervalSince1970)
        return Date(timeIntervalSince1970: baseline + Double(interval * 60))
    }

    private func isWithinActiveHours(_ reminder: ReminderConfig, now: Date) -> Bool {
        let start = parseClock(reminder.activeStart)
        let end = parseClock(reminder.activeEnd)
        let current = minutesInDay(now)
        if start <= end {
            return current >= start && current <= end
        }
        return current >= start || current <= end
    }

    private func parseClock(_ raw: String) -> Int {
        let parts = raw.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return 0 }
        return parts[0] * 60 + parts[1]
    }

    private func minutesInDay(_ date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let comps = calendar.dateComponents([.hour, .minute], from: date)
        return (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: storeURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(file)
            try data.write(to: storeURL, options: [.atomic])
        } catch {
            NSLog("\(AppIdentity.displayName) failed to save reminders: \(error)")
        }
    }

    static func defaultFile(now: Date) -> ReminderFile {
        let seed = now.timeIntervalSince1970
        return ReminderFile(
            bubbleAutoDismissSeconds: 10,
            reminders: [
                ReminderConfig(id: "water", kind: .water, enabled: true, intervalMinutes: 90, fixedTime: nil, activeStart: "09:00", activeEnd: "22:00", message: "喝点水吧", action: "purr", lastTriggeredAt: nil, lastCompletedAt: seed, snoozedUntil: nil, skipDate: nil),
                ReminderConfig(id: "rest", kind: .rest, enabled: true, intervalMinutes: 60, fixedTime: nil, activeStart: "09:00", activeEnd: "22:30", message: "休息 5 分钟", action: "stretch", lastTriggeredAt: nil, lastCompletedAt: seed, snoozedUntil: nil, skipDate: nil),
                ReminderConfig(id: "stand", kind: .stand, enabled: true, intervalMinutes: 90, fixedTime: nil, activeStart: "09:00", activeEnd: "22:00", message: "起来活动一下", action: "stretch", lastTriggeredAt: nil, lastCompletedAt: seed, snoozedUntil: nil, skipDate: nil),
                ReminderConfig(id: "sleep", kind: .sleep, enabled: true, intervalMinutes: nil, fixedTime: "23:30", activeStart: "22:30", activeEnd: "23:59", message: "该准备睡觉啦", action: "sleep", lastTriggeredAt: nil, lastCompletedAt: nil, snoozedUntil: nil, skipDate: nil),
            ],
            deferredIds: [],
            history: []
        )
    }

    static func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func clockString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

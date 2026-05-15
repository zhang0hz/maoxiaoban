import AppKit
import Foundation

extension MiuRunner {
    func showReminderBubble(_ reminder: ReminderConfig) {
        if reminderBubble?.isVisible == true { return }
        reminderBubbleTimer?.invalidate()

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 286, height: 118),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.ignoresMouseEvents = false

        let root = NSView(frame: NSRect(x: 0, y: 0, width: 286, height: 118))
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.94).cgColor
        root.layer?.cornerRadius = 12

        let stack = NSStackView(frame: NSRect(x: 12, y: 12, width: 262, height: 94))
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8

        let title = NSTextField(labelWithString: "\(reminder.kind.chineseName)提醒")
        title.font = NSFont.boldSystemFont(ofSize: 13)
        stack.addArrangedSubview(title)

        let message = NSTextField(labelWithString: reminder.message)
        message.font = NSFont.systemFont(ofSize: 13)
        stack.addArrangedSubview(message)

        let buttons = NSStackView()
        buttons.orientation = .horizontal
        buttons.spacing = 6
        buttons.addArrangedSubview(tinyButton("完成", #selector(completeReminder)))
        buttons.addArrangedSubview(tinyButton("稍后10", #selector(snoozeReminder10)))
        buttons.addArrangedSubview(tinyButton("稍后30", #selector(snoozeReminder30)))
        buttons.addArrangedSubview(tinyButton("跳过", #selector(skipReminderToday)))
        buttons.addArrangedSubview(tinyButton("关闭", #selector(dismissReminderBubble)))
        stack.addArrangedSubview(buttons)

        root.addSubview(stack)
        panel.contentView = root
        reminderBubble = panel
        placeReminderBubble()
        panel.orderFrontRegardless()

        if let seconds = reminderScheduler.bubbleAutoDismissSeconds {
            reminderBubbleTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
                self?.dismissReminderBubble()
            }
        }
    }

    func tinyButton(_ title: String, _ action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.font = NSFont.systemFont(ofSize: 11)
        return button
    }

    func placeReminderBubble() {
        guard let reminderBubble, let window else { return }
        let petFrame = window.frame
        let x = petFrame.midX - reminderBubble.frame.width / 2
        let y = petFrame.maxY + 10
        reminderBubble.setFrameOrigin(NSPoint(x: x, y: y))
    }

    func hideReminderBubble() {
        reminderBubbleTimer?.invalidate()
        reminderBubbleTimer = nil
        reminderBubble?.orderOut(nil)
        reminderBubble = nil
    }
}

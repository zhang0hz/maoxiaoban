import AppKit

final class PetView: NSView {
    var image: NSImage? {
        didSet { needsDisplay = true }
    }
    var onUserDragged: (() -> Void)?
    var onUserDragEnded: (() -> Void)?
    var onMouseEnteredPet: (() -> Void)?
    var onMouseExitedPet: (() -> Void)?
    var contextMenuProvider: (() -> NSMenu)?
    private var dragStartMouse: NSPoint?
    private var dragStartFrame: NSRect?
    private var trackingAreaRef: NSTrackingArea?

    override var isFlipped: Bool { true }

    override func updateTrackingAreas() {
        if let trackingAreaRef {
            removeTrackingArea(trackingAreaRef)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingAreaRef = area
        super.updateTrackingAreas()
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill()
        dirtyRect.fill()
        guard let image else { return }
        image.draw(in: bounds, from: .zero, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.none])
    }

    override func mouseDown(with event: NSEvent) {
        dragStartMouse = NSEvent.mouseLocation
        dragStartFrame = window?.frame
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window, let dragStartMouse, let dragStartFrame else { return }
        let current = NSEvent.mouseLocation
        let delta = NSPoint(x: current.x - dragStartMouse.x, y: current.y - dragStartMouse.y)
        var next = dragStartFrame
        next.origin.x += delta.x
        next.origin.y += delta.y
        window.setFrame(next, display: true)
        onUserDragged?()
    }

    override func mouseUp(with event: NSEvent) {
        dragStartMouse = nil
        dragStartFrame = nil
        onUserDragEnded?()
    }

    override func mouseEntered(with event: NSEvent) {
        onMouseEnteredPet?()
    }

    override func mouseExited(with event: NSEvent) {
        onMouseExitedPet?()
    }

    override func rightMouseDown(with event: NSEvent) {
        guard let menu = contextMenuProvider?() else { return }
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
}

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
    private let alphaHitTestThreshold: CGFloat = 0.08

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard bounds.contains(point), isOpaquePixel(at: point) else { return nil }
        return self
    }

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

    func isOpaquePixel(at point: NSPoint) -> Bool {
        guard let image,
              bounds.width > 0,
              bounds.height > 0,
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        else {
            return false
        }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        let xRatio = min(max(point.x / bounds.width, 0), 1)
        let yRatio = min(max(point.y / bounds.height, 0), 1)
        let pixelX = min(max(Int(xRatio * CGFloat(bitmap.pixelsWide)), 0), bitmap.pixelsWide - 1)
        let pixelY = min(max(Int(yRatio * CGFloat(bitmap.pixelsHigh)), 0), bitmap.pixelsHigh - 1)
        return (bitmap.colorAt(x: pixelX, y: pixelY)?.alphaComponent ?? 1) > alphaHitTestThreshold
    }
}

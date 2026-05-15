import AppKit
import CoreGraphics
import Foundation

extension MiuRunner {
    func placementVisibleFrame() -> NSRect {
        if let window,
           let screen = NSScreen.screens.first(where: { $0.visibleFrame.intersects(window.frame) || $0.frame.intersects(window.frame) }) {
            return screen.visibleFrame
        }
        return NSScreen.main?.visibleFrame
            ?? NSScreen.screens.first?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
    }

    func placeCorner(screen: NSRect, avoiding frontWindow: NSRect? = nil, force: Bool = false) {
        if !force, shouldKeepCurrentPlacement(in: screen, avoiding: frontWindow) {
            placeReminderBubble()
            return
        }
        let rect = bestSafePlacement(in: screen, avoiding: frontWindow)
        window.setFrame(rect, display: true)
        placeReminderBubble()
    }

    func bestSafePlacement(in screen: NSRect, avoiding frontWindow: NSRect?) -> NSRect {
        let size = displaySize
        let margin = placementMargin
        let base: [(PlacementPreference?, NSPoint)] = [
            (.lowerRight, NSPoint(x: screen.maxX - size.width - margin, y: screen.minY + margin)),
            (.lowerLeft, NSPoint(x: screen.minX + margin, y: screen.minY + margin)),
            (.upperRight, NSPoint(x: screen.maxX - size.width - margin, y: screen.maxY - size.height - margin)),
            (.upperLeft, NSPoint(x: screen.minX + margin, y: screen.maxY - size.height - margin)),
            (nil, NSPoint(x: screen.maxX - size.width - margin, y: screen.midY - size.height / 2)),
            (nil, NSPoint(x: screen.minX + margin, y: screen.midY - size.height / 2)),
            (nil, NSPoint(x: screen.midX - size.width / 2, y: screen.minY + margin)),
            (nil, NSPoint(x: screen.midX - size.width / 2, y: screen.maxY - size.height - margin)),
        ]
        let ordered = orderedCandidates(base)
        let candidates = ordered.map { clampOrigin($0.1, size: size, in: screen) }

        guard let frontWindow else {
            return NSRect(origin: candidates[0], size: size)
        }

        let avoid = frontWindow.insetBy(dx: -frontWindowAvoidanceMargin, dy: -frontWindowAvoidanceMargin)
        if placementPreference != .auto {
            let preferred = NSRect(origin: candidates[0], size: size)
            if intersectionArea(preferred, avoid) == 0 {
                return preferred
            }
        }
        let frontCenter = NSPoint(x: avoid.midX, y: avoid.midY)
        let scored = candidates.enumerated().map { index, origin -> (Int, CGFloat, NSRect) in
            let rect = NSRect(origin: origin, size: size)
            let overlap = intersectionArea(rect, avoid)
            let center = NSPoint(x: rect.midX, y: rect.midY)
            let distance = hypot(center.x - frontCenter.x, center.y - frontCenter.y)
            let preferredCornerPenalty = CGFloat(index) * 3
            let score = distance - overlap * 100 - preferredCornerPenalty
            return (index, score, rect)
        }
        return scored.max { left, right in left.1 < right.1 }?.2 ?? NSRect(origin: candidates[0], size: size)
    }

    func orderedCandidates(_ candidates: [(PlacementPreference?, NSPoint)]) -> [(PlacementPreference?, NSPoint)] {
        guard placementPreference != .auto else { return candidates }
        let preferred = candidates.filter { $0.0 == placementPreference }
        let rest = candidates.filter { $0.0 != placementPreference }
        return preferred + rest
    }

    func shouldKeepCurrentPlacement(in screen: NSRect, avoiding frontWindow: NSRect?) -> Bool {
        guard placementPreference == .auto, let window else { return false }
        let current = window.frame
        guard containsRect(screen, current) else { return false }
        guard let frontWindow else { return true }
        let avoid = frontWindow.insetBy(dx: -frontWindowAvoidanceMargin, dy: -frontWindowAvoidanceMargin)
        return intersectionArea(current, avoid) == 0
    }

    func containsRect(_ outer: NSRect, _ inner: NSRect) -> Bool {
        inner.minX >= outer.minX &&
            inner.maxX <= outer.maxX &&
            inner.minY >= outer.minY &&
            inner.maxY <= outer.maxY
    }

    func clampOrigin(_ origin: NSPoint, size: CGSize, in screen: NSRect) -> NSPoint {
        NSPoint(
            x: min(max(origin.x, screen.minX + placementMargin), screen.maxX - size.width - placementMargin),
            y: min(max(origin.y, screen.minY + placementMargin), screen.maxY - size.height - placementMargin)
        )
    }

    func intersectionArea(_ left: NSRect, _ right: NSRect) -> CGFloat {
        let intersection = left.intersection(right)
        if intersection.isNull { return 0 }
        return max(0, intersection.width) * max(0, intersection.height)
    }

    func moveAlongSafeEdge() {
        if userPositionPinned { return }
        let screen = placementVisibleFrame()
        var frame = window.frame
        frame.origin.y = screen.minY + config.margin
        frame.origin.x += edgeDirection * 6
        if frame.maxX >= screen.maxX - config.margin {
            edgeDirection = -1
            frame.origin.x = screen.maxX - config.margin - frame.width
        } else if frame.minX <= screen.minX + config.margin {
            edgeDirection = 1
            frame.origin.x = screen.minX + config.margin
        }
        setAction(walkAction())
        window.setFrame(frame, display: true)
        placeReminderBubble()
    }

    func walkAction() -> String {
        edgeDirection >= 0 ? "walk-right" : "walk-left"
    }

    func applyPetSize() {
        guard let window, let petView else { return }
        var frame = window.frame
        frame.size = displaySize
        petView.setFrameSize(displaySize)
        window.setFrame(frame, display: true)
        placeReminderBubble()
        if autoPositionEnabled && !userPositionPinned {
            let screen = placementVisibleFrame()
            placeCorner(screen: screen, avoiding: frontWindowRect(on: screen))
        }
    }


    func frontWindowRect(on screen: NSRect) -> NSRect? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        let ownPID = ProcessInfo.processInfo.processIdentifier
        for info in windows {
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let pid = info[kCGWindowOwnerPID as String] as? Int32, pid != ownPID else { continue }
            guard let alpha = info[kCGWindowAlpha as String] as? Double, alpha > 0 else { continue }
            guard let bounds = info[kCGWindowBounds as String] as? [String: Any] else { continue }
            let x = bounds["X"] as? CGFloat ?? 0
            let y = bounds["Y"] as? CGFloat ?? 0
            let width = bounds["Width"] as? CGFloat ?? 0
            let height = bounds["Height"] as? CGFloat ?? 0
            if width < 80 || height < 80 { continue }
            let raw = NSRect(x: x, y: y, width: width, height: height)
            let fullScreen = NSScreen.main?.frame ?? screen
            let converted = NSRect(x: x, y: fullScreen.maxY - y - height, width: width, height: height)
            return bestScreenCoordinateRect(raw: raw, converted: converted, screen: screen)
        }
        return nil
    }

    func bestScreenCoordinateRect(raw: NSRect, converted: NSRect, screen: NSRect) -> NSRect {
        let rawOverlap = intersectionArea(raw, screen)
        let convertedOverlap = intersectionArea(converted, screen)
        if convertedOverlap > rawOverlap {
            return converted
        }
        return raw
    }

    func windowCoverage(_ window: NSRect, _ screen: NSRect) -> CGFloat {
        let windowArea = max(0, window.width) * max(0, window.height)
        let screenArea = max(1, screen.width * screen.height)
        return windowArea / screenArea
    }
}

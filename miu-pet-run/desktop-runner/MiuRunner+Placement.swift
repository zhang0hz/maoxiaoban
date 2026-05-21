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
        let frontWindows = windowAvoidanceRects(on: screen, primary: frontWindow)
        placeCorner(screen: screen, avoiding: frontWindows, force: force)
    }

    func placeCorner(screen: NSRect, avoiding frontWindows: [NSRect], force: Bool = false) {
        if !force, shouldKeepCurrentPlacement(in: screen, avoiding: frontWindows) {
            placeReminderBubble()
            return
        }
        let rect = bestSafePlacement(in: screen, avoiding: frontWindows)
        window.setFrame(rect, display: true)
        placeReminderBubble()
    }

    func bestSafePlacement(in screen: NSRect, avoiding frontWindow: NSRect?) -> NSRect {
        bestSafePlacement(in: screen, avoiding: windowAvoidanceRects(on: screen, primary: frontWindow))
    }

    func bestSafePlacement(in screen: NSRect, avoiding frontWindows: [NSRect]) -> NSRect {
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

        let avoidRects = frontWindows.map {
            $0.insetBy(dx: -frontWindowAvoidanceMargin, dy: -frontWindowAvoidanceMargin)
        }

        guard !avoidRects.isEmpty else {
            return NSRect(origin: candidates[0], size: size)
        }

        if placementPreference != .auto {
            let preferred = NSRect(origin: candidates[0], size: size)
            if totalIntersectionArea(preferred, avoidRects) == 0 {
                return preferred
            }
        }
        let frontCenter = combinedCenter(of: avoidRects)
        let scored = candidates.enumerated().map { index, origin -> (Int, CGFloat, NSRect) in
            let rect = NSRect(origin: origin, size: size)
            let overlap = totalIntersectionArea(rect, avoidRects)
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
        shouldKeepCurrentPlacement(in: screen, avoiding: windowAvoidanceRects(on: screen, primary: frontWindow))
    }

    func shouldKeepCurrentPlacement(in screen: NSRect, avoiding frontWindows: [NSRect]) -> Bool {
        guard placementPreference == .auto, let window else { return false }
        let current = window.frame
        guard containsRect(screen, current) else { return false }
        let avoidRects = frontWindows.map {
            $0.insetBy(dx: -frontWindowAvoidanceMargin, dy: -frontWindowAvoidanceMargin)
        }
        return totalIntersectionArea(current, avoidRects) == 0
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

    func totalIntersectionArea(_ rect: NSRect, _ avoidRects: [NSRect]) -> CGFloat {
        avoidRects.reduce(0) { total, avoid in
            total + intersectionArea(rect, avoid)
        }
    }

    func combinedCenter(of rects: [NSRect]) -> NSPoint {
        guard !rects.isEmpty else { return .zero }
        let total = rects.reduce((x: CGFloat(0), y: CGFloat(0), area: CGFloat(0))) { partial, rect in
            let area = max(1, rect.width * rect.height)
            return (
                x: partial.x + rect.midX * area,
                y: partial.y + rect.midY * area,
                area: partial.area + area
            )
        }
        return NSPoint(x: total.x / total.area, y: total.y / total.area)
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
        frontWindowRects(on: screen).first
    }

    func frontWindowRects(on screen: NSRect) -> [NSRect] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        let ownPID = ProcessInfo.processInfo.processIdentifier
        var rects: [NSRect] = []
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
            let rect = bestScreenCoordinateRect(raw: raw, converted: converted, screen: screen)
            if intersectionArea(rect, screen) > 0 {
                rects.append(rect)
            }
            if rects.count >= 6 { break }
        }
        return rects
    }

    func windowAvoidanceRects(on screen: NSRect, primary: NSRect?) -> [NSRect] {
        var rects = frontWindowRects(on: screen)
        if let primary, !rects.contains(where: { NSEqualRects($0, primary) }) {
            rects.insert(primary, at: 0)
        }
        return rects
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

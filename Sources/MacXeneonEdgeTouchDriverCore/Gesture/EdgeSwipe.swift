import CoreGraphics

/// A system shortcut an edge swipe can trigger. The shortcuts act on the
/// display under the cursor, which is the touched panel during the gesture.
public enum SpaceShortcut: String, Equatable, Sendable {
    /// Mission Control "Move left a space" (Control + Left Arrow).
    case previousSpace
    /// Mission Control "Move right a space" (Control + Right Arrow).
    case nextSpace
    /// Mission Control (Control + Up Arrow).
    case missionControl
}

/// One-finger swipes that start on a panel border. Disabled by default.
public struct EdgeSwipeOptions: Equatable, Sendable {
    public var enabled: Bool
    /// Width of the left, right and bottom border strips, in display points.
    public var edgeZonePx: Double
    /// Distance the finger must travel along the swipe direction, in display points.
    public var minDistancePx: Double

    public init(enabled: Bool = false, edgeZonePx: Double = 40, minDistancePx: Double = 200) {
        self.enabled = enabled
        self.edgeZonePx = edgeZonePx.isFinite ? min(200, max(5, edgeZonePx)) : 40
        self.minDistancePx = minDistancePx.isFinite ? min(2000, max(50, minDistancePx)) : 200
    }
}

/// Classifies a single-finger path. A swipe counts only when it starts inside a
/// border strip, travels at least the minimum distance away from that border,
/// and stays mostly along that direction (at least twice the cross movement).
struct EdgeSwipeRecognizer {
    let options: EdgeSwipeOptions

    private enum Edge { case left, right, bottom }

    func startsInEdgeZone(_ point: CGPoint, bounds: CGRect) -> Bool {
        !edges(at: point, bounds: bounds).isEmpty
    }

    func shortcut(from start: CGPoint, to end: CGPoint, bounds: CGRect) -> SpaceShortcut? {
        let dx = end.x - start.x, dy = end.y - start.y
        for edge in edges(at: start, bounds: bounds) {
            switch edge {
            case .left where dx >= options.minDistancePx && abs(dx) >= 2 * abs(dy): return .previousSpace
            case .right where -dx >= options.minDistancePx && abs(dx) >= 2 * abs(dy): return .nextSpace
            case .bottom where -dy >= options.minDistancePx && abs(dy) >= 2 * abs(dx): return .missionControl
            default: continue
            }
        }
        return nil
    }

    private func edges(at point: CGPoint, bounds: CGRect) -> [Edge] {
        guard options.enabled, bounds.contains(point) else { return [] }
        var edges: [Edge] = []
        if point.x - bounds.minX < options.edgeZonePx { edges.append(.left) }
        if bounds.maxX - point.x <= options.edgeZonePx { edges.append(.right) }
        if bounds.maxY - point.y <= options.edgeZonePx { edges.append(.bottom) }
        return edges
    }
}

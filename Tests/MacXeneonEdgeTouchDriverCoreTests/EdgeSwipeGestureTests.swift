import CoreGraphics
@testable import MacXeneonEdgeTouchDriverCore
import XCTest

final class EdgeSwipeGestureTests: XCTestCase {
    private let edgeOn = EdgeSwipeOptions(enabled: true)

    func testLeftEdgeSwipeSwitchesToPreviousSpaceWithoutClickOrScroll() {
        let f = EdgeFixture(options: GestureOptions(mode: .scroll, edgeSwipes: edgeOn))
        f.swipe(from: (10, 360), to: (320, 360))
        XCTAssertEqual(f.input.shortcuts, [.previousSpace])
        XCTAssertTrue(f.input.counts.isEmpty, "An edge swipe never presses the mouse button")
        XCTAssertTrue(f.input.scrolls.isEmpty)
        XCTAssertEqual(f.cursor.releases, 1)
        XCTAssertEqual(f.controller.state, .idle)
    }

    func testRightAndBottomEdgeSwipes() {
        let f = EdgeFixture(options: GestureOptions(mode: .scroll, edgeSwipes: edgeOn))
        f.swipe(from: (2550, 360), to: (2200, 360))
        f.swipe(from: (1280, 715), to: (1280, 400), startingAt: 1000)
        XCTAssertEqual(f.input.shortcuts, [.nextSpace, .missionControl])
        XCTAssertTrue(f.input.counts.isEmpty)
    }

    func testEdgeSwipeWorksInDirectModeWithoutDragging() {
        let f = EdgeFixture(options: GestureOptions(mode: .direct, edgeSwipes: edgeOn))
        f.swipe(from: (10, 360), to: (320, 360))
        XCTAssertEqual(f.input.shortcuts, [.previousSpace])
        XCTAssertTrue(f.input.counts.isEmpty)
        XCTAssertTrue(f.input.drags.isEmpty)
    }

    func testShortcutIsPostedBeforeTheCursorLeavesThePanel() {
        let f = EdgeFixture(options: GestureOptions(mode: .scroll, edgeSwipes: edgeOn))
        f.swipe(from: (10, 360), to: (320, 360))
        XCTAssertEqual(f.log, ["borrow", "shortcut:previousSpace", "release"],
                       "Spaces switch on the display under the cursor, so the cursor must still be on the Edge")
    }

    func testTooShortOrWrongWayEdgeSwipeDoesNothing() {
        let f = EdgeFixture(options: GestureOptions(mode: .scroll, edgeSwipes: edgeOn))
        f.swipe(from: (10, 360), to: (150, 360))
        f.swipe(from: (2550, 360), to: (2550, 100), startingAt: 1000)
        XCTAssertTrue(f.input.shortcuts.isEmpty)
        XCTAssertTrue(f.input.counts.isEmpty, "A failed edge swipe must not turn into a click")
        XCTAssertTrue(f.input.scrolls.isEmpty, "Nor into a scroll")
        XCTAssertEqual(f.cursor.releases, 2)
        XCTAssertEqual(f.controller.state, .idle)
    }

    func testTapInsideAnEdgeZoneStillClicks() {
        let f = EdgeFixture(options: GestureOptions(mode: .scroll, edgeSwipes: edgeOn))
        f.send(.down, at: 0, x: 10, y: 360)
        f.send(.up, at: 10, x: 10, y: 360)
        XCTAssertEqual(f.input.counts, [1, 1])
        XCTAssertTrue(f.input.shortcuts.isEmpty)
    }

    func testHoldInsideAnEdgeZoneThenMoveDrags() {
        let f = EdgeFixture(options: GestureOptions(mode: .direct, edgeSwipes: edgeOn))
        f.send(.down, at: 0, x: 10, y: 360)
        f.clock.advance(toMilliseconds: 300)
        XCTAssertEqual(f.input.counts, [1], "Holding still past the hold duration presses the button")
        f.send(.move, at: 310, x: 320, y: 360)
        f.send(.up, at: 320, x: 320, y: 360)
        XCTAssertEqual(f.input.counts, [1, 1])
        XCTAssertEqual(f.input.drags.count, 1)
        XCTAssertTrue(f.input.shortcuts.isEmpty)
    }

    func testSwipeStartingOutsideEdgeZonesScrollsAsBefore() {
        let f = EdgeFixture(options: GestureOptions(mode: .scroll, edgeSwipes: edgeOn))
        f.swipe(from: (1280, 360), to: (1600, 360))
        XCTAssertFalse(f.input.scrolls.isEmpty)
        XCTAssertTrue(f.input.shortcuts.isEmpty)
    }

    func testDirectModeOutsideEdgeZonesStillPressesWithoutHoldDelay() {
        let f = EdgeFixture(options: GestureOptions(mode: .direct, edgeSwipes: edgeOn))
        f.send(.down, at: 0, x: 1280, y: 360)
        XCTAssertEqual(f.input.counts, [1], "Only edge-zone touches wait for the hold duration")
    }

    func testDisabledEdgeSwipesKeepDirectDragAtTheEdge() {
        let f = EdgeFixture(options: GestureOptions(mode: .direct))
        f.swipe(from: (10, 360), to: (320, 360))
        XCTAssertTrue(f.input.shortcuts.isEmpty)
        XCTAssertEqual(f.input.counts, [1, 1])
        XCTAssertFalse(f.input.drags.isEmpty)
    }

    func testFailedShortcutStillReleasesTheCursorWithoutClicking() {
        let f = EdgeFixture(options: GestureOptions(mode: .scroll, edgeSwipes: edgeOn))
        f.input.shortcutFails = true
        f.swipe(from: (10, 360), to: (320, 360))
        XCTAssertTrue(f.input.counts.isEmpty)
        XCTAssertEqual(f.cursor.releases, 1)
        XCTAssertEqual(f.controller.state, .idle)
    }
}

extension EdgeSwipeGestureTests {
    // An empty desktop has no window under the finger, so the target check fails.
    func testEdgeSwipeOverAnUnconfirmedTargetStillSwitchesSpaces() {
        let f = EdgeFixture(options: GestureOptions(mode: .scroll, edgeSwipes: edgeOn), targetAccepts: false)
        f.swipe(from: (10, 360), to: (320, 360))
        f.swipe(from: (1280, 715), to: (1280, 400), startingAt: 1000)
        XCTAssertEqual(f.input.shortcuts, [.previousSpace, .missionControl])
        XCTAssertTrue(f.input.counts.isEmpty)
        XCTAssertEqual(f.cursor.releases, 2)
        XCTAssertEqual(f.controller.state, .idle)
    }

    func testTapOverAnUnconfirmedTargetInAnEdgeZoneClicksNothing() {
        let f = EdgeFixture(options: GestureOptions(mode: .scroll, edgeSwipes: edgeOn), targetAccepts: false)
        f.send(.down, at: 0, x: 10, y: 360)
        f.send(.up, at: 10, x: 10, y: 360)
        f.clock.advance(toMilliseconds: 1000)
        XCTAssertTrue(f.input.counts.isEmpty, "Only a swipe may proceed without a confirmed target")
        XCTAssertTrue(f.input.shortcuts.isEmpty)
        XCTAssertEqual(f.cursor.releases, 1)
        XCTAssertEqual(f.controller.state, .idle)
    }

    func testHoldOverAnUnconfirmedTargetNeverPresses() {
        let f = EdgeFixture(options: GestureOptions(mode: .direct, edgeSwipes: edgeOn), targetAccepts: false)
        f.send(.down, at: 0, x: 10, y: 360)
        f.clock.advance(toMilliseconds: 400)
        f.send(.move, at: 410, x: 330, y: 360)
        f.send(.up, at: 420, x: 330, y: 360)
        XCTAssertTrue(f.input.counts.isEmpty)
        XCTAssertTrue(f.input.drags.isEmpty)
        XCTAssertEqual(f.input.shortcuts, [.previousSpace], "A slow swipe still counts when nothing can be clicked")
        XCTAssertEqual(f.controller.state, .idle)
    }

    func testUnconfirmedTargetOutsideEdgeZonesIsStillRejected() {
        let f = EdgeFixture(options: GestureOptions(mode: .scroll, edgeSwipes: edgeOn), targetAccepts: false)
        f.swipe(from: (1280, 360), to: (1600, 360))
        XCTAssertTrue(f.input.counts.isEmpty)
        XCTAssertTrue(f.input.scrolls.isEmpty)
        XCTAssertTrue(f.input.shortcuts.isEmpty)
        XCTAssertEqual(f.cursor.releases, 0, "A rejected touch never borrows the cursor")
        XCTAssertEqual(f.controller.state, .idle)
    }

    func testConfirmedTargetBehavesAsBefore() {
        let f = EdgeFixture(options: GestureOptions(mode: .scroll, edgeSwipes: edgeOn), targetAccepts: true)
        f.send(.down, at: 0, x: 10, y: 360)
        f.send(.up, at: 10, x: 10, y: 360)
        XCTAssertEqual(f.input.counts, [1, 1])
        f.swipe(from: (10, 360), to: (320, 360), startingAt: 1000)
        XCTAssertEqual(f.input.shortcuts, [.previousSpace])
    }

    func testConfigurationReachesGestureOptions() {
        var configuration = DriverConfiguration.defaults.gesture
        XCTAssertFalse(GestureOptions(configuration: configuration).edgeSwipes.enabled)
        configuration.edgeSwipes = DriverConfiguration.EdgeSwipes(enabled: true, edgeZonePx: 60, minDistancePx: 300)
        XCTAssertEqual(GestureOptions(configuration: configuration).edgeSwipes,
                       EdgeSwipeOptions(enabled: true, edgeZonePx: 60, minDistancePx: 300))
    }
}

private final class EdgeFixture {
    let input: EdgeInput
    let cursor: EdgeCursor
    let clock = TestGestureScheduler(executeCancelledActions: true)
    var log: [String] = []
    var controller: GestureController!

    let preparer: EdgeTarget?

    /// `targetAccepts` installs a target check like production's; nil skips it.
    init(options: GestureOptions, targetAccepts: Bool? = nil) {
        input = EdgeInput(); cursor = EdgeCursor()
        preparer = targetAccepts.map { EdgeTarget(accepts: $0) }
        // Raw coordinates equal display points to keep the tests readable.
        let mapper = CoordinateMapper(rawMinX: 0, rawMaxX: 2560, rawMinY: 0, rawMaxY: 720,
                                      displayBounds: CGRect(x: 0, y: 0, width: 2560, height: 720))
        let timing = GestureTiming(warpToClickDelayMs: 0, downToUpDelayMs: 0, clickToWarpBackDelayMs: 0, tapDebounceMs: 0)
        input.onShortcut = { [weak self] in self?.log.append("shortcut:\($0.rawValue)") }
        cursor.onEffect = { [weak self] in self?.log.append($0) }
        controller = GestureController(mapperProvider: { mapper }, inputSink: input,
            cursorController: cursor, timing: timing, scheduler: clock,
            targetPreparer: preparer ?? NoOpTouchTargetPreparer(),
            doubleClickInterval: { 500_000_000 }, captureDoubleClickPermit: { { true } }, options: options)
    }

    /// A quick swipe: three moves 20 ms apart, well inside the hold duration.
    func swipe(from start: (CGFloat, CGFloat), to end: (CGFloat, CGFloat), startingAt ms: UInt64 = 0) {
        send(.down, at: ms, x: start.0, y: start.1)
        for step in 1...3 {
            let t = CGFloat(step) / 3
            send(.move, at: ms + UInt64(step * 20),
                 x: start.0 + (end.0 - start.0) * t, y: start.1 + (end.1 - start.1) * t)
        }
        send(.up, at: ms + 80, x: end.0, y: end.1)
        clock.advance(toMilliseconds: ms + 100)
    }

    func send(_ kind: TouchEvent.Kind, at ms: UInt64, x: CGFloat, y: CGFloat) {
        clock.advance(toMilliseconds: ms)
        controller.handle(TouchEvent(kind: kind, contactID: 0, rawX: Int(x), rawY: Int(y), timestamp: clock.now))
    }
}

private final class EdgeInput: ClickCountSyntheticInputSink, ScrollInputSink, ShortcutInputSink {
    var shortcuts: [SpaceShortcut] = []
    var shortcutFails = false
    var onShortcut: ((SpaceShortcut) -> Void)?
    var scrolls: [(Double, Double)] = []
    var drags: [CGPoint] = []
    var counts: [Int] = []
    private var active: Int?

    func tryPostShortcut(_ shortcut: SpaceShortcut) -> SyntheticInputResult {
        if shortcutFails { return .constructionFailed }
        shortcuts.append(shortcut); onShortcut?(shortcut); return .postInvoked
    }
    func tryPostScroll(deltaX: Double, deltaY: Double, at point: CGPoint) -> SyntheticInputResult {
        scrolls.append((deltaX, deltaY)); return .postInvoked
    }
    func tryPostMouseDown(at point: CGPoint, clickCount: Int) -> SyntheticInputResult {
        guard active == nil else { return .busy }
        active = clickCount; counts.append(clickCount); return .postInvoked
    }
    func tryPostMouseDown(at point: CGPoint) -> SyntheticInputResult { tryPostMouseDown(at: point, clickCount: 1) }
    func tryPostMouseUp(at point: CGPoint) -> SyntheticInputResult {
        guard let count = active else { return .noPendingMouseDown }
        active = nil; counts.append(count); return .postInvoked
    }
    func tryPostMouseDragged(to point: CGPoint) -> SyntheticInputResult { drags.append(point); return .postInvoked }
    func postMouseDown(at point: CGPoint) { _ = tryPostMouseDown(at: point) }
    func postMouseUp(at point: CGPoint) { _ = tryPostMouseUp(at: point) }
    func postMouseDragged(to point: CGPoint) {}
}

private final class EdgeTarget: TouchTargetPreparing {
    let requiresPreparation = true
    let accepts: Bool
    init(accepts: Bool) { self.accepts = accepts }
    func prepare(at point: CGPoint, completion: @escaping (Bool) -> Void) { completion(accepts) }
    func cancel() {}
}

private final class EdgeCursor: CursorController {
    var releases = 0
    var onEffect: ((String) -> Void)?
    func borrow(warpingTo point: CGPoint) -> Bool { onEffect?("borrow"); return true }
    func updatePosition(_ point: CGPoint) {}
    func returnToOrigin() {}
    func forceShow() {}
    func releaseBorrow(returnToPreviousPosition: Bool) { releases += 1; onEffect?("release") }
}

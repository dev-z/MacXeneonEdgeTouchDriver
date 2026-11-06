import CoreGraphics
@testable import MacXeneonEdgeTouchDriverCore
import XCTest

final class EdgeSwipeRecognizerTests: XCTestCase {
    // The Edge as macOS placed it in the reported setup: right of a 1800-point display, offset down.
    private let bounds = CGRect(x: 1800, y: 281, width: 2560, height: 720)
    private let recognizer = EdgeSwipeRecognizer(options: EdgeSwipeOptions(enabled: true))

    private func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: bounds.minX + x, y: bounds.minY + y) }

    func testSwipeInFromLeftEdgeSwitchesToPreviousSpace() {
        XCTAssertEqual(recognizer.shortcut(from: point(10, 360), to: point(310, 380), bounds: bounds), .previousSpace)
    }

    func testSwipeInFromRightEdgeSwitchesToNextSpace() {
        XCTAssertEqual(recognizer.shortcut(from: point(2550, 360), to: point(2250, 340), bounds: bounds), .nextSpace)
    }

    func testSwipeUpFromBottomEdgeOpensMissionControl() {
        XCTAssertEqual(recognizer.shortcut(from: point(1280, 715), to: point(1300, 415), bounds: bounds), .missionControl)
    }

    func testSwipeShorterThanMinimumDistanceDoesNothing() {
        XCTAssertNil(recognizer.shortcut(from: point(10, 360), to: point(190, 360), bounds: bounds))
    }

    func testSwipeAwayFromItsEdgeDoesNothing() {
        XCTAssertNil(recognizer.shortcut(from: point(30, 360), to: point(0, 360), bounds: bounds))
        XCTAssertNil(recognizer.shortcut(from: point(2550, 600), to: point(2550, 100), bounds: bounds),
                     "A vertical swipe from the right edge is not a horizontal edge swipe")
    }

    func testDiagonalSwipeDoesNothing() {
        XCTAssertNil(recognizer.shortcut(from: point(10, 100), to: point(310, 300), bounds: bounds))
    }

    func testEdgeZoneBoundaryIsExact() {
        XCTAssertTrue(recognizer.startsInEdgeZone(point(39.9, 360), bounds: bounds))
        XCTAssertFalse(recognizer.startsInEdgeZone(point(40, 360), bounds: bounds))
        XCTAssertFalse(recognizer.startsInEdgeZone(point(1280, 360), bounds: bounds))
        XCTAssertNil(recognizer.shortcut(from: point(40, 360), to: point(400, 360), bounds: bounds))
    }

    func testRightAndBottomZonesMeasureFromTheLastPixel() {
        // CoordinateMapper never returns maxX/maxY; its largest values are just below them.
        XCTAssertTrue(recognizer.startsInEdgeZone(CGPoint(x: bounds.maxX.nextDown, y: bounds.midY), bounds: bounds))
        XCTAssertTrue(recognizer.startsInEdgeZone(CGPoint(x: bounds.midX, y: bounds.maxY.nextDown), bounds: bounds))
        XCTAssertFalse(recognizer.startsInEdgeZone(point(2519, 360), bounds: bounds))
        XCTAssertFalse(recognizer.startsInEdgeZone(point(1280, 679), bounds: bounds))
    }

    func testTopEdgeIsNotAGestureZone() {
        XCTAssertFalse(recognizer.startsInEdgeZone(point(1280, 5), bounds: bounds))
        XCTAssertNil(recognizer.shortcut(from: point(1280, 5), to: point(1280, 400), bounds: bounds))
    }

    func testCornerStartUsesTheSwipeDirection() {
        XCTAssertEqual(recognizer.shortcut(from: point(10, 715), to: point(20, 400), bounds: bounds), .missionControl)
        XCTAssertEqual(recognizer.shortcut(from: point(10, 715), to: point(320, 700), bounds: bounds), .previousSpace)
    }

    func testDisabledRecognizerHasNoZones() {
        let disabled = EdgeSwipeRecognizer(options: EdgeSwipeOptions(enabled: false))
        XCTAssertFalse(disabled.startsInEdgeZone(point(10, 360), bounds: bounds))
        XCTAssertNil(disabled.shortcut(from: point(10, 360), to: point(310, 360), bounds: bounds))
    }

    func testOptionsAreClampedToUsableRanges() {
        let options = EdgeSwipeOptions(enabled: true, edgeZonePx: 0, minDistancePx: .infinity)
        XCTAssertEqual(options.edgeZonePx, 5)
        XCTAssertEqual(options.minDistancePx, 200)
        XCTAssertEqual(EdgeSwipeOptions(enabled: true, edgeZonePx: 900, minDistancePx: 5).edgeZonePx, 200)
        XCTAssertEqual(EdgeSwipeOptions(enabled: true, edgeZonePx: 900, minDistancePx: 5).minDistancePx, 50)
    }
}

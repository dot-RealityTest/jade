import XCTest
@testable import Muxy

@MainActor
final class WindowLayoutMetricsTests: XCTestCase {
    func testMainWindowMinimumMatchesSceneConfiguration() {
        XCTAssertEqual(WindowLayoutMetrics.mainMinWidth, 900)
        XCTAssertEqual(WindowLayoutMetrics.mainMinHeight, 640)
        XCTAssertEqual(WindowLayoutMetrics.mainDefaultWidth, 1200)
        XCTAssertEqual(WindowLayoutMetrics.mainDefaultHeight, 800)
    }

    func testSettingsSizingMatchesHIGBand() {
        XCTAssertEqual(WindowLayoutMetrics.settingsMinWidth, 520)
        XCTAssertEqual(WindowLayoutMetrics.settingsIdealWidth, 560)
        XCTAssertEqual(WindowLayoutMetrics.settingsMaxWidth, 640)
        XCTAssertEqual(WindowLayoutMetrics.settingsMinHeight, 360)
        XCTAssertEqual(WindowLayoutMetrics.settingsIdealHeight, 420)
        XCTAssertEqual(WindowLayoutMetrics.settingsMaxHeight, 520)
    }

    func testNarrowWidthAdjustmentsHideLowestPriorityPanelsFirst() {
        let visibility = WindowLayoutMetrics.AuxiliaryVisibility(
            vcsVisible: false,
            vcsWidth: 0,
            fileTreeVisible: false,
            fileTreeWidth: 0,
            snippetsVisible: true,
            aiVisible: true,
            notesVisible: true,
            todoVisible: true
        )
        let adjustments = WindowLayoutMetrics.narrowWidthAdjustments(
            windowWidth: 900,
            sidebarWidth: WindowLayoutMetrics.sidebarExpandedWidth + 1,
            visibility: visibility
        )
        XCTAssertTrue(adjustments.hideAI)
        XCTAssertTrue(adjustments.hideSnippets)
        XCTAssertTrue(adjustments.hideInspector)
    }

    func testNarrowWidthAdjustmentsKeepContentWhenWideEnough() {
        let visibility = WindowLayoutMetrics.AuxiliaryVisibility(
            vcsVisible: false,
            vcsWidth: 0,
            fileTreeVisible: false,
            fileTreeWidth: 0,
            snippetsVisible: true,
            aiVisible: true,
            notesVisible: false,
            todoVisible: false
        )
        let adjustments = WindowLayoutMetrics.narrowWidthAdjustments(
            windowWidth: 1400,
            sidebarWidth: WindowLayoutMetrics.sidebarExpandedWidth + 1,
            visibility: visibility
        )
        XCTAssertEqual(adjustments, WindowLayoutMetrics.NarrowWidthAdjustments())
    }
}

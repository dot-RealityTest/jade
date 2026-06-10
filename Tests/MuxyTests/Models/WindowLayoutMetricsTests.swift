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
        XCTAssertEqual(WindowLayoutMetrics.settingsMinWidth, 640)
        XCTAssertEqual(WindowLayoutMetrics.settingsIdealWidth, 760)
        XCTAssertEqual(WindowLayoutMetrics.settingsMaxWidth, 1100)
        XCTAssertEqual(WindowLayoutMetrics.settingsMinHeight, 460)
        XCTAssertEqual(WindowLayoutMetrics.settingsIdealHeight, 600)
        XCTAssertEqual(WindowLayoutMetrics.settingsMaxHeight, 900)
        XCTAssertEqual(WindowLayoutMetrics.settingsSidebarIdealWidth, 220)
    }

    func testNarrowWidthAdjustmentsHideLowestPriorityPanelsFirst() {
        let visibility = WindowLayoutMetrics.AuxiliaryVisibility(
            vcsVisible: false,
            vcsWidth: 0,
            fileTreeVisible: false,
            fileTreeWidth: 0,
            snippetsVisible: true,
            aiVisible: true
        )
        let adjustments = WindowLayoutMetrics.narrowWidthAdjustments(
            windowWidth: 900,
            sidebarWidth: WindowLayoutMetrics.sidebarExpandedWidth + 1,
            visibility: visibility
        )
        XCTAssertTrue(adjustments.hideAI)
        XCTAssertTrue(adjustments.hideSnippets)
    }

    func testNarrowWidthAdjustmentsKeepContentWhenWideEnough() {
        let visibility = WindowLayoutMetrics.AuxiliaryVisibility(
            vcsVisible: false,
            vcsWidth: 0,
            fileTreeVisible: false,
            fileTreeWidth: 0,
            snippetsVisible: true,
            aiVisible: true
        )
        let adjustments = WindowLayoutMetrics.narrowWidthAdjustments(
            windowWidth: 1400,
            sidebarWidth: WindowLayoutMetrics.sidebarExpandedWidth + 1,
            visibility: visibility
        )
        XCTAssertEqual(adjustments, WindowLayoutMetrics.NarrowWidthAdjustments())
    }
}

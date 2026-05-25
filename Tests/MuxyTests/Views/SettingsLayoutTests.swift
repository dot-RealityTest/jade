import XCTest
@testable import Muxy

@MainActor
final class SettingsLayoutTests: XCTestCase {
    func testCompactLayoutThreshold() {
        XCTAssertFalse(SettingsLayout.isCompact(contentWidth: SettingsMetrics.compactContentWidth))
        XCTAssertTrue(SettingsLayout.isCompact(contentWidth: SettingsMetrics.compactContentWidth - 1))
    }

    func testResolvedControlWidthUsesFullWidthWhenCompact() {
        let width = SettingsMetrics.resolvedControlWidth(for: 300)
        XCTAssertEqual(width, 300 - SettingsMetrics.horizontalPadding * 2)
    }

    func testResolvedControlWidthCapsAtDefaultWhenWide() {
        XCTAssertEqual(
            SettingsMetrics.resolvedControlWidth(for: 800),
            SettingsMetrics.controlWidth
        )
    }
}

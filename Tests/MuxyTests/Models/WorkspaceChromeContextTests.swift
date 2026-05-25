import XCTest
@testable import Muxy

@MainActor
final class WorkspaceChromeContextTests: XCTestCase {
    func testPanelAccentIsMutedWhenNotRequested() {
        let color = WorkspaceChromePanelAccent.color(requested: false, suppressed: false)
        XCTAssertEqual(color, MuxyTheme.fgMuted)
    }

    func testPanelAccentIsDimmedWhenSuppressedButStillRequested() {
        let color = WorkspaceChromePanelAccent.color(requested: true, suppressed: true)
        XCTAssertNotEqual(color, MuxyTheme.fgMuted)
        XCTAssertNotEqual(color, MuxyTheme.accent)
    }

    func testPanelAccentUsesAccentWhenVisible() {
        let color = WorkspaceChromePanelAccent.color(requested: true, suppressed: false)
        XCTAssertEqual(color, MuxyTheme.accent)
    }
}

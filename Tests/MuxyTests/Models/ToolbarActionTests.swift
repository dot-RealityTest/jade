import Testing

@testable import Muxy

@Suite("ToolbarAction")
struct ToolbarActionTests {
    @Test("default actions keep the toolbar compact")
    func defaultActionsAreCompact() {
        #expect(ToolbarAction.visibleActions(from: ToolbarAction.defaultRawValue) == [
            .debug,
            .tools,
            .snippets,
            .newTab,
        ])
    }

    @Test("raw value preserves case order and supports empty selection")
    func rawValueRoundTrip() {
        let actions: Set<ToolbarAction> = [.fileTree, .debug, .splitDown]
        let rawValue = ToolbarAction.rawValue(for: actions)
        #expect(rawValue == "debug,fileTree,splitDown")
        #expect(ToolbarAction.visibleActions(from: rawValue) == actions)
        #expect(ToolbarAction.visibleActions(from: "").isEmpty)
    }
}

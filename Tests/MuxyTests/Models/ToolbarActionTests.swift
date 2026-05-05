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
            .notes,
            .todo,
            .newTab,
        ])
        #expect(ToolbarAction.visibleActions(from: "debug,tools,snippets,newTab").contains(.notes))
        #expect(ToolbarAction.visibleActions(from: "debug,tools,snippets,newTab").contains(.todo))
        #expect(ToolbarAction.visibleActions(from: "debug,tools,snippets,inspector,newTab").contains(.notes))
        #expect(ToolbarAction.visibleActions(from: "debug,tools,snippets,inspector,newTab").contains(.todo))
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

import Testing
@testable import Muxy

@Suite("SidePanelPolicy")
struct SidePanelPolicyTests {
    @Test("Enabling snippets closes other right-rail panels")
    func enablingSnippetsClosesOthers() {
        let initial = SidePanelVisibility(snippets: false, ai: true, notes: true, todo: true)
        let next = SidePanelPolicy.toggling(.snippets, in: initial)
        #expect(next.snippets)
        #expect(!next.ai)
        #expect(!next.notes)
        #expect(!next.todo)
    }

    @Test("Enabling AI closes other right-rail panels")
    func enablingAIClosesOthers() {
        let initial = SidePanelVisibility(snippets: true, ai: false, notes: true, todo: false)
        let next = SidePanelPolicy.toggling(.ai, in: initial)
        #expect(next.ai)
        #expect(!next.snippets)
        #expect(!next.notes)
    }

    @Test("Disabling a panel leaves others unchanged")
    func disablingLeavesOthers() {
        let initial = SidePanelVisibility(snippets: true, ai: false, notes: false, todo: false)
        let next = SidePanelPolicy.toggling(.snippets, in: initial)
        #expect(!next.snippets)
        #expect(!next.ai)
    }
}

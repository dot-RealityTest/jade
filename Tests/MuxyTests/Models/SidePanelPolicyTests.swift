import Testing
@testable import Muxy

@Suite("SidePanelPolicy")
struct SidePanelPolicyTests {
    @Test("Enabling snippets closes AI panel")
    func enablingSnippetsClosesAI() {
        let initial = SidePanelVisibility(snippets: false, ai: true)
        let next = SidePanelPolicy.toggling(.snippets, in: initial)
        #expect(next.snippets)
        #expect(!next.ai)
    }

    @Test("Enabling AI closes snippets panel")
    func enablingAIClosesSnippets() {
        let initial = SidePanelVisibility(snippets: true, ai: false)
        let next = SidePanelPolicy.toggling(.ai, in: initial)
        #expect(next.ai)
        #expect(!next.snippets)
    }

    @Test("Disabling a panel leaves others unchanged")
    func disablingLeavesOthers() {
        let initial = SidePanelVisibility(snippets: true, ai: false)
        let next = SidePanelPolicy.toggling(.snippets, in: initial)
        #expect(!next.snippets)
        #expect(!next.ai)
    }
}

import Foundation
import Testing

@testable import Muxy

@Suite("ProjectWorkspaceMarkdown Preview")
struct ProjectWorkspaceMarkdownPreviewTests {
    @Test("previewLines parses notes and tasks")
    func previewLines() {
        let markdown = """
        Hello notes

        - [ ] Ship preview
        - [x] Done item
        """
        let lines = ProjectWorkspaceMarkdown.previewLines(from: markdown)
        #expect(lines.count == 4)
        #expect(lines[0].kind == .note)
        #expect(lines[0].displayText == "Hello notes")
        #expect(lines[1].kind == .blank)
        #expect(lines[2].kind == .task(isDone: false))
        #expect(lines[2].displayText == "Ship preview")
        #expect(lines[3].kind == .task(isDone: true))
    }

    @Test("toggleTaskLine flips checkbox marker")
    func toggleTaskLine() {
        let markdown = "- [ ] Buy milk\n- [x] Done"
        let toggled = ProjectWorkspaceMarkdown.toggleTaskLine(at: 0, in: markdown)
        #expect(toggled == "- [x] Buy milk\n- [x] Done")

        let toggledBack = ProjectWorkspaceMarkdown.toggleTaskLine(at: 0, in: toggled ?? "")
        #expect(toggledBack == "- [ ] Buy milk\n- [x] Done")
    }

    @Test("toggleTaskLine returns nil for non-task lines")
    func toggleNonTaskLine() {
        let markdown = "Just notes"
        #expect(ProjectWorkspaceMarkdown.toggleTaskLine(at: 0, in: markdown) == nil)
    }
}

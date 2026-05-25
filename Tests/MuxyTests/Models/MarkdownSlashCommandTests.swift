import Foundation
import Testing

@testable import Muxy

@Suite("MarkdownSlashCommandSession")
struct MarkdownSlashCommandSessionTests {
    @Test("detects slash query at line start")
    func detectsSlashQueryAtLineStart() {
        let context = MarkdownSlashCommandSession.context(in: "/bul", selectedLocation: 4)
        #expect(context?.query == "bul")
        #expect(context?.replaceRange == NSRange(location: 0, length: 4))
    }

    @Test("detects slash query after whitespace")
    func detectsSlashQueryAfterWhitespace() {
        let text = "hello /todo"
        let context = MarkdownSlashCommandSession.context(in: text, selectedLocation: (text as NSString).length)
        #expect(context?.query == "todo")
    }

    @Test("ignores slash inside word")
    func ignoresSlashInsideWord() {
        let context = MarkdownSlashCommandSession.context(in: "path/to/file", selectedLocation: 9)
        #expect(context == nil)
    }

    @Test("applies todo command")
    func appliesTodoCommand() {
        let command = MarkdownSlashCommand.catalog.first { $0.id == "todo" }!
        let applied = MarkdownSlashCommandSession.apply(
            command: command,
            replaceRange: NSRange(location: 0, length: 5),
            in: "/todo",
            selectedLocation: 5
        )
        #expect(applied.text == "- [ ] ")
    }

    @Test("filters commands by query")
    func filtersCommandsByQuery() {
        let matches = MarkdownSlashCommandSession.filteredCommands(query: "head")
        #expect(matches.contains(where: { $0.id == "heading1" }))
        #expect(!matches.contains(where: { $0.id == "todo" }))
    }
}

@Suite("ProjectWorkspaceMarkdown")
struct ProjectWorkspaceMarkdownTests {
    @Test("compose merges notes and todos")
    func composeMergesNotesAndTodos() {
        let document = ProjectInspectorDocument(
            notes: "Plan release",
            todos: [
                ProjectTodoItem(title: "Ship", isDone: false),
                ProjectTodoItem(title: "Archive", isDone: true),
            ]
        )
        let markdown = ProjectWorkspaceMarkdown.compose(document)
        #expect(markdown.contains("Plan release"))
        #expect(markdown.contains("- [ ] Ship"))
        #expect(markdown.contains("- [x] Archive"))
    }

    @Test("apply splits markdown into notes and todos")
    func applySplitsMarkdownIntoNotesAndTodos() {
        var document = ProjectInspectorDocument()
        ProjectWorkspaceMarkdown.apply(
            """
            Plan release

            - [ ] Ship
            - [x] Archive
            - Regular bullet
            """,
            to: &document
        )
        #expect(document.notes.contains("Plan release"))
        #expect(document.notes.contains("- Regular bullet"))
        #expect(document.todos.count == 2)
        #expect(document.todos.contains(where: { $0.title == "Ship" && !$0.isDone }))
        #expect(document.todos.contains(where: { $0.title == "Archive" && $0.isDone }))
    }
}

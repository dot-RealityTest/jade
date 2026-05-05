import Foundation
import Testing

@testable import Muxy

@Suite("TerminalSnippetCapture")
struct TerminalSnippetCaptureTests {
    @Test("command trims selected terminal text")
    func commandTrimsSelectedTerminalText() {
        #expect(TerminalSnippetCapture.command(from: "  swift test  \n") == "swift test")
        #expect(TerminalSnippetCapture.command(from: "\n\t\n") == nil)
    }

    @Test("title strips simple prompts and truncates long commands")
    func titleStripsSimplePromptsAndTruncatesLongCommands() {
        #expect(TerminalSnippetCapture.title(for: "$ git status") == "git status")
        #expect(TerminalSnippetCapture.title(for: "> docker compose ps") == "docker compose ps")

        let title = TerminalSnippetCapture.title(for: "swift test --filter SomeExtremelyLongSpecificSuiteName")
        #expect(title == "swift test --filter SomeExtremelyLongSp...")
    }

    @Test("save writes into selected snippet scope")
    @MainActor
    func saveWritesIntoSelectedSnippetScope() {
        let sharedScope = SnippetScope(
            id: "shared-test",
            displayName: "Snippets",
            fileURL: URL(fileURLWithPath: "/tmp/shared-terminal-snippets.json"),
            starterSnippets: [],
            starterSeedPolicy: .missingStorage
        )
        let remoteScope = SnippetScope(
            id: "remote-test",
            displayName: "Zen Snippets",
            fileURL: URL(fileURLWithPath: "/tmp/remote-terminal-snippets.json"),
            starterSnippets: [],
            starterSeedPolicy: .missingStorage
        )
        let sharedPersistence = TerminalSnippetPersistence()
        let remotePersistence = TerminalSnippetPersistence()
        let store = SnippetsStore(scope: sharedScope) { scope in
            scope.id == remoteScope.id ? remotePersistence : sharedPersistence
        }

        let saved = TerminalSnippetCapture.save(command: " df -h ", scope: remoteScope, store: store)

        #expect(saved?.name == "df -h")
        #expect(saved?.command == "df -h")
        #expect(saved?.tags == ["linux"])
        #expect(remotePersistence.savedSnippets?.map(\.command) == ["df -h"])
        #expect(sharedPersistence.savedSnippets == nil)
    }
}

private final class TerminalSnippetPersistence: SnippetsPersisting {
    var savedSnippets: [Snippet]?

    func loadSnippets() throws -> [Snippet] {
        []
    }

    func saveSnippets(_ snippets: [Snippet]) throws {
        savedSnippets = snippets
    }

    func hasSavedSnippets() -> Bool {
        true
    }
}

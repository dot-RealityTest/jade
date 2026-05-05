import Foundation
import Testing

@testable import Muxy

@Suite("SnippetsStore")
@MainActor
struct SnippetsStoreTests {
    @Test("missing persistence starts empty")
    func missingPersistenceStartsEmpty() {
        let store = testStore(persistence: InMemorySnippetsPersistence())

        #expect(store.snippets.isEmpty)
        #expect(store.filteredSnippets.isEmpty)
    }

    @Test("add trims normalizes and persists snippet")
    func addTrimsNormalizesAndPersistsSnippet() {
        let persistence = InMemorySnippetsPersistence()
        let store = testStore(persistence: persistence)

        let snippet = store.add(Snippet(
            name: " Tests ",
            description: " Run tests ",
            command: " swift test ",
            tags: [" Swift ", "#test", "swift"],
            variableDefaults: ["unused": "value"]
        ))

        #expect(snippet == Snippet(
            id: snippet?.id ?? UUID(),
            name: "Tests",
            description: "Run tests",
            command: "swift test",
            tags: ["swift", "test"]
        ))
        #expect(store.snippets == persistence.savedSnippets)
    }

    @Test("add ignores empty command")
    func addIgnoresEmptyCommand() {
        let persistence = InMemorySnippetsPersistence()
        let store = testStore(persistence: persistence)

        let snippet = store.add(Snippet(name: "Empty", command: " "))

        #expect(snippet == nil)
        #expect(store.snippets.isEmpty)
        #expect(persistence.savedSnippets == nil)
    }

    @Test("update persists existing snippet")
    func updatePersistsExistingSnippet() {
        let original = Snippet(name: "Status", command: "git status", tags: ["git"])
        let persistence = InMemorySnippetsPersistence(snippets: [original])
        let store = testStore(persistence: persistence)
        var updated = original
        updated.name = "Tests"
        updated.command = " swift test "
        updated.tags = ["Swift", "Tests"]

        store.update(updated)

        #expect(store.snippets == [Snippet(id: original.id, name: "Tests", command: "swift test", tags: ["swift", "tests"])])
        #expect(persistence.savedSnippets == store.snippets)
    }

    @Test("filter matches name command and tags")
    func filterMatchesNameCommandAndTags() {
        let store = testStore(persistence: InMemorySnippetsPersistence(snippets: [
            Snippet(name: "Status", command: "git status", tags: ["git"]),
            Snippet(name: "Tests", command: "swift test", tags: ["build"]),
        ]))

        store.searchQuery = "git"
        #expect(store.filteredSnippets.map(\.name) == ["Status"])

        store.searchQuery = "swift"
        #expect(store.filteredSnippets.map(\.name) == ["Tests"])

        store.searchQuery = "build"
        #expect(store.filteredSnippets.map(\.name) == ["Tests"])
    }

    @Test("scope switching keeps remote snippets isolated")
    func scopeSwitchingKeepsRemoteSnippetsIsolated() {
        let sharedScope = SnippetScope(
            id: "shared-test",
            displayName: "Snippets",
            fileURL: URL(fileURLWithPath: "/tmp/shared-snippets.json"),
            starterSnippets: [],
            starterSeedPolicy: .missingStorage
        )
        let remoteScope = SnippetScope(
            id: "remote-test",
            displayName: "Zen Snippets",
            fileURL: URL(fileURLWithPath: "/tmp/zen-snippets.json"),
            starterSnippets: [],
            starterSeedPolicy: .missingStorage
        )
        let sharedPersistence = InMemorySnippetsPersistence(snippets: [
            Snippet(name: "Build", command: "swift build", tags: ["mac"])
        ])
        let remotePersistence = InMemorySnippetsPersistence(snippets: [
            Snippet(name: "Processes", command: "ps aux", tags: ["linux"])
        ])
        let store = SnippetsStore(scope: sharedScope) { scope in
            scope.id == remoteScope.id ? remotePersistence : sharedPersistence
        }

        #expect(store.filteredSnippets.map(\.command) == ["swift build"])

        store.searchQuery = "build"
        store.selectScope(remoteScope)

        #expect(store.searchQuery.isEmpty)
        #expect(store.filteredSnippets.map(\.command) == ["ps aux"])

        store.add(Snippet(name: "Disk", command: "df -h", tags: ["linux"]))

        #expect(remotePersistence.savedSnippets?.map(\.command) == ["df -h", "ps aux"])
        #expect(sharedPersistence.savedSnippets == nil)
    }

    @Test("remote scope seeds linux starters only when storage is missing")
    func remoteScopeSeedsLinuxStartersOnlyWhenStorageIsMissing() {
        let remoteScope = SnippetScope(
            id: "remote-test",
            displayName: "Zen Snippets",
            fileURL: URL(fileURLWithPath: "/tmp/zen-snippets.json"),
            starterSnippets: [
                Snippet(name: "Uptime", command: "uptime", tags: ["linux"])
            ],
            starterSeedPolicy: .missingStorage
        )
        let missingPersistence = InMemorySnippetsPersistence(hasSavedSnippets: false)
        let missingStore = SnippetsStore(scope: remoteScope) { _ in missingPersistence }

        #expect(missingStore.snippets.map(\.command) == ["uptime"])
        #expect(missingPersistence.savedSnippets == missingStore.snippets)

        let emptyPersistence = InMemorySnippetsPersistence(hasSavedSnippets: true)
        let emptyStore = SnippetsStore(scope: remoteScope) { _ in emptyPersistence }

        #expect(emptyStore.snippets.isEmpty)
        #expect(emptyPersistence.savedSnippets == nil)
    }

    @Test("shared scope seeds starters when storage is empty")
    func sharedScopeSeedsStartersWhenStorageIsEmpty() {
        let sharedScope = SnippetScope(
            id: "shared-test",
            displayName: "Snippets",
            fileURL: URL(fileURLWithPath: "/tmp/shared-snippets.json"),
            starterSnippets: [
                Snippet(name: "Status", command: "git status", tags: ["git"])
            ],
            starterSeedPolicy: .missingOrEmptyStorage
        )
        let persistence = InMemorySnippetsPersistence(hasSavedSnippets: true)
        let store = SnippetsStore(scope: sharedScope) { _ in persistence }

        #expect(store.snippets.map(\.command) == ["git status"])
        #expect(persistence.savedSnippets == store.snippets)
    }

    private func testStore(persistence: InMemorySnippetsPersistence) -> SnippetsStore {
        let scope = SnippetScope(
            id: "test",
            displayName: "Test Snippets",
            fileURL: URL(fileURLWithPath: "/tmp/test-snippets.json"),
            starterSnippets: [],
            starterSeedPolicy: .missingStorage
        )
        return SnippetsStore(scope: scope) { _ in persistence }
    }
}

private final class InMemorySnippetsPersistence: SnippetsPersisting {
    var snippets: [Snippet]
    var savedSnippets: [Snippet]?
    var savedExists: Bool

    init(snippets: [Snippet] = [], hasSavedSnippets: Bool? = nil) {
        self.snippets = snippets
        savedExists = hasSavedSnippets ?? !snippets.isEmpty
    }

    func loadSnippets() throws -> [Snippet] {
        snippets
    }

    func saveSnippets(_ snippets: [Snippet]) throws {
        savedSnippets = snippets
        savedExists = true
    }

    func hasSavedSnippets() -> Bool {
        savedExists
    }
}

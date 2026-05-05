import Foundation
import os

private let snippetsLogger = Logger(subsystem: "app.muxy", category: "SnippetsStore")

protocol SnippetsPersisting {
    func loadSnippets() throws -> [Snippet]
    func saveSnippets(_ snippets: [Snippet]) throws
    func hasSavedSnippets() -> Bool
}

final class FileSnippetsPersistence: SnippetsPersisting {
    private let store: CodableFileStore<[Snippet]>

    init(fileURL: URL = MuxyFileStorage.fileURL(filename: "snippets.json")) {
        store = CodableFileStore(
            fileURL: fileURL,
            options: CodableFileStoreOptions(
                prettyPrinted: true,
                sortedKeys: true,
                filePermissions: FilePermissions.privateFile
            )
        )
    }

    func loadSnippets() throws -> [Snippet] {
        try store.load() ?? []
    }

    func saveSnippets(_ snippets: [Snippet]) throws {
        try store.save(snippets)
    }

    func hasSavedSnippets() -> Bool {
        FileManager.default.fileExists(atPath: store.fileURL.path)
    }
}

@MainActor
@Observable
final class SnippetsStore {
    static let shared = SnippetsStore()

    private(set) var snippets: [Snippet] = []
    var searchQuery = ""
    private(set) var scope: SnippetScope
    private var persistence: any SnippetsPersisting
    private let persistenceFactory: (SnippetScope) -> any SnippetsPersisting

    init(
        scope: SnippetScope = .shared,
        persistenceFactory: @escaping (SnippetScope) -> any SnippetsPersisting = {
            FileSnippetsPersistence(fileURL: $0.fileURL)
        }
    ) {
        self.scope = scope
        self.persistenceFactory = persistenceFactory
        persistence = persistenceFactory(scope)
        load()
    }

    convenience init(persistence: any SnippetsPersisting) {
        self.init(persistenceFactory: { _ in persistence })
    }

    func selectScope(_ scope: SnippetScope) {
        guard self.scope != scope else { return }
        self.scope = scope
        persistence = persistenceFactory(scope)
        searchQuery = ""
        load()
    }

    var filteredSnippets: [Snippet] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return snippets }
        return snippets.filter { snippet in
            snippet.displayName.lowercased().contains(query)
                || snippet.trimmedDescription.lowercased().contains(query)
                || snippet.trimmedCommand.lowercased().contains(query)
                || snippet.tags.contains { $0.contains(query) }
                || snippet.variables.contains { $0.lowercased().contains(query) }
        }
    }

    @discardableResult
    func add(_ snippet: Snippet) -> Snippet? {
        guard let snippet = sanitized(snippet) else { return nil }
        snippets.insert(snippet, at: 0)
        save()
        return snippet
    }

    func update(_ snippet: Snippet) {
        guard let index = snippets.firstIndex(where: { $0.id == snippet.id }),
              let snippet = sanitized(snippet)
        else { return }
        snippets[index] = snippet
        save()
    }

    func delete(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
        save()
    }

    private func load() {
        do {
            let hasSavedSnippets = persistence.hasSavedSnippets()
            let loaded = try persistence.loadSnippets().compactMap(sanitized)
            if shouldSeedStarters(loaded: loaded, hasSavedSnippets: hasSavedSnippets) {
                snippets = scope.starterSnippets.compactMap(sanitized)
                save()
                return
            }
            snippets = loaded
        } catch {
            snippetsLogger.error("Failed to load snippets: \(error.localizedDescription)")
            snippets = []
        }
    }

    private func save() {
        do {
            try persistence.saveSnippets(snippets)
        } catch {
            snippetsLogger.error("Failed to save snippets: \(error.localizedDescription)")
        }
    }

    private func shouldSeedStarters(loaded: [Snippet], hasSavedSnippets: Bool) -> Bool {
        guard loaded.isEmpty, !scope.starterSnippets.isEmpty else { return false }
        switch scope.starterSeedPolicy {
        case .missingStorage:
            return !hasSavedSnippets
        case .missingOrEmptyStorage:
            return true
        }
    }

    private func sanitized(_ snippet: Snippet) -> Snippet? {
        let command = snippet.trimmedCommand
        guard !command.isEmpty else { return nil }
        return Snippet(
            id: snippet.id,
            name: snippet.trimmedName,
            description: snippet.trimmedDescription,
            command: command,
            tags: Snippet.normalizedTags(from: snippet.tags),
            variableDefaults: Snippet.normalizedVariableDefaults(snippet.variableDefaults, command: command)
        )
    }
}

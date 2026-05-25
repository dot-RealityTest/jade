import Foundation
import os

private let projectInspectorLogger = Logger(subsystem: "app.muxy", category: "ProjectInspectorStore")

protocol ProjectInspectorPersisting {
    func loadDocument() throws -> ProjectInspectorDocument
    func saveDocument(_ document: ProjectInspectorDocument) throws
}

struct FileProjectInspectorPersistence: ProjectInspectorPersisting {
    private let store: CodableFileStore<ProjectInspectorDocument>

    init(projectID: UUID) {
        let directory = MuxyFileStorage.appSupportDirectory()
            .appendingPathComponent("project-inspector", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: FilePermissions.privateDirectory]
        )
        store = CodableFileStore(
            fileURL: directory.appendingPathComponent("\(projectID.uuidString).json"),
            options: CodableFileStoreOptions(
                prettyPrinted: true,
                sortedKeys: true,
                filePermissions: FilePermissions.privateFile
            )
        )
    }

    func loadDocument() throws -> ProjectInspectorDocument {
        try store.load() ?? ProjectInspectorDocument()
    }

    func saveDocument(_ document: ProjectInspectorDocument) throws {
        try store.save(document)
    }
}

@MainActor
@Observable
final class ProjectInspectorStore {
    static let shared = ProjectInspectorStore()

    private(set) var projectID: UUID?
    private(set) var document = ProjectInspectorDocument()
    private var persistence: (any ProjectInspectorPersisting)?
    private let persistenceFactory: (UUID) -> any ProjectInspectorPersisting

    init(persistenceFactory: @escaping (UUID) -> any ProjectInspectorPersisting = {
        FileProjectInspectorPersistence(projectID: $0)
    }) {
        self.persistenceFactory = persistenceFactory
    }

    var sortedTodos: [ProjectTodoItem] {
        document.todos.sorted { lhs, rhs in
            if lhs.isDone != rhs.isDone { return !lhs.isDone }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    func selectProject(_ projectID: UUID?) {
        guard self.projectID != projectID else { return }
        self.projectID = projectID
        guard let projectID else {
            persistence = nil
            document = ProjectInspectorDocument()
            return
        }
        persistence = persistenceFactory(projectID)
        load()
    }

    func updateNotes(_ notes: String) {
        document.notes = notes
        save()
    }

    var workspaceMarkdown: String {
        ProjectWorkspaceMarkdown.compose(document)
    }

    func updateWorkspace(_ markdown: String) {
        ProjectWorkspaceMarkdown.apply(markdown, to: &document)
        save()
    }

    @discardableResult
    func addTodo(title: String, now: Date = Date()) -> ProjectTodoItem? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let item = ProjectTodoItem(title: trimmed, createdAt: now, updatedAt: now)
        document.todos.insert(item, at: 0)
        save()
        return item
    }

    func updateTodoTitle(_ itemID: UUID, title: String, now: Date = Date()) {
        guard let index = document.todos.firstIndex(where: { $0.id == itemID }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            deleteTodo(itemID)
            return
        }
        document.todos[index].title = trimmed
        document.todos[index].updatedAt = now
        save()
    }

    func toggleTodo(_ itemID: UUID, now: Date = Date()) {
        guard let index = document.todos.firstIndex(where: { $0.id == itemID }) else { return }
        document.todos[index].isDone.toggle()
        document.todos[index].updatedAt = now
        save()
    }

    func deleteTodo(_ itemID: UUID) {
        document.todos.removeAll { $0.id == itemID }
        save()
    }

    func clearCompleted() {
        document.todos.removeAll(where: \.isDone)
        save()
    }

    private func load() {
        do {
            document = try persistence?.loadDocument() ?? ProjectInspectorDocument()
        } catch {
            projectInspectorLogger.error("Failed to load project inspector document: \(error.localizedDescription)")
            document = ProjectInspectorDocument()
        }
    }

    private func save() {
        do {
            try persistence?.saveDocument(document)
        } catch {
            projectInspectorLogger.error("Failed to save project inspector document: \(error.localizedDescription)")
        }
    }
}

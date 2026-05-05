import Foundation
import Testing

@testable import Muxy

@Suite("ProjectInspectorStore")
@MainActor
struct ProjectInspectorStoreTests {
    @Test("selectProject loads isolated project documents")
    func selectProjectLoadsIsolatedProjectDocuments() {
        let firstID = UUID()
        let secondID = UUID()
        let firstPersistence = InMemoryProjectInspectorPersistence(document: ProjectInspectorDocument(notes: "Alpha"))
        let secondPersistence = InMemoryProjectInspectorPersistence(document: ProjectInspectorDocument(notes: "Beta"))
        let store = ProjectInspectorStore { projectID in
            projectID == firstID ? firstPersistence : secondPersistence
        }

        store.selectProject(firstID)
        #expect(store.document.notes == "Alpha")

        store.selectProject(secondID)
        #expect(store.document.notes == "Beta")
    }

    @Test("notes persist for active project")
    func notesPersistForActiveProject() {
        let persistence = InMemoryProjectInspectorPersistence()
        let store = ProjectInspectorStore { _ in persistence }

        store.selectProject(UUID())
        store.updateNotes("Ship Jade")

        #expect(persistence.savedDocument?.notes == "Ship Jade")
    }

    @Test("todo lifecycle trims toggles renames and clears completed")
    func todoLifecycle() {
        let persistence = InMemoryProjectInspectorPersistence()
        let store = ProjectInspectorStore { _ in persistence }
        let createdAt = Date(timeIntervalSince1970: 10)
        let updatedAt = Date(timeIntervalSince1970: 20)

        store.selectProject(UUID())
        let item = store.addTodo(title: "  Add inspector  ", now: createdAt)

        #expect(item?.title == "Add inspector")
        #expect(store.document.todos.count == 1)

        store.updateTodoTitle(item?.id ?? UUID(), title: " Add notes ", now: updatedAt)
        store.toggleTodo(item?.id ?? UUID(), now: updatedAt)

        #expect(store.document.todos.first?.title == "Add notes")
        #expect(store.document.todos.first?.isDone == true)
        #expect(store.document.todos.first?.updatedAt == updatedAt)

        store.clearCompleted()

        #expect(store.document.todos.isEmpty)
        #expect(persistence.savedDocument?.todos.isEmpty == true)
    }

    @Test("sorted todos returns open items first")
    func sortedTodosReturnsOpenItemsFirst() {
        let first = ProjectTodoItem(title: "Open task", isDone: false, updatedAt: Date(timeIntervalSince1970: 10))
        let second = ProjectTodoItem(title: "Done task", isDone: true, updatedAt: Date(timeIntervalSince1970: 20))
        let persistence = InMemoryProjectInspectorPersistence(document: ProjectInspectorDocument(todos: [second, first]))
        let store = ProjectInspectorStore { _ in persistence }

        store.selectProject(UUID())

        #expect(store.sortedTodos.map(\.title) == ["Open task", "Done task"])
    }
}

private final class InMemoryProjectInspectorPersistence: ProjectInspectorPersisting {
    var document: ProjectInspectorDocument
    var savedDocument: ProjectInspectorDocument?

    init(document: ProjectInspectorDocument = ProjectInspectorDocument()) {
        self.document = document
    }

    func loadDocument() throws -> ProjectInspectorDocument {
        document
    }

    func saveDocument(_ document: ProjectInspectorDocument) throws {
        self.document = document
        savedDocument = document
    }
}

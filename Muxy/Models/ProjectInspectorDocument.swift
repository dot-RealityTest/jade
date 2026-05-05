import Foundation

struct ProjectTodoItem: Codable, Equatable, Identifiable {
    let id: UUID
    var title: String
    var isDone: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ProjectInspectorDocument: Codable, Equatable {
    var notes: String
    var todos: [ProjectTodoItem]

    init(notes: String = "", todos: [ProjectTodoItem] = []) {
        self.notes = notes
        self.todos = todos
    }
}

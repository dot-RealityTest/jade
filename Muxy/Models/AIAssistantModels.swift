import Foundation

struct AIAssistantMessage: Identifiable, Equatable, Codable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }

    let id: UUID
    let role: Role
    var content: String
    let timestamp: Date

    var isError: Bool {
        content.hasPrefix("**Error:**")
    }

    init(role: Role, content: String, timestamp: Date = Date()) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

import Foundation

struct InspectorChatContext {
    var prompt: String
    var projectID: UUID
    var projectPath: String?
    var activeFile: String?
    var worktreeID: UUID?
    var worktreePath: String?
}

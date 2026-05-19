import Foundation

@MainActor
@Observable
final class AIAssistantStore {
    static let shared = AIAssistantStore()

    private var conversations: [UUID: [AIAssistantMessage]] = [:]
    private var streamingTasks: [UUID: Task<Void, Never>] = [:]

    var isStreaming: [UUID: Bool] = [:]

    func messages(for projectID: UUID) -> [AIAssistantMessage] {
        conversations[projectID] ?? []
    }

    func appendMessage(_ message: AIAssistantMessage, projectID: UUID) {
        conversations[projectID, default: []].append(message)
    }

    func updateLastAssistantMessage(content: String, projectID: UUID) {
        guard var msgs = conversations[projectID],
              let lastIndex = msgs.lastIndex(where: { $0.role == .assistant })
        else { return }
        msgs[lastIndex].content = content
        conversations[projectID] = msgs
    }

    func clear(projectID: UUID) {
        conversations[projectID] = []
        cancel(projectID: projectID)
    }

    func cancel(projectID: UUID) {
        streamingTasks[projectID]?.cancel()
        streamingTasks[projectID] = nil
        isStreaming[projectID] = false
    }

    func setStreaming(_ streaming: Bool, projectID: UUID) {
        isStreaming[projectID] = streaming
    }

    func setTask(_ task: Task<Void, Never>, projectID: UUID) {
        streamingTasks[projectID] = task
    }
}

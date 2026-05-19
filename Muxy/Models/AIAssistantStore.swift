import Foundation
import os

private let aiAssistantLogger = Logger(subsystem: "app.muxy", category: "AIAssistantStore")

@MainActor
@Observable
final class AIAssistantStore {
    static let shared = AIAssistantStore()

    private var conversations: [UUID: [AIAssistantMessage]] = [:]
    private var streamingTasks: [UUID: Task<Void, Never>] = [:]
    private let persistence: CodableFileStore<[String: [AIAssistantMessage]]>

    var isStreaming: [UUID: Bool] = [:]
    var lastFailedPrompt: [UUID: String] = [:]

    init() {
        let fileURL = MuxyFileStorage.appSupportDirectory()
            .appendingPathComponent("ai-conversations.json")
        persistence = CodableFileStore(
            fileURL: fileURL,
            options: CodableFileStoreOptions(
                prettyPrinted: false,
                sortedKeys: true,
                filePermissions: FilePermissions.privateFile
            )
        )
        load()
    }

    func messages(for projectID: UUID) -> [AIAssistantMessage] {
        conversations[projectID] ?? []
    }

    func appendMessage(_ message: AIAssistantMessage, projectID: UUID) {
        conversations[projectID, default: []].append(message)
        save()
    }

    func updateLastAssistantMessage(content: String, projectID: UUID) {
        guard var msgs = conversations[projectID],
              let lastIndex = msgs.lastIndex(where: { $0.role == .assistant })
        else { return }
        msgs[lastIndex].content = content
        conversations[projectID] = msgs
        save()
    }

    func clear(projectID: UUID) {
        conversations[projectID] = []
        lastFailedPrompt[projectID] = nil
        cancel(projectID: projectID)
        save()
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

    func setLastFailedPrompt(_ prompt: String?, projectID: UUID) {
        lastFailedPrompt[projectID] = prompt
    }

    private func load() {
        do {
            let stored = try persistence.load() ?? [:]
            var loaded: [UUID: [AIAssistantMessage]] = [:]
            for (key, messages) in stored {
                if let uuid = UUID(uuidString: key) {
                    loaded[uuid] = messages
                }
            }
            conversations = loaded
        } catch {
            aiAssistantLogger.error("Failed to load AI conversations: \(error.localizedDescription)")
            conversations = [:]
        }
    }

    private func save() {
        do {
            var stored: [String: [AIAssistantMessage]] = [:]
            for (key, messages) in conversations {
                stored[key.uuidString] = messages
            }
            try persistence.save(stored)
        } catch {
            aiAssistantLogger.error("Failed to save AI conversations: \(error.localizedDescription)")
        }
    }
}

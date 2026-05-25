import AppKit
import Foundation
import os
import UserNotifications

private let logger = Logger(subsystem: "app.muxy", category: "AIAssistantChatService")

@MainActor
final class AIAssistantChatService {
    static let shared = AIAssistantChatService()

    private let store = AIAssistantStore.shared
    private let baseURLProvider: @Sendable () async -> URL?
    private let modelProvider: @Sendable () async -> String
    private let dataLoader: @Sendable (URLRequest) async throws -> Data

    init(
        baseURLProvider: @escaping @Sendable () async -> URL? = {
            await MainActor.run {
                URL(string: NaturalCommandSettings.shared.ollamaBaseURL.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        },
        modelProvider: @escaping @Sendable () async -> String = {
            await MainActor.run {
                NaturalCommandSettings.shared.ollamaModel.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        },
        dataLoader: @escaping @Sendable (URLRequest) async throws -> Data = { request in
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  200 ..< 300 ~= http.statusCode
            else {
                throw AIAssistantError.backendFailed
            }
            return data
        }
    ) {
        self.baseURLProvider = baseURLProvider
        self.modelProvider = modelProvider
        self.dataLoader = dataLoader
    }

    func isAvailable() async -> Bool {
        let settings = MoltisAssistantSettings.shared
        if settings.usesDirectOllamaOnly {
            return await isOllamaAvailable()
        }
        if settings.usesMoltisFirst {
            if MoltisChatBackend.isAvailable() {
                return true
            }
            if settings.fallbackToOllama {
                return await isOllamaAvailable()
            }
            return false
        }
        return await isOllamaAvailable()
    }

    func send(context: InspectorChatContext) {
        store.cancel(projectID: context.projectID)
        store.setStreaming(true, projectID: context.projectID)

        let userMessage = AIAssistantMessage(role: .user, content: context.prompt)
        store.appendMessage(userMessage, projectID: context.projectID)

        let assistantPlaceholder = AIAssistantMessage(role: .assistant, content: "")
        store.appendMessage(assistantPlaceholder, projectID: context.projectID)

        let task = Task {
            do {
                try await streamResponse(context: context)
                store.setLastFailedPrompt(nil, projectID: context.projectID)
            } catch {
                logger.error("AI assistant stream failed: \(error.localizedDescription)")
                store.setLastFailedPrompt(context.prompt, projectID: context.projectID)
                store.updateLastAssistantMessage(
                    content: "**Error:** \(error.localizedDescription)",
                    projectID: context.projectID
                )
            }
            store.setStreaming(false, projectID: context.projectID)
            if !NSApplication.shared.isActive {
                postResponseNotification(projectID: context.projectID)
            }
        }

        store.setTask(task, projectID: context.projectID)
    }

    func cancel(projectID: UUID) {
        store.cancel(projectID: projectID)
        Task { await MoltisChatBackend.cancelActiveRun() }
    }

    private func streamResponse(context: InspectorChatContext) async throws {
        let settings = MoltisAssistantSettings.shared
        if settings.usesMoltisFirst {
            do {
                try await streamViaMoltis(context: context)
                return
            } catch {
                guard settings.fallbackToOllama else { throw error }
                logger.error("Moltis (Ollama) failed, falling back to direct Ollama: \(error.localizedDescription)")
            }
        }
        try await streamViaOllama(context: context)
    }

    private func streamViaMoltis(context: InspectorChatContext) async throws {
        try await MoltisChatBackend.stream(context: context) { [self] content in
            store.updateLastAssistantMessage(content: content, projectID: context.projectID)
        }
    }

    private func streamViaOllama(context: InspectorChatContext) async throws {
        guard let baseURL = await baseURLProvider() else { throw AIAssistantError.unavailable }
        let model = await modelProvider()
        guard !model.isEmpty else { throw AIAssistantError.unavailable }

        let history = store.messages(for: context.projectID)
            .filter { $0.role != .system }
            .map { OllamaChatMessage(role: $0.role.rawValue, content: $0.content) }

        let systemPrompt = Self.buildSystemPrompt(
            projectPath: context.projectPath,
            activeFile: context.activeFile
        )
        var messages = [OllamaChatMessage(role: "system", content: systemPrompt)]
        messages.append(contentsOf: history)

        var request = URLRequest(url: baseURL.appending(path: "api/chat"))
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AIAssistantOllamaChatRequest(
            model: model,
            messages: messages,
            stream: true
        ))

        let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse,
              200 ..< 300 ~= http.statusCode
        else {
            throw AIAssistantError.backendFailed
        }

        var accumulated = ""
        for try await line in asyncBytes.lines {
            guard let data = line.data(using: .utf8),
                  let chunk = try? JSONDecoder().decode(OllamaChatStreamChunk.self, from: data),
                  let text = chunk.message?.content ?? chunk.response
            else { continue }
            accumulated += text
            store.updateLastAssistantMessage(content: accumulated, projectID: context.projectID)
            if chunk.done == true { break }
        }
    }

    private func isOllamaAvailable() async -> Bool {
        guard let baseURL = await baseURLProvider() else { return false }
        var request = URLRequest(url: baseURL.appending(path: "api/tags"))
        request.timeoutInterval = 1.5
        do {
            _ = try await dataLoader(request)
            return true
        } catch {
            return false
        }
    }

    private func postResponseNotification(projectID: UUID) {
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        let content = UNMutableNotificationContent()
        content.title = "Jade AI Assistant"
        content.body = "Response ready"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "ai-response-\(projectID.uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private static func buildSystemPrompt(projectPath: String?, activeFile: String?) -> String {
        var context = """
        You are Jade, a helpful AI coding assistant embedded in a macOS terminal multiplexer app.
        The user is asking you about code in their active project.
        You DO have access to the following workspace context — use it to ground every response:

        """
        if let projectPath {
            context += "- Active project root: \(projectPath)\n"
        } else {
            context += "- No active project is currently open.\n"
        }
        if let activeFile {
            let fileName = URL(fileURLWithPath: activeFile).lastPathComponent
            context += "- Currently open file: \(activeFile) (filename: \(fileName))\n"
        } else {
            context += "- No file is currently open in the editor.\n"
        }
        context += """

        Rules:
        1. Always reference the active file and project path when relevant.
        2. If the user asks "where am I" or "what project is this", tell them the project root and open file from the context above.
        3. Keep responses concise and actionable.
        4. Use markdown code blocks for any code.
        5. You cannot read files from disk directly, but you CAN see any code the user pastes into the chat.
        """
        return context
    }
}

enum AIAssistantError: Error {
    case unavailable
    case backendFailed
}

private struct AIAssistantOllamaChatRequest: Codable {
    var model: String
    var messages: [OllamaChatMessage]
    var stream: Bool
}

private struct OllamaChatStreamChunk: Codable {
    struct Message: Codable {
        var role: String?
        var content: String
    }

    var message: Message?
    var response: String?
    var done: Bool?
}

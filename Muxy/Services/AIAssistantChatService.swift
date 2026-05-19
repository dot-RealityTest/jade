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

    func send(
        prompt: String,
        projectID: UUID,
        projectPath: String?,
        activeFile: String?
    ) {
        store.cancel(projectID: projectID)
        store.setStreaming(true, projectID: projectID)

        let userMessage = AIAssistantMessage(role: .user, content: prompt)
        store.appendMessage(userMessage, projectID: projectID)

        let assistantPlaceholder = AIAssistantMessage(role: .assistant, content: "")
        store.appendMessage(assistantPlaceholder, projectID: projectID)

        let task = Task {
            do {
                try await streamResponse(
                    prompt: prompt,
                    projectID: projectID,
                    projectPath: projectPath,
                    activeFile: activeFile
                )
                store.setLastFailedPrompt(nil, projectID: projectID)
            } catch {
                logger.error("AI assistant stream failed: \(error.localizedDescription)")
                store.setLastFailedPrompt(prompt, projectID: projectID)
                store.updateLastAssistantMessage(
                    content: "**Error:** \(error.localizedDescription)",
                    projectID: projectID
                )
            }
            store.setStreaming(false, projectID: projectID)
            if !NSApplication.shared.isActive {
                postResponseNotification(projectID: projectID)
            }
        }

        store.setTask(task, projectID: projectID)
    }

    private func streamResponse(
        prompt: String,
        projectID: UUID,
        projectPath: String?,
        activeFile: String?
    ) async throws {
        guard let baseURL = await baseURLProvider() else { throw AIAssistantError.unavailable }
        let model = await modelProvider()
        guard !model.isEmpty else { throw AIAssistantError.unavailable }

        let history = store.messages(for: projectID)
            .filter { $0.role != .system }
            .map { OllamaChatMessage(role: $0.role.rawValue, content: $0.content) }

        let systemPrompt = Self.buildSystemPrompt(projectPath: projectPath, activeFile: activeFile)
        var messages = [OllamaChatMessage(role: "system", content: systemPrompt)]
        messages.append(contentsOf: history)

        var request = URLRequest(url: baseURL.appending(path: "api/chat"))
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(OllamaChatRequest(
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
            store.updateLastAssistantMessage(content: accumulated, projectID: projectID)
            if chunk.done == true { break }
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

private struct OllamaChatRequest: Codable {
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

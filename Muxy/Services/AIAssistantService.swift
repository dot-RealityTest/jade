import Foundation
import os

private let logger = Logger(subsystem: "app.muxy", category: "AIAssistantService")

@MainActor
final class AIAssistantService {
    static let shared = AIAssistantService()

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
                  200..<300 ~= http.statusCode
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
            } catch {
                logger.error("AI assistant stream failed: \(error.localizedDescription)")
                store.updateLastAssistantMessage(
                    content: "Sorry, something went wrong. \(error.localizedDescription)",
                    projectID: projectID
                )
            }
            store.setStreaming(false, projectID: projectID)
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
              200..<300 ~= http.statusCode
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

    private static func buildSystemPrompt(projectPath: String?, activeFile: String?) -> String {
        var context = "You are Jade, a helpful AI coding assistant embedded in a macOS terminal multiplexer."
        if let projectPath {
            context += "\nActive project path: \(projectPath)"
        }
        if let activeFile {
            context += "\nCurrently open file: \(activeFile)"
        }
        context += "\nKeep responses concise and actionable. Use markdown for code blocks."
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

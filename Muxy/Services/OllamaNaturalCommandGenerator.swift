import Foundation

struct OllamaChatMessage: Codable, Equatable {
    var role: String
    var content: String
}

struct OllamaNaturalCommandRequest: Codable, Equatable {
    var model: String
    var messages: [OllamaChatMessage]
    var stream: Bool
    var format: String
}

struct OllamaNaturalCommandResponse: Codable, Equatable {
    struct Message: Codable, Equatable {
        var role: String?
        var content: String
    }

    var message: Message?
    var response: String?

    var content: String? {
        message?.content ?? response
    }
}

struct OllamaNaturalCommandGenerator: NaturalCommandGenerator {
    let backend: NaturalCommandBackend = .ollama
    private let baseURLProvider: @Sendable () async -> URL?
    private let modelProvider: @Sendable () async -> String
    private let dataLoader: @Sendable (URLRequest) async throws -> Data

    init(
        baseURLProvider: @escaping @Sendable () async -> URL?,
        modelProvider: @escaping @Sendable () async -> String,
        dataLoader: @escaping @Sendable (URLRequest) async throws -> Data
    ) {
        self.baseURLProvider = baseURLProvider
        self.modelProvider = modelProvider
        self.dataLoader = dataLoader
    }

    static func live() -> Self {
        OllamaNaturalCommandGenerator(
            baseURLProvider: {
                await MainActor.run {
                    URL(string: NaturalCommandSettings.shared.ollamaBaseURL.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            },
            modelProvider: {
                await MainActor.run {
                    NaturalCommandSettings.shared.ollamaModel.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            },
            dataLoader: { request in
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      200 ..< 300 ~= http.statusCode
                else {
                    throw NaturalCommandFailure.backendFailed("Ollama did not return a successful response")
                }
                return data
            }
        )
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

    func generate(request: NaturalCommandRequest) async throws -> NaturalCommandPlan {
        guard let baseURL = await baseURLProvider() else { throw NaturalCommandFailure.unavailable }
        let model = await modelProvider()
        guard !model.isEmpty else { throw NaturalCommandFailure.unavailable }

        var urlRequest = URLRequest(url: baseURL.appending(path: "api/chat"))
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = 60
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(OllamaNaturalCommandRequest(
            model: model,
            messages: NaturalCommandPromptBuilder.messages(for: request),
            stream: false,
            format: "json"
        ))

        let data = try await dataLoader(urlRequest)
        let response = try JSONDecoder().decode(OllamaNaturalCommandResponse.self, from: data)
        guard let content = response.content else { throw NaturalCommandFailure.invalidResponse }
        return try NaturalCommandPlanParser.parse(content, request: request, backend: .ollama)
    }
}

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct AppleFoundationNaturalCommandGenerator: NaturalCommandGenerator {
    let backend: NaturalCommandBackend = .appleFoundationModels

    func isAvailable() async -> Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif
        return false
    }

    func generate(request: NaturalCommandRequest) async throws -> NaturalCommandPlan {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let session = LanguageModelSession {
                NaturalCommandPromptBuilder.messages(for: request).first?.content ?? ""
            }
            session.prewarm()
            let response = try await session.respond(to: NaturalCommandPromptBuilder.userPrompt(for: request))
            return try NaturalCommandPlanParser.parse(
                String(describing: response.content),
                request: request,
                backend: .appleFoundationModels
            )
        }
        #endif
        throw NaturalCommandFailure.unavailable
    }
}

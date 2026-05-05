import Foundation
import Testing

@testable import Muxy

@Suite("NaturalCommandGenerator")
struct NaturalCommandGeneratorTests {
    @Test("automatic mode falls back from Apple to Ollama")
    func automaticFallsBackToOllama() async throws {
        let ollamaPlan = NaturalCommandPlan(
            title: "List Files",
            summary: "List files",
            targetKind: .local,
            riskLevel: .low,
            backend: .ollama,
            steps: [NaturalCommandStep(title: "List Files", command: "ls -la", explanation: "Lists files")]
        )
        let coordinator = NaturalCommandCoordinator(
            settings: FakeNaturalCommandSettings(enabled: true, mode: .automatic),
            appleGenerator: FakeNaturalCommandGenerator(backend: .appleFoundationModels, available: false, outcome: .failure("unavailable")),
            ollamaGenerator: FakeNaturalCommandGenerator(backend: .ollama, available: true, outcome: .success(ollamaPlan))
        )

        let plan = try await coordinator.generate(request: request("list files"))

        #expect(plan.backend == .ollama)
        #expect(plan.primaryCommand == "ls -la")
    }

    @Test("destructive intent returns inspect first plan before backends")
    func destructiveIntentReturnsInspectFirstPlan() async throws {
        let coordinator = NaturalCommandCoordinator(
            settings: FakeNaturalCommandSettings(enabled: true, mode: .automatic),
            appleGenerator: FakeNaturalCommandGenerator(backend: .appleFoundationModels, available: true, outcome: .failure("should not run")),
            ollamaGenerator: FakeNaturalCommandGenerator(backend: .ollama, available: true, outcome: .failure("should not run"))
        )

        let plan = try await coordinator.generate(request: request("find large files and delete them"))

        #expect(plan.backend == .localRules)
        #expect(plan.riskLevel == .inspect)
        #expect(plan.primaryCommand.contains("-print"))
    }

    @Test("Ollama sends chat request and decodes response")
    func ollamaSendsChatRequestAndDecodesResponse() async throws {
        let box = RequestBox()
        let generator = OllamaNaturalCommandGenerator(
            baseURLProvider: { URL(string: "http://localhost:11434") },
            modelProvider: { "llama3.2" },
            dataLoader: { request in
                box.request = request
                return Data(#"{"message":{"role":"assistant","content":"{\"title\":\"Disk\",\"summary\":\"Show disk\",\"command\":\"df -h\",\"explanation\":\"Shows disk usage\",\"risk\":\"inspect\"}"}}"#.utf8)
            }
        )

        let plan = try await generator.generate(request: request("check disk"))

        #expect(box.request?.url?.absoluteString == "http://localhost:11434/api/chat")
        #expect(box.request?.httpMethod == "POST")
        #expect(plan.primaryCommand == "df -h")
        #expect(plan.backend == .ollama)
    }

    @Test("disabled settings fail generation")
    func disabledSettingsFailGeneration() async {
        let coordinator = NaturalCommandCoordinator(
            settings: FakeNaturalCommandSettings(enabled: false, mode: .automatic),
            appleGenerator: FakeNaturalCommandGenerator(backend: .appleFoundationModels, available: true, outcome: .failure("unused")),
            ollamaGenerator: FakeNaturalCommandGenerator(backend: .ollama, available: true, outcome: .failure("unused"))
        )

        do {
            _ = try await coordinator.generate(request: request("list files"))
            Issue.record("Expected disabled generation to throw")
        } catch let error as NaturalCommandFailure {
            #expect(error == .disabled)
        } catch {
            Issue.record("Unexpected error \(error)")
        }
    }

    private func request(_ prompt: String) -> NaturalCommandRequest {
        NaturalCommandRequest(prompt: prompt, context: .local(projectPath: "/tmp/project"))
    }
}

private struct FakeNaturalCommandSettings: NaturalCommandSettingsProvider {
    let enabled: Bool
    let mode: NaturalCommandBackendMode

    func isEnabled() async -> Bool {
        enabled
    }

    func backendMode() async -> NaturalCommandBackendMode {
        mode
    }
}

private enum FakeNaturalCommandOutcome: Sendable {
    case success(NaturalCommandPlan)
    case failure(String)
}

private struct FakeNaturalCommandGenerator: NaturalCommandGenerator {
    let backend: NaturalCommandBackend
    let available: Bool
    let outcome: FakeNaturalCommandOutcome

    func isAvailable() async -> Bool {
        available
    }

    func generate(request _: NaturalCommandRequest) async throws -> NaturalCommandPlan {
        switch outcome {
        case let .success(plan):
            return plan
        case let .failure(message):
            throw NaturalCommandFailure.backendFailed(message)
        }
    }
}

private final class RequestBox: @unchecked Sendable {
    var request: URLRequest?
}

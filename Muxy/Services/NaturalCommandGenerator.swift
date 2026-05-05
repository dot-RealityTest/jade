import Foundation

protocol NaturalCommandGenerator: Sendable {
    var backend: NaturalCommandBackend { get }
    func isAvailable() async -> Bool
    func generate(request: NaturalCommandRequest) async throws -> NaturalCommandPlan
}

enum NaturalCommandPromptBuilder {
    static func messages(for request: NaturalCommandRequest) -> [OllamaChatMessage] {
        [
            OllamaChatMessage(role: "system", content: instructions),
            OllamaChatMessage(role: "user", content: userPrompt(for: request)),
        ]
    }

    static func userPrompt(for request: NaturalCommandRequest) -> String {
        let target = request.context.targetKind == .remote ? "remote Linux shell" : "local macOS shell"
        let directory = request.context.workingDirectory ?? "unknown"
        let remote = request.context.remoteSummary ?? "none"
        return """
        User request: \(request.prompt)
        Target: \(target)
        Active name: \(request.context.displayName)
        Working directory: \(directory)
        Remote: \(remote)
        """
    }

    private static let instructions = """
    Convert the user's request into one safe shell command for the stated target.
    Return only JSON with keys: title, summary, command, explanation, risk.
    risk must be inspect, low, medium, or blocked.
    Prefer read-only inspect commands.
    Do not generate rm, find -delete, mkfs, diskutil erase, reboot, shutdown, poweroff,
    docker rm, docker rmi, docker system prune, or kill -9.
    If the user asks to delete, remove, erase, wipe, reboot, power off, kill, or destroy, generate an inspect-only command instead.
    """
}

enum NaturalCommandPlanParser {
    static func parse(_ content: String, request: NaturalCommandRequest, backend: NaturalCommandBackend) throws -> NaturalCommandPlan {
        let json = try extractJSONObject(from: content)
        let decoded = try JSONDecoder().decode(NaturalCommandDecodedPlan.self, from: Data(json.utf8))
        let command = decoded.command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { throw NaturalCommandFailure.invalidResponse }

        let classifiedRisk = ShellCommandSafetyClassifier.risk(for: command)
        let risk = classifiedRisk == .blocked ? .blocked : decoded.risk ?? classifiedRisk
        let blockedReason = ShellCommandSafetyClassifier.blockedReason(for: command)

        return NaturalCommandPlan(
            title: decoded.planTitle,
            summary: decoded.summary.trimmingCharacters(in: .whitespacesAndNewlines),
            targetKind: request.context.targetKind,
            riskLevel: blockedReason == nil ? risk : .blocked,
            backend: backend,
            steps: [
                NaturalCommandStep(
                    title: decoded.planTitle,
                    command: command,
                    explanation: decoded.explanation.trimmingCharacters(in: .whitespacesAndNewlines)
                ),
            ],
            blockedReason: blockedReason
        )
    }

    static func extractJSONObject(from content: String) throws -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("{"), trimmed.hasSuffix("}") {
            return trimmed
        }
        guard let start = trimmed.firstIndex(of: "{"),
              let end = trimmed.lastIndex(of: "}"),
              start < end
        else {
            throw NaturalCommandFailure.invalidResponse
        }
        return String(trimmed[start ... end])
    }
}

struct NaturalCommandCoordinator: NaturalCommandGenerator {
    let backend: NaturalCommandBackend = .ollama
    private let settings: NaturalCommandSettingsProvider
    private let appleGenerator: any NaturalCommandGenerator
    private let ollamaGenerator: any NaturalCommandGenerator

    init(
        settings: NaturalCommandSettingsProvider,
        appleGenerator: any NaturalCommandGenerator,
        ollamaGenerator: any NaturalCommandGenerator
    ) {
        self.settings = settings
        self.appleGenerator = appleGenerator
        self.ollamaGenerator = ollamaGenerator
    }

    static func live() -> Self {
        NaturalCommandCoordinator(
            settings: LiveNaturalCommandSettingsProvider(),
            appleGenerator: AppleFoundationNaturalCommandGenerator(),
            ollamaGenerator: OllamaNaturalCommandGenerator.live()
        )
    }

    func isAvailable() async -> Bool {
        guard await settings.isEnabled() else { return false }
        switch await settings.backendMode() {
        case .apple:
            return await appleGenerator.isAvailable()
        case .ollama:
            return await ollamaGenerator.isAvailable()
        case .automatic:
            if await appleGenerator.isAvailable() {
                return true
            }
            return await ollamaGenerator.isAvailable()
        }
    }

    func generate(request: NaturalCommandRequest) async throws -> NaturalCommandPlan {
        guard await settings.isEnabled() else { throw NaturalCommandFailure.disabled }
        let prompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { throw NaturalCommandFailure.emptyPrompt }

        var request = request
        request.prompt = prompt

        if let inspectPlan = ShellCommandSafetyClassifier.inspectFirstPlan(for: request) {
            return inspectPlan
        }

        switch await settings.backendMode() {
        case .apple:
            return try await appleGenerator.generate(request: request)
        case .ollama:
            return try await ollamaGenerator.generate(request: request)
        case .automatic:
            if await appleGenerator.isAvailable(),
               let plan = try? await appleGenerator.generate(request: request)
            {
                return plan
            }
            return try await ollamaGenerator.generate(request: request)
        }
    }
}

protocol NaturalCommandSettingsProvider: Sendable {
    func isEnabled() async -> Bool
    func backendMode() async -> NaturalCommandBackendMode
}

struct LiveNaturalCommandSettingsProvider: NaturalCommandSettingsProvider {
    func isEnabled() async -> Bool {
        await MainActor.run { NaturalCommandSettings.shared.isEnabled }
    }

    func backendMode() async -> NaturalCommandBackendMode {
        await MainActor.run { NaturalCommandSettings.shared.resolvedBackendMode }
    }
}

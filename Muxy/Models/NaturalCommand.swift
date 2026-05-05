import Foundation

enum NaturalCommandTargetKind: String, Codable, Equatable {
    case local
    case remote
}

struct NaturalCommandContext: Equatable {
    var targetKind: NaturalCommandTargetKind
    var displayName: String
    var workingDirectory: String?
    var remoteSummary: String?

    static func local(projectPath: String?) -> Self {
        NaturalCommandContext(
            targetKind: .local,
            displayName: "Local",
            workingDirectory: projectPath,
            remoteSummary: nil
        )
    }

    static func remote(_ space: RemoteSpace) -> Self {
        NaturalCommandContext(
            targetKind: .remote,
            displayName: space.displayName,
            workingDirectory: nil,
            remoteSummary: space.connectionSummary
        )
    }
}

struct NaturalCommandRequest: Equatable {
    var prompt: String
    var context: NaturalCommandContext
}

enum NaturalCommandRiskLevel: String, Codable, CaseIterable, Identifiable {
    case inspect
    case low
    case medium
    case blocked

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .inspect: "Inspect"
        case .low: "Low Risk"
        case .medium: "Review"
        case .blocked: "Blocked"
        }
    }
}

enum NaturalCommandBackend: String, Codable, Equatable {
    case appleFoundationModels
    case ollama
    case localRules

    var displayName: String {
        switch self {
        case .appleFoundationModels: "Apple Intelligence"
        case .ollama: "Ollama"
        case .localRules: "Safety Rules"
        }
    }
}

struct NaturalCommandStep: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var command: String
    var explanation: String

    init(
        id: UUID = UUID(),
        title: String,
        command: String,
        explanation: String
    ) {
        self.id = id
        self.title = title
        self.command = command
        self.explanation = explanation
    }

    var trimmedCommand: String {
        command.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct NaturalCommandPlan: Codable, Equatable, Identifiable {
    var id: UUID
    var title: String
    var summary: String
    var targetKind: NaturalCommandTargetKind
    var riskLevel: NaturalCommandRiskLevel
    var backend: NaturalCommandBackend
    var steps: [NaturalCommandStep]
    var blockedReason: String?

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        targetKind: NaturalCommandTargetKind,
        riskLevel: NaturalCommandRiskLevel,
        backend: NaturalCommandBackend,
        steps: [NaturalCommandStep],
        blockedReason: String? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.targetKind = targetKind
        self.riskLevel = riskLevel
        self.backend = backend
        self.steps = steps
        self.blockedReason = blockedReason
    }

    var primaryCommand: String {
        steps.first?.trimmedCommand ?? ""
    }

    var isRunnable: Bool {
        riskLevel != .blocked && !primaryCommand.isEmpty
    }
}

enum NaturalCommandFailure: Error, Equatable, LocalizedError {
    case disabled
    case emptyPrompt
    case unavailable
    case invalidResponse
    case blocked(String)
    case backendFailed(String)

    var errorDescription: String? {
        switch self {
        case .disabled: "Natural commands are disabled"
        case .emptyPrompt: "Type what you want to do"
        case .unavailable: "No local AI backend is available"
        case .invalidResponse: "The model returned an invalid command plan"
        case let .blocked(reason): reason
        case let .backendFailed(message): message
        }
    }
}

struct NaturalCommandDecodedPlan: Codable, Equatable {
    var title: String
    var summary: String
    var command: String
    var explanation: String
    var risk: NaturalCommandRiskLevel?

    var planTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Generated Command" : title
    }
}

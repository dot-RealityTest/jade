import Foundation

enum JadeJourneyLayout {
    static let folderName = ".jade"

    static func root(in projectPath: String) -> String {
        URL(fileURLWithPath: projectPath, isDirectory: true)
            .appendingPathComponent(folderName, isDirectory: true)
            .path
    }

    static func journeyFile(in projectPath: String) -> String {
        URL(fileURLWithPath: root(in: projectPath), isDirectory: true)
            .appendingPathComponent("journey.md")
            .path
    }

    static func rulesFile(in projectPath: String) -> String {
        URL(fileURLWithPath: root(in: projectPath), isDirectory: true)
            .appendingPathComponent("rules.md")
            .path
    }

    static func decisionsFolder(in projectPath: String) -> String {
        URL(fileURLWithPath: root(in: projectPath), isDirectory: true)
            .appendingPathComponent("decisions", isDirectory: true)
            .path
    }

    static func achievementsFolder(in projectPath: String) -> String {
        URL(fileURLWithPath: root(in: projectPath), isDirectory: true)
            .appendingPathComponent("achievements", isDirectory: true)
            .path
    }

    static func blockersFolder(in projectPath: String) -> String {
        URL(fileURLWithPath: root(in: projectPath), isDirectory: true)
            .appendingPathComponent("blockers", isDirectory: true)
            .path
    }

    static func logFolder(in projectPath: String) -> String {
        URL(fileURLWithPath: root(in: projectPath), isDirectory: true)
            .appendingPathComponent("log", isDirectory: true)
            .path
    }
}

enum JourneyStepRisk: String, Equatable {
    case low
    case medium
    case blocked

    var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Review"
        case .blocked: "Blocked"
        }
    }
}

struct JourneyStepProposal: Equatable, Identifiable {
    let id: UUID
    let title: String
    let summary: String
    let why: String
    let sourceFile: String?
    let risk: JourneyStepRisk
    let blockedReason: String?
    let matchedRule: String?

    init(
        id: UUID = UUID(),
        title: String,
        summary: String,
        why: String,
        sourceFile: String? = nil,
        risk: JourneyStepRisk = .low,
        blockedReason: String? = nil,
        matchedRule: String? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.why = why
        self.sourceFile = sourceFile
        self.risk = risk
        self.blockedReason = blockedReason
        self.matchedRule = matchedRule
    }

    var isConfirmable: Bool {
        risk != .blocked || blockedReason != nil
    }

    var requiresOverrideToConfirm: Bool {
        risk == .blocked
    }
}

enum JourneySessionOutcome: String, Equatable {
    case started
    case completed
    case skipped
    case declined
    case blocked
    case overridden
}

enum JadeJourneyError: Error, LocalizedError {
    case noProject
    case alreadyInitialized
    case notInitialized
    case noNextStep
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .noProject: "Open a project first."
        case .alreadyInitialized: "This project already has a project log (.jade/)."
        case .notInitialized: "Add todo.md or goals.md, or run Set Up Project Log for .jade/journey.md."
        case .noNextStep: "Add an open `- [ ]` item to todo.md, a goal in goals.md, or a ## Next step in .jade/journey.md."
        case let .writeFailed(message): message
        }
    }
}

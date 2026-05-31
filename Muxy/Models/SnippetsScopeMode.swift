import Foundation

enum SnippetsScopeMode: String, CaseIterable, Codable {
    case general
    case project

    var displayName: String {
        switch self {
        case .general: "General"
        case .project: "Project"
        }
    }

    mutating func toggle() {
        self = self == .general ? .project : .general
    }
}

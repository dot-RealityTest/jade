import Foundation

struct RichInputPreviewLine: Identifiable, Equatable {
    enum Kind: Equatable {
        case blank
        case note
        case task(isDone: Bool)
    }

    let lineIndex: Int
    let rawLine: String
    let displayText: String
    let kind: Kind

    var id: Int { lineIndex }

    var isTask: Bool {
        if case .task = kind { return true }
        return false
    }

    var isDone: Bool {
        if case let .task(isDone) = kind { return isDone }
        return false
    }

    var copyText: String {
        switch kind {
        case .blank:
            ""
        case .note:
            rawLine
        case .task:
            displayText
        }
    }
}

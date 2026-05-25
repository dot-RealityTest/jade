import Foundation

enum RichInputPreferences {
    static let fontSizeKey = "muxy.richInput.fontSize"
    static let defaultFontSize: Double = 13
    static let minFontSize: Double = 9
    static let maxFontSize: Double = 32
    static let fontStep: Double = 1

    static let floatingKey = "muxy.richInput.floating"
    static let defaultFloating = true

    static let positionKey = "muxy.richInput.position"
    static let defaultPosition: RichInputPanelPosition = .right

    static let broadcastKey = "muxy.richInput.broadcast"
    static let defaultBroadcast = false
}

enum RichInputPanelPosition: String, CaseIterable, Identifiable {
    case right
    case bottom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .right: "Right"
        case .bottom: "Bottom"
        }
    }
}

enum RichInputPanelMode: String, CaseIterable, Identifiable {
    case send
    case notes

    var id: String { rawValue }

    var title: String {
        switch self {
        case .send: "Send"
        case .notes: "Notes"
        }
    }

    var symbolName: String {
        switch self {
        case .send: "keyboard"
        case .notes: "note.text"
        }
    }
}

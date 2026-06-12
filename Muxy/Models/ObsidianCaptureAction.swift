import Foundation

enum ObsidianCaptureAction: String, CaseIterable, Identifiable {
    case sendCapture
    case openSettings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sendCapture: "Send to Obsidian"
        case .openSettings: "Open Log Settings"
        }
    }

    var subtitle: String {
        switch self {
        case .sendCapture: "Capture selection, rich input, or clipboard into your logs folder"
        case .openSettings: "Choose where session logs and captures are saved"
        }
    }

    var symbolName: String {
        switch self {
        case .sendCapture: "note.text.badge.plus"
        case .openSettings: "folder.badge.gearshape"
        }
    }

    var searchText: String {
        switch self {
        case .sendCapture: "obsidian capture note inbox send clipboard selection log"
        case .openSettings: "obsidian logs settings configure vault folder capture"
        }
    }

    func isAvailable(for settings: ObsidianCaptureSettings) -> Bool {
        switch self {
        case .openSettings:
            true
        case .sendCapture:
            settings.canSendCaptures
        }
    }
}

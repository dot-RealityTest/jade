import AppKit
import Foundation

enum TerminalCopyFeedback {
    static let copiedMessage = "Copied to clipboard"

    @MainActor
    static func copyToPasteboard(_ text: String, showIndicator: Bool = true) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        if showIndicator {
            showCopiedIndicator()
        }
        return true
    }

    @MainActor
    static func showCopiedIndicator() {
        ToastState.shared.show(copiedMessage)
    }
}

enum GeneralSettingsMigration {
    @MainActor
    static func applyIfNeeded(using defaults: UserDefaults = .standard) {
        migrateAutoCopyTerminalSelectionDefault(using: defaults)
    }

    private static func migrateAutoCopyTerminalSelectionDefault(using defaults: UserDefaults) {
        let key = GeneralSettingsKeys.autoCopyTerminalSelection
        guard defaults.object(forKey: key) == nil else { return }
        defaults.set(true, forKey: key)
    }
}

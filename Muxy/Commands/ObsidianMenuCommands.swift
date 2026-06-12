import SwiftUI

struct ObsidianMenuCommands: Commands {
    let keyBindings: KeyBindingStore

    private var settings: ObsidianCaptureSettings {
        ObsidianCaptureSettingsStore.shared.snapshot
    }

    var body: some Commands {
        CommandMenu("Obsidian") {
            Button(ObsidianCaptureAction.sendCapture.title) {
                NotificationCenter.default.post(name: .sendToObsidian, object: nil)
            }
            .shortcut(for: .sendToObsidian, store: keyBindings)
            .disabled(!ObsidianCaptureAction.sendCapture.isAvailable(for: settings))

            Divider()

            Button("\(ObsidianCaptureAction.openSettings.title)...") {
                NotificationCenter.default.post(name: .openLogSettings, object: nil)
            }
        }
    }
}

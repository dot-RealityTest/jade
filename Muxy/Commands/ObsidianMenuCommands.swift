import SwiftUI

struct ObsidianMenuCommands: Commands {
    let keyBindings: KeyBindingStore

    private var settings: ObsidianMCPSettings {
        ObsidianMCPSettingsStore.shared.snapshot
    }

    var body: some Commands {
        CommandMenu("Obsidian") {
            Button(ObsidianMCPToolAction.sendCapture.title) {
                ObsidianMCPMenuTrigger.run(.sendCapture)
            }
            .shortcut(for: .sendToObsidian, store: keyBindings)
            .disabled(!ObsidianMCPToolAction.sendCapture.isAvailable(for: settings))

            Divider()

            Button(ObsidianMCPToolAction.listInboxNotes.title) {
                ObsidianMCPMenuTrigger.run(.listInboxNotes)
            }
            .disabled(!ObsidianMCPToolAction.listInboxNotes.isAvailable(for: settings))

            Button("\(ObsidianMCPToolAction.searchNotes.title)...") {
                ObsidianMCPMenuTrigger.promptSearch()
            }
            .disabled(!ObsidianMCPToolAction.searchNotes.isAvailable(for: settings))

            Button(ObsidianMCPToolAction.getAllTags.title) {
                ObsidianMCPMenuTrigger.run(.getAllTags)
            }
            .disabled(!ObsidianMCPToolAction.getAllTags.isAvailable(for: settings))

            Button(ObsidianMCPToolAction.getFolderStructure.title) {
                ObsidianMCPMenuTrigger.run(.getFolderStructure)
            }
            .disabled(!ObsidianMCPToolAction.getFolderStructure.isAvailable(for: settings))

            Divider()

            Button(ObsidianMCPToolAction.openSettings.title) {
                ObsidianMCPMenuTrigger.run(.openSettings)
            }
        }
    }
}

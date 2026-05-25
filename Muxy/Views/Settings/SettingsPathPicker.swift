import AppKit

@MainActor
enum SettingsPathPicker {
    static func chooseDirectory(title: String, initialPath: String, completion: @escaping (URL?) -> Void) {
        present(
            title: title,
            initialPath: initialPath,
            canChooseFiles: false,
            completion: completion
        )
    }

    static func chooseFile(title: String, initialPath: String, completion: @escaping (URL?) -> Void) {
        present(
            title: title,
            initialPath: initialPath,
            canChooseFiles: true,
            completion: completion
        )
    }

    static func normalizedPath(from url: URL) -> String {
        url.standardizedFileURL.path(percentEncoded: false)
    }

    private static func present(
        title: String,
        initialPath: String,
        canChooseFiles: Bool,
        completion: @escaping (URL?) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = !canChooseFiles
        panel.canChooseFiles = canChooseFiles
        panel.allowsMultipleSelection = false
        panel.message = title
        panel.prompt = "Choose"
        if !initialPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let url = URL(fileURLWithPath: initialPath, isDirectory: !canChooseFiles)
            if FileManager.default.fileExists(atPath: url.path) {
                panel.directoryURL = url.deletingLastPathComponent()
            }
        }

        guard let window = presentationWindow() else {
            completion(panel.runModal() == .OK ? panel.url : nil)
            return
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        panel.beginSheetModal(for: window) { response in
            completion(response == .OK ? panel.url : nil)
        }
    }

    private static func presentationWindow() -> NSWindow? {
        if let keyWindow = NSApp.keyWindow, isSettingsWindow(keyWindow) {
            return keyWindow
        }
        if let settingsWindow = NSApp.windows.first(where: isSettingsWindow) {
            return settingsWindow
        }
        return NSApp.keyWindow ?? NSApp.mainWindow
    }

    private static func isSettingsWindow(_ window: NSWindow) -> Bool {
        let title = window.title.lowercased()
        return title.contains("settings")
    }
}

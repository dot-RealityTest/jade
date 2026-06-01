import AppKit
import Foundation

@MainActor
enum CLIAccessor {
    static func openProjectFromPath(
        _ path: String,
        appState: AppState,
        projectStore: ProjectStore,
        worktreeStore: WorktreeStore
    ) {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: standardizedPath, isDirectory: &isDirectory),
              isDirectory.boolValue
        else { return }

        if let existing = projectStore.projects.first(where: { $0.path == standardizedPath }),
           let primary = worktreeStore.primary(for: existing.id)
        {
            appState.selectProject(existing, worktree: primary)
            activateApp()
            return
        }

        let url = URL(fileURLWithPath: standardizedPath)
        let project = Project(
            name: url.lastPathComponent,
            path: standardizedPath,
            sortOrder: projectStore.projects.count
        )
        projectStore.add(project)
        worktreeStore.ensurePrimary(for: project)
        guard let primary = worktreeStore.primary(for: project.id) else { return }
        appState.selectProject(project, worktree: primary)
        activateApp()
    }

    private static func activateApp() {
        let app = NSApplication.shared
        guard app.isRunning else { return }
        app.activate(ignoringOtherApps: true)
    }

    static func installCLI() {
        guard let resourceURL = Bundle.appResources.url(
            forResource: "muxy-cli",
            withExtension: ""
        )
        else {
            alert(title: "CLI Not Found", body: "The CLI script was not found in the app bundle.")
            return
        }

        guard confirmInstall() else { return }

        if copyScripts(from: resourceURL, to: "/usr/local/bin") {
            showInstalledAlert(binPath: "/usr/local/bin", pathNote: "")
            return
        }

        Task.detached(priority: .userInitiated) {
            let success = runAdminInstall(resourceURL: resourceURL)
            await MainActor.run {
                if success {
                    showInstalledAlert(binPath: "/usr/local/bin", pathNote: "")
                    return
                }
                if tryFallbackInstalls(resourceURL: resourceURL) { return }
                alert(
                    title: "CLI Installation Failed",
                    body: """
                    Could not install \(AppIdentity.cliName) to /usr/local/bin or any fallback directory.

                    Try manually:
                      sudo cp "\(resourceURL.path)" /usr/local/bin/\(AppIdentity.cliName)
                      sudo chmod +x /usr/local/bin/\(AppIdentity.cliName)
                    """
                )
            }
        }
    }

    private static func copyScripts(from resourceURL: URL, to binPath: String) -> Bool {
        let target = URL(fileURLWithPath: "\(binPath)/\(AppIdentity.cliName)")
        let dir = URL(fileURLWithPath: binPath)
        if !FileManager.default.fileExists(atPath: binPath) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        do {
            if FileManager.default.fileExists(atPath: target.path) {
                try FileManager.default.removeItem(at: target)
            }
            try FileManager.default.copyItem(at: resourceURL, to: target)
            try FileManager.default.setAttributes(
                [.posixPermissions: FilePermissions.executable],
                ofItemAtPath: target.path
            )
            return true
        } catch {
            if FileManager.default.fileExists(atPath: target.path) {
                try? FileManager.default.removeItem(at: target)
            }
            return false
        }
    }

    nonisolated private static func runAdminInstall(resourceURL: URL) -> Bool {
        let quotedSource = ShellEscaper.escape(resourceURL.path)
        let shellCommand = """
        mkdir -p /usr/local/bin && \
        cp \(quotedSource) /usr/local/bin/\(AppIdentity.cliName) && \
        chmod +x /usr/local/bin/\(AppIdentity.cliName)
        """
        let escapedForAppleScript = shellCommand
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let source = "do shell script \"\(escapedForAppleScript)\" with administrator privileges"
        guard let script = NSAppleScript(source: source) else { return false }
        var error: NSDictionary?
        script.executeAndReturnError(&error)
        return error == nil
    }

    private static func tryFallbackInstalls(resourceURL: URL) -> Bool {
        let home = NSHomeDirectory()
        let fallbacks = [
            "\(home)/bin",
            "\(home)/.local/bin",
        ]
        for fallback in fallbacks {
            guard copyScripts(from: resourceURL, to: fallback) else {
                continue
            }
            let pathNote = "\n\nAdd to PATH:\n  export PATH=\"$PATH:\(fallback)\""
            showInstalledAlert(binPath: fallback, pathNote: pathNote)
            return true
        }
        return false
    }

    private static func showInstalledAlert(binPath: String, pathNote: String) {
        alert(
            title: "CLI Installed",
            body: """
            Installed to: \(binPath)/\(AppIdentity.cliName)
            Run '\(AppIdentity.cliName) .' or '\(AppIdentity.cliName) /path/to/project'\(pathNote)
            """
        )
    }

    private static func confirmInstall() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Install \(AppIdentity.displayName) CLI?"
        alert.informativeText = """
        This will install the '\(AppIdentity.cliName)' command-line tool to \
        /usr/local/bin so you can launch projects from your terminal \
        (e.g. '\(AppIdentity.cliName) .').

        If /usr/local/bin is not writable, you will be prompted for your \
        administrator password. If that is declined, \(AppIdentity.displayName) \
        will fall back to ~/bin or ~/.local/bin.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Install")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private static func alert(title: String, body: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

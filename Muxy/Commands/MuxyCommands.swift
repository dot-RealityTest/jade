import AppKit
import SwiftUI

struct MuxyCommands: Commands {
    let appState: AppState
    let projectStore: ProjectStore
    let worktreeStore: WorktreeStore
    let keyBindings: KeyBindingStore
    let config: MuxyConfig
    let ghostty: GhosttyService
    let updateService: UpdateService

    private var isMainWindowFocused: Bool {
        ShortcutContext.isMainWindow(NSApp.keyWindow)
    }

    private var activeProject: Project? {
        guard let projectID = appState.activeProjectID else { return nil }
        return projectStore.projects.first { $0.id == projectID }
    }

    private var shortcutDispatcher: ShortcutActionDispatcher {
        ShortcutActionDispatcher(
            appState: appState,
            projectStore: projectStore,
            worktreeStore: worktreeStore,
            ghostty: ghostty
        )
    }

    private func performShortcutAction(_ action: ShortcutAction) {
        _ = shortcutDispatcher.perform(action, activeProject: activeProject) { project in
            VCSDisplayMode.current.route(
                tab: { appState.createVCSTab(projectID: project.id) },
                window: { NotificationCenter.default.post(name: .openVCSWindow, object: nil) },
                attached: { NotificationCenter.default.post(name: .toggleAttachedVCS, object: nil) }
            )
        }
    }

    var body: some Commands {
        CommandGroup(after: .appSettings) {
            Button {
                NSWorkspace.shared.open(
                    [config.ghosttyConfigURL],
                    withApplicationAt: URL(fileURLWithPath: "/System/Applications/TextEdit.app"),
                    configuration: NSWorkspace.OpenConfiguration()
                )
            } label: {
                Label("Open Configuration...", systemImage: "doc.text")
            }

            Button {
                performShortcutAction(.reloadConfig)
            } label: {
                Label("Reload Configuration", systemImage: "arrow.clockwise")
            }
            .shortcut(for: .reloadConfig, store: keyBindings)

            Divider()

            Button {
                CLIAccessor.installCLI()
            } label: {
                Label("Install CLI", systemImage: "terminal")
            }

            Button {
                updateService.checkForUpdates()
            } label: {
                Label("Check for Updates...", systemImage: "arrow.triangle.2.circlepath")
            }
            .disabled(!updateService.canCheckForUpdates)
        }

        CommandGroup(replacing: .pasteboard) {
            Button("Cut") { NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil) }
                .keyboardShortcut("x", modifiers: .command)
            Button("Copy") { NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil) }
                .keyboardShortcut("c", modifiers: .command)
            Button("Paste") { NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil) }
                .keyboardShortcut("v", modifiers: .command)
            Button("Select All") { NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil) }
                .keyboardShortcut("a", modifiers: .command)

            Divider()

            Button("Find") {
                guard isMainWindowFocused else { return }
                performShortcutAction(.findInTerminal)
            }
            .shortcut(for: .findInTerminal, store: keyBindings)
        }

        CommandGroup(replacing: .newItem) {
            Button("Open Project...") {
                performShortcutAction(.openProject)
            }
            .shortcut(for: .openProject, store: keyBindings)

            Divider()

            Button("New Tab") {
                guard isMainWindowFocused else { return }
                performShortcutAction(.newTab)
            }
            .shortcut(for: .newTab, store: keyBindings)

            Button("Command Palette") {
                guard isMainWindowFocused else { return }
                performShortcutAction(.commandPalette)
            }
            .shortcut(for: .commandPalette, store: keyBindings)

            Button("Quick Open") {
                guard isMainWindowFocused else { return }
                performShortcutAction(.quickOpen)
            }
            .shortcut(for: .quickOpen, store: keyBindings)

            Button("Save") {
                guard isMainWindowFocused else { return }
                performShortcutAction(.saveFile)
            }
            .shortcut(for: .saveFile, store: keyBindings)

            Divider()

            Button("Close Tab") {
                guard isMainWindowFocused else {
                    NSApp.keyWindow?.performClose(nil)
                    return
                }
                performShortcutAction(.closeTab)
            }
            .shortcut(for: .closeTab, store: keyBindings)
        }

        CommandGroup(after: .windowList) {
            Button("Next Tab") {
                guard isMainWindowFocused else { return }
                performShortcutAction(.nextTab)
            }
            .shortcut(for: .nextTab, store: keyBindings)

            Button("Previous Tab") {
                guard isMainWindowFocused else { return }
                performShortcutAction(.previousTab)
            }
            .shortcut(for: .previousTab, store: keyBindings)
        }

        CommandGroup(after: .sidebar) {
            Button("Toggle Sidebar") {
                guard isMainWindowFocused else { return }
                performShortcutAction(.toggleSidebar)
            }
            .shortcut(for: .toggleSidebar, store: keyBindings)
        }
    }
}

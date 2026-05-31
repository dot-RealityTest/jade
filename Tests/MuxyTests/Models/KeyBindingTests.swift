import Foundation
import Testing

@testable import Muxy

@Suite("KeyBinding")
struct KeyBindingTests {
    @Test("ShortcutAction.allCases is non-empty")
    func allCasesNonEmpty() {
        #expect(!ShortcutAction.allCases.isEmpty)
    }

    @Test("ShortcutAction.displayName is non-empty for every case")
    func displayNameNonEmpty() {
        for action in ShortcutAction.allCases {
            #expect(!action.displayName.isEmpty, "displayName empty for \(action.rawValue)")
        }
    }

    @Test("ShortcutAction.category is in known set for every case")
    func categoryInKnownSet() {
        let known = Set(ShortcutAction.categories)
        for action in ShortcutAction.allCases {
            #expect(known.contains(action.category), "\(action.rawValue) has unknown category '\(action.category)'")
        }
    }

    @Test("ShortcutAction.tabAction returns correct actions for valid indices")
    func tabActionValid() {
        for i in 1 ... 9 {
            let action = ShortcutAction.tabAction(for: i)
            #expect(action != nil, "tabAction(for: \(i)) should not be nil")
        }
    }

    @Test("ShortcutAction.tabAction returns nil for invalid indices")
    func tabActionInvalid() {
        #expect(ShortcutAction.tabAction(for: 0) == nil)
        #expect(ShortcutAction.tabAction(for: 10) == nil)
    }

    @Test("ShortcutAction.projectAction returns correct actions for valid indices")
    func projectActionValid() {
        for i in 1 ... 9 {
            let action = ShortcutAction.projectAction(for: i)
            #expect(action != nil, "projectAction(for: \(i)) should not be nil")
        }
    }

    @Test("ShortcutAction.projectAction returns nil for invalid indices")
    func projectActionInvalid() {
        #expect(ShortcutAction.projectAction(for: 0) == nil)
        #expect(ShortcutAction.projectAction(for: 10) == nil)
    }

    @Test("ShortcutAction tabSelectionIndex maps tab actions")
    func tabSelectionIndex() {
        #expect(ShortcutAction.selectTab1.tabSelectionIndex == 0)
        #expect(ShortcutAction.selectTab9.tabSelectionIndex == 8)
        #expect(ShortcutAction.newTab.tabSelectionIndex == nil)
    }

    @Test("ShortcutAction projectSelectionIndex maps project actions")
    func projectSelectionIndex() {
        #expect(ShortcutAction.selectProject1.projectSelectionIndex == 0)
        #expect(ShortcutAction.selectProject9.projectSelectionIndex == 8)
        #expect(ShortcutAction.nextProject.projectSelectionIndex == nil)
    }

    @Test("KeyBinding.defaults has unique actions")
    func defaultsUniqueActions() {
        let actions = KeyBinding.defaults.map(\.action)
        let unique = Set(actions)
        #expect(actions.count == unique.count)
    }

    @Test("KeyBinding.defaults has unique combos")
    func defaultsUniqueCombos() {
        let combos = KeyBinding.defaults.map(\.combo)
        let unique = Set(combos)
        #expect(combos.count == unique.count)
    }

    @Test("Snippets notes and todo shortcut metadata and default combos")
    func snippetsPanelShortcut() {
        #expect(ShortcutAction.toggleSnippetsPanel.displayName == "Toggle Snippets")
        #expect(ShortcutAction.toggleSnippetsPanel.category == "App")
        #expect(ShortcutAction.toggleSnippetsPanel.scope == .mainWindow)
        #expect(KeyBinding.defaults.first { $0.action == .toggleSnippetsPanel }?.combo == KeyCombo(key: "j", command: true))
        #expect(ShortcutAction.toggleSnippetsScope.displayName == "Toggle Snippet Scope")
        #expect(KeyBinding.defaults.first { $0.action == .toggleSnippetsScope }?.combo == KeyCombo(key: "j", command: true, control: true))
        #expect(ShortcutAction.toggleProjectNotesPanel.displayName == "Toggle Notes")
        #expect(KeyBinding.defaults.first { $0.action == .toggleProjectNotesPanel }?.combo == KeyCombo(key: "j", command: true, shift: true))
        #expect(ShortcutAction.toggleProjectTodoPanel.displayName == "Toggle Todo")
        #expect(KeyBinding.defaults.first { $0.action == .toggleProjectTodoPanel }?.combo == KeyCombo(key: "j", command: true, option: true))
    }

    @Test("Command palette owns Cmd+K default")
    func commandPaletteShortcut() {
        #expect(ShortcutAction.commandPalette.displayName == "Command Palette")
        #expect(ShortcutAction.commandPalette.category == "App")
        #expect(ShortcutAction.commandPalette.scope == .mainWindow)
        #expect(KeyBinding.defaults.first { $0.action == .commandPalette }?.combo == KeyCombo(key: "k", command: true))
        #expect(KeyBinding.defaults.first { $0.action == .openVCSTab }?.combo != KeyCombo(key: "k", command: true))
    }

    @Test("Kaku-inspired terminal tool shortcuts")
    func terminalToolShortcuts() {
        #expect(ShortcutAction.openLazygit.displayName == "Open Lazygit")
        #expect(ShortcutAction.openLazygit.category == "Terminal")
        #expect(ShortcutAction.openYazi.displayName == "Open Yazi")
        #expect(ShortcutAction.openYazi.category == "Terminal")
        #expect(KeyBinding.defaults.first { $0.action == .openLazygit }?.combo == KeyCombo(key: "g", command: true, shift: true))
        #expect(KeyBinding.defaults.first { $0.action == .openYazi }?.combo == KeyCombo(key: "y", command: true, shift: true))
    }

    @Test("KeyBinding.defaults includes cycle tab across panes shortcuts")
    func defaultsIncludesCycleTabAcrossPanesShortcuts() {
        let combos = Dictionary(uniqueKeysWithValues: KeyBinding.defaults.map { ($0.action, $0.combo) })
        #expect(combos[.cycleNextTabAcrossPanes] == KeyCombo(key: "tab", control: true))
        #expect(combos[.cyclePreviousTabAcrossPanes] == KeyCombo(key: "tab", shift: true, control: true))
    }

    @Test("KeyBinding.defaults includes maximize pane shortcut")
    func defaultsIncludesMaximizePaneShortcut() {
        let combos = Dictionary(uniqueKeysWithValues: KeyBinding.defaults.map { ($0.action, $0.combo) })
        #expect(combos[.toggleMaximizePane] == KeyCombo(key: KeyCombo.returnKey, command: true, option: true))
    }

    @Test("KeyBinding.defaults uses browser reopen shortcut")
    func defaultsIncludesReopenClosedTerminalTabShortcut() {
        let combos = Dictionary(uniqueKeysWithValues: KeyBinding.defaults.map { ($0.action, $0.combo) })
        #expect(combos[.reopenClosedTerminalTab] == KeyCombo(key: "t", command: true, shift: true))
        #expect(combos[.renameTab] == KeyCombo(key: "t", shift: true, option: true))
    }

    @Test("KeyBinding Codable round-trip")
    func codableRoundTrip() throws {
        let binding = KeyBinding(
            action: .newTab,
            combo: KeyCombo(key: "t", command: true)
        )
        let data = try JSONEncoder().encode(binding)
        let decoded = try JSONDecoder().decode(KeyBinding.self, from: data)
        #expect(decoded.action == binding.action)
        #expect(decoded.combo == binding.combo)
    }
}

import SwiftUI

extension View {
    @ViewBuilder
    func shortcut(for action: ShortcutAction, store: KeyBindingStore) -> some View {
        let combo = store.combo(for: action)
        if combo.key.isEmpty {
            self
        } else {
            keyboardShortcut(combo.swiftUIKeyEquivalent, modifiers: combo.swiftUIModifiers)
        }
    }
}

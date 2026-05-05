import SwiftUI

struct CommandsSettingsView: View {
    private enum Section: String, CaseIterable, Identifiable {
        case shortcuts = "Shortcuts"
        case custom = "Custom"
        case natural = "Natural"

        var id: String { rawValue }
    }

    @State private var section: Section = .shortcuts

    var body: some View {
        VStack(spacing: 0) {
            SettingsSegmentedHeader(selection: $section)

            Divider()

            switch section {
            case .shortcuts:
                KeyboardShortcutsSettingsView(mode: .app)
            case .custom:
                KeyboardShortcutsSettingsView(mode: .custom)
            case .natural:
                NaturalCommandSettingsView()
            }
        }
    }
}

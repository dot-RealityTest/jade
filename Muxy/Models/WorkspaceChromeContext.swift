import SwiftUI

struct WorkspaceChromePanelState: Equatable {
    var snippetsVisible: Bool
    var snippetsSuppressed: Bool
    var aiVisible: Bool
    var aiSuppressed: Bool
}

struct WorkspaceChromeHandlers {
    let onQuickOpen: () -> Void
    let onToggleFileTree: () -> Void
    let onToggleSnippets: () -> Void
    let onToggleAIAssistant: () -> Void
}

@MainActor
enum WorkspaceChromePanelAccent {
    static func color(requested: Bool, suppressed: Bool) -> Color {
        if requested, !suppressed {
            return MuxyTheme.accent
        }
        if requested {
            return MuxyTheme.accent.opacity(0.45)
        }
        return MuxyTheme.fgMuted
    }
}

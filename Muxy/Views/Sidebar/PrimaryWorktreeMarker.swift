import SwiftUI

struct PrimaryWorktreeMarker: View {
    var body: some View {
        Circle()
            .fill(MuxyTheme.fg.opacity(0.55))
            .frame(width: 4, height: 4)
            .accessibilityHidden(true)
    }
}

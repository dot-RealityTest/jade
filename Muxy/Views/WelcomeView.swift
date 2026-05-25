import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: UIMetrics.spacing7) {
            Spacer()
            Image(systemName: "folder.badge.plus")
                .font(.system(size: UIMetrics.fontMega))
                .foregroundStyle(MuxyTheme.fgMuted)
                .accessibilityHidden(true)
            Text("Welcome to \(AppIdentity.displayName)")
                .font(.system(size: UIMetrics.fontHeadline, weight: .semibold))
                .foregroundStyle(MuxyTheme.fg)
            Text("Open a project folder to start terminals, tabs, and workspaces.")
                .font(.system(size: UIMetrics.fontBody))
                .foregroundStyle(MuxyTheme.fgMuted)
                .multilineTextAlignment(.center)
                .frame(maxWidth: UIMetrics.scaled(360))
            Button(action: openProjectPicker) {
                HStack(spacing: UIMetrics.spacing4) {
                    Text("Open Project")
                    Text(KeyBindingStore.shared.combo(for: .openProject).displayString)
                        .font(.system(size: UIMetrics.fontFootnote, weight: .medium, design: .rounded))
                        .opacity(0.72)
                }
            }
            .buttonStyle(.borderedProminent)
            .help("Open a project folder")
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func openProjectPicker() {
        NotificationCenter.default.post(name: .openProjectPicker, object: nil)
    }
}

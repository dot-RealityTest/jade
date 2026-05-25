import SwiftUI

enum SettingsLayout {
    static func isCompact(contentWidth: CGFloat) -> Bool {
        contentWidth < SettingsMetrics.compactContentWidth
    }
}

extension EnvironmentValues {
    @Entry var settingsContentWidth: CGFloat = 640
}

struct SettingsContentWidthReader: ViewModifier {
    @State private var contentWidth: CGFloat = 640

    func body(content: Content) -> some View {
        content
            .environment(\.settingsContentWidth, contentWidth)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.size.width, initial: true) { _, width in
                            guard width > 0 else { return }
                            contentWidth = width
                        }
                }
            }
    }
}

private struct SettingsControlFrameModifier: ViewModifier {
    @Environment(\.settingsContentWidth) private var contentWidth
    var alignment: Alignment

    func body(content: Content) -> some View {
        if SettingsLayout.isCompact(contentWidth: contentWidth) {
            content
                .frame(maxWidth: .infinity, alignment: resolvedCompactAlignment)
        } else {
            content
                .frame(
                    width: SettingsMetrics.resolvedControlWidth(for: contentWidth),
                    alignment: alignment
                )
        }
    }

    private var resolvedCompactAlignment: Alignment {
        switch alignment {
        case .trailing: .leading
        default: alignment
        }
    }
}

extension View {
    func settingsContentWidthAware() -> some View {
        modifier(SettingsContentWidthReader())
    }

    func settingsControlFrame(alignment: Alignment = .trailing) -> some View {
        modifier(SettingsControlFrameModifier(alignment: alignment))
    }
}

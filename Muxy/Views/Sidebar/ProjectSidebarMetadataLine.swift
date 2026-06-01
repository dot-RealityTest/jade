import SwiftUI

struct ProjectSidebarMetadataLine: View {
    let status: ProjectSidebarStatus
    let isActive: Bool

    private var hasContent: Bool {
        status.branch != nil || status.listeningPortCount > 0 || status.latestUnreadPreview != nil
    }

    var body: some View {
        if hasContent {
            HStack(spacing: UIMetrics.spacing3) {
                if let branch = status.branch {
                    metadataChip(symbol: "arrow.triangle.branch", text: branch)
                }
                if status.listeningPortCount > 0 {
                    metadataChip(
                        symbol: "point.3.connected.trianglepath.dotted",
                        text: "\(status.listeningPortCount)"
                    )
                }
                if let preview = status.latestUnreadPreview {
                    Text(preview)
                        .font(.system(size: UIMetrics.fontCaption))
                        .foregroundStyle(isActive ? MuxyTheme.accent : MuxyTheme.fgMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func metadataChip(symbol: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .semibold))
            Text(text)
                .font(.system(size: UIMetrics.fontCaption, design: .monospaced))
                .lineLimit(1)
        }
        .foregroundStyle(MuxyTheme.fgMuted)
    }
}

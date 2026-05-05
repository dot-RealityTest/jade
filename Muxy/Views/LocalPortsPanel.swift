import SwiftUI

struct LocalPortsPanel: View {
    @State private var monitor = LocalPortMonitor.shared
    let onDismiss: () -> Void

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(MuxyTheme.border)
            content
        }
        .frame(width: 620, height: 500)
        .task {
            await monitor.refresh()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "network")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MuxyTheme.accent)
            Text("Local Ports")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MuxyTheme.fg)
            Text("\(monitor.active.count) active")
                .font(.system(size: 11))
                .foregroundStyle(MuxyTheme.fgMuted)
            if !monitor.dead.isEmpty {
                Text("\(monitor.dead.count) dead")
                    .font(.system(size: 11))
                    .foregroundStyle(MuxyTheme.diffRemoveFg)
            }
            Spacer()
            if monitor.isRefreshing {
                ProgressView()
                    .controlSize(.small)
                    .scaleEffect(0.7)
            }
            Button {
                Task { await monitor.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .foregroundStyle(MuxyTheme.fgMuted)
            .help("Refresh ports")
            if !monitor.dead.isEmpty {
                Button {
                    monitor.clearDead()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .foregroundStyle(MuxyTheme.fgMuted)
                .help("Clear dead ports")
            }
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .foregroundStyle(MuxyTheme.fgMuted)
            .help("Close")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(MuxyTheme.bg)
    }

    private var content: some View {
        VStack(spacing: 0) {
            if let message = monitor.errorMessage {
                errorBanner(message)
            }
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0) {
                    sectionHeader("Active", count: monitor.active.count)
                    if monitor.active.isEmpty {
                        emptyRow("No listening TCP ports")
                    } else {
                        ForEach(monitor.active) { listener in
                            PortListenerRow(listener: listener, status: .active)
                        }
                    }
                    sectionHeader("Dead", count: monitor.dead.count)
                    if monitor.dead.isEmpty {
                        emptyRow("Refresh after a listener stops to see it here")
                    } else {
                        ForEach(monitor.dead) { item in
                            PortListenerRow(
                                listener: item.listener,
                                status: .dead(lastSeen: relativeDate(item.lastSeenAt))
                            )
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .background(MuxyTheme.bg)
    }

    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(MuxyTheme.fgMuted)
            Text(String(count))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(MuxyTheme.fgDim)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    private func emptyRow(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(MuxyTheme.fgDim)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 11, weight: .semibold))
            Text(message)
                .font(.system(size: 11))
                .lineLimit(2)
            Spacer()
        }
        .foregroundStyle(MuxyTheme.warning)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(MuxyTheme.warning.opacity(0.08))
    }

    private func relativeDate(_ date: Date) -> String {
        Self.relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}

private enum PortListenerStatus: Equatable {
    case active
    case dead(lastSeen: String)
}

private struct PortListenerRow: View {
    let listener: LocalPortListener
    let status: PortListenerStatus
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 12) {
            statusIndicator
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(listener.endpoint)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(MuxyTheme.fg)
                    Text(listener.protocolName)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(MuxyTheme.fgMuted)
                    Spacer()
                    statusText
                }
                HStack(spacing: 8) {
                    Text(listener.command)
                        .lineLimit(1)
                    Text("pid \(listener.pid)")
                    if !listener.userID.isEmpty {
                        Text("user \(listener.userID)")
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(MuxyTheme.fgMuted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(hovered ? MuxyTheme.hover : Color.clear)
        .onHover { hovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 7, height: 7)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var statusText: some View {
        switch status {
        case .active:
            Text("active")
                .foregroundStyle(MuxyTheme.diffAddFg)
        case let .dead(lastSeen):
            Text("dead \(lastSeen)")
                .foregroundStyle(MuxyTheme.diffRemoveFg)
        }
    }

    private var statusColor: Color {
        switch status {
        case .active:
            MuxyTheme.diffAddFg
        case .dead:
            MuxyTheme.diffRemoveFg
        }
    }

    private var accessibilityLabel: String {
        switch status {
        case .active:
            "\(listener.endpoint), active, \(listener.command), pid \(listener.pid)"
        case let .dead(lastSeen):
            "\(listener.endpoint), dead \(lastSeen), \(listener.command), pid \(listener.pid)"
        }
    }
}

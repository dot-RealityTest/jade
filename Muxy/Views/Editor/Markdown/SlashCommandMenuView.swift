import SwiftUI

struct SlashCommandMenuView: View {
    let commands: [MarkdownSlashCommand]
    let onSelect: (MarkdownSlashCommand) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if commands.isEmpty {
                emptyRow
            } else {
                ForEach(commands) { command in
                    Button {
                        onSelect(command)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: command.symbolName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MuxyTheme.accent)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(command.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(MuxyTheme.fg)
                                Text(command.detail)
                                    .font(.system(size: 10))
                                    .foregroundStyle(MuxyTheme.fgMuted)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if command.id != commands.last?.id {
                        Divider().overlay(MuxyTheme.border.opacity(0.6))
                    }
                }
            }
        }
        .frame(width: 240)
        .background(MuxyTheme.surface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(MuxyTheme.border, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
    }

    private var emptyRow: some View {
        Text("No matching blocks")
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(MuxyTheme.fgMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
    }
}

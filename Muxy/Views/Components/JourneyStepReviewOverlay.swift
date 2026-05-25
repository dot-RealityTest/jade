import AppKit
import SwiftUI

struct JourneyStepReviewOverlay: View {
    let proposal: JourneyStepProposal
    let projectName: String
    let onConfirm: (_ overrideBlocker: Bool) -> Void
    let onNotNow: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 0) {
                header
                Divider().overlay(MuxyTheme.border)
                content
                Divider().overlay(MuxyTheme.border)
                footer
            }
            .frame(width: 520, height: proposal.requiresOverrideToConfirm ? 400 : 360)
            .background(MuxyTheme.bg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(MuxyTheme.border, lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
            .padding(.top, 60)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Next step")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MuxyTheme.fg)
                Text(projectName)
                    .font(.system(size: 11))
                    .foregroundStyle(MuxyTheme.fgDim)
                    .lineLimit(1)
                if let source = proposal.sourceFile {
                    Text("From \(source)")
                        .font(.system(size: 10))
                        .foregroundStyle(MuxyTheme.fgMuted)
                        .lineLimit(1)
                }
            }
            Spacer()
            riskBadge
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(proposal.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MuxyTheme.fg)

                Text(proposal.summary)
                    .font(.system(size: 12))
                    .foregroundStyle(MuxyTheme.fgDim)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Why")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MuxyTheme.fgMuted)
                    Text(proposal.why)
                        .font(.system(size: 12))
                        .foregroundStyle(MuxyTheme.fg)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let blockedReason = proposal.blockedReason {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(MuxyTheme.warning)
                        Text(blockedReason)
                            .font(.system(size: 11))
                            .foregroundStyle(MuxyTheme.warning)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(MuxyTheme.surface, in: RoundedRectangle(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7).stroke(MuxyTheme.border, lineWidth: 1))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button("Cancel", action: onCancel)
            Button("Defer", action: onNotNow)
            Spacer()
            if proposal.requiresOverrideToConfirm {
                Button("Change step", action: onCancel)
                Button("Override once") {
                    onConfirm(true)
                }
                .foregroundStyle(MuxyTheme.warning)
            } else {
                Button("Start") {
                    onConfirm(false)
                }
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var riskBadge: some View {
        Text(proposal.risk.displayName)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(proposal.risk == .blocked ? MuxyTheme.warning : MuxyTheme.fgMuted)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(MuxyTheme.surface, in: Capsule())
    }
}

import AppKit
import SwiftUI

struct NaturalCommandReviewView: View {
    let request: NaturalCommandRequest
    let generator: any NaturalCommandGenerator
    let onRun: (NaturalCommandPlan) -> Void
    let onSave: (NaturalCommandPlan) -> Void
    let onBack: () -> Void
    let onDismiss: () -> Void

    @State private var plan: NaturalCommandPlan?
    @State private var errorMessage: String?
    @State private var isGenerating = true

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 0) {
                header
                Divider().overlay(MuxyTheme.border)
                content
                Divider().overlay(MuxyTheme.border)
                footer
            }
            .frame(width: 540, height: 430)
            .background(MuxyTheme.bg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(MuxyTheme.border, lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
            .padding(.top, 60)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .task(id: request.prompt) {
            await generate()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(MuxyTheme.fgMuted)
            .keyboardShortcut(.leftArrow, modifiers: .command)

            VStack(alignment: .leading, spacing: 2) {
                Text("Natural Command")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MuxyTheme.fg)
                Text(request.prompt)
                    .font(.system(size: 11))
                    .foregroundStyle(MuxyTheme.fgDim)
                    .lineLimit(1)
            }

            Spacer()

            targetBadge
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var content: some View {
        if isGenerating {
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.small)
                Text("Generating a safe shell plan...")
                    .font(.system(size: 12))
                    .foregroundStyle(MuxyTheme.fgDim)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let plan {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        riskBadge(plan.riskLevel)
                        backendBadge(plan.backend)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MuxyTheme.fg)
                        Text(plan.summary)
                            .font(.system(size: 11))
                            .foregroundStyle(MuxyTheme.fgDim)
                    }

                    commandBlock(plan.primaryCommand)

                    Text(plan.blockedReason ?? plan.steps.first?.explanation ?? "")
                        .font(.system(size: 11))
                        .foregroundStyle(plan.riskLevel == .blocked ? MuxyTheme.warning : MuxyTheme.fgDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(MuxyTheme.warning)
                Text(errorMessage ?? "Could not generate a command")
                    .font(.system(size: 12))
                    .foregroundStyle(MuxyTheme.fgDim)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button("Back", action: onBack)
            Spacer()
            if let plan {
                Button("Copy") {
                    copy(plan.primaryCommand)
                }
                .disabled(plan.primaryCommand.isEmpty)
                Button("Save as Snippet") {
                    onSave(plan)
                }
                .disabled(plan.primaryCommand.isEmpty)
                Button("Run") {
                    onRun(plan)
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(!plan.isRunnable)
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var targetBadge: some View {
        Text(request.context.displayName)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(MuxyTheme.fgMuted)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(MuxyTheme.surface, in: Capsule())
    }

    private func commandBlock(_ command: String) -> some View {
        Text(command)
            .font(.system(size: 11, design: .monospaced))
            .foregroundStyle(MuxyTheme.fg)
            .textSelection(.enabled)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MuxyTheme.surface, in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(MuxyTheme.border, lineWidth: 1))
    }

    private func riskBadge(_ risk: NaturalCommandRiskLevel) -> some View {
        Text(risk.displayName)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(risk == .blocked ? MuxyTheme.warning : MuxyTheme.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((risk == .blocked ? MuxyTheme.warning : MuxyTheme.accent).opacity(0.12), in: Capsule())
    }

    private func backendBadge(_ backend: NaturalCommandBackend) -> some View {
        Text(backend.displayName)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(MuxyTheme.fgDim)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(MuxyTheme.surface, in: Capsule())
    }

    private func generate() async {
        isGenerating = true
        errorMessage = nil
        plan = nil
        do {
            let generated = try await generator.generate(request: request)
            await MainActor.run {
                plan = generated
                isGenerating = false
            }
        } catch {
            await MainActor.run {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                isGenerating = false
            }
        }
    }

    private func copy(_ command: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        ToastState.shared.show("Copied command")
    }
}

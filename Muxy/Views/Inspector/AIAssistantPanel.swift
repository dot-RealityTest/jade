import SwiftUI

struct AIAssistantPanel: View {
    let projectID: UUID?
    let projectPath: String?
    let activeFile: String?

    @State private var store = AIAssistantStore.shared
    @State private var service = AIAssistantService.shared
    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(MuxyTheme.border)
            messageList
            Divider().overlay(MuxyTheme.border)
            inputBar
        }
        .frame(width: 340)
        .background(MuxyTheme.bg)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(MuxyTheme.border)
                .frame(width: 1)
        }
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 1) {
                Text("Assistant")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(projectName)
                    .font(.system(size: 10))
                    .foregroundStyle(MuxyTheme.fgMuted)
                    .lineLimit(1)
            }
            Spacer()
            if let pid = projectID, store.isStreaming[pid] == true {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 16, height: 16)
            }
            Button {
                clearConversation()
            } label: {
                Image(systemName: "eraser")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MuxyTheme.fgMuted)
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .help("Clear conversation")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if let pid = projectID {
                        ForEach(store.messages(for: pid)) { message in
                            MessageBubble(message: message)
                        }
                    } else {
                        aiEmptyState
                    }
                }
                .padding(.vertical, 8)
            }
            .onChange(of: lastMessageID) { _, newValue in
                guard let id = newValue else { return }
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(id, anchor: .bottom)
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask anything...", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .lineLimit(1 ... 4)
                .focused($inputFocused)
                .onSubmit {
                    guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    send()
                }

            Button {
                send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(canSend ? MuxyTheme.accent : MuxyTheme.fgDim)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(MuxyTheme.surface)
    }

    private var aiEmptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 22))
                .foregroundStyle(MuxyTheme.fgDim)
            Text("Select a project to start")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MuxyTheme.fgMuted)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var projectName: String {
        guard let path = projectPath else { return "No project" }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    private var lastMessageID: UUID? {
        guard let pid = projectID else { return nil }
        return store.messages(for: pid).last?.id
    }

    private var canSend: Bool {
        guard let pid = projectID else { return false }
        return !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && store.isStreaming[pid] != true
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let pid = projectID else { return }
        draft = ""
        service.send(
            prompt: text,
            projectID: pid,
            projectPath: projectPath,
            activeFile: activeFile
        )
    }

    private func clearConversation() {
        guard let pid = projectID else { return }
        store.clear(projectID: pid)
    }
}

private struct MessageBubble: View {
    let message: AIAssistantMessage

    var body: some View {
        HStack(spacing: 0) {
            if message.role == .user {
                Spacer(minLength: 24)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 12))
                    .foregroundStyle(message.role == .user ? MuxyTheme.fg : MuxyTheme.fg)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(message.role == .user ? MuxyTheme.accentSoft : MuxyTheme.surface)
            .cornerRadius(8)
            if message.role == .assistant {
                Spacer(minLength: 24)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
    }
}

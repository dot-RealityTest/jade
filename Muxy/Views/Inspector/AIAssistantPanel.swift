import SwiftUI

struct AIAssistantPanel: View {
    let projectID: UUID?
    let projectPath: String?
    let worktreeID: UUID?
    let worktreePath: String?
    let activeFile: String?

    @State private var store = AIAssistantStore.shared
    @State private var service = AIAssistantChatService.shared
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
        .frame(width: WindowLayoutMetrics.aiAssistantWidth)
        .background(MuxyTheme.bg)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(MuxyTheme.border)
                .frame(width: 1)
        }
        .background {
            Button {
                inputFocused = true
            } label: {
                EmptyView()
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])
            .opacity(0)
            .frame(width: 0, height: 0)
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusAIAssistantInput)) { _ in
            inputFocused = true
        }
    }

    private var header: some View {
        HStack(spacing: UIMetrics.spacing4) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: UIMetrics.fontEmphasis, weight: .semibold))
                .foregroundStyle(MuxyTheme.fgMuted)
                .frame(width: UIMetrics.iconLG)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text("Assistant")
                    .font(.system(size: UIMetrics.fontEmphasis, weight: .semibold))
                    .foregroundStyle(MuxyTheme.fg)
                Text(projectName)
                    .font(.system(size: UIMetrics.fontCaption))
                    .foregroundStyle(MuxyTheme.fgMuted)
                    .lineLimit(1)
            }
            Spacer()
            if let pid = projectID, store.isStreaming[pid] == true {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: UIMetrics.iconLG, height: UIMetrics.iconLG)
                    .accessibilityLabel("Assistant is responding")
            }
            Button {
                clearConversation()
            } label: {
                Image(systemName: "eraser")
                    .font(.system(size: UIMetrics.fontFootnote, weight: .semibold))
                    .foregroundStyle(MuxyTheme.fgMuted)
                    .frame(width: UIMetrics.controlMedium, height: UIMetrics.controlMedium)
            }
            .buttonStyle(.plain)
            .help("Clear conversation")
            .accessibilityLabel("Clear conversation")
        }
        .padding(.horizontal, UIMetrics.spacing6)
        .padding(.vertical, UIMetrics.spacing4)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if let pid = projectID {
                        ForEach(store.messages(for: pid)) { message in
                            MessageBubble(
                                message: message,
                                activeFile: activeFile,
                                onRetry: message.isError ? { retry() } : nil
                            )
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
        HStack(spacing: UIMetrics.spacing4) {
            TextField(inputPlaceholder, text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: UIMetrics.fontBody))
                .lineLimit(1 ... 4)
                .focused($inputFocused)
                .onSubmit {
                    guard !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    send()
                }

            if let pid = projectID, store.isStreaming[pid] == true {
                Button {
                    service.cancel(projectID: pid)
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.system(size: UIMetrics.fontEmphasis, weight: .semibold))
                        .foregroundStyle(MuxyTheme.diffRemoveFg)
                        .frame(width: UIMetrics.controlMedium, height: UIMetrics.controlMedium)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop response")
            } else {
                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: UIMetrics.fontTitleLarge, weight: .semibold))
                        .foregroundStyle(canSend ? MuxyTheme.accent : MuxyTheme.fgDim)
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .accessibilityLabel("Send message")
            }
        }
        .padding(.horizontal, UIMetrics.spacing5)
        .padding(.vertical, UIMetrics.spacing4)
        .background(MuxyTheme.surface)
    }

    private var aiEmptyState: some View {
        VStack(spacing: UIMetrics.spacing4) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: UIMetrics.fontDisplay))
                .foregroundStyle(MuxyTheme.fgDim)
                .accessibilityHidden(true)
            Text("Select a project to start")
                .font(.system(size: UIMetrics.fontBody, weight: .medium))
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

    private var inputPlaceholder: String {
        "Ask anything..."
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
        service.send(context: InspectorChatContext(
            prompt: text,
            projectID: pid,
            projectPath: projectPath,
            activeFile: activeFile,
            worktreeID: worktreeID,
            worktreePath: worktreePath
        ))
    }

    private func clearConversation() {
        guard let pid = projectID else { return }
        store.clear(projectID: pid)
    }

    private func retry() {
        guard let pid = projectID,
              let prompt = store.lastFailedPrompt[pid]
        else { return }
        store.setLastFailedPrompt(nil, projectID: pid)
        service.send(context: InspectorChatContext(
            prompt: prompt,
            projectID: pid,
            projectPath: projectPath,
            activeFile: activeFile,
            worktreeID: worktreeID,
            worktreePath: worktreePath
        ))
    }
}

private struct MessageBubble: View {
    let message: AIAssistantMessage
    let activeFile: String?
    let onRetry: (() -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            if message.role == .user {
                Spacer(minLength: 24)
            }
            VStack(alignment: .leading, spacing: 6) {
                MarkdownMessageContent(text: message.content, isUser: message.role == .user, activeFile: activeFile)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(message.role == .user ? MuxyTheme.accentSoft : MuxyTheme.surface)
                    .cornerRadius(8)
                if let onRetry, message.isError {
                    Button {
                        onRetry()
                    } label: {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 9, weight: .semibold))
                            Text("Retry")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(MuxyTheme.diffRemoveFg)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(MuxyTheme.diffRemoveFg.opacity(0.1), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10)
                }
            }
            if message.role == .assistant {
                Spacer(minLength: 24)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
    }
}

private struct MarkdownMessageContent: View {
    let text: String
    let isUser: Bool
    let activeFile: String?

    var body: some View {
        let blocks = MarkdownBlockParser.cachedBlocks(for: text)
        VStack(alignment: .leading, spacing: UIMetrics.spacing4) {
            ForEach(blocks) { block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case let .paragraph(segments):
            paragraphView(segments)
        case let .heading(level, text):
            headingView(level: level, text: text)
        case let .codeBlock(_, code):
            codeBlockView(code)
        case let .bulletList(items):
            bulletListView(items)
        case let .orderedList(items):
            orderedListView(items)
        case let .blockquote(text):
            blockquoteView(text)
        }
    }

    private func paragraphView(_ segments: [InlineSegment]) -> some View {
        Text(attributedString(from: segments))
            .font(.system(size: UIMetrics.fontBody))
            .foregroundStyle(MuxyTheme.fg)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func headingView(level: Int, text: String) -> some View {
        let size = max(UIMetrics.fontHeadline, UIMetrics.fontDisplay - CGFloat(level) * 2)
        return Text(text)
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(MuxyTheme.fg)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func codeBlockView(_ code: String) -> some View {
        ZStack(alignment: .topTrailing) {
            Text(code)
                .font(.system(size: UIMetrics.fontFootnote, design: .monospaced))
                .foregroundStyle(MuxyTheme.fg)
                .padding(.horizontal, UIMetrics.spacing4)
                .padding(.vertical, UIMetrics.spacing3)
                .padding(.top, UIMetrics.spacing8)
                .background(MuxyTheme.hover, in: RoundedRectangle(cornerRadius: UIMetrics.radiusMD))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                if !isUser, let filePath = activeFile {
                    ApplyCodeButton(code: code, filePath: filePath)
                }
                CopyCodeButton(code: code)
            }
            .padding(.trailing, 4)
            .padding(.top, 2)
        }
    }

    private func bulletListView(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 6) {
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundStyle(MuxyTheme.fgMuted)
                    Text(items[index])
                        .font(.system(size: 12))
                        .foregroundStyle(MuxyTheme.fg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func orderedListView(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(items.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 6) {
                    Text("\(index + 1).")
                        .font(.system(size: 12))
                        .foregroundStyle(MuxyTheme.fgMuted)
                        .frame(width: 16, alignment: .trailing)
                    Text(items[index])
                        .font(.system(size: 12))
                        .foregroundStyle(MuxyTheme.fg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func blockquoteView(_ text: String) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(MuxyTheme.fgMuted.opacity(0.4))
                .frame(width: 2)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(MuxyTheme.fgMuted)
                .padding(.leading, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }

    private func attributedString(from segments: [InlineSegment]) -> AttributedString {
        var result = AttributedString()
        for segment in segments {
            var attr = AttributedString(segment.text)
            switch segment.kind {
            case .plain:
                attr.font = .systemFont(ofSize: 12)
                attr.foregroundColor = MuxyTheme.fg.toNSColor()
            case .bold:
                attr.font = .systemFont(ofSize: 12, weight: .bold)
                attr.foregroundColor = MuxyTheme.fg.toNSColor()
            case .italic:
                var descriptor = NSFont.systemFont(ofSize: 12).fontDescriptor.withSymbolicTraits(.italic)
                attr.font = NSFont(descriptor: descriptor, size: 12) ?? .systemFont(ofSize: 12)
                attr.foregroundColor = MuxyTheme.fg.toNSColor()
            case .code:
                attr.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
                attr.foregroundColor = MuxyTheme.fg.toNSColor()
                attr.backgroundColor = MuxyTheme.hover.toNSColor()
            }
            result.append(attr)
        }
        return result
    }
}

private enum MarkdownBlock: Identifiable {
    case paragraph(segments: [InlineSegment])
    case heading(level: Int, text: String)
    case codeBlock(language: String?, code: String)
    case bulletList(items: [String])
    case orderedList(items: [String])
    case blockquote(text: String)

    var id: String {
        switch self {
        case let .paragraph(segments):
            "p-\(segments.map(\.id).joined(separator: "-"))"
        case let .heading(level, text):
            "h\(level)-\(text.hashValue)"
        case let .codeBlock(language, code):
            "c-\((language ?? "").hashValue)-\(code.hashValue)"
        case let .bulletList(items):
            "ul-\(items.joined(separator: "|").hashValue)"
        case let .orderedList(items):
            "ol-\(items.joined(separator: "|").hashValue)"
        case let .blockquote(text):
            "q-\(text.hashValue)"
        }
    }
}

private struct InlineSegment: Identifiable {
    enum Kind {
        case plain
        case bold
        case italic
        case code
    }

    let kind: Kind
    let text: String

    var id: String {
        let kindLabel = switch kind {
        case .plain: "plain"
        case .bold: "bold"
        case .italic: "italic"
        case .code: "code"
        }
        return "\(kindLabel)-\(text.hashValue)"
    }
}

@MainActor
private enum MarkdownBlockParser {
    private static var cache: [String: [MarkdownBlock]] = [:]
    private static let cacheLimit = 128

    static func cachedBlocks(for text: String) -> [MarkdownBlock] {
        if let cached = cache[text] {
            return cached
        }
        let parsed = parse(text)
        cache[text] = parsed
        if cache.count > cacheLimit {
            cache.removeAll(keepingCapacity: true)
        }
        return parsed
    }

    static func parse(_ text: String) -> [MarkdownBlock] {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var blocks: [MarkdownBlock] = []
        var index = 0
        while index < lines.count {
            let line = String(lines[index])
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                index += 1
                continue
            }
            if let block = parseCodeBlock(lines: lines, start: index) {
                blocks.append(block.block)
                index = block.nextIndex
                continue
            }
            if let heading = parseHeading(line) {
                blocks.append(heading)
                index += 1
                continue
            }
            if let blockquote = parseBlockquote(lines: lines, start: index) {
                blocks.append(blockquote.block)
                index = blockquote.nextIndex
                continue
            }
            if let list = parseBulletList(lines: lines, start: index) {
                blocks.append(list.block)
                index = list.nextIndex
                continue
            }
            if let list = parseOrderedList(lines: lines, start: index) {
                blocks.append(list.block)
                index = list.nextIndex
                continue
            }
            let paragraphLines = gatherParagraphLines(lines: lines, start: index)
            let rawText = paragraphLines.joined(separator: "\n")
            blocks.append(.paragraph(segments: InlineParser.parse(rawText)))
            index += paragraphLines.count
        }
        return blocks
    }

    private static func parseHeading(_ line: String) -> MarkdownBlock? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#") else { return nil }
        var level = 0
        for char in trimmed {
            if char == "#", level < 6 { level += 1 } else { break }
        }
        guard level >= 1 else { return nil }
        let afterHashes = trimmed.dropFirst(level)
        guard afterHashes.hasPrefix(" ") else { return nil }
        let text = String(afterHashes.dropFirst()).trimmingCharacters(in: .whitespaces)
        return .heading(level: level, text: text)
    }

    private static func parseCodeBlock(lines: [String.SubSequence], start: Int) -> (block: MarkdownBlock, nextIndex: Int)? {
        let line = String(lines[start]).trimmingCharacters(in: .whitespaces)
        guard line.hasPrefix("```") else { return nil }
        let language = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        var codeLines: [String] = []
        var index = start + 1
        while index < lines.count {
            let current = String(lines[index])
            if current.trimmingCharacters(in: .whitespaces) == "```" {
                return (.codeBlock(language: language.isEmpty ? nil : language, code: codeLines.joined(separator: "\n")), index + 1)
            }
            codeLines.append(current)
            index += 1
        }
        return (.codeBlock(language: language.isEmpty ? nil : language, code: codeLines.joined(separator: "\n")), index)
    }

    private static func parseBlockquote(lines: [String.SubSequence], start: Int) -> (block: MarkdownBlock, nextIndex: Int)? {
        let line = String(lines[start])
        guard line.trimmingCharacters(in: .whitespaces).hasPrefix(">") else { return nil }
        var quoteLines: [String] = []
        var index = start
        while index < lines.count {
            let current = String(lines[index])
            let trimmed = current.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { break }
            guard trimmed.hasPrefix(">") else { break }
            let afterMarker = trimmed.dropFirst()
            let content = afterMarker.hasPrefix(" ") ? String(afterMarker.dropFirst()) : String(afterMarker)
            quoteLines.append(content)
            index += 1
        }
        return (.blockquote(text: quoteLines.joined(separator: " ")), index)
    }

    private static func parseBulletList(lines: [String.SubSequence], start: Int) -> (block: MarkdownBlock, nextIndex: Int)? {
        let line = String(lines[start])
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") else { return nil }
        var items: [String] = []
        var index = start
        while index < lines.count {
            let current = String(lines[index]).trimmingCharacters(in: .whitespaces)
            if current.isEmpty { break }
            guard current.hasPrefix("- ") || current.hasPrefix("* ") else { break }
            items.append(String(current.dropFirst(2)))
            index += 1
        }
        return (.bulletList(items: items), index)
    }

    private static func parseOrderedList(lines: [String.SubSequence], start: Int) -> (block: MarkdownBlock, nextIndex: Int)? {
        let line = String(lines[start])
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.first?.isNumber == true else { return nil }
        let pattern = #"^\d+\.\s"#
        guard trimmed.range(of: pattern, options: .regularExpression) != nil else { return nil }
        var items: [String] = []
        var index = start
        while index < lines.count {
            let current = String(lines[index]).trimmingCharacters(in: .whitespaces)
            if current.isEmpty { break }
            guard current.first?.isNumber == true,
                  current.range(of: pattern, options: .regularExpression) != nil
            else { break }
            let afterNumber = current.drop(while: { $0.isNumber }).dropFirst()
            let content = afterNumber.hasPrefix(" ") ? String(afterNumber.dropFirst()) : String(afterNumber)
            items.append(content)
            index += 1
        }
        return (.orderedList(items: items), index)
    }

    private static func gatherParagraphLines(lines: [String.SubSequence], start: Int) -> [String] {
        var result: [String] = []
        var index = start
        while index < lines.count {
            let current = String(lines[index])
            if current.trimmingCharacters(in: .whitespaces).isEmpty { break }
            result.append(current)
            index += 1
        }
        return result
    }
}

private enum InlineParser {
    static func parse(_ text: String) -> [InlineSegment] {
        let pattern = #"(\*\*[^*]+\*\*|\*[^*]+\*|_[^_]+_|`[^`]+`)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return [InlineSegment(kind: .plain, text: text)]
        }
        let ns = text as NSString
        let range = NSRange(location: 0, length: ns.length)
        let matches = regex.matches(in: text, options: [], range: range)
        var segments: [InlineSegment] = []
        var current = 0
        for match in matches {
            let matchRange = match.range
            if matchRange.location > current {
                let plain = ns.substring(with: NSRange(location: current, length: matchRange.location - current))
                segments.append(InlineSegment(kind: .plain, text: plain))
            }
            let raw = ns.substring(with: matchRange)
            let kind: InlineSegment.Kind
            let content: String
            if raw.hasPrefix("**"), raw.hasSuffix("**") {
                kind = .bold
                content = String(raw.dropFirst(2).dropLast(2))
            } else if raw.hasPrefix("*"), raw.hasSuffix("*") {
                kind = .italic
                content = String(raw.dropFirst().dropLast())
            } else if raw.hasPrefix("_"), raw.hasSuffix("_") {
                kind = .italic
                content = String(raw.dropFirst().dropLast())
            } else if raw.hasPrefix("`"), raw.hasSuffix("`") {
                kind = .code
                content = String(raw.dropFirst().dropLast())
            } else {
                kind = .plain
                content = raw
            }
            segments.append(InlineSegment(kind: kind, text: content))
            current = matchRange.location + matchRange.length
        }
        if current < ns.length {
            let plain = ns.substring(with: NSRange(location: current, length: ns.length - current))
            segments.append(InlineSegment(kind: .plain, text: plain))
        }
        if segments.isEmpty {
            segments.append(InlineSegment(kind: .plain, text: text))
        }
        return segments
    }
}

private struct CopyCodeButton: View {
    let code: String
    @State private var copied = false

    var body: some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(code, forType: .string)
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                copied = false
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 9, weight: .semibold))
                Text(copied ? "Copied" : "Copy")
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(copied ? MuxyTheme.diffAddFg : MuxyTheme.fgMuted)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(MuxyTheme.bg.opacity(0.8), in: Capsule())
        }
        .buttonStyle(.plain)
        .help("Copy code to clipboard")
    }
}

private struct ApplyCodeButton: View {
    let code: String
    let filePath: String
    @State private var applied = false

    var body: some View {
        Button {
            NotificationCenter.default.post(
                name: .applyAIAssistantCode,
                object: nil,
                userInfo: [
                    "code": code,
                    "filePath": filePath,
                ]
            )
            applied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                applied = false
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: applied ? "checkmark" : "arrow.down.doc")
                    .font(.system(size: 9, weight: .semibold))
                Text(applied ? "Applied" : "Apply")
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(applied ? MuxyTheme.diffAddFg : MuxyTheme.fgMuted)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(MuxyTheme.bg.opacity(0.8), in: Capsule())
        }
        .buttonStyle(.plain)
        .help("Apply code to editor")
    }
}

private extension Color {
    func toNSColor() -> NSColor {
        NSColor(self)
    }
}

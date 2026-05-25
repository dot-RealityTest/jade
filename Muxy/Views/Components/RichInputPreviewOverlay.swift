import AppKit
import SwiftUI

struct RichInputPreviewOverlay: View {
    let projectName: String
    let markdown: String
    let onToggleTask: (Int) -> Void
    let onCopyAll: () -> Void
    let onCopyLine: (RichInputPreviewLine) -> Void
    let onDismiss: () -> Void

    @State private var lines: [RichInputPreviewLine] = []
    @State private var highlightedIndex: Int?
    @State private var focusToken = 0

    var body: some View {
        ZStack {
            Button(action: onDismiss) {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
            }
            .buttonStyle(.plain)
            .accessibilityHidden(true)

            VStack(spacing: 0) {
                header
                Divider().overlay(MuxyTheme.border)
                linesList
                Divider().overlay(MuxyTheme.border)
                footer
            }
            .frame(width: UIMetrics.scaled(560), height: UIMetrics.scaled(420))
            .background(MuxyTheme.bg)
            .clipShape(RoundedRectangle(cornerRadius: UIMetrics.radiusXL))
            .overlay(RoundedRectangle(cornerRadius: UIMetrics.radiusXL).stroke(MuxyTheme.border, lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: UIMetrics.scaled(20), y: UIMetrics.scaled(8))
            .padding(.top, UIMetrics.scaled(60))
            .frame(maxHeight: .infinity, alignment: .top)
            .accessibilityAddTraits(.isModal)
            .overlay {
                RichInputPreviewKeyCapture(
                    focusToken: focusToken,
                    onArrowUp: { moveHighlight(-1) },
                    onArrowDown: { moveHighlight(1) },
                    onToggleTask: toggleHighlightedTask,
                    onCopyAll: onCopyAll,
                    onCopyLine: copyHighlightedLine,
                    onDismiss: onDismiss
                )
                .frame(width: 0, height: 0)
            }
        }
        .onAppear {
            reloadLines(selectFirstTask: true)
            focusToken += 1
        }
        .onChange(of: markdown) { _, _ in
            reloadLines(selectFirstTask: false)
        }
    }

    private var header: some View {
        HStack(spacing: UIMetrics.spacing4) {
            Image(systemName: "eye")
                .font(.system(size: UIMetrics.fontEmphasis, weight: .semibold))
                .foregroundStyle(MuxyTheme.fgMuted)
            VStack(alignment: .leading, spacing: 1) {
                Text("Rich Input Preview")
                    .font(.system(size: UIMetrics.fontEmphasis, weight: .semibold))
                    .foregroundStyle(MuxyTheme.fg)
                Text(projectName)
                    .font(.system(size: UIMetrics.fontCaption))
                    .foregroundStyle(MuxyTheme.fgMuted)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
        }
        .padding(.horizontal, UIMetrics.spacing6)
        .padding(.vertical, UIMetrics.spacing5)
    }

    private var linesList: some View {
        Group {
            if lines.isEmpty {
                VStack {
                    Spacer()
                    Text("No notes or tasks yet")
                        .font(.system(size: UIMetrics.fontBody))
                        .foregroundStyle(MuxyTheme.fgMuted)
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(Array(lines.enumerated()), id: \.element.id) { index, line in
                                RichInputPreviewRow(line: line, isHighlighted: index == highlightedIndex)
                                    .id(line.id)
                            }
                        }
                        .padding(.vertical, UIMetrics.spacing3)
                    }
                    .onChange(of: highlightedIndex) { _, newIndex in
                        guard let newIndex, newIndex < lines.count else { return }
                        proxy.scrollTo(lines[newIndex].id, anchor: .center)
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            hint("Space", "Toggle task")
            hint("⌘C", "Copy all")
            hint("⌘⇧C", "Copy line")
            hint("Esc", "Close")
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 5) {
            Text(key)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(MuxyTheme.fgMuted)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(MuxyTheme.surface, in: RoundedRectangle(cornerRadius: 4))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(MuxyTheme.fgDim)
        }
    }

    private func reloadLines(selectFirstTask: Bool) {
        lines = ProjectWorkspaceMarkdown.previewLines(from: markdown)
        guard !lines.isEmpty else {
            highlightedIndex = nil
            return
        }
        if selectFirstTask, let firstTaskIndex = lines.firstIndex(where: \.isTask) {
            highlightedIndex = firstTaskIndex
            return
        }
        if let highlightedIndex, highlightedIndex < lines.count {
            return
        }
        highlightedIndex = 0
    }

    private func moveHighlight(_ delta: Int) {
        guard !lines.isEmpty else { return }
        guard let current = highlightedIndex else {
            highlightedIndex = delta > 0 ? 0 : lines.count - 1
            return
        }
        highlightedIndex = max(0, min(lines.count - 1, current + delta))
    }

    private func toggleHighlightedTask() {
        guard let index = highlightedIndex, index < lines.count else { return }
        let line = lines[index]
        guard line.isTask else { return }
        onToggleTask(line.lineIndex)
    }

    private func copyHighlightedLine() {
        guard let index = highlightedIndex, index < lines.count else { return }
        onCopyLine(lines[index])
    }
}

private struct RichInputPreviewRow: View {
    let line: RichInputPreviewLine
    let isHighlighted: Bool

    var body: some View {
        HStack(alignment: .top, spacing: UIMetrics.spacing4) {
            switch line.kind {
            case .blank:
                Color.clear.frame(height: 6)
            case .note:
                Text(line.displayText)
                    .font(.system(size: UIMetrics.fontBody, design: .monospaced))
                    .foregroundStyle(MuxyTheme.fg)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            case let .task(isDone):
                Image(systemName: isDone ? "checkmark.square.fill" : "square")
                    .font(.system(size: UIMetrics.fontBody, weight: .semibold))
                    .foregroundStyle(isDone ? MuxyTheme.diffAddFg : MuxyTheme.fgMuted)
                    .frame(width: 16)
                Text(line.displayText)
                    .font(.system(size: UIMetrics.fontBody))
                    .foregroundStyle(isDone ? MuxyTheme.fgMuted : MuxyTheme.fg)
                    .strikethrough(isDone, color: MuxyTheme.fgMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, UIMetrics.spacing6)
        .padding(.vertical, line.kind == .blank ? 2 : UIMetrics.spacing3)
        .background(isHighlighted ? MuxyTheme.surface.opacity(0.9) : Color.clear)
        .overlay(alignment: .leading) {
            if isHighlighted {
                Rectangle()
                    .fill(MuxyTheme.accent)
                    .frame(width: 2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch line.kind {
        case .blank:
            "Blank line"
        case .note:
            line.displayText
        case let .task(isDone):
            isDone ? "Done: \(line.displayText)" : "Task: \(line.displayText)"
        }
    }
}

private struct RichInputPreviewKeyCapture: NSViewRepresentable {
    let focusToken: Int
    let onArrowUp: () -> Void
    let onArrowDown: () -> Void
    let onToggleTask: () -> Void
    let onCopyAll: () -> Void
    let onCopyLine: () -> Void
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> RichInputPreviewKeyCaptureView {
        let view = RichInputPreviewKeyCaptureView()
        configure(view)
        context.coordinator.lastToken = focusToken
        view.requestFocusClaim()
        return view
    }

    func updateNSView(_ nsView: RichInputPreviewKeyCaptureView, context: Context) {
        configure(nsView)
        if context.coordinator.lastToken != focusToken {
            context.coordinator.lastToken = focusToken
            nsView.requestFocusClaim()
        }
    }

    private func configure(_ view: RichInputPreviewKeyCaptureView) {
        view.onArrowUp = onArrowUp
        view.onArrowDown = onArrowDown
        view.onToggleTask = onToggleTask
        view.onCopyAll = onCopyAll
        view.onCopyLine = onCopyLine
        view.onDismiss = onDismiss
    }

    final class Coordinator {
        var lastToken: Int = .min
    }
}

private enum RichInputPreviewKey: UInt16 {
    case arrowDown = 125
    case arrowUp = 126
    case returnKey = 36
    case keypadEnter = 76
    case escape = 53
    case space = 49
    case c = 8
}

private final class RichInputPreviewKeyCaptureView: NSView {
    var onArrowUp: (() -> Void)?
    var onArrowDown: (() -> Void)?
    var onToggleTask: (() -> Void)?
    var onCopyAll: (() -> Void)?
    var onCopyLine: (() -> Void)?
    var onDismiss: (() -> Void)?

    private var focusClaimPending = false

    override var acceptsFirstResponder: Bool { true }

    func requestFocusClaim() {
        if window != nil {
            window?.makeFirstResponder(self)
            return
        }
        focusClaimPending = true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard focusClaimPending, let window else { return }
        focusClaimPending = false
        window.makeFirstResponder(self)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }
        guard event.keyCode == RichInputPreviewKey.c.rawValue else {
            return super.performKeyEquivalent(with: event)
        }
        if event.modifierFlags.contains(.shift) {
            onCopyLine?()
        } else {
            onCopyAll?()
        }
        return true
    }

    override func keyDown(with event: NSEvent) {
        guard let key = RichInputPreviewKey(rawValue: event.keyCode) else {
            super.keyDown(with: event)
            return
        }
        switch key {
        case .arrowUp:
            onArrowUp?()
        case .arrowDown:
            onArrowDown?()
        case .space,
             .returnKey,
             .keypadEnter:
            onToggleTask?()
        case .escape:
            onDismiss?()
        case .c:
            break
        }
    }
}

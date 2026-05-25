import Foundation

enum ProjectWorkspaceMarkdown {
    static func compose(_ document: ProjectInspectorDocument) -> String {
        var parts: [String] = []
        let notes = document.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !notes.isEmpty {
            parts.append(document.notes)
        }
        let openTodos = document.todos.filter { !$0.isDone }.sorted { $0.updatedAt > $1.updatedAt }
        let doneTodos = document.todos.filter(\.isDone).sorted { $0.updatedAt > $1.updatedAt }
        let orderedTodos = openTodos + doneTodos
        if !orderedTodos.isEmpty {
            if !parts.isEmpty { parts.append("") }
            parts.append(contentsOf: orderedTodos.map(todoLine))
        }
        return parts.joined(separator: "\n")
    }

    static func apply(_ markdown: String, to document: inout ProjectInspectorDocument, now: Date = Date()) {
        var notesLines: [String] = []
        var todos: [ProjectTodoItem] = []
        let lines = markdown.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)

        for lineSubsequence in lines {
            let line = String(lineSubsequence)
            if let parsed = parseTodoLine(line, now: now) {
                todos.append(parsed)
                continue
            }
            notesLines.append(line)
        }

        while notesLines.last?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
            notesLines.removeLast()
        }

        document.notes = notesLines.joined(separator: "\n")
        document.todos = todos
    }

    private static func todoLine(_ item: ProjectTodoItem) -> String {
        let marker = item.isDone ? "- [x] " : "- [ ] "
        return marker + item.title
    }

    static func previewLines(from markdown: String) -> [RichInputPreviewLine] {
        let lines = markdown.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        return lines.enumerated().map { index, subsequence in
            let rawLine = String(subsequence)
            if rawLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return RichInputPreviewLine(
                    lineIndex: index,
                    rawLine: rawLine,
                    displayText: "",
                    kind: .blank
                )
            }
            if let task = parseTodoLine(rawLine, now: Date()) {
                return RichInputPreviewLine(
                    lineIndex: index,
                    rawLine: rawLine,
                    displayText: task.title,
                    kind: .task(isDone: task.isDone)
                )
            }
            return RichInputPreviewLine(
                lineIndex: index,
                rawLine: rawLine,
                displayText: rawLine,
                kind: .note
            )
        }
    }

    static func toggleTaskLine(at lineIndex: Int, in markdown: String) -> String? {
        var lines = markdown.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).map(String.init)
        guard lineIndex >= 0, lineIndex < lines.count else { return nil }

        let rawLine = lines[lineIndex]
        guard parseTodoLine(rawLine, now: Date()) != nil else { return nil }

        let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 6 else { return nil }

        let markerIndex = trimmed.index(trimmed.startIndex, offsetBy: 3)
        let closeIndex = trimmed.index(trimmed.startIndex, offsetBy: 4)
        guard trimmed[closeIndex] == "]" else { return nil }

        let marker = trimmed[markerIndex]
        let nextMarker: Character = marker == " " ? "x" : " "
        var trimmedCharacters = Array(trimmed)
        trimmedCharacters[3] = nextMarker
        let leadingWhitespace = String(rawLine.prefix(rawLine.count - trimmed.count))
        lines[lineIndex] = leadingWhitespace + String(trimmedCharacters)
        return lines.joined(separator: "\n")
    }

    private static func parseTodoLine(_ line: String, now: Date) -> ProjectTodoItem? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("- [") else { return nil }
        guard trimmed.count >= 6 else { return nil }

        let markerIndex = trimmed.index(trimmed.startIndex, offsetBy: 3)
        let closeIndex = trimmed.index(trimmed.startIndex, offsetBy: 4)
        guard trimmed[closeIndex] == "]" else { return nil }

        let marker = trimmed[markerIndex]
        guard marker == " " || marker == "x" || marker == "X" else { return nil }

        let afterMarker = trimmed.index(closeIndex, offsetBy: 1)
        guard afterMarker < trimmed.endIndex, trimmed[afterMarker] == " " else { return nil }

        let titleStart = trimmed.index(after: afterMarker)
        let title = String(trimmed[titleStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return nil }

        return ProjectTodoItem(title: title, isDone: marker != " ", createdAt: now, updatedAt: now)
    }
}

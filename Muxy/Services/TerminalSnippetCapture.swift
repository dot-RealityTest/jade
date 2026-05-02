import Foundation

enum TerminalSnippetCapture {
    static func command(from text: String?) -> String? {
        guard let text else { return nil }
        let command = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return command.isEmpty ? nil : command
    }

    static func title(for command: String) -> String {
        let fallback = "Snippet"
        guard let firstLine = command
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else { return fallback }

        let normalized = strippedPrompt(from: firstLine.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !normalized.isEmpty else { return fallback }
        guard normalized.count > 42 else { return normalized }
        return "\(normalized.prefix(39))..."
    }

    @MainActor
    @discardableResult
    static func save(command rawCommand: String, scope: SnippetScope, store: SnippetsStore) -> Snippet? {
        guard let command = command(from: rawCommand) else { return nil }
        store.selectScope(scope)
        return store.add(Snippet(
            name: title(for: command),
            command: command,
            tags: defaultTags(for: scope)
        ))
    }

    private static func defaultTags(for scope: SnippetScope) -> [String] {
        scope.id.hasPrefix("remote-") ? ["linux"] : []
    }

    private static func strippedPrompt(from line: String) -> String {
        for prefix in ["$ ", "> ", "% ", "❯ ", "➜ "] where line.hasPrefix(prefix) {
            return String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return line
    }
}

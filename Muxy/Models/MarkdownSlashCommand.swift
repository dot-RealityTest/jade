import Foundation

struct MarkdownSlashCommand: Identifiable, Equatable {
    let id: String
    let title: String
    let detail: String
    let symbolName: String
    let keywords: [String]
    let insertion: String

    static let catalog: [MarkdownSlashCommand] = [
        MarkdownSlashCommand(
            id: "todo",
            title: "To-do",
            detail: "Checkbox task",
            symbolName: "checkmark.square",
            keywords: ["todo", "task", "checkbox", "check"],
            insertion: "- [ ] "
        ),
        MarkdownSlashCommand(
            id: "bullet",
            title: "Bullet list",
            detail: "Unordered list item",
            symbolName: "list.bullet",
            keywords: ["bullet", "list", "ul"],
            insertion: "- "
        ),
        MarkdownSlashCommand(
            id: "numbered",
            title: "Numbered list",
            detail: "Ordered list item",
            symbolName: "list.number",
            keywords: ["numbered", "ordered", "ol", "number"],
            insertion: "1. "
        ),
        MarkdownSlashCommand(
            id: "heading1",
            title: "Heading 1",
            detail: "Large section title",
            symbolName: "textformat.size.larger",
            keywords: ["h1", "heading", "title"],
            insertion: "# "
        ),
        MarkdownSlashCommand(
            id: "heading2",
            title: "Heading 2",
            detail: "Medium section title",
            symbolName: "textformat.size",
            keywords: ["h2", "heading", "subtitle"],
            insertion: "## "
        ),
        MarkdownSlashCommand(
            id: "heading3",
            title: "Heading 3",
            detail: "Small section title",
            symbolName: "textformat.size.smaller",
            keywords: ["h3", "heading"],
            insertion: "### "
        ),
        MarkdownSlashCommand(
            id: "quote",
            title: "Quote",
            detail: "Indented quote block",
            symbolName: "text.quote",
            keywords: ["quote", "blockquote"],
            insertion: "> "
        ),
        MarkdownSlashCommand(
            id: "code",
            title: "Code block",
            detail: "Fenced code snippet",
            symbolName: "chevron.left.forwardslash.chevron.right",
            keywords: ["code", "snippet", "fence"],
            insertion: "```\n\n```"
        ),
        MarkdownSlashCommand(
            id: "divider",
            title: "Divider",
            detail: "Horizontal rule",
            symbolName: "minus",
            keywords: ["divider", "hr", "line", "rule"],
            insertion: "---\n"
        ),
    ]
}

struct MarkdownSlashCommandContext: Equatable {
    let query: String
    let replaceRange: NSRange
}

struct MarkdownSlashCommandApplyRequest: Equatable {
    let token: UUID
    let command: MarkdownSlashCommand
    let replaceRange: NSRange
}

enum MarkdownSlashCommandSession {
    static func context(in text: String, selectedLocation: Int) -> MarkdownSlashCommandContext? {
        let ns = text as NSString
        let length = ns.length
        guard length > 0 else { return nil }
        let location = min(max(selectedLocation, 0), length)

        var lineStart = 0
        var lineEnd = 0
        var contentsEnd = 0
        ns.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: location, length: 0))

        let linePrefixLength = location - lineStart
        guard linePrefixLength > 0 else { return nil }
        let prefixRange = NSRange(location: lineStart, length: linePrefixLength)
        let prefix = ns.substring(with: prefixRange)

        guard let slashIndex = prefix.lastIndex(of: "/") else { return nil }
        let beforeSlash = prefix[..<slashIndex]
        guard beforeSlash.isEmpty || beforeSlash.last?.isWhitespace == true else { return nil }

        let queryStart = prefix.index(after: slashIndex)
        let query = String(prefix[queryStart...])
        guard query.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else { return nil }

        let slashOffset = prefix.distance(from: prefix.startIndex, to: slashIndex)
        let replaceStart = lineStart + slashOffset
        let replaceLength = linePrefixLength - slashOffset
        return MarkdownSlashCommandContext(
            query: query,
            replaceRange: NSRange(location: replaceStart, length: replaceLength)
        )
    }

    static func filteredCommands(query: String) -> [MarkdownSlashCommand] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return MarkdownSlashCommand.catalog }
        return MarkdownSlashCommand.catalog.filter { command in
            command.title.lowercased().contains(trimmed)
                || command.id.contains(trimmed)
                || command.keywords.contains(where: { $0.contains(trimmed) || trimmed.contains($0) })
        }
    }

    static func apply(
        command: MarkdownSlashCommand,
        replaceRange: NSRange,
        in text: String,
        selectedLocation: Int
    ) -> (text: String, selectedLocation: Int) {
        let ns = text as NSString
        guard replaceRange.location >= 0,
              replaceRange.location + replaceRange.length <= ns.length
        else { return (text, selectedLocation) }

        let prefix = ns.substring(to: replaceRange.location)
        let suffix = ns.substring(from: replaceRange.location + replaceRange.length)
        let insertion = command.insertion

        var nextText = prefix + insertion + suffix
        var nextLocation = replaceRange.location + (insertion as NSString).length

        if command.id == "code" {
            let cursorOffset = (insertion as NSString).range(of: "\n\n").location
            if cursorOffset != NSNotFound {
                nextLocation = replaceRange.location + cursorOffset + 1
            }
        }

        return (nextText, nextLocation)
    }
}

import Foundation

enum ObsidianNotePathBuilder {
    static func inboxNotePath(inboxFolder: String, titleHint: String?) -> String {
        let folder = inboxFolder
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let timestamp = filenameTimestamp()
        let slug = slugify(titleHint ?? "capture")
        if folder.isEmpty {
            return "\(timestamp)-\(slug).md"
        }
        return "\(folder)/\(timestamp)-\(slug).md"
    }

    static func slugify(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = trimmed.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? "capture"
        var slug = firstLine.lowercased().map { character -> Character in
            if character.isLetter || character.isNumber {
                return character
            }
            if character == " " || character == "-" || character == "_" {
                return "-"
            }
            return "-"
        }
        var normalized = String(slug)
        while normalized.contains("--") {
            normalized = normalized.replacingOccurrences(of: "--", with: "-")
        }
        normalized = normalized.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        if normalized.isEmpty {
            return "capture"
        }
        return String(normalized.prefix(48))
    }

    static func title(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstLine = trimmed.split(separator: "\n", maxSplits: 1).first else {
            return "Jade capture"
        }
        let title = String(firstLine).trimmingCharacters(in: .whitespacesAndNewlines)
        if title.isEmpty {
            return "Jade capture"
        }
        return String(title.prefix(120))
    }

    private static func filenameTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
    }
}

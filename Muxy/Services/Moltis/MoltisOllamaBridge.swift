import Foundation

enum MoltisOllamaBridge {
    static func normalizedBaseURL(_ raw: String) -> String {
        var url = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if url.isEmpty {
            url = "http://localhost:11434"
        }
        while url.hasSuffix("/") {
            url.removeLast()
        }
        if url.hasSuffix("/v1") {
            return url
        }
        return "\(url)/v1"
    }

    static func resolvedModel(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "llama3.2"
        }
        return trimmed
    }

    static func tomlQuoted(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }
}

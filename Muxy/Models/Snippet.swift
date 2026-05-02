import Foundation

struct Snippet: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var description: String
    var command: String
    var tags: [String]
    var variableDefaults: [String: String]

    init(
        id: UUID = UUID(),
        name: String = "",
        description: String = "",
        command: String = "",
        tags: [String] = [],
        variableDefaults: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.command = command
        self.tags = Self.normalizedTags(from: tags)
        self.variableDefaults = Self.normalizedVariableDefaults(variableDefaults)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case command
        case tags
        case variableDefaults
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        command = try container.decodeIfPresent(String.self, forKey: .command) ?? ""
        tags = try Self.normalizedTags(from: container.decodeIfPresent([String].self, forKey: .tags) ?? [])
        variableDefaults = try Self.normalizedVariableDefaults(
            container.decodeIfPresent([String: String].self, forKey: .variableDefaults) ?? [:]
        )
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedDescription: String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedCommand: String {
        command.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayName: String {
        guard !trimmedName.isEmpty else { return Self.commandTitle(trimmedCommand) }
        return trimmedName
    }

    var isRunnable: Bool {
        !trimmedCommand.isEmpty
    }

    var variables: [String] {
        Self.variables(in: trimmedCommand)
    }

    var hasVariables: Bool {
        !variables.isEmpty
    }

    func resolvedCommand(values: [String: String]) -> String {
        var resolved = trimmedCommand
        for variable in variables {
            let value = values[variable] ?? variableDefaults[variable] ?? ""
            resolved = resolved.replacingOccurrences(of: "{\(variable)}", with: value)
        }
        return resolved
    }

    static func normalizedTags(from text: String) -> [String] {
        normalizedTags(from: text.split { character in
            character == "," || character == " " || character == "\n" || character == "\t"
        }.map(String.init))
    }

    static func normalizedTags(from tags: [String]) -> [String] {
        var seen: Set<String> = []
        var normalized: [String] = []
        for tag in tags {
            let value = tag
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
                .lowercased()
            guard !value.isEmpty, !seen.contains(value) else { continue }
            seen.insert(value)
            normalized.append(value)
        }
        return normalized
    }

    static func variables(in command: String) -> [String] {
        let pattern = #"\{([A-Za-z_][A-Za-z0-9_-]*)\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(command.startIndex ..< command.endIndex, in: command)
        var seen: Set<String> = []
        var variables: [String] = []
        for match in regex.matches(in: command, range: range) {
            guard let matchRange = Range(match.range(at: 1), in: command) else { continue }
            let variable = String(command[matchRange])
            guard !seen.contains(variable) else { continue }
            seen.insert(variable)
            variables.append(variable)
        }
        return variables
    }

    static func normalizedVariableDefaults(_ defaults: [String: String], command: String? = nil) -> [String: String] {
        let allowed = command.map { Set(variables(in: $0)) }
        var normalized: [String: String] = [:]
        for key in defaults.keys.sorted() {
            let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedKey.isEmpty else { continue }
            if let allowed, !allowed.contains(trimmedKey) { continue }
            normalized[trimmedKey] = defaults[key]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }
        return normalized
    }

    static func commandTitle(_ command: String) -> String {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Command" }
        return String(trimmed.prefix(32))
    }
}

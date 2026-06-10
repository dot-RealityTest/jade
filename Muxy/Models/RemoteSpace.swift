import Foundation

struct RemoteSpace: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var command: String
    var colorID: String?
    var user: String
    var host: String
    var port: Int?
    var identityFile: String
    var jumpHost: String
    var startupCommands: [String]
    var themeName: String
    var storageKey: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case command
        case colorID
        case user
        case host
        case port
        case identityFile
        case jumpHost
        case startupCommands
        case themeName
        case storageKey
    }

    init(
        id: UUID = UUID(),
        name: String,
        command: String = "",
        colorID: String? = nil,
        user: String = "",
        host: String = "",
        port: Int? = nil,
        identityFile: String = "",
        jumpHost: String = "",
        startupCommands: [String] = [],
        themeName: String = "",
        storageKey: String = ""
    ) {
        self.id = id
        self.name = name
        self.command = command
        self.colorID = colorID
        self.user = user
        self.host = host
        self.port = port
        self.identityFile = identityFile
        self.jumpHost = jumpHost
        self.startupCommands = startupCommands
        self.themeName = themeName
        self.storageKey = storageKey
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        command = try container.decodeIfPresent(String.self, forKey: .command) ?? ""
        colorID = try container.decodeIfPresent(String.self, forKey: .colorID)
        user = try container.decodeIfPresent(String.self, forKey: .user) ?? ""
        host = try container.decodeIfPresent(String.self, forKey: .host) ?? ""
        port = try container.decodeIfPresent(Int.self, forKey: .port)
        identityFile = try container.decodeIfPresent(String.self, forKey: .identityFile) ?? ""
        jumpHost = try container.decodeIfPresent(String.self, forKey: .jumpHost) ?? ""
        startupCommands = try container.decodeIfPresent([String].self, forKey: .startupCommands) ?? []
        themeName = try container.decodeIfPresent(String.self, forKey: .themeName) ?? ""
        storageKey = try container.decodeIfPresent(String.self, forKey: .storageKey) ?? ""
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedCommand: String {
        command.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedUser: String {
        user.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedHost: String {
        host.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedIdentityFile: String {
        identityFile.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedJumpHost: String {
        jumpHost.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedThemeName: String {
        themeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedStartupCommands: [String] {
        startupCommands.compactMap { command in
            let value = command.trimmingCharacters(in: .whitespacesAndNewlines)
            return value.isEmpty ? nil : value
        }
    }

    var displayName: String {
        trimmedName.isEmpty ? "Remote" : trimmedName
    }

    var isConnectable: Bool {
        !connectionCommand.isEmpty
    }

    var connectionSummary: String {
        guard !trimmedHost.isEmpty else { return trimmedCommand }
        let target = trimmedUser.isEmpty ? trimmedHost : "\(trimmedUser)@\(trimmedHost)"
        guard let port else { return target }
        return "\(target):\(port)"
    }

    var connectionCommand: String {
        guard !trimmedHost.isEmpty else { return trimmedCommand }
        var parts = ["ssh"]
        if !normalizedStartupCommands.isEmpty {
            parts.append("-t")
        }
        if let port {
            parts.append("-p")
            parts.append(String(port))
        }
        if !trimmedIdentityFile.isEmpty {
            parts.append("-i")
            parts.append(trimmedIdentityFile)
        }
        if !trimmedJumpHost.isEmpty {
            parts.append("-J")
            parts.append(trimmedJumpHost)
        }
        parts.append(trimmedUser.isEmpty ? trimmedHost : "\(trimmedUser)@\(trimmedHost)")
        if !normalizedStartupCommands.isEmpty {
            parts.append("\(normalizedStartupCommands.joined(separator: " && ")); exec ${SHELL:-/bin/sh} -l")
        }
        return parts.map(ShellEscaper.escape).joined(separator: " ")
    }

    var effectiveThemeName: String? {
        let theme = trimmedThemeName
        guard !theme.isEmpty else { return Self.defaultThemeName(for: displayName) }
        return theme
    }

    var storageSlug: String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let parts = displayName.lowercased().unicodeScalars.map { scalar in
            allowed.contains(scalar) ? String(scalar) : "-"
        }
        let slug = parts.joined()
            .split(separator: "-")
            .joined(separator: "-")
        return slug.isEmpty ? id.uuidString.lowercased() : slug
    }

    var resolvedStorageKey: String {
        storageKey.isEmpty ? storageSlug : storageKey
    }

    static var remoteSpacesRoot: URL {
        MuxyFileStorage.appSupportDirectory()
            .appendingPathComponent("remote-spaces", isDirectory: true)
    }

    func stableStorageKey() -> String {
        resolvedStorageKey
    }

    func backingDirectory(create: Bool = true) -> URL {
        let root = Self.remoteSpacesRoot
        if create {
            try? FileManager.default.createDirectory(
                at: root,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: FilePermissions.privateDirectory]
            )
        }
        let directory = root.appendingPathComponent(resolvedStorageKey, isDirectory: true)
        if create {
            try? FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: FilePermissions.privateDirectory]
            )
        }
        return directory
    }

    var snippetsFileURL: URL {
        backingDirectory().appendingPathComponent("snippets.json")
    }

    static func parsedSSHCommand(_ command: String) -> RemoteSpace? {
        let tokens = command.split { $0 == " " || $0 == "\t" || $0 == "\n" }.map(String.init)
        guard tokens.first == "ssh" else { return nil }
        var port: Int?
        var identityFile = ""
        var jumpHost = ""
        var target = ""
        var index = 1

        while index < tokens.count {
            let token = tokens[index]
            if token == "-p", index + 1 < tokens.count {
                port = Int(tokens[index + 1])
                index += 2
                continue
            }
            if token == "-i", index + 1 < tokens.count {
                identityFile = tokens[index + 1]
                index += 2
                continue
            }
            if token == "-J", index + 1 < tokens.count {
                jumpHost = tokens[index + 1]
                index += 2
                continue
            }
            if token.hasPrefix("-") {
                return nil
            }
            target = token
            break
        }

        guard !target.isEmpty else { return nil }
        let parts = target.split(separator: "@", maxSplits: 1).map(String.init)
        let user = parts.count == 2 ? parts[0] : ""
        let host = parts.count == 2 ? parts[1] : parts[0]
        guard !host.isEmpty else { return nil }
        return RemoteSpace(
            name: "",
            command: command,
            user: user,
            host: host,
            port: port,
            identityFile: identityFile,
            jumpHost: jumpHost
        )
    }

    static func defaultThemeName(for name: String) -> String? {
        let lowered = name.lowercased()
        if lowered.contains("zen") {
            return "Muxy Zen"
        }
        if lowered.contains("alien") || lowered.contains("nvidia") {
            return "Muxy Alienware"
        }
        return nil
    }
}

import Foundation

struct RemoteSpace: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var command: String
    var colorID: String?

    init(id: UUID = UUID(), name: String, command: String, colorID: String? = nil) {
        self.id = id
        self.name = name
        self.command = command
        self.colorID = colorID
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedCommand: String {
        command.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var displayName: String {
        trimmedName.isEmpty ? "Remote" : trimmedName
    }

    var isConnectable: Bool {
        !trimmedCommand.isEmpty
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

    func backingDirectory(create: Bool = true) -> URL {
        let root = MuxyFileStorage.appSupportDirectory()
            .appendingPathComponent("remote-spaces", isDirectory: true)
        if create {
            try? FileManager.default.createDirectory(
                at: root,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: FilePermissions.privateDirectory]
            )
        }
        let directory = root.appendingPathComponent(storageSlug, isDirectory: true)
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
}

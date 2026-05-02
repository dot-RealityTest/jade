import Foundation
import os

private let remoteSpacesLogger = Logger(subsystem: "app.muxy", category: "RemoteSpacesStore")

protocol RemoteSpacesPersisting {
    func loadRemoteSpaces() throws -> [RemoteSpace]
    func saveRemoteSpaces(_ spaces: [RemoteSpace]) throws
}

final class FileRemoteSpacesPersistence: RemoteSpacesPersisting {
    private let store: CodableFileStore<[RemoteSpace]>

    init(fileURL: URL = MuxyFileStorage.fileURL(filename: "remote-spaces.json")) {
        store = CodableFileStore(
            fileURL: fileURL,
            options: CodableFileStoreOptions(
                prettyPrinted: true,
                sortedKeys: true,
                filePermissions: FilePermissions.privateFile
            )
        )
    }

    func loadRemoteSpaces() throws -> [RemoteSpace] {
        try store.load() ?? []
    }

    func saveRemoteSpaces(_ spaces: [RemoteSpace]) throws {
        try store.save(spaces)
    }
}

@MainActor
@Observable
final class RemoteSpacesStore {
    static let shared = RemoteSpacesStore()

    private(set) var spaces: [RemoteSpace] = []
    private let persistence: any RemoteSpacesPersisting

    init(persistence: any RemoteSpacesPersisting = FileRemoteSpacesPersistence()) {
        self.persistence = persistence
        load()
    }

    func filteredSpaces(matching query: String) -> [RemoteSpace] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return spaces }
        return spaces.filter { space in
            space.displayName.lowercased().contains(query)
                || space.trimmedCommand.lowercased().contains(query)
                || space.connectionSummary.lowercased().contains(query)
                || space.connectionCommand.lowercased().contains(query)
        }
    }

    func space(forProjectPath path: String) -> RemoteSpace? {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        return spaces.first {
            $0.backingDirectory(create: false).standardizedFileURL.path == standardizedPath
        }
    }

    @discardableResult
    func add(_ space: RemoteSpace) -> RemoteSpace? {
        guard let space = sanitized(space) else { return nil }
        spaces.append(space)
        save()
        return space
    }

    func update(_ space: RemoteSpace) {
        guard let index = spaces.firstIndex(where: { $0.id == space.id }),
              let space = sanitized(space)
        else { return }
        spaces[index] = space
        save()
    }

    func delete(_ space: RemoteSpace) {
        spaces.removeAll { $0.id == space.id }
        save()
    }

    func replaceAll(_ spaces: [RemoteSpace]) {
        self.spaces = spaces.compactMap(sanitized)
        save()
    }

    private func load() {
        do {
            spaces = try persistence.loadRemoteSpaces().compactMap(sanitized)
        } catch {
            remoteSpacesLogger.error("Failed to load remote spaces: \(error.localizedDescription)")
            spaces = []
        }
    }

    private func save() {
        do {
            try persistence.saveRemoteSpaces(spaces)
        } catch {
            remoteSpacesLogger.error("Failed to save remote spaces: \(error.localizedDescription)")
        }
    }

    private func sanitized(_ space: RemoteSpace) -> RemoteSpace? {
        let name = space.trimmedName
        let parsed = space.trimmedHost.isEmpty ? RemoteSpace.parsedSSHCommand(space.trimmedCommand) : nil
        let host = space.trimmedHost.isEmpty ? parsed?.trimmedHost ?? "" : space.trimmedHost
        let command = space.trimmedCommand
        let port = normalizedPort(space.port ?? parsed?.port)
        let user = space.trimmedUser.isEmpty ? parsed?.trimmedUser ?? "" : space.trimmedUser
        let identityFile = space.trimmedIdentityFile.isEmpty ? parsed?.trimmedIdentityFile ?? "" : space.trimmedIdentityFile
        let jumpHost = space.trimmedJumpHost.isEmpty ? parsed?.trimmedJumpHost ?? "" : space.trimmedJumpHost
        let startupCommands = space.normalizedStartupCommands
        guard !host.isEmpty || !command.isEmpty else { return nil }
        return RemoteSpace(
            id: space.id,
            name: name.isEmpty ? "Remote" : name,
            command: command,
            colorID: space.colorID,
            user: user,
            host: host,
            port: port,
            identityFile: identityFile,
            jumpHost: jumpHost,
            startupCommands: startupCommands
        )
    }

    private func normalizedPort(_ port: Int?) -> Int? {
        guard let port, (1 ... 65535).contains(port) else { return nil }
        return port
    }
}

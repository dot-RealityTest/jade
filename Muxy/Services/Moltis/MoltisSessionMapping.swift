import Foundation

struct MoltisSessionMapping: Codable, Equatable {
    var projectID: UUID
    var sessionKey: String
    var updatedAt: Date

    static func sessionKey(for projectID: UUID) -> String {
        "jade-\(projectID.uuidString.lowercased())"
    }
}

enum MoltisSessionMappingStore {
    private static let store = CodableFileStore<[String: MoltisSessionMapping]>(
        fileURL: MoltisStoragePaths.sessionMappingURL(),
        options: CodableFileStoreOptions(
            prettyPrinted: true,
            sortedKeys: true,
            filePermissions: FilePermissions.privateFile
        )
    )

    static func sessionKey(for projectID: UUID) -> String {
        if let stored = loadAll()[projectID.uuidString] {
            return stored.sessionKey
        }
        return MoltisSessionMapping.sessionKey(for: projectID)
    }

    static func record(projectID: UUID, sessionKey: String) {
        var all = loadAll()
        all[projectID.uuidString] = MoltisSessionMapping(
            projectID: projectID,
            sessionKey: sessionKey,
            updatedAt: Date()
        )
        try? store.save(all)
    }

    private static func loadAll() -> [String: MoltisSessionMapping] {
        (try? store.load()) ?? [:]
    }
}

import Foundation

enum MoltisStoragePaths {
    static func root(create: Bool = true) -> URL {
        let dir = MuxyFileStorage.appSupportDirectory(create: create)
            .appendingPathComponent("moltis", isDirectory: true)
        guard create else { return dir }
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: FilePermissions.privateDirectory]
        )
        return dir
    }

    static func configDirectory(create: Bool = true) -> URL {
        let dir = root(create: create).appendingPathComponent("config", isDirectory: true)
        guard create else { return dir }
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: FilePermissions.privateDirectory]
        )
        return dir
    }

    static func dataDirectory(create: Bool = true) -> URL {
        let dir = root(create: create).appendingPathComponent("data", isDirectory: true)
        guard create else { return dir }
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: FilePermissions.privateDirectory]
        )
        return dir
    }

    static func workspaceRoot(for projectID: UUID, create: Bool = true) -> URL {
        let dir = root(create: create)
            .appendingPathComponent("workspaces", isDirectory: true)
            .appendingPathComponent(projectID.uuidString, isDirectory: true)
        guard create else { return dir }
        try? FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: FilePermissions.privateDirectory]
        )
        return dir
    }

    static func sessionMappingURL() -> URL {
        root().appendingPathComponent("session-mapping.json")
    }
}

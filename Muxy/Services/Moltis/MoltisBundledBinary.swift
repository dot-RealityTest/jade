import Foundation

enum MoltisBundledBinary {
    static func executableURL() -> URL? {
        if let bundled = Bundle.main.url(forResource: "moltis", withExtension: nil) {
            return bundled
        }
        let devPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/moltis")
        if FileManager.default.isExecutableFile(atPath: devPath.path) {
            return devPath
        }
        return nil
    }

    static func shareDirectoryURL() -> URL? {
        if let bundled = Bundle.main.url(forResource: "moltis-share", withExtension: nil) {
            return bundled
        }
        let devPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/moltis-share")
        if FileManager.default.fileExists(atPath: devPath.path) {
            return devPath
        }
        return nil
    }

    static var isAvailable: Bool {
        executableURL() != nil && shareDirectoryURL() != nil
    }
}

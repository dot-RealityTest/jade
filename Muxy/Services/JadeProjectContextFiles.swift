import Foundation

enum JadeProjectContextFiles {
    static let todoNames = ["todo.md", "TODO.md"]
    static let goalsNames = ["goals.md", "GOALS.md"]
    static let agentsNames = ["AGENTS.md", "agents.md"]
    static let projectMapNames = ["project-map.md", "project_map.md", "PROJECT_MAP.md", "project map.md"]

    static func todo(in projectPath: String) -> String? {
        firstExisting(in: projectPath, names: todoNames)
    }

    static func goals(in projectPath: String) -> String? {
        firstExisting(in: projectPath, names: goalsNames)
    }

    static func agents(in projectPath: String) -> String? {
        firstExisting(in: projectPath, names: agentsNames)
    }

    static func projectMap(in projectPath: String) -> String? {
        firstExisting(in: projectPath, names: projectMapNames)
    }

    static func firstExisting(in projectPath: String, names: [String]) -> String? {
        let base = URL(fileURLWithPath: projectPath, isDirectory: true)
        for name in names {
            let path = base.appendingPathComponent(name).path
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory), !isDirectory.boolValue {
                return path
            }
        }
        return nil
    }

    static func relativeName(for path: String, projectPath: String) -> String {
        let projectURL = URL(fileURLWithPath: projectPath, isDirectory: true).standardizedFileURL
        let fileURL = URL(fileURLWithPath: path).standardizedFileURL
        if fileURL.path.hasPrefix(projectURL.path + "/") {
            return String(fileURL.path.dropFirst(projectURL.path.count + 1))
        }
        return fileURL.lastPathComponent
    }
}

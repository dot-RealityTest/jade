import Foundation

struct JadeProjectContext: Equatable {
    let todoPath: String?
    let goalsPath: String?
    let agentsPath: String?
    let projectMapPath: String?

    var availableSourceLabels: [String] {
        [todoPath, goalsPath, agentsPath, projectMapPath]
            .compactMap(\.self)
            .map { URL(fileURLWithPath: $0).lastPathComponent }
    }
}

struct JadeStructuredProjectContext: Equatable {
    let projectPath: String
    let paths: JadeProjectContext
    let openTodos: [String]
    let goals: [String]
    let mapEntries: [String]
    let agentsExcerpt: String?
    let projectMapExcerpt: String?

    var firstOpenTodo: String? { openTodos.first }
    var firstGoal: String? { goals.first }
}

enum JadeProjectContextReader {
    static func load(projectPath: String) -> JadeProjectContext {
        paths(in: projectPath)
    }

    static func loadStructured(projectPath: String) -> JadeStructuredProjectContext {
        let paths = paths(in: projectPath)
        let todoContent = readContent(at: paths.todoPath)
        let goalsContent = readContent(at: paths.goalsPath)
        let mapContent = readContent(at: paths.projectMapPath)

        return JadeStructuredProjectContext(
            projectPath: projectPath,
            paths: paths,
            openTodos: todoContent.map { openTodos(in: $0) } ?? [],
            goals: goalsContent.map { goalItems(in: $0) } ?? [],
            mapEntries: mapContent.map { bulletedItems(in: $0) } ?? [],
            agentsExcerpt: excerpt(from: paths.agentsPath),
            projectMapExcerpt: excerpt(from: paths.projectMapPath)
        )
    }

    static func firstOpenTodo(in content: String) -> String? {
        openTodos(in: content).first
    }

    static func firstGoalItem(in content: String) -> String? {
        goalItems(in: content).first
    }

    static func openTodos(in content: String) -> [String] {
        checkboxItems(in: content, marker: "- [ ]")
    }

    static func goalItems(in content: String) -> [String] {
        bulletedItems(in: content, excludingCheckboxLines: true)
    }

    static func bulletedItems(in content: String, excludingCheckboxLines: Bool = false) -> [String] {
        var items: [String] = []
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- ") else { continue }
            if excludingCheckboxLines, trimmed.hasPrefix("- [") { continue }
            let item = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            if !item.isEmpty, item != "-" {
                items.append(item)
            }
        }
        return items
    }

    static func excerpt(from path: String?, maxCharacters: Int = 280) -> String? {
        guard let path else { return nil }
        guard let content = readContent(at: path) else { return nil }
        let collapsed = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
            .joined(separator: " ")
        guard !collapsed.isEmpty else { return nil }
        if collapsed.count <= maxCharacters {
            return collapsed
        }
        return String(collapsed.prefix(maxCharacters)).trimmingCharacters(in: .whitespaces) + "…"
    }

    private static func paths(in projectPath: String) -> JadeProjectContext {
        JadeProjectContext(
            todoPath: JadeProjectContextFiles.todo(in: projectPath),
            goalsPath: JadeProjectContextFiles.goals(in: projectPath),
            agentsPath: JadeProjectContextFiles.agents(in: projectPath),
            projectMapPath: JadeProjectContextFiles.projectMap(in: projectPath)
        )
    }

    private static func readContent(at path: String?) -> String? {
        guard let path else { return nil }
        return try? String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
    }

    private static func checkboxItems(in content: String, marker: String) -> [String] {
        var items: [String] = []
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix(marker) else { continue }
            let item = trimmed
                .replacingOccurrences(of: marker, with: "")
                .trimmingCharacters(in: .whitespaces)
            if !item.isEmpty {
                items.append(item)
            }
        }
        return items
    }
}

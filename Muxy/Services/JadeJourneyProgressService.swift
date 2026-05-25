import Foundation

enum JadeJourneyProgressService {
    static func completeCurrentStep(projectPath: String, proposal: JourneyStepProposal) throws {
        if proposal.sourceFile == "todo.md" || proposal.sourceFile == "TODO.md" {
            try completeTodoItem(projectPath: projectPath, title: proposal.title)
        }

        guard JadeJourneyBootstrapService.isInitialized(projectPath: projectPath) else {
            return
        }

        let journeyPath = JadeJourneyLayout.journeyFile(in: projectPath)
        var content = try String(contentsOf: URL(fileURLWithPath: journeyPath), encoding: .utf8)
        let title = proposal.title

        let doneEntry = "- \(title) — \(ISO8601DateFormatter().string(from: Date()))"
        content = appendToDoneSection(content, entry: doneEntry)
        content = replaceSection(
            in: content,
            heading: "Next step",
            body: """
            What should we tackle next?

            ### Why
            Pick the next smallest step that moves the project forward.
            """
        )

        try content.write(to: URL(fileURLWithPath: journeyPath), atomically: true, encoding: .utf8)

        let achievementPath = URL(
            fileURLWithPath: JadeJourneyLayout.achievementsFolder(in: projectPath),
            isDirectory: true
        ).appendingPathComponent("\(ObsidianNotePathBuilder.slugify(title)).md")

        let achievementBody = """
        # \(title)

        Completed on \(ISO8601DateFormatter().string(from: Date())).
        """
        try achievementBody.write(to: achievementPath, atomically: true, encoding: .utf8)
    }

    private static func completeTodoItem(projectPath: String, title: String) throws {
        guard let todoPath = JadeProjectContextFiles.todo(in: projectPath) else { return }
        var lines = try String(contentsOf: URL(fileURLWithPath: todoPath), encoding: .utf8)
            .components(separatedBy: .newlines)
        var replaced = false
        for index in lines.indices {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("- [ ]") else { continue }
            let item = trimmed.replacingOccurrences(of: "- [ ]", with: "").trimmingCharacters(in: .whitespaces)
            if item == title {
                lines[index] = lines[index].replacingOccurrences(of: "- [ ]", with: "- [x]")
                replaced = true
                break
            }
        }
        guard replaced else { return }
        try lines.joined(separator: "\n").write(to: URL(fileURLWithPath: todoPath), atomically: true, encoding: .utf8)
    }

    private static func appendToDoneSection(_ markdown: String, entry: String) -> String {
        guard markdown.contains("## Done") else {
            return markdown + "\n\n## Done\n\(entry)\n"
        }
        return markdown.replacingOccurrences(of: "## Done\n", with: "## Done\n\(entry)\n")
    }

    private static func replaceSection(in markdown: String, heading: String, body: String) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        var output: [String] = []
        var index = 0
        while index < lines.count {
            let line = lines[index]
            if line.trimmingCharacters(in: .whitespaces) == "## \(heading)" {
                output.append(line)
                index += 1
                while index < lines.count {
                    let next = lines[index].trimmingCharacters(in: .whitespaces)
                    if next.hasPrefix("## ") {
                        break
                    }
                    index += 1
                }
                output.append(contentsOf: body.components(separatedBy: .newlines))
                continue
            }
            output.append(line)
            index += 1
        }
        return output.joined(separator: "\n")
    }
}

import Foundation

enum JadeJourneyReader {
    static func loadNextStepProposal(projectPath: String) throws -> JourneyStepProposal {
        if let fromProjectFiles = try loadFromProjectMarkdown(projectPath: projectPath) {
            return fromProjectFiles
        }
        return try loadFromJourneyFile(projectPath: projectPath)
    }

    private static func loadFromProjectMarkdown(projectPath: String) throws -> JourneyStepProposal? {
        let context = JadeProjectContextReader.load(projectPath: projectPath)

        if let todoPath = context.todoPath,
           let content = try? String(contentsOf: URL(fileURLWithPath: todoPath), encoding: .utf8),
           let title = JadeProjectContextReader.firstOpenTodo(in: content)
        {
            return makeProposal(
                title: title,
                summary: "Next open item from project todo list.",
                why: "Pulled from `\(JadeProjectContextFiles.relativeName(for: todoPath, projectPath: projectPath))`.",
                sourceFile: JadeProjectContextFiles.relativeName(for: todoPath, projectPath: projectPath),
                projectPath: projectPath
            )
        }

        if let goalsPath = context.goalsPath,
           let content = try? String(contentsOf: URL(fileURLWithPath: goalsPath), encoding: .utf8),
           let title = JadeProjectContextReader.firstGoalItem(in: content)
        {
            return makeProposal(
                title: title,
                summary: "Next goal from project goals file.",
                why: "Pulled from `\(JadeProjectContextFiles.relativeName(for: goalsPath, projectPath: projectPath))`.",
                sourceFile: JadeProjectContextFiles.relativeName(for: goalsPath, projectPath: projectPath),
                projectPath: projectPath
            )
        }

        return nil
    }

    private static func loadFromJourneyFile(projectPath: String) throws -> JourneyStepProposal {
        guard JadeJourneyBootstrapService.isInitialized(projectPath: projectPath) else {
            throw JadeJourneyError.notInitialized
        }

        let journeyURL = URL(fileURLWithPath: JadeJourneyLayout.journeyFile(in: projectPath))
        let content = try String(contentsOf: journeyURL, encoding: .utf8)
        let title = sectionBody(in: content, heading: "Next step")
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty && !$0.hasPrefix("#") }
            .map { String($0) }

        guard let title, !title.isEmpty else {
            throw JadeJourneyError.noNextStep
        }

        let why = sectionBody(in: content, heading: "Why", parent: "Next step")
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty && !$0.hasPrefix("#") }
            .map { String($0) } ?? "This is the current focus in .jade/journey.md."

        return makeProposal(
            title: title,
            summary: "Focus for this session: \(title)",
            why: why,
            sourceFile: ".jade/journey.md",
            projectPath: projectPath
        )
    }

    private static func makeProposal(
        title: String,
        summary: String,
        why: String,
        sourceFile: String,
        projectPath: String
    ) -> JourneyStepProposal {
        let ruleCheck = JadeJourneyRuleChecker.evaluate(
            title: title,
            summary: summary,
            projectPath: projectPath
        )
        return JourneyStepProposal(
            title: title,
            summary: summary,
            why: why,
            sourceFile: sourceFile,
            risk: ruleCheck.risk,
            blockedReason: ruleCheck.blockedReason,
            matchedRule: ruleCheck.matchedRule
        )
    }

    static func sectionBody(in markdown: String, heading: String, parent: String? = nil) -> String {
        let lines = markdown.components(separatedBy: .newlines)
        var inParent = parent == nil
        var capturing = false
        var level = 0
        var collected: [String] = []

        for line in lines {
            if let parent, line.hasPrefix("#") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed == "## \(parent)" {
                    inParent = true
                    capturing = false
                    continue
                }
                if inParent, trimmed.hasPrefix("## "), trimmed != "## \(parent)" {
                    break
                }
            }

            if line.hasPrefix("#") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed == "## \(heading)" || trimmed == "### \(heading)" {
                    if parent == nil || inParent {
                        capturing = true
                        level = trimmed.count(where: { $0 == "#" })
                        continue
                    }
                } else if capturing {
                    let nextLevel = trimmed.count(where: { $0 == "#" })
                    if nextLevel <= level {
                        break
                    }
                }
            }

            if capturing {
                collected.append(line)
            }
        }

        return collected.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

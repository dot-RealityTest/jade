import Foundation

enum ObsidianJourneyLogService {
    static func logSession(
        outcome: JourneySessionOutcome,
        proposal: JourneyStepProposal,
        projectName: String,
        projectPath: String,
        overriddenBlocker: Bool = false,
        settings: ObsidianMCPSettings
    ) async -> Result<String, Error> {
        guard settings.isEnabled else {
            return .failure(MCPClientError.notConfigured("Enable Obsidian MCP in Settings"))
        }
        guard settings.canSendNotes else {
            return .failure(MCPClientError.notConfigured("Configure vault, Python, and server.py in Settings"))
        }

        let slug = ObsidianNotePathBuilder.slugify(projectName)
        let stepSlug = ObsidianNotePathBuilder.slugify(proposal.title)
        let timestamp = ObsidianNotePathBuilder.sessionTimestamp()
        let notePath = "Jade/Logs/\(slug)/sessions/\(timestamp)-\(stepSlug).md"
        let context = JadeProjectContextReader.load(projectPath: projectPath)
        let content = JadeJourneyLogFormatter.sessionNote(
            input: JadeJourneyLogFormatter.SessionNoteInput(
                outcome: outcome,
                proposal: proposal,
                projectName: projectName,
                projectPath: projectPath,
                context: context,
                overriddenBlocker: overriddenBlocker
            )
        )

        do {
            let configuration = MCPStdioSessionConfiguration(
                pythonPath: settings.pythonPath,
                serverScriptPath: settings.serverScriptPath,
                environment: settings.serverEnvironment
            )
            var tags = settings.defaultTags
            tags.append("project-log")
            tags.append("session-log")
            tags.append(slug)
            tags.append(outcome.rawValue)

            let encodedArguments = try JSONSerialization.data(withJSONObject: [
                "path": notePath,
                "content": content,
                "title": proposal.title,
                "tags": tags,
            ])
            let response = try await MCPStdioSession.callTool(
                configuration: configuration,
                toolName: "create_note",
                encodedArguments: encodedArguments
            )
            let savedPath = response["path"] as? String ?? notePath
            return .success(savedPath)
        } catch {
            return .failure(error)
        }
    }
}

enum JadeJourneyLogFormatter {
    struct SessionNoteInput: Equatable {
        let outcome: JourneySessionOutcome
        let proposal: JourneyStepProposal
        let projectName: String
        let projectPath: String
        let context: JadeProjectContext
        let overriddenBlocker: Bool
    }

    static func sessionNote(input: SessionNoteInput) -> String {
        let outcome = input.outcome
        let proposal = input.proposal
        let projectName = input.projectName
        let projectPath = input.projectPath
        let context = input.context
        let overriddenBlocker = input.overriddenBlocker

        let date = ISO8601DateFormatter().string(from: Date()).prefix(10)
        let escapedProject = projectName.replacingOccurrences(of: "\"", with: "'")
        let source = proposal.sourceFile ?? "project markdown"

        var body = """
        ---
        type: project-session-log
        date: "\(date)"
        project: "\(escapedProject)"
        project_note: "\(escapedProject)"
        status: \(outcome.rawValue)
        source: "\(source)"
        tags:
          - project-log
          - session-log
          - jade
        ---

        # \(projectName) — \(date)

        **Project:** [[\(projectName)]]
        **Session Date:** \(date)
        **Status:** \(outcomeLabel(outcome))
        **Source:** `\(source)`

        ## What We Did

        - \(proposal.summary)
        - Step: \(proposal.title)

        ## Decisions

        - \(proposal.why)

        ## Files / Repos / Surfaces

        \(projectContextLines(context: context, projectPath: projectPath))

        """

        if let blocked = proposal.blockedReason {
            body += """

            ## Open Questions

            - Blocker: \(blocked)

            """
            if overriddenBlocker {
                body += "- User chose to override once and continue anyway.\n"
            }
        }

        body += """

        ## Next Moves

        - [ ] Next open item from `todo.md` or `goals.md`

        ## Links

        - Parent project: [[\(projectName)]]
        - Source file: `\(source)`
        """

        return body
    }

    private static func projectContextLines(context: JadeProjectContext, projectPath: String) -> String {
        var lines = ["- Project path: `\(projectPath)`"]
        if let path = context.todoPath {
            lines.append("- `\(JadeProjectContextFiles.relativeName(for: path, projectPath: projectPath))`")
        }
        if let path = context.goalsPath {
            lines.append("- `\(JadeProjectContextFiles.relativeName(for: path, projectPath: projectPath))`")
        }
        if let path = context.agentsPath {
            lines.append("- `\(JadeProjectContextFiles.relativeName(for: path, projectPath: projectPath))`")
        }
        if let path = context.projectMapPath {
            lines.append("- `\(JadeProjectContextFiles.relativeName(for: path, projectPath: projectPath))`")
        }
        if JadeJourneyBootstrapService.isInitialized(projectPath: projectPath) {
            lines.append("- `.jade/journey.md`")
            lines.append("- `.jade/rules.md`")
        }
        return lines.map { "\($0)" }.joined(separator: "\n")
    }

    private static func outcomeLabel(_ outcome: JourneySessionOutcome) -> String {
        switch outcome {
        case .started: "started"
        case .completed: "completed"
        case .skipped: "skipped"
        case .declined: "declined"
        case .blocked: "blocked"
        case .overridden: "overridden"
        }
    }
}

extension ObsidianNotePathBuilder {
    static func sessionTimestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
    }
}

import Foundation

enum ObsidianJourneyLogService {
    static func logSession(
        outcome: JourneySessionOutcome,
        proposal: JourneyStepProposal,
        projectName: String,
        projectPath: String,
        overriddenBlocker: Bool = false,
        settings: ObsidianCaptureSettings
    ) -> Result<String, Error> {
        guard settings.canSendCaptures else {
            return .failure(ObsidianCaptureError.notConfigured("Choose a logs folder in Settings first."))
        }

        let slug = ObsidianNotePathBuilder.slugify(projectName)
        let stepSlug = ObsidianNotePathBuilder.slugify(proposal.title)
        let timestamp = ObsidianNotePathBuilder.sessionTimestamp()
        let notePath = "Jade/Logs/\(slug)/sessions/\(timestamp)-\(stepSlug).md"
        let structured = JadeProjectContextReader.loadStructured(projectPath: projectPath)

        if case let .failure(error) = ObsidianProjectLogIndex.ensure(
            projectName: projectName,
            projectPath: projectPath,
            settings: settings
        ) {
            return .failure(error)
        }

        let content = JadeJourneyLogFormatter.sessionNote(
            input: JadeJourneyLogFormatter.SessionNoteInput(
                outcome: outcome,
                proposal: proposal,
                projectName: projectName,
                projectPath: projectPath,
                context: structured.paths,
                structured: structured,
                overriddenBlocker: overriddenBlocker
            )
        )

        do {
            let savedPath = try ObsidianVaultWriter.writeNote(
                vaultPath: settings.vaultPath,
                relativePath: notePath,
                content: content,
                append: false
            )
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
        let structured: JadeStructuredProjectContext
        let overriddenBlocker: Bool
    }

    struct CaptureNoteInput: Equatable {
        let content: String
        let projectName: String
        let projectPath: String
        let structured: JadeStructuredProjectContext
    }

    static func sessionNote(input: SessionNoteInput) -> String {
        let outcome = input.outcome
        let proposal = input.proposal
        let projectName = input.projectName
        let projectPath = input.projectPath
        let context = input.context
        let structured = input.structured
        let overriddenBlocker = input.overriddenBlocker

        let now = Date()
        let date = dayString(from: now)
        let time = timeString(from: now)
        let slug = ObsidianNotePathBuilder.slugify(projectName)
        let source = proposal.sourceFile ?? "project markdown"
        let hubLink = "Jade/Logs/\(slug)/project"

        var body = """
        ---
        type: project-session-log
        date: "\(date)"
        time: "\(time)"
        project: "\(yamlEscape(projectName))"
        project_path: "\(yamlEscape(projectPath))"
        session:
          step: "\(yamlEscape(proposal.title))"
          outcome: \(outcome.rawValue)
          risk: \(proposal.risk.rawValue)
          source: "\(yamlEscape(source))"
        tags:
          - jade
          - project-log
          - session-log
          - \(slug)
        ---

        # Session — \(proposal.title)

        **Project:** [[\(hubLink)|\(projectName)]] · **Date:** \(date) · **Outcome:** \(outcomeLabel(outcome)) · **Risk:** \(proposal.risk
            .displayName)

        ## Focus step

        **\(proposal.title)** — \(proposal.summary)

        *Why this step:* \(proposal.why)

        ## Work log

        - \(proposal.summary)
        - [ ] Document what shipped, changed, or was verified this session

        ## Session notes

        *(Decisions, snippets, commands, links, or context worth keeping.)*


        """

        if !structured.goals.isEmpty {
            body += """

            ## Goals (reference)

            \(bulletedLines(structured.goals))

            """
        }

        body += """

        ## Follow-up

        \(followUpSection(proposal: proposal, structured: structured))

        ## Project files

        \(projectFilesTable(context: context, projectPath: projectPath))

        """

        if let blocked = proposal.blockedReason {
            body += """

            ## Blockers

            - \(blocked)
            """
            if let rule = proposal.matchedRule {
                body += "\n- Matched rule: `\(rule)`"
            }
            if overriddenBlocker {
                body += "\n- Continued once with override."
            }
            body += "\n"
        }

        body += """

        ## Related

        - Project log: [[\(hubLink)|\(projectName) log]]
        - Source: `\(source)`
        - Repo: `\(projectPath)`
        """

        return body
    }

    static func captureNote(input: CaptureNoteInput) -> String {
        let trimmed = input.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = ObsidianNotePathBuilder.title(from: trimmed)
        let now = Date()
        let date = dayString(from: now)
        let time = timeString(from: now)
        let slug = ObsidianNotePathBuilder.slugify(input.projectName)
        let hubLink = "Jade/Logs/\(slug)/project"

        var body = """
        ---
        type: project-capture
        date: "\(date)"
        time: "\(time)"
        project: "\(yamlEscape(input.projectName))"
        project_path: "\(yamlEscape(input.projectPath))"
        tags:
          - jade
          - project-capture
          - \(slug)
        ---

        # Capture — \(title)

        **Project:** [[\(hubLink)|\(input.projectName)]] · **Date:** \(date)

        ## Note

        \(trimmed)

        """

        if !input.structured.openTodos.isEmpty {
            body += """

            ## Open tasks (reference)

            \(checkboxLines(input.structured.openTodos))

            """
        }

        if !input.structured.goals.isEmpty {
            body += """

            ## Goals (reference)

            \(bulletedLines(input.structured.goals))

            """
        }

        body += """

        ## Related

        - Project log: [[\(hubLink)|\(input.projectName) log]]
        - Repo: `\(input.projectPath)`
        """

        return body
    }

    static func projectLogIndex(
        projectName: String,
        projectPath: String,
        structured: JadeStructuredProjectContext
    ) -> String {
        let date = dayString(from: Date())
        let slug = ObsidianNotePathBuilder.slugify(projectName)

        var body = """
        ---
        type: project-log
        date: "\(date)"
        project: "\(yamlEscape(projectName))"
        project_path: "\(yamlEscape(projectPath))"
        tags:
          - jade
          - project-log
          - \(slug)
        ---

        # \(projectName) — project log

        Central index for Jade session logs and captures in Obsidian.

        **Repo:** `\(projectPath)` · **Updated:** \(date)

        ## Status

        - [ ] Define current focus in `todo.md` or `goals.md`
        - [ ] Complete a session and log outcomes from Jade

        ## Sessions

        *(Session notes live in `Jade/Logs/\(slug)/sessions/`.)*

        ## Captures

        *(Quick notes live in `Jade/Logs/\(slug)/notes/`.)*

        """

        if !structured.openTodos.isEmpty {
            body += """

            ## Todo

            \(checkboxLines(structured.openTodos))

            """
        }

        if !structured.goals.isEmpty {
            body += """

            ## Goals

            \(bulletedLines(structured.goals))

            """
        }

        body += """

        ## Project files

        \(projectFilesTable(context: structured.paths, projectPath: projectPath))

        ## Links

        - Repo root: `\(projectPath)`
        """

        return body
    }

    private static func followUpSection(
        proposal: JourneyStepProposal,
        structured: JadeStructuredProjectContext
    ) -> String {
        let normalizedStep = proposal.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let remaining = structured.openTodos.filter {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != normalizedStep
        }
        if remaining.isEmpty {
            return "- [ ] Add the next open item to `todo.md` or `goals.md`"
        }
        return checkboxLines(remaining)
    }

    private static func projectFilesTable(context: JadeProjectContext, projectPath: String) -> String {
        var rows = [("Repo", "`\(projectPath)`")]
        if let path = context.todoPath {
            rows.append(("Todo", "`\(JadeProjectContextFiles.relativeName(for: path, projectPath: projectPath))`"))
        }
        if let path = context.goalsPath {
            rows.append(("Goals", "`\(JadeProjectContextFiles.relativeName(for: path, projectPath: projectPath))`"))
        }
        if let path = context.projectMapPath {
            rows.append(("Map", "`\(JadeProjectContextFiles.relativeName(for: path, projectPath: projectPath))`"))
        }
        if let path = context.agentsPath {
            rows.append(("Agents", "`\(JadeProjectContextFiles.relativeName(for: path, projectPath: projectPath))`"))
        }
        if JadeJourneyBootstrapService.isInitialized(projectPath: projectPath) {
            rows.append(("Log", "`.jade/journey.md`"))
            rows.append(("Rules", "`.jade/rules.md`"))
        }
        let header = "| Surface | Location |\n| --- | --- |"
        let lines = rows.map { "| \($0.0) | \($0.1) |" }
        return ([header] + lines).joined(separator: "\n")
    }

    private static func checkboxLines(_ items: [String]) -> String {
        items.map { "- [ ] \($0)" }.joined(separator: "\n")
    }

    private static func bulletedLines(_ items: [String]) -> String {
        items.map { "- \($0)" }.joined(separator: "\n")
    }

    private static func dayString(from date: Date) -> String {
        String(ISO8601DateFormatter().string(from: date).prefix(10))
    }

    private static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func yamlEscape(_ value: String) -> String {
        value.replacingOccurrences(of: "\"", with: "'")
    }

    private static func outcomeLabel(_ outcome: JourneySessionOutcome) -> String {
        switch outcome {
        case .started: "Started"
        case .completed: "Completed"
        case .skipped: "Skipped"
        case .declined: "Declined"
        case .blocked: "Blocked"
        case .overridden: "Overridden"
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

    static func projectCapturePath(projectName: String, content: String) -> String {
        let slug = slugify(projectName)
        let timestamp = sessionTimestamp()
        let titleSlug = slugify(title(from: content))
        return "Jade/Logs/\(slug)/notes/\(timestamp)-\(titleSlug).md"
    }

    static func projectLogIndexPath(projectName: String) -> String {
        let slug = slugify(projectName)
        return "Jade/Logs/\(slug)/project.md"
    }
}

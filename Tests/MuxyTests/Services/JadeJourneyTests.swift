import Foundation
import Testing
@testable import Muxy

@Suite("Jade Journey Bootstrap")
struct JadeJourneyBootstrapTests {
    @Test("bootstrap creates journey scaffold")
    func bootstrapCreatesScaffold() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try JadeJourneyBootstrapService.bootstrap(projectPath: root.path, projectName: "Demo")

        #expect(JadeJourneyBootstrapService.isInitialized(projectPath: root.path))
        #expect(FileManager.default.fileExists(atPath: JadeJourneyLayout.rulesFile(in: root.path)))
        #expect(FileManager.default.fileExists(atPath: JadeJourneyLayout.logFolder(in: root.path)))
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("todo.md").path))
        #expect(FileManager.default.fileExists(atPath: root.appendingPathComponent("goals.md").path))
    }

    @Test("bootstrap rejects duplicate initialize")
    func bootstrapRejectsDuplicate() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try JadeJourneyBootstrapService.bootstrap(projectPath: root.path, projectName: "Demo")
        var didThrow = false
        do {
            try JadeJourneyBootstrapService.bootstrap(projectPath: root.path, projectName: "Demo")
        } catch JadeJourneyError.alreadyInitialized {
            didThrow = true
        }
        #expect(didThrow)
    }
}

@Suite("Jade Journey Reader")
struct JadeJourneyReaderTests {
    @Test("loads next step and why from journey markdown")
    func loadsNextStep() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try JadeJourneyBootstrapService.bootstrap(projectPath: root.path, projectName: "Demo")
        let journeyPath = JadeJourneyLayout.journeyFile(in: root.path)
        try """
        # Journey

        ## Next step
        Build the login screen

        ### Why
        Auth before polish.

        ## Done
        """.write(to: URL(fileURLWithPath: journeyPath), atomically: true, encoding: .utf8)

        try FileManager.default.removeItem(at: root.appendingPathComponent("todo.md"))
        try FileManager.default.removeItem(at: root.appendingPathComponent("goals.md"))

        let proposal = try JadeJourneyReader.loadNextStepProposal(projectPath: root.path)
        #expect(proposal.title == "Build the login screen")
        #expect(proposal.why == "Auth before polish.")
        #expect(proposal.sourceFile == ".jade/journey.md")
    }

    @Test("prefers open todo item over journey markdown")
    func prefersTodoOverJourney() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try """
        # Todo
        - [ ] Wire Obsidian MCP settings
        - [x] Done item
        """.write(to: root.appendingPathComponent("todo.md"), atomically: true, encoding: .utf8)

        try JadeJourneyBootstrapService.bootstrap(projectPath: root.path, projectName: "Demo")

        let proposal = try JadeJourneyReader.loadNextStepProposal(projectPath: root.path)
        #expect(proposal.title == "Wire Obsidian MCP settings")
        #expect(proposal.sourceFile == "todo.md")
    }
}

@Suite("Jade Project Context")
struct JadeProjectContextReaderTests {
    @Test("reads first open todo")
    func readsOpenTodo() {
        let content = """
        # Todo
        - [x] Done
        - [ ] Ship palette polish
        """
        #expect(JadeProjectContextReader.firstOpenTodo(in: content) == "Ship palette polish")
    }

    @Test("reads first goal bullet")
    func readsGoal() {
        let content = """
        # Goals
        - Launch beta
        """
        #expect(JadeProjectContextReader.firstGoalItem(in: content) == "Launch beta")
    }

    @Test("loadStructured extracts todos goals and paths")
    func loadStructured() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try """
        # Todo
        - [ ] Wire context reader
        - [x] Done
        """.write(to: root.appendingPathComponent("todo.md"), atomically: true, encoding: .utf8)

        try """
        # Goals
        - Ship Journey from project markdown
        """.write(to: root.appendingPathComponent("goals.md"), atomically: true, encoding: .utf8)

        try """
        # Map
        - Docs: docs/architecture.md
        """.write(to: root.appendingPathComponent("project-map.md"), atomically: true, encoding: .utf8)

        let structured = JadeProjectContextReader.loadStructured(projectPath: root.path)
        #expect(structured.openTodos == ["Wire context reader"])
        #expect(structured.goals == ["Ship Journey from project markdown"])
        #expect(structured.mapEntries == ["Docs: docs/architecture.md"])
        #expect(structured.paths.todoPath?.hasSuffix("todo.md") == true)
    }
}

@Suite("Jade Journey Rules")
struct JadeJourneyRuleCheckerTests {
    @Test("blocks step that matches not yet rule")
    func blocksMatchingRule() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try JadeJourneyBootstrapService.bootstrap(projectPath: root.path, projectName: "Demo")

        let result = JadeJourneyRuleChecker.evaluate(
            title: "Add Stripe billing",
            summary: "Focus for payments",
            projectPath: root.path
        )
        #expect(result.risk == .blocked)
        #expect(result.blockedReason?.contains("billing") == true)
    }

    @Test("forbidden rules parser reads not yet section")
    func forbiddenRulesParser() {
        let rules = """
        # Rules
        ## Not yet
        - deploy to production
        ## Always
        - log wins
        """
        #expect(JadeJourneyRuleChecker.forbiddenRules(from: rules) == ["deploy to production"])
    }
}

@Suite("Jade Journey Log Formatter")
struct JadeJourneyLogFormatterTests {
    @Test("session note includes frontmatter and outcome")
    func sessionNoteShape() {
        let proposal = JourneyStepProposal(
            title: "Ship onboarding",
            summary: "Focus for this session",
            why: "Users need a first win.",
            sourceFile: "todo.md"
        )
        let context = JadeProjectContext(
            todoPath: "/tmp/demo/todo.md",
            goalsPath: nil,
            agentsPath: "/tmp/demo/AGENTS.md",
            projectMapPath: nil
        )
        let structured = JadeStructuredProjectContext(
            projectPath: "/tmp/demo",
            paths: context,
            openTodos: ["Ship onboarding", "Write release notes"],
            goals: ["Launch beta"],
            mapEntries: [],
            agentsExcerpt: nil,
            projectMapExcerpt: nil
        )
        let note = JadeJourneyLogFormatter.sessionNote(
            input: JadeJourneyLogFormatter.SessionNoteInput(
                outcome: .started,
                proposal: proposal,
                projectName: "Demo",
                projectPath: "/tmp/demo",
                context: context,
                structured: structured,
                overriddenBlocker: false
            )
        )
        #expect(note.contains("type: project-session-log"))
        #expect(note.contains("## Focus step"))
        #expect(note.contains("## Work log"))
        #expect(note.contains("## Follow-up"))
        #expect(note.contains("## Session notes"))
        #expect(note.contains("todo.md"))
        #expect(note.contains("Write release notes"))
        #expect(note.contains("Personal") == false)
        #expect(note.contains("Energy") == false)
        #expect(note.contains("Ship onboarding"))
    }

    @Test("capture note includes project frontmatter and open tasks")
    func captureNoteShape() {
        let structured = JadeStructuredProjectContext(
            projectPath: "/tmp/demo",
            paths: JadeProjectContext(
                todoPath: "/tmp/demo/todo.md",
                goalsPath: nil,
                agentsPath: nil,
                projectMapPath: nil
            ),
            openTodos: ["Fix sidebar spacing"],
            goals: [],
            mapEntries: [],
            agentsExcerpt: nil,
            projectMapExcerpt: nil
        )
        let note = JadeJourneyLogFormatter.captureNote(
            input: JadeJourneyLogFormatter.CaptureNoteInput(
                content: "Terminal selection snippet",
                projectName: "Demo",
                projectPath: "/tmp/demo",
                structured: structured
            )
        )
        #expect(note.contains("type: project-capture"))
        #expect(note.contains("## Note"))
        #expect(note.contains("Fix sidebar spacing"))
    }

    @Test("project log index template includes sessions and captures sections")
    func projectLogIndexShape() {
        let structured = JadeStructuredProjectContext(
            projectPath: "/tmp/demo",
            paths: JadeProjectContext(
                todoPath: "/tmp/demo/todo.md",
                goalsPath: nil,
                agentsPath: nil,
                projectMapPath: nil
            ),
            openTodos: ["Ship onboarding"],
            goals: ["Launch beta"],
            mapEntries: [],
            agentsExcerpt: nil,
            projectMapExcerpt: nil
        )
        let note = JadeJourneyLogFormatter.projectLogIndex(
            projectName: "Demo",
            projectPath: "/tmp/demo",
            structured: structured
        )
        #expect(note.contains("type: project-log"))
        #expect(note.contains("## Sessions"))
        #expect(note.contains("## Captures"))
        #expect(note.contains("Ship onboarding"))
    }
}

@Suite("Obsidian Project Log Index")
struct ObsidianProjectLogIndexTests {
    @Test("exists detects vault hub note on disk")
    func existsDetectsHubNote() throws {
        let vault = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: vault, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: vault) }

        let hubFolder = vault.appendingPathComponent("Jade/Logs/demo", isDirectory: true)
        try FileManager.default.createDirectory(at: hubFolder, withIntermediateDirectories: true)
        let hubFile = hubFolder.appendingPathComponent("project.md")
        try "# Demo log".write(to: hubFile, atomically: true, encoding: .utf8)

        let settings = ObsidianMCPSettings(
            isEnabled: true,
            vaultPath: vault.path,
            pythonPath: "/usr/bin/python3",
            serverScriptPath: "/tmp/server.py",
            readOnly: false,
            backupOnWrite: false,
            inboxFolder: "Jade/Inbox",
            defaultTags: ["jade"]
        )

        #expect(ObsidianProjectLogIndex.exists(projectName: "Demo", settings: settings))
        #expect(ObsidianProjectLogIndex.vaultRelativePath(projectName: "Demo") == "Jade/Logs/demo/project.md")
        #expect(ObsidianProjectLogIndex.exists(projectName: "Other", settings: settings) == false)
    }
}

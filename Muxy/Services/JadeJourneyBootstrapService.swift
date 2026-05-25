import Foundation

enum JadeJourneyBootstrapService {
    static func isInitialized(projectPath: String) -> Bool {
        FileManager.default.fileExists(atPath: JadeJourneyLayout.journeyFile(in: projectPath))
    }

    static func bootstrap(projectPath: String, projectName: String) throws {
        guard !isInitialized(projectPath: projectPath) else {
            throw JadeJourneyError.alreadyInitialized
        }

        let fileManager = FileManager.default
        let root = JadeJourneyLayout.root(in: projectPath)
        try fileManager.createDirectory(atPath: root, withIntermediateDirectories: true)
        for folder in [
            JadeJourneyLayout.decisionsFolder(in: projectPath),
            JadeJourneyLayout.achievementsFolder(in: projectPath),
            JadeJourneyLayout.blockersFolder(in: projectPath),
            JadeJourneyLayout.logFolder(in: projectPath),
        ] {
            try fileManager.createDirectory(atPath: folder, withIntermediateDirectories: true)
        }

        try Self.journeyTemplate(projectName: projectName).write(
            to: URL(fileURLWithPath: JadeJourneyLayout.journeyFile(in: projectPath)),
            atomically: true,
            encoding: .utf8
        )
        try Self.rulesTemplate.write(
            to: URL(fileURLWithPath: JadeJourneyLayout.rulesFile(in: projectPath)),
            atomically: true,
            encoding: .utf8
        )
        try bootstrapProjectMarkdownIfNeeded(projectPath: projectPath, projectName: projectName)
    }

    private static func bootstrapProjectMarkdownIfNeeded(projectPath: String, projectName: String) throws {
        let fileManager = FileManager.default
        let base = URL(fileURLWithPath: projectPath, isDirectory: true)

        let scaffolds: [(String, String)] = [
            ("goals.md", goalsTemplate(projectName: projectName)),
            ("todo.md", todoTemplate),
            ("project-map.md", projectMapTemplate(projectName: projectName)),
        ]

        for (name, body) in scaffolds {
            let path = base.appendingPathComponent(name).path
            guard !fileManager.fileExists(atPath: path) else { continue }
            try body.write(to: URL(fileURLWithPath: path), atomically: true, encoding: .utf8)
        }
    }

    private static func goalsTemplate(projectName: String) -> String {
        """
        # Goals — \(projectName)

        - Define the outcome this project should reach.
        """
    }

    private static var todoTemplate: String {
        """
        # Todo

        - [ ] First concrete task for this project
        """
    }

    private static func projectMapTemplate(projectName: String) -> String {
        """
        # Project map — \(projectName)

        - Source code:
        - Docs:
        - Related repos:
        """
    }

    private static func journeyTemplate(projectName: String) -> String {
        """
        # Project log — \(projectName)

        ## Current focus
        Project started. Jade proposes one step at a time and logs each session to Obsidian.

        ## Next step
        Describe the first thing you want this project to do.

        ### Why
        One clear goal keeps the work focused.

        ## Done
        """
    }

    private static var rulesTemplate: String {
        """
        # Rules

        Plain-language guardrails. Jade may disagree with a step if it breaks these rules.

        ## Not yet
        - deploy to production
        - add payments or billing
        - delete user data without a backup

        ## Always
        - keep changes small enough to test in one session
        - log decisions and wins to Obsidian
        """
    }
}

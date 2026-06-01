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
            ("todo.md", todoTemplate(projectName: projectName)),
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

        Outcomes this project should reach. Jade reads this file when proposing the next session step.

        ## Primary outcome


        ## Milestones

        - [ ] First milestone
        """
    }

    private static func todoTemplate(projectName: String) -> String {
        """
        # Todo — \(projectName)

        Open tasks for this project. Jade picks the next `- [ ]` item for session focus.

        ## Now

        - [ ] First concrete task

        ## Later

        - [ ] 
        """
    }

    private static func projectMapTemplate(projectName: String) -> String {
        """
        # Project map — \(projectName)

        Quick orientation for humans and agents.

        | Area | Location | Notes |
        | --- | --- | --- |
        | Source | | |
        | Docs | | |
        | Related | | |
        """
    }

    private static func journeyTemplate(projectName: String) -> String {
        """
        # Project log — \(projectName)

        Local session history for this repo. Jade mirrors structured session logs to Obsidian under `Jade/Logs/`.

        ## Current focus

        Project started. Confirm the next step from `todo.md`, `goals.md`, or the section below.

        ## Next step

        Describe the first thing you want to accomplish in this project.

        ### Why

        One clear goal keeps each session focused and loggable.

        ## Done

        """
    }

    private static var rulesTemplate: String {
        """
        # Rules — project guardrails

        Plain-language constraints. Jade may flag a step if it conflicts with this file.

        ## Not yet

        - deploy to production
        - add payments or billing
        - delete user data without a backup

        ## Always

        - keep changes small enough to test in one session
        - log decisions and outcomes to Obsidian
        """
    }
}

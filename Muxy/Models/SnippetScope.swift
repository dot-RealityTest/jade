import Foundation

struct SnippetScope: Equatable {
    enum StarterSeedPolicy {
        case missingStorage
        case missingOrEmptyStorage
    }

    let id: String
    let displayName: String
    let fileURL: URL
    let starterSnippets: [Snippet]
    let starterSeedPolicy: StarterSeedPolicy

    static let shared = SnippetScope(
        id: "shared",
        displayName: "General Snippets",
        fileURL: MuxyFileStorage.fileURL(filename: "snippets.json"),
        starterSnippets: sharedStarterSnippets,
        starterSeedPolicy: .missingOrEmptyStorage
    )

    static func project(_ project: Project) -> SnippetScope {
        SnippetScope(
            id: "project-\(project.id.uuidString)",
            displayName: "\(project.name) Snippets",
            fileURL: projectSnippetsFileURL(projectID: project.id),
            starterSnippets: [],
            starterSeedPolicy: .missingStorage
        )
    }

    static func projectSnippetsFileURL(projectID: UUID) -> URL {
        let directory = MuxyFileStorage.appSupportDirectory()
            .appendingPathComponent("project-snippets", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: FilePermissions.privateDirectory]
        )
        return directory.appendingPathComponent("\(projectID.uuidString).json")
    }

    static func remote(_ space: RemoteSpace) -> SnippetScope {
        SnippetScope(
            id: "remote-\(space.id.uuidString)",
            displayName: "\(space.displayName) Snippets",
            fileURL: space.snippetsFileURL,
            starterSnippets: remoteStarterSnippets,
            starterSeedPolicy: .missingStorage
        )
    }

    private static let remotePrefix = "remote-"

    var isRemote: Bool {
        id.hasPrefix(Self.remotePrefix)
    }

    var remoteSpaceID: UUID? {
        guard isRemote else { return nil }
        return UUID(uuidString: String(id.dropFirst(Self.remotePrefix.count)))
    }

    private static let sharedStarterSnippets: [Snippet] = [
        Snippet(
            name: "Project Status",
            description: "Show branch, short git status, and the current directory.",
            command: "pwd && git status --short --branch",
            tags: ["git", "status"]
        ),
        Snippet(
            name: "Refresh Git",
            description: "Fetch remotes, prune stale refs, and show the current status.",
            command: "git fetch --all --prune && git status --short --branch",
            tags: ["git", "sync"]
        ),
        Snippet(
            name: "Run Checks",
            description: "Run the project check script when present, otherwise fall back to Swift tests.",
            command: "if [ -x scripts/checks.sh ]; then scripts/checks.sh --fix; else swift test; fi",
            tags: ["build", "test", "swift"]
        ),
        Snippet(
            name: "Swift Build",
            description: "Build the active Swift package.",
            command: "swift build",
            tags: ["swift", "build"]
        ),
        Snippet(
            name: "Swift Test",
            description: "Run Swift package tests.",
            command: "swift test",
            tags: ["swift", "test"]
        ),
        Snippet(
            name: "Start Dev Server",
            description: "Run the package dev script when this is a Node project.",
            command: "if [ -f package.json ]; then npm run dev; else echo 'No package.json found'; fi",
            tags: ["node", "dev"]
        ),
        Snippet(
            name: "Listening Ports",
            description: "Show listening TCP ports with owning processes.",
            command: "lsof -nP -iTCP -sTCP:LISTEN",
            tags: ["macos", "network"]
        ),
        Snippet(
            name: "Find Large Files",
            description: "Find project files larger than 50 MB outside .git.",
            command: "find . -type f -size +50M -not -path './.git/*' -print",
            tags: ["files", "cleanup"]
        ),
        Snippet(
            name: "Search Text",
            description: "Search the project with ripgrep.",
            command: "rg \"{query}\" .",
            tags: ["search", "files"],
            variableDefaults: ["query": "TODO"]
        ),
        Snippet(
            name: "Recent Files",
            description: "List project files changed in the last seven days.",
            command: "find . -type f -mtime -7 -not -path './.git/*' -print | head -80",
            tags: ["files", "recent"]
        ),
        Snippet(
            name: "Open In Finder",
            description: "Open the current project folder in Finder.",
            command: "open .",
            tags: ["macos", "finder"]
        ),
    ]

    private static let remoteStarterSnippets: [Snippet] = [
        Snippet(
            name: "System Overview",
            description: "Show hostname, uptime, disk, memory, and kernel details.",
            command: "hostname && uptime && df -h && free -h && uname -a",
            tags: ["linux", "system"]
        ),
        Snippet(
            name: "Docker Containers",
            description: "List running containers with names, images, status, and ports.",
            command: "docker ps --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.Ports}}'",
            tags: ["linux", "docker"]
        ),
        Snippet(
            name: "Service Status",
            description: "Check a systemd service by name.",
            command: "systemctl status {service}",
            tags: ["linux", "service"],
            variableDefaults: ["service": "ssh"]
        ),
        Snippet(
            name: "Recent Service Logs",
            description: "Tail recent logs for a systemd service.",
            command: "journalctl -u {service} -n 100 --no-pager",
            tags: ["linux", "logs"],
            variableDefaults: ["service": "ssh"]
        ),
        Snippet(
            name: "Listening Ports",
            description: "Show listening TCP and UDP ports with owning processes.",
            command: "ss -tulpn",
            tags: ["linux", "network"]
        ),
    ]
}

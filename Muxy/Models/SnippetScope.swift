import Foundation

struct SnippetScope: Equatable {
    let id: String
    let displayName: String
    let fileURL: URL
    let starterSnippets: [Snippet]

    static let shared = SnippetScope(
        id: "shared",
        displayName: "Snippets",
        fileURL: MuxyFileStorage.fileURL(filename: "snippets.json"),
        starterSnippets: []
    )

    static func remote(_ space: RemoteSpace) -> SnippetScope {
        SnippetScope(
            id: "remote-\(space.id.uuidString)",
            displayName: "\(space.displayName) Snippets",
            fileURL: space.snippetsFileURL,
            starterSnippets: remoteStarterSnippets
        )
    }

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

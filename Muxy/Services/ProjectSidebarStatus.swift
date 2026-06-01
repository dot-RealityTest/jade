import Foundation

struct ProjectSidebarStatus: Equatable {
    let branch: String?
    let listeningPortCount: Int
    let latestUnreadPreview: String?

    static func empty(branch: String? = nil) -> Self {
        Self(branch: branch, listeningPortCount: 0, latestUnreadPreview: nil)
    }

    @MainActor
    static func resolve(
        project: Project,
        worktree: Worktree?,
        notificationStore: NotificationStore = .shared,
        portMonitor: LocalPortMonitor = .shared
    ) -> Self {
        let branch = displayBranch(for: project, worktree: worktree)
        let ports = listeningPortCount(for: project, worktree: worktree, portMonitor: portMonitor)
        let preview = latestUnreadPreview(for: project.id, notificationStore: notificationStore)
        return Self(branch: branch, listeningPortCount: ports, latestUnreadPreview: preview)
    }

    static func displayBranch(for project: Project, worktree: Worktree?) -> String? {
        guard let branch = resolvedBranch(worktree: worktree) else { return nil }
        if branch.caseInsensitiveCompare(project.name) == .orderedSame { return nil }
        return branch
    }

    static func resolvedBranch(worktree: Worktree?) -> String? {
        guard let worktree else { return nil }
        if let branch = worktree.branch, !branch.isEmpty { return branch }
        if !worktree.name.isEmpty { return worktree.name }
        return worktree.isPrimary ? "main" : nil
    }

    @MainActor
    static func listeningPortCount(
        for project: Project,
        worktree: Worktree?,
        portMonitor: LocalPortMonitor
    ) -> Int {
        let markers = pathMarkers(project: project, worktree: worktree)
        guard !markers.isEmpty else { return 0 }
        return portMonitor.active.count(where: { listener in
            markers.contains { marker in
                listener.command.localizedCaseInsensitiveContains(marker)
            }
        })
    }

    @MainActor
    static func latestUnreadPreview(
        for projectID: UUID,
        notificationStore: NotificationStore
    ) -> String? {
        guard let notification = notificationStore.latestUnread(for: projectID) else { return nil }
        let body = notification.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if body.isEmpty { return notification.title }
        if notification.title.isEmpty { return truncate(body) }
        return truncate("\(notification.title) — \(body)")
    }

    private static func pathMarkers(project: Project, worktree: Worktree?) -> [String] {
        var markers: [String] = []
        let projectName = URL(fileURLWithPath: project.path).lastPathComponent
        if !projectName.isEmpty { markers.append(projectName) }
        if let worktree, !worktree.isPrimary, !worktree.name.isEmpty {
            markers.append(worktree.name)
        }
        return markers
    }

    private static func truncate(_ text: String, limit: Int = 72) -> String {
        guard text.count > limit else { return text }
        return String(text.prefix(limit - 1)) + "…"
    }
}

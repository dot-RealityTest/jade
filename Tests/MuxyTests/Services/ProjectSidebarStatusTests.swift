import Foundation
import Testing
@testable import Muxy

@Suite("ProjectSidebarStatus")
struct ProjectSidebarStatusTests {
    @Test("display branch hides duplicate project name")
    func displayBranchHidesProjectName() {
        let project = Project(name: "akakika", path: "/tmp/akakika", sortOrder: 0)
        let worktree = Worktree(name: "akakika", path: "/tmp/akakika", branch: "akakika", isPrimary: true)
        #expect(ProjectSidebarStatus.displayBranch(for: project, worktree: worktree) == nil)
    }

    @Test("resolved branch prefers worktree branch")
    func branchPrefersWorktreeBranch() {
        let worktree = Worktree(name: "feature", path: "/tmp/feature", branch: "feature/login", isPrimary: false)
        #expect(ProjectSidebarStatus.resolvedBranch(worktree: worktree) == "feature/login")
    }

    @Test("latest unread preview combines title and body")
    @MainActor
    func previewCombinesTitleAndBody() {
        let store = NotificationStore.shared
        let projectID = UUID()
        let notification = MuxyNotification(
            paneID: UUID(),
            projectID: projectID,
            worktreeID: UUID(),
            areaID: UUID(),
            tabID: UUID(),
            worktreePath: "/tmp/project",
            source: .socket,
            title: "Build finished",
            body: "Tests passed"
        )
        store.stageNotification(notification)
        let preview = ProjectSidebarStatus.latestUnreadPreview(for: projectID, notificationStore: store)
        #expect(preview == "Build finished — Tests passed")
        store.remove(notification.id)
    }

    @Test("listening port count matches project marker in command")
    @MainActor
    func portCountMatchesProjectMarker() {
        let monitor = LocalPortMonitor(snapshotReader: LocalPortSnapshotReader(read: { [] }))
        let listener = LocalPortListener(
            pid: 42,
            command: "node /Users/me/muxy/server.js",
            userID: "501",
            protocolName: "TCP",
            address: "127.0.0.1",
            port: 3000
        )
        monitor.replaceSnapshot([listener])
        let project = Project(name: "muxy", path: "/Users/me/muxy", sortOrder: 0)
        let worktree = Worktree(name: "main", path: "/Users/me/muxy", isPrimary: true)
        let count = ProjectSidebarStatus.listeningPortCount(
            for: project,
            worktree: worktree,
            portMonitor: monitor
        )
        #expect(count == 1)
    }
}

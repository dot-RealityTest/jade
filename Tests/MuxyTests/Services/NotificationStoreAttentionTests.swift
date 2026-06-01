import Foundation
import Testing
@testable import Muxy

@Suite("NotificationStore attention")
struct NotificationStoreAttentionTests {
    @Test("latest unread returns newest unread notification for project")
    @MainActor
    func latestUnreadForProject() {
        let store = NotificationStore.shared
        let projectID = UUID()
        let older = MuxyNotification(
            paneID: UUID(),
            projectID: projectID,
            worktreeID: UUID(),
            areaID: UUID(),
            tabID: UUID(),
            worktreePath: "/tmp/a",
            source: .socket,
            title: "Older",
            body: ""
        )
        let newer = MuxyNotification(
            paneID: UUID(),
            projectID: projectID,
            worktreeID: UUID(),
            areaID: UUID(),
            tabID: UUID(),
            worktreePath: "/tmp/a",
            source: .socket,
            title: "Newer",
            body: ""
        )
        store.stageNotification(older)
        store.stageNotification(newer)
        #expect(store.latestUnread(for: projectID)?.title == "Newer")
        store.remove(older.id)
        store.remove(newer.id)
    }

    @Test("has unread pane matches pane id")
    @MainActor
    func hasUnreadPane() {
        let store = NotificationStore.shared
        let paneID = UUID()
        let notification = MuxyNotification(
            paneID: paneID,
            projectID: UUID(),
            worktreeID: UUID(),
            areaID: UUID(),
            tabID: UUID(),
            worktreePath: "/tmp/a",
            source: .osc,
            title: "Waiting",
            body: ""
        )
        store.stageNotification(notification)
        #expect(store.hasUnread(paneID: paneID))
        store.markAsRead(notification.id)
        #expect(!store.hasUnread(paneID: paneID))
        store.remove(notification.id)
    }
}

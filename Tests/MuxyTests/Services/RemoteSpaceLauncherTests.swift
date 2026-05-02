import Foundation
import Testing

@testable import Muxy

@Suite("RemoteSpaceLauncher")
@MainActor
struct RemoteSpaceLauncherTests {
    private func makeStores() -> (AppState, ProjectStore, WorktreeStore) {
        let projectStore = ProjectStore(persistence: ProjectPersistenceStub())
        let worktreeStore = WorktreeStore(
            persistence: WorktreePersistenceStub(),
            projects: []
        )
        let appState = AppState(
            selectionStore: SelectionStoreStub(),
            terminalViews: TerminalViewRemovingStub(),
            workspacePersistence: WorkspacePersistenceStub()
        )
        return (appState, projectStore, worktreeStore)
    }

    @Test("open creates dedicated project space and SSH tab")
    func openCreatesDedicatedProjectSpaceAndSSHTab() throws {
        let (appState, projectStore, worktreeStore) = makeStores()
        let space = RemoteSpace(name: "Zen", command: "ssh kika@100.86.62.100", colorID: "blue")
        var themedSpace: RemoteSpace?

        RemoteSpaceLauncher.open(
            space,
            appState: appState,
            projectStore: projectStore,
            worktreeStore: worktreeStore,
            applyTheme: { themedSpace = $0 }
        )

        let project = try #require(projectStore.projects.first)
        #expect(project.name == "Zen")
        #expect(project.path == space.backingDirectory(create: false).path)
        #expect(project.iconColor == "blue")
        #expect(appState.activeProjectID == project.id)
        let area = try #require(appState.focusedArea(for: project.id))
        let tab = try #require(area.activeTab)
        #expect(tab.customTitle == "Zen")
        #expect(tab.colorID == "blue")
        #expect(tab.content.pane?.startupCommand == "ssh kika@100.86.62.100")
        #expect(worktreeStore.primary(for: project.id)?.path == project.path)
        #expect(themedSpace?.id == space.id)
    }

    @Test("open existing space selects existing SSH tab without duplicating project")
    func openExistingSpaceSelectsExistingSSHTab() throws {
        let (appState, projectStore, worktreeStore) = makeStores()
        let space = RemoteSpace(name: "Alienware", command: "ssh kika@192.168.1.171", colorID: "green")

        RemoteSpaceLauncher.open(
            space,
            appState: appState,
            projectStore: projectStore,
            worktreeStore: worktreeStore,
            applyTheme: { _ in }
        )
        RemoteSpaceLauncher.open(
            space,
            appState: appState,
            projectStore: projectStore,
            worktreeStore: worktreeStore,
            applyTheme: { _ in }
        )

        let project = try #require(projectStore.projects.first)
        #expect(projectStore.projects.count == 1)
        let tabs = appState.allAreas(for: project.id).flatMap(\.tabs)
        #expect(tabs.filter { $0.content.pane?.startupCommand == space.trimmedCommand }.count == 1)
    }

    @Test("open structured profile uses generated SSH command")
    func openStructuredProfileUsesGeneratedSSHCommand() throws {
        let (appState, projectStore, worktreeStore) = makeStores()
        let space = RemoteSpace(
            name: "Zen",
            colorID: "blue",
            user: "kika",
            host: "100.86.62.100",
            startupCommands: ["tmux attach || tmux new"]
        )

        RemoteSpaceLauncher.open(
            space,
            appState: appState,
            projectStore: projectStore,
            worktreeStore: worktreeStore,
            applyTheme: { _ in }
        )

        let project = try #require(projectStore.projects.first)
        let area = try #require(appState.focusedArea(for: project.id))
        let tab = try #require(area.activeTab)
        #expect(tab.content.pane?.startupCommand == space.connectionCommand)
    }
}

private final class ProjectPersistenceStub: ProjectPersisting {
    private var projects: [Project] = []
    func loadProjects() throws -> [Project] { projects }
    func saveProjects(_ projects: [Project]) throws { self.projects = projects }
}

private final class WorktreePersistenceStub: WorktreePersisting {
    private var storage: [UUID: [Worktree]] = [:]
    func loadWorktrees(projectID: UUID) throws -> [Worktree] { storage[projectID] ?? [] }
    func saveWorktrees(_ worktrees: [Worktree], projectID: UUID) throws {
        storage[projectID] = worktrees
    }
    func removeWorktrees(projectID: UUID) throws { storage.removeValue(forKey: projectID) }
}

private final class WorkspacePersistenceStub: WorkspacePersisting {
    private var snapshots: [WorkspaceSnapshot] = []
    func loadWorkspaces() throws -> [WorkspaceSnapshot] { snapshots }
    func saveWorkspaces(_ workspaces: [WorkspaceSnapshot]) throws { snapshots = workspaces }
}

@MainActor
private final class SelectionStoreStub: ActiveProjectSelectionStoring {
    private var activeProjectID: UUID?
    private var activeWorktreeIDs: [UUID: UUID] = [:]
    func loadActiveProjectID() -> UUID? { activeProjectID }
    func saveActiveProjectID(_ id: UUID?) { activeProjectID = id }
    func loadActiveWorktreeIDs() -> [UUID: UUID] { activeWorktreeIDs }
    func saveActiveWorktreeIDs(_ ids: [UUID: UUID]) { activeWorktreeIDs = ids }
}

@MainActor
private final class TerminalViewRemovingStub: TerminalViewRemoving {
    func removeView(for paneID: UUID) {}
    func needsConfirmQuit(for paneID: UUID) -> Bool { false }
}

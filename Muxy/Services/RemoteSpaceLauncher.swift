import Foundation

@MainActor
enum RemoteSpaceLauncher {
    static func open(
        _ space: RemoteSpace,
        appState: AppState,
        projectStore: ProjectStore,
        worktreeStore: WorktreeStore
    ) {
        guard space.isConnectable else { return }
        let project = project(for: space, projectStore: projectStore)
        worktreeStore.ensurePrimary(for: project)
        guard let worktree = worktreeStore.primary(for: project.id) else { return }
        appState.selectProject(project, worktree: worktree)

        if selectExistingSSHSpace(space, appState: appState, projectID: project.id) {
            return
        }

        let defaultTab = defaultTerminalTab(appState: appState, projectID: project.id)
        appState.dispatch(.createCommandTab(
            projectID: project.id,
            areaID: nil,
            name: space.displayName,
            command: space.connectionCommand
        ))
        guard let area = appState.focusedArea(for: project.id), let tabID = area.activeTabID else { return }
        area.setCustomTitle(tabID, title: space.displayName)
        area.setColorID(tabID, colorID: space.colorID)
        if let defaultTab {
            appState.closeTab(defaultTab.tabID, areaID: defaultTab.areaID, projectID: project.id)
        }
        appState.saveWorkspaces()
    }

    private static func project(for space: RemoteSpace, projectStore: ProjectStore) -> Project {
        let path = space.backingDirectory().path
        if let existing = projectStore.projects.first(where: { $0.path == path }) {
            return existing
        }
        var project = Project(
            name: space.displayName,
            path: path,
            sortOrder: projectStore.projects.count
        )
        project.iconColor = space.colorID
        projectStore.add(project)
        return project
    }

    private static func selectExistingSSHSpace(
        _ space: RemoteSpace,
        appState: AppState,
        projectID: UUID
    ) -> Bool {
        for area in appState.allAreas(for: projectID) {
            guard let tab = area.tabs.first(where: { $0.content.pane?.startupCommand == space.connectionCommand }) else {
                continue
            }
            appState.dispatch(.selectTab(projectID: projectID, areaID: area.id, tabID: tab.id))
            return true
        }
        return false
    }

    private static func defaultTerminalTab(appState: AppState, projectID: UUID) -> (areaID: UUID, tabID: UUID)? {
        for area in appState.allAreas(for: projectID) {
            guard area.tabs.count == 1, let tab = area.tabs.first else { continue }
            guard let pane = tab.content.pane,
                  pane.startupCommand == nil,
                  tab.customTitle == nil,
                  !tab.isPinned
            else { continue }
            return (area.id, tab.id)
        }
        return nil
    }
}

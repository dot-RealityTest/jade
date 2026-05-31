import Foundation
import Testing

@testable import Muxy

@Suite("HomeWorkspace")
@MainActor
struct HomeWorkspaceTests {
    private func makeStore() -> ProjectStore {
        ProjectStore(persistence: ProjectPersistenceStub())
    }

    @Test("syncSidebarProject adds Home at the top of the sidebar")
    func syncSidebarProjectAddsHomeAtTop() {
        let store = makeStore()
        let existing = Project(name: "muxy", path: "/tmp/muxy", sortOrder: 0)
        store.add(existing)

        HomeWorkspace.syncSidebarProject(projectStore: store)

        #expect(store.projects.count == 2)
        #expect(store.projects.first?.name == HomeWorkspace.displayName)
        #expect(HomeWorkspace.matchesPath(store.projects.first?.path ?? ""))
        #expect(store.projects.first?.iconColor == HomeWorkspace.iconColorID)
    }

    @Test("syncSidebarProject reuses an existing home folder project")
    func syncSidebarProjectReusesExistingHomeProject() {
        let store = makeStore()
        let homePath = HomeWorkspace.directoryPath
        let existing = Project(name: "My Home", path: homePath, sortOrder: 1)
        store.add(existing)
        store.add(Project(name: "Other", path: "/tmp/other", sortOrder: 0))

        HomeWorkspace.syncSidebarProject(projectStore: store)

        #expect(store.projects.count == 2)
        #expect(store.projects.first?.id == existing.id)
        #expect(store.projects.first?.name == "My Home")
        #expect(store.projects.first?.iconColor == HomeWorkspace.iconColorID)
    }

    @Test("applyPreference removes managed Home when disabled")
    func applyPreferenceRemovesManagedHomeWhenDisabled() {
        let defaults = UserDefaults(suiteName: "HomeWorkspaceTests.remove")!
        defaults.removePersistentDomain(forName: "HomeWorkspaceTests.remove")
        defaults.set(false, forKey: GeneralSettingsKeys.showHomeWorkspaceInSidebar)

        let store = makeStore()
        store.insertAtTop(Project(
            name: HomeWorkspace.displayName,
            path: HomeWorkspace.directoryPath,
            sortOrder: 0
        ))

        HomeWorkspace.applyPreference(projectStore: store, defaults: defaults)

        #expect(store.projects.isEmpty)
    }

    @Test("applyPreference keeps renamed home project when disabled")
    func applyPreferenceKeepsRenamedHomeWhenDisabled() {
        let defaults = UserDefaults(suiteName: "HomeWorkspaceTests.rename")!
        defaults.removePersistentDomain(forName: "HomeWorkspaceTests.rename")
        defaults.set(false, forKey: GeneralSettingsKeys.showHomeWorkspaceInSidebar)

        let store = makeStore()
        store.insertAtTop(Project(
            name: "Shell",
            path: HomeWorkspace.directoryPath,
            sortOrder: 0
        ))

        HomeWorkspace.applyPreference(projectStore: store, defaults: defaults)

        #expect(store.projects.count == 1)
        #expect(store.projects.first?.name == "Shell")
    }
}

private final class ProjectPersistenceStub: ProjectPersisting {
    private var projects: [Project] = []
    func loadProjects() throws -> [Project] { projects }
    func saveProjects(_ projects: [Project]) throws { self.projects = projects }
}

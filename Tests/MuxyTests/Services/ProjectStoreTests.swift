import Foundation
import Testing

@testable import Muxy

@Suite("ProjectStore")
@MainActor
struct ProjectStoreTests {
    @Test("setPreferredWorktreeParentPath persists normalized path")
    func setPreferredWorktreeParentPath() {
        let project = Project(name: "Repo", path: "/tmp/repo")
        let persistence = ProjectPersistenceStub(initial: [project])
        let store = ProjectStore(persistence: persistence)

        store.setPreferredWorktreeParentPath(id: project.id, to: " ~/worktrees ")
        store.flushPendingSave()

        #expect(store.projects.first?.preferredWorktreeParentPath == NSString(string: "~/worktrees").expandingTildeInPath)
        #expect(persistence.projects.first?.preferredWorktreeParentPath == NSString(string: "~/worktrees").expandingTildeInPath)
    }

    @Test("setPreferredWorktreeParentPath clears empty path")
    func clearPreferredWorktreeParentPath() {
        var project = Project(name: "Repo", path: "/tmp/repo")
        project.preferredWorktreeParentPath = "/tmp/worktrees"
        let persistence = ProjectPersistenceStub(initial: [project])
        let store = ProjectStore(persistence: persistence)

        store.setPreferredWorktreeParentPath(id: project.id, to: " ")
        store.flushPendingSave()

        #expect(store.projects.first?.preferredWorktreeParentPath == nil)
        #expect(persistence.projects.first?.preferredWorktreeParentPath == nil)
    }

    @Test("mutations debounce persistence until flushed")
    func mutationsDebouncePersistence() {
        let persistence = ProjectPersistenceStub(initial: [])
        let store = ProjectStore(persistence: persistence, saveDebounce: .seconds(60))

        store.add(Project(name: "One", path: "/tmp/one"))
        store.add(Project(name: "Two", path: "/tmp/two"))

        #expect(persistence.saveCount == 0)

        store.flushPendingSave()

        #expect(persistence.saveCount == 1)
        #expect(persistence.projects.count == 2)
    }

    @Test("debounced save fires after the debounce interval")
    func debouncedSaveFires() async throws {
        let persistence = ProjectPersistenceStub(initial: [])
        let store = ProjectStore(persistence: persistence, saveDebounce: .milliseconds(10))

        store.add(Project(name: "One", path: "/tmp/one"))
        store.rename(id: store.projects[0].id, to: "Renamed")

        for _ in 0..<400 where persistence.saveCount == 0 {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(persistence.saveCount == 1)
        #expect(persistence.projects.first?.name == "Renamed")
    }
}

private final class ProjectPersistenceStub: ProjectPersisting {
    var projects: [Project]
    var saveCount = 0

    init(initial: [Project]) {
        projects = initial
    }

    func loadProjects() throws -> [Project] {
        projects
    }

    func saveProjects(_ projects: [Project]) throws {
        self.projects = projects
        saveCount += 1
    }
}

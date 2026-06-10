import Foundation
import Testing

@testable import Muxy

@Suite("SnippetScopeResolver")
struct SnippetScopeResolverTests {
    @Test("general mode uses shared scope for local projects")
    @MainActor
    func generalModeUsesSharedScope() {
        let project = Project(name: "Muxy", path: "/tmp/muxy")

        let scope = SnippetScopeResolver.resolve(mode: .general, project: project, remoteSpace: nil)

        #expect(scope == .shared)
    }

    @Test("remote space resolves to its own scope regardless of mode")
    @MainActor
    func remoteSpaceResolvesToRemoteScope() {
        let project = Project(name: "Alien", path: "/tmp/alien")
        let space = RemoteSpace(id: UUID(), name: "Alien", command: "ssh host")

        #expect(SnippetScopeResolver.resolve(mode: .general, project: project, remoteSpace: space) == .remote(space))
        #expect(SnippetScopeResolver.resolve(mode: .project, project: project, remoteSpace: space) == .remote(space))
    }

    @Test("project mode uses project scope for local projects")
    @MainActor
    func projectModeUsesProjectScope() {
        let project = Project(name: "Muxy", path: "/tmp/muxy")

        let scope = SnippetScopeResolver.resolve(mode: .project, project: project, remoteSpace: nil)

        #expect(scope == .project(project))
        #expect(scope.fileURL.lastPathComponent == "\(project.id.uuidString).json")
    }

    @Test("project mode uses remote scope for remote projects")
    @MainActor
    func projectModeUsesRemoteScope() {
        let project = Project(name: "Alien", path: "/tmp/alien")
        let space = RemoteSpace(id: UUID(), name: "Alien", command: "ssh host")

        let scope = SnippetScopeResolver.resolve(mode: .project, project: project, remoteSpace: space)

        #expect(scope == .remote(space))
    }

    @Test("project mode without project falls back to shared")
    @MainActor
    func projectModeWithoutProjectFallsBack() {
        let scope = SnippetScopeResolver.resolve(mode: .project, project: nil, remoteSpace: nil)

        #expect(scope == .shared)
    }
}

@Suite("SnippetsScopePreferences")
struct SnippetsScopePreferencesTests {
    @Test("defaults to general mode")
    @MainActor
    func defaultsToGeneralMode() {
        let defaults = UserDefaults.standard
        let key = GeneralSettingsKeys.snippetsScopeMode
        let previous = defaults.string(forKey: key)
        defer {
            if let previous {
                defaults.set(previous, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        defaults.removeObject(forKey: key)
        let preferences = SnippetsScopePreferences.shared
        preferences.setMode(.general)

        #expect(preferences.mode == .general)
    }

    @Test("toggle switches between general and project")
    @MainActor
    func toggleSwitchesModes() {
        let preferences = SnippetsScopePreferences.shared
        preferences.setMode(.general)
        preferences.toggle()
        #expect(preferences.mode == .project)
        preferences.toggle()
        #expect(preferences.mode == .general)
    }
}

import Foundation
import Observation

@MainActor
@Observable
final class SnippetsScopePreferences {
    static let shared = SnippetsScopePreferences()

    private(set) var mode: SnippetsScopeMode {
        didSet {
            guard mode != oldValue else { return }
            UserDefaults.standard.set(mode.rawValue, forKey: GeneralSettingsKeys.snippetsScopeMode)
        }
    }

    private init() {
        let raw = UserDefaults.standard.string(forKey: GeneralSettingsKeys.snippetsScopeMode)
        mode = SnippetsScopeMode(rawValue: raw ?? "") ?? .general
    }

    func setMode(_ mode: SnippetsScopeMode) {
        self.mode = mode
    }

    func toggle() {
        mode.toggle()
    }
}

@MainActor
enum SnippetScopeResolver {
    static func resolve(
        mode: SnippetsScopeMode,
        project: Project?,
        remoteSpace: RemoteSpace?
    ) -> SnippetScope {
        if let remoteSpace {
            return .remote(remoteSpace)
        }
        guard mode == .project, let project else { return .shared }
        return .project(project)
    }

    static func resolve(mode: SnippetsScopeMode, projectPath: String) -> SnippetScope {
        let remoteSpace = RemoteSpacesStore.shared.space(forProjectPath: projectPath)
        let project = project(matchingPath: projectPath)
        return resolve(mode: mode, project: project, remoteSpace: remoteSpace)
    }

    static func project(matchingPath path: String) -> Project? {
        let standardizedPath = URL(fileURLWithPath: path).standardizedFileURL.path
        let projects = (try? FileProjectPersistence().loadProjects()) ?? []
        return projects.first { project in
            let projectPath = URL(fileURLWithPath: project.path).standardizedFileURL.path
            return standardizedPath == projectPath || standardizedPath.hasPrefix(projectPath + "/")
        }
    }
}

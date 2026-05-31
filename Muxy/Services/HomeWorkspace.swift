import Foundation

@MainActor
enum HomeWorkspace {
    static let displayName = "Home"
    static let iconColorID = "blue"

    static var isEnabled: Bool {
        isEnabled(defaults: .standard)
    }

    static func isEnabled(defaults: UserDefaults) -> Bool {
        if defaults.object(forKey: GeneralSettingsKeys.showHomeWorkspaceInSidebar) == nil {
            return true
        }
        return defaults.bool(forKey: GeneralSettingsKeys.showHomeWorkspaceInSidebar)
    }

    static var directoryPath: String {
        FileManager.default.homeDirectoryForCurrentUser.path
    }

    static func matchesPath(_ path: String) -> Bool {
        standardizedPath(path) == standardizedPath(directoryPath)
    }

    static func applyPreference(projectStore: ProjectStore, defaults: UserDefaults = .standard) {
        if isEnabled(defaults: defaults) {
            syncSidebarProject(projectStore: projectStore)
            return
        }
        removeManagedProject(projectStore: projectStore)
    }

    static func syncSidebarProject(projectStore: ProjectStore) {
        guard isEnabled(defaults: .standard) else { return }
        let path = directoryPath
        if let existing = projectStore.projects.first(where: { matchesPath($0.path) }) {
            if existing.iconColor == nil {
                projectStore.setIconColor(id: existing.id, to: iconColorID)
            }
            projectStore.pinToTop(id: existing.id)
            return
        }
        var project = Project(name: displayName, path: path, sortOrder: 0)
        project.iconColor = iconColorID
        projectStore.insertAtTop(project)
    }

    static func removeManagedProject(projectStore: ProjectStore) {
        guard let project = projectStore.projects.first(where: {
            matchesPath($0.path) && $0.name == displayName
        })
        else { return }
        projectStore.remove(id: project.id)
    }

    private static func standardizedPath(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path
    }
}

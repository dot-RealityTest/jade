import Foundation
import os

private let logger = Logger(subsystem: "app.muxy", category: "ProjectStore")

@MainActor
@Observable
final class ProjectStore {
    private(set) var projects: [Project] = []
    private let persistence: any ProjectPersisting
    private let saveDebounce: Duration
    @ObservationIgnored private var pendingSaveTask: Task<Void, Never>?

    init(persistence: any ProjectPersisting, saveDebounce: Duration = .milliseconds(300)) {
        self.persistence = persistence
        self.saveDebounce = saveDebounce
        load()
    }

    func add(_ project: Project) {
        projects.append(project)
        scheduleSave()
    }

    func remove(id: UUID) {
        if let project = projects.first(where: { $0.id == id }) {
            VCSPersistedSettings.clearSettings(repoPath: project.path)
        }
        projects.removeAll { $0.id == id }
        scheduleSave()
    }

    func rename(id: UUID, to newName: String) {
        guard let index = projects.firstIndex(where: { $0.id == id }) else { return }
        projects[index].name = newName
        scheduleSave()
    }

    func setLogo(id: UUID, to logo: String?) {
        guard let index = projects.firstIndex(where: { $0.id == id }) else { return }
        if logo == nil {
            ProjectLogoStorage.remove(forProjectID: id)
        }
        projects[index].logo = logo
        scheduleSave()
    }

    func setIconColor(id: UUID, to color: String?) {
        guard let index = projects.firstIndex(where: { $0.id == id }) else { return }
        projects[index].iconColor = color
        scheduleSave()
    }

    func setPreferredWorktreeParentPath(id: UUID, to path: String?) {
        guard let index = projects.firstIndex(where: { $0.id == id }) else { return }
        projects[index].preferredWorktreeParentPath = WorktreeLocationResolver.normalizedPath(path)
        scheduleSave()
    }

    func reorder(fromOffsets source: IndexSet, toOffset destination: Int) {
        projects.move(fromOffsets: source, toOffset: destination)
        normalizeSortOrders()
        scheduleSave()
    }

    func insertAtTop(_ project: Project) {
        projects.insert(project, at: 0)
        normalizeSortOrders()
        scheduleSave()
    }

    func pinToTop(id: UUID) {
        guard let index = projects.firstIndex(where: { $0.id == id }), index > 0 else { return }
        let project = projects.remove(at: index)
        projects.insert(project, at: 0)
        normalizeSortOrders()
        scheduleSave()
    }

    private func normalizeSortOrders() {
        for index in projects.indices {
            projects[index].sortOrder = index
        }
    }

    func flushPendingSave() {
        guard pendingSaveTask != nil else { return }
        pendingSaveTask?.cancel()
        pendingSaveTask = nil
        save()
    }

    private func scheduleSave() {
        pendingSaveTask?.cancel()
        let debounce = saveDebounce
        pendingSaveTask = Task { [weak self] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self else { return }
                self.pendingSaveTask = nil
                self.save()
            }
        }
    }

    func save() {
        do {
            try persistence.saveProjects(projects)
        } catch {
            logger.error("Failed to save projects: \(error)")
        }
    }

    private func load() {
        do {
            projects = try persistence.loadProjects()
            projects.sort { $0.sortOrder < $1.sortOrder }
        } catch {
            logger.error("Failed to load projects: \(error)")
        }
    }
}

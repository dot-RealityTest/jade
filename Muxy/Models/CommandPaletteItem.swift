import Foundation

enum CommandPaletteSection: String, CaseIterable {
    case app = "App"
    case remoteCommand = "Remote Commands"
    case remote = "Remote Spaces"
    case snippet = "Snippets"
    case todo = "Todos"
    case file = "Files"
    case worktree = "Worktrees"

    var sortOrder: Int {
        Self.defaultOrder.firstIndex(of: self) ?? Self.defaultOrder.count
    }

    static let defaultOrder: [CommandPaletteSection] = [.app, .todo, .remote, .remoteCommand, .snippet, .file, .worktree]
    static let remoteSpaceOrder: [CommandPaletteSection] = [.remoteCommand, .snippet, .remote, .app, .todo, .file, .worktree]
}

enum CommandPaletteFileSearchPolicy {
    static func shouldSearchFiles(query: String) -> Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

enum RemoteCommandPaletteAction: String, CaseIterable {
    case openSession
    case copySSHCommand
    case systemOverview
    case updateLinux
    case reboot
    case powerOff
    case gpuStatus
    case gpuMonitor

    var title: String {
        switch self {
        case .openSession: "Open SSH Session"
        case .copySSHCommand: "Copy SSH Command"
        case .systemOverview: "System Overview"
        case .updateLinux: "Update Linux"
        case .reboot: "Reboot"
        case .powerOff: "Power Off"
        case .gpuStatus: "NVIDIA GPU Status"
        case .gpuMonitor: "NVIDIA GPU Monitor"
        }
    }

    var subtitle: String {
        switch self {
        case .openSession: "Open or focus the saved SSH session"
        case .copySSHCommand: "Copy the connection command"
        case .systemOverview: "hostname, uptime, disk, memory, and kernel"
        case .updateLinux: "sudo apt update && sudo apt upgrade -y"
        case .reboot: "sudo reboot"
        case .powerOff: "sudo poweroff"
        case .gpuStatus: "nvidia-smi"
        case .gpuMonitor: "nvtop"
        }
    }

    var confirmationTitle: String {
        switch self {
        case .reboot: "Confirm Reboot"
        case .powerOff: "Confirm Power Off"
        default: title
        }
    }

    var confirmationSubtitle: String {
        switch self {
        case .reboot: "Press Enter again to reboot the remote machine"
        case .powerOff: "Press Enter again to power off the remote machine"
        default: subtitle
        }
    }

    var symbolName: String {
        switch self {
        case .openSession: "terminal"
        case .copySSHCommand: "doc.on.doc"
        case .systemOverview: "gauge.with.dots.needle.bottom.50percent"
        case .updateLinux: "arrow.triangle.2.circlepath"
        case .reboot: "restart"
        case .powerOff: "power"
        case .gpuStatus: "display"
        case .gpuMonitor: "waveform.path.ecg"
        }
    }

    var searchText: String {
        switch self {
        case .openSession: "ssh connect session remote shell open space host"
        case .copySSHCommand: "copy ssh command connection host user clipboard"
        case .systemOverview: "linux status health hostname uptime df free uname memory disk overview"
        case .updateLinux: "linux apt update upgrade packages software limnux update"
        case .reboot: "linux restart sudo reboot reset bounce"
        case .powerOff: "linux shutdown sudo poweroff halt stop"
        case .gpuStatus: "nvidia gpu cuda driver status smi alien alienware graphics"
        case .gpuMonitor: "nvidia gpu monitor nvtop alien alienware graphics console"
        }
    }

    var command: String? {
        switch self {
        case .openSession,
             .copySSHCommand:
            nil
        case .systemOverview:
            "hostname && uptime && df -h && free -h && uname -a"
        case .updateLinux:
            "sudo apt update && sudo apt upgrade -y"
        case .reboot:
            "sudo reboot"
        case .powerOff:
            "sudo poweroff"
        case .gpuStatus:
            "nvidia-smi"
        case .gpuMonitor:
            "nvtop"
        }
    }

    var sortPriority: Int {
        switch self {
        case .openSession: 0
        case .copySSHCommand: 1
        case .systemOverview: 10
        case .updateLinux: 11
        case .reboot: 12
        case .powerOff: 13
        case .gpuStatus: 20
        case .gpuMonitor: 21
        }
    }

    var requiresConfirmation: Bool {
        switch self {
        case .reboot,
             .powerOff:
            true
        default:
            false
        }
    }

    func tabTitle(for space: RemoteSpace) -> String {
        "\(space.displayName) · \(title)"
    }

    func isAvailable(for space: RemoteSpace) -> Bool {
        switch self {
        case .gpuStatus,
             .gpuMonitor:
            space.displayName.lowercased().contains("alien")
                || space.displayName.lowercased().contains("nvidia")
                || space.effectiveThemeName?.lowercased().contains("alienware") == true
        default:
            true
        }
    }
}

struct CommandPaletteItem: Identifiable, Equatable {
    enum Target: Equatable {
        case shortcut(ShortcutAction)
        case remoteCommand(RemoteCommandPaletteAction)
        case remote(UUID)
        case snippet(UUID)
        case file(String)
        case worktree(projectID: UUID, worktreeID: UUID)
        case naturalCommand(String)
        case localPorts
        case projectTodo(UUID)
    }

    let id: String
    let title: String
    let subtitle: String
    let symbolName: String
    let section: CommandPaletteSection
    let searchText: String
    let target: Target
    let sortPriority: Int
    let requiresConfirmation: Bool
    let showsSectionHeader: Bool

    init(
        id: String,
        title: String,
        subtitle: String,
        symbolName: String,
        section: CommandPaletteSection,
        searchText: String = "",
        target: Target,
        sortPriority: Int = 0,
        requiresConfirmation: Bool = false,
        showsSectionHeader: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.section = section
        self.searchText = searchText
        self.target = target
        self.sortPriority = sortPriority
        self.requiresConfirmation = requiresConfirmation
        self.showsSectionHeader = showsSectionHeader
    }

    var normalizedSearchText: String {
        [title, subtitle, section.rawValue, searchText].joined(separator: " ").lowercased()
    }

    func matches(query: String) -> Bool {
        let terms = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .split(separator: " ")
        guard !terms.isEmpty else { return true }
        return terms.allSatisfy { normalizedSearchText.contains($0) }
    }

    static func filter(
        _ items: [CommandPaletteItem],
        query: String,
        sectionOrder: [CommandPaletteSection] = CommandPaletteSection.defaultOrder
    ) -> [CommandPaletteItem] {
        let sortedItems = items
            .filter { $0.matches(query: query) }
            .sorted { lhs, rhs in
                let lhsOrder = sectionOrder.firstIndex(of: lhs.section) ?? sectionOrder.count
                let rhsOrder = sectionOrder.firstIndex(of: rhs.section) ?? sectionOrder.count
                if lhsOrder != rhsOrder {
                    return lhsOrder < rhsOrder
                }
                if lhs.sortPriority != rhs.sortPriority {
                    return lhs.sortPriority < rhs.sortPriority
                }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        return markedSectionStarts(sortedItems)
    }

    private static func markedSectionStarts(_ items: [CommandPaletteItem]) -> [CommandPaletteItem] {
        var seenSections: Set<CommandPaletteSection> = []
        return items.map { item in
            let isFirst = !seenSections.contains(item.section)
            seenSections.insert(item.section)
            return item.withSectionHeader(isFirst)
        }
    }

    private func withSectionHeader(_ isVisible: Bool) -> CommandPaletteItem {
        CommandPaletteItem(
            id: id,
            title: title,
            subtitle: subtitle,
            symbolName: symbolName,
            section: section,
            searchText: searchText,
            target: target,
            sortPriority: sortPriority,
            requiresConfirmation: requiresConfirmation,
            showsSectionHeader: isVisible
        )
    }
}

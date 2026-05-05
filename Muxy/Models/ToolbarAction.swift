import Foundation

enum ToolbarAction: String, CaseIterable, Identifiable {
    case debug
    case tools
    case snippets
    case notes
    case todo
    case newTab
    case quickOpen
    case sourceControl
    case fileTree
    case splitRight
    case splitDown
    case updates

    static let storageKey = "muxy.toolbar.visibleActions"
    static let defaultActions: [ToolbarAction] = [.debug, .tools, .snippets, .notes, .todo, .newTab]
    static let defaultRawValue = defaultActions.map(\.rawValue).joined(separator: ",")

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .debug: "Debug"
        case .tools: "Tools menu"
        case .snippets: "Snippets"
        case .notes: "Notes"
        case .todo: "Todo"
        case .newTab: "New tab"
        case .quickOpen: "Quick Open"
        case .sourceControl: "Source Control"
        case .fileTree: "File Tree"
        case .splitRight: "Split Right"
        case .splitDown: "Split Down"
        case .updates: "Update Badge"
        }
    }

    var settingsDescription: String {
        switch self {
        case .debug: "Development diagnostics badge."
        case .tools: "Open the project or focused file in external tools."
        case .snippets: "Show or hide snippets."
        case .notes: "Show or hide project notes."
        case .todo: "Show or hide the project todo list."
        case .newTab: "Create a terminal tab."
        case .quickOpen: "Open file search from the toolbar."
        case .sourceControl: "Open Source Control from the toolbar."
        case .fileTree: "Show or hide the file tree."
        case .splitRight: "Split the focused pane to the right."
        case .splitDown: "Split the focused pane downward."
        case .updates: "Show available update badge in the toolbar."
        }
    }

    static func visibleActions(from rawValue: String) -> Set<ToolbarAction> {
        var actions = Set(rawValue
            .split(separator: ",")
            .compactMap { ToolbarAction(rawValue: String($0)) })
        let rawParts = Set(rawValue.split(separator: ",").map(String.init))
        if rawValue == "debug,tools,snippets,newTab" || rawParts.contains("inspector") {
            actions.insert(.notes)
            actions.insert(.todo)
        }
        return actions
    }

    static func rawValue(for actions: Set<ToolbarAction>) -> String {
        allCases
            .filter { actions.contains($0) }
            .map(\.rawValue)
            .joined(separator: ",")
    }
}

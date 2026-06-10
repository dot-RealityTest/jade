import Foundation

enum SnippetRunAction: Equatable {
    case sendToPane(paneID: UUID, text: String)
    case newTab(command: String, title: String)
    case refuse(reason: String)
}

struct SnippetRunFocus: Equatable {
    let paneID: UUID?
    let isLive: Bool
    let belongsToScope: Bool

    static let none = SnippetRunFocus(paneID: nil, isLive: false, belongsToScope: false)

    var livePaneID: UUID? {
        isLive ? paneID : nil
    }
}

@MainActor
enum SnippetRunner {
    static func run(scope: SnippetScope, command: String, title: String, appState: AppState) {
        let remoteSpace = scope.remoteSpaceID.flatMap { RemoteSpacesStore.shared.space(id: $0) }
        let focusedPane = NotificationNavigator.activePane(appState: appState)
        let focusedView = focusedPane.flatMap { TerminalViewRegistry.shared.view(for: $0.id) }

        let focus = SnippetRunFocus(
            paneID: focusedPane?.id,
            isLive: focusedView?.hasLiveSurface ?? false,
            belongsToScope: paneBelongs(focusedPane, to: remoteSpace)
        )

        let action = SnippetRunRouter.resolve(
            scope: scope,
            command: command,
            title: title,
            remoteSpace: remoteSpace,
            focus: focus
        )

        switch action {
        case let .sendToPane(paneID, text):
            sendToPane(paneID: paneID, text: text)
        case let .newTab(command, title):
            openTab(command: command, title: title, appState: appState)
        case let .refuse(reason):
            ToastState.shared.show(reason)
        }
    }

    private static func paneBelongs(_ pane: TerminalPaneState?, to space: RemoteSpace?) -> Bool {
        guard let pane, let space else { return false }
        return pane.startupCommand == space.connectionCommand
    }

    private static func sendToPane(paneID: UUID, text: String) {
        guard let view = TerminalViewRegistry.shared.view(for: paneID), view.hasLiveSurface else {
            ToastState.shared.show(SnippetRunRouter.remoteUnavailableReason)
            return
        }
        view.sendText(text)
        view.sendReturnKey()
    }

    private static func openTab(command: String, title: String, appState: AppState) {
        guard let projectID = appState.activeProjectID else {
            ToastState.shared.show("Select a project first")
            return
        }
        appState.dispatch(.createCommandTab(projectID: projectID, areaID: nil, name: title, command: command))
    }
}

enum SnippetRunRouter {
    static let remoteUnavailableReason = "Open the remote session before running this snippet."

    static func resolve(
        scope: SnippetScope,
        command: String,
        title: String,
        remoteSpace: RemoteSpace?,
        focus: SnippetRunFocus
    ) -> SnippetRunAction {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)

        guard scope.isRemote else {
            if let paneID = focus.livePaneID {
                return .sendToPane(paneID: paneID, text: trimmed)
            }
            return .newTab(command: trimmed, title: title)
        }

        guard let space = remoteSpace, space.isConnectable else {
            return .refuse(reason: remoteUnavailableReason)
        }

        if let paneID = focus.livePaneID, focus.belongsToScope {
            return .sendToPane(paneID: paneID, text: trimmed)
        }

        return .newTab(command: RemoteCommandBuilder.command(trimmed, for: space), title: title)
    }
}

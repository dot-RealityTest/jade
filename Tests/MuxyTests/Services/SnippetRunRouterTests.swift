import Foundation
import Testing

@testable import Muxy

@Suite("Snippet Run Router")
struct SnippetRunRouterTests {
    private let paneID = UUID()

    private func remoteScope(_ space: RemoteSpace) -> SnippetScope {
        SnippetScope.remote(space)
    }

    private var connectableSpace: RemoteSpace {
        RemoteSpace(name: "Alienware", user: "kika", host: "alienware.local")
    }

    private func focus(belongsToScope: Bool, live: Bool = true) -> SnippetRunFocus {
        SnippetRunFocus(paneID: paneID, isLive: live, belongsToScope: belongsToScope)
    }

    @Test("local scope with a live focused pane runs in that pane")
    func localScopeSendsToFocusedPane() {
        let action = SnippetRunRouter.resolve(
            scope: .shared,
            command: "ls -la",
            title: "List",
            remoteSpace: nil,
            focus: focus(belongsToScope: false)
        )
        #expect(action == .sendToPane(paneID: paneID, text: "ls -la"))
    }

    @Test("local scope without a live pane opens a local command tab")
    func localScopeFallsBackToLocalTab() {
        let action = SnippetRunRouter.resolve(
            scope: .shared,
            command: "ls -la",
            title: "List",
            remoteSpace: nil,
            focus: .none
        )
        #expect(action == .newTab(command: "ls -la", title: "List"))
    }

    @Test("remote scope that cannot resolve its space refuses instead of running locally")
    func remoteScopeUnresolvedRefuses() {
        let space = connectableSpace
        let action = SnippetRunRouter.resolve(
            scope: remoteScope(space),
            command: "reboot",
            title: "Reboot",
            remoteSpace: nil,
            focus: focus(belongsToScope: true)
        )
        #expect(action == .refuse(reason: SnippetRunRouter.remoteUnavailableReason))
    }

    @Test("remote scope with a non-connectable space refuses instead of running locally")
    func remoteScopeNotConnectableRefuses() {
        let action = SnippetRunRouter.resolve(
            scope: remoteScope(RemoteSpace(name: "Broken")),
            command: "reboot",
            title: "Reboot",
            remoteSpace: RemoteSpace(name: "Broken"),
            focus: focus(belongsToScope: true)
        )
        #expect(action == .refuse(reason: SnippetRunRouter.remoteUnavailableReason))
    }

    @Test("remote scope runs in the focused pane only when it belongs to that remote session")
    func remoteScopeSendsToOwnSession() {
        let space = connectableSpace
        let action = SnippetRunRouter.resolve(
            scope: remoteScope(space),
            command: "uptime",
            title: "Uptime",
            remoteSpace: space,
            focus: focus(belongsToScope: true)
        )
        #expect(action == .sendToPane(paneID: paneID, text: "uptime"))
    }

    @Test("remote scope never types into a local focused pane; it opens a remote tab")
    func remoteScopeWithLocalPaneOpensRemoteTab() {
        let space = connectableSpace
        let action = SnippetRunRouter.resolve(
            scope: remoteScope(space),
            command: "uptime",
            title: "Uptime",
            remoteSpace: space,
            focus: focus(belongsToScope: false)
        )
        guard case let .newTab(command, title) = action else {
            Issue.record("expected a new remote tab, got \(action)")
            return
        }
        #expect(command.contains("ssh"))
        #expect(command.contains("uptime"))
        #expect(title == "Uptime")
    }

    @Test("remote scope without a live pane opens an ssh-wrapped tab, never a local shell")
    func remoteScopeNoPaneOpensRemoteTab() {
        let space = connectableSpace
        let action = SnippetRunRouter.resolve(
            scope: remoteScope(space),
            command: "uptime",
            title: "Uptime",
            remoteSpace: space,
            focus: .none
        )
        guard case let .newTab(command, _) = action else {
            Issue.record("expected a new remote tab, got \(action)")
            return
        }
        #expect(command.contains("ssh"))
        #expect(command != "uptime")
    }
}

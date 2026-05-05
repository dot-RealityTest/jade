import Foundation
import Testing

@testable import Muxy

@Suite("LocalPortMonitor")
struct LocalPortMonitorTests {
    @Test("parser reads lsof field output")
    func parserReadsLsofFieldOutput() {
        let output = """
        p1234
        cnode
        u501
        f18
        PTCP
        n127.0.0.1:3000
        f19
        PTCP
        n[::1]:3000
        p777
        cpython
        u502
        PTCP
        n*:8000
        """

        let listeners = LocalPortSnapshotParser.parse(output)

        #expect(listeners.map(\.port) == [3000, 3000, 8000])
        #expect(listeners[0].address == "::1")
        #expect(listeners[1].address == "127.0.0.1")
        #expect(listeners[2].endpoint == "*:8000")
        #expect(listeners[2].command == "python")
        #expect(listeners[2].pid == 777)
    }

    @Test("monitor tracks removed listeners as dead")
    @MainActor
    func monitorTracksRemovedListenersAsDead() {
        let monitor = LocalPortMonitor(snapshotReader: LocalPortSnapshotReader(read: { [] }))
        let node = listener(port: 3000, pid: 10, command: "node")
        let python = listener(port: 8000, pid: 20, command: "python")
        let firstRefresh = Date(timeIntervalSince1970: 10)
        let secondRefresh = Date(timeIntervalSince1970: 20)

        monitor.replaceSnapshot([node, python], now: firstRefresh)
        monitor.replaceSnapshot([python], now: secondRefresh)

        #expect(monitor.active == [python])
        #expect(monitor.dead.map(\.listener) == [node])
        #expect(monitor.dead.first?.lastSeenAt == secondRefresh)
    }

    @Test("dead listeners are removed when they become active again")
    @MainActor
    func deadListenersAreRemovedWhenTheyBecomeActiveAgain() {
        let monitor = LocalPortMonitor(snapshotReader: LocalPortSnapshotReader(read: { [] }))
        let node = listener(port: 3000, pid: 10, command: "node")

        monitor.replaceSnapshot([node])
        monitor.replaceSnapshot([])
        monitor.replaceSnapshot([node])

        #expect(monitor.active == [node])
        #expect(monitor.dead.isEmpty)
    }

    private func listener(port: Int, pid: Int, command: String) -> LocalPortListener {
        LocalPortListener(
            pid: pid,
            command: command,
            userID: "501",
            protocolName: "TCP",
            address: "127.0.0.1",
            port: port
        )
    }
}

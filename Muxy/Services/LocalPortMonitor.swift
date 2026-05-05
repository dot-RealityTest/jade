import Foundation
import os

private let localPortLogger = Logger(subsystem: "app.muxy", category: "LocalPortMonitor")

struct LocalPortListener: Equatable, Identifiable {
    let pid: Int
    let command: String
    let userID: String
    let protocolName: String
    let address: String
    let port: Int

    var id: String {
        [protocolName, String(port), String(pid), address, command].joined(separator: ":")
    }

    var endpoint: String {
        "\(address):\(port)"
    }
}

struct DeadLocalPortListener: Equatable, Identifiable {
    let listener: LocalPortListener
    let lastSeenAt: Date

    var id: String { listener.id }
}

enum LocalPortSnapshotParser {
    static func parse(_ output: String) -> [LocalPortListener] {
        var listeners: [LocalPortListener] = []
        var process = LocalPortProcessFields()
        var seen: Set<String> = []

        for line in output.split(whereSeparator: \.isNewline).map(String.init) {
            guard let marker = line.first else { continue }
            let value = String(line.dropFirst())
            switch marker {
            case "p":
                process = LocalPortProcessFields(pid: Int(value))
            case "c":
                process.command = value
            case "u":
                process.userID = value
            case "P":
                process.protocolName = value.uppercased()
            case "n":
                guard let listener = process.listener(from: value), !seen.contains(listener.id) else { continue }
                listeners.append(listener)
                seen.insert(listener.id)
            default:
                continue
            }
        }

        return listeners.sorted { lhs, rhs in
            if lhs.port != rhs.port { return lhs.port < rhs.port }
            if lhs.command != rhs.command { return lhs.command.localizedCaseInsensitiveCompare(rhs.command) == .orderedAscending }
            if lhs.address != rhs.address { return lhs.address.localizedCaseInsensitiveCompare(rhs.address) == .orderedAscending }
            return lhs.pid < rhs.pid
        }
    }

    static func port(from endpoint: String) -> Int? {
        guard let separator = endpoint.lastIndex(of: ":") else { return nil }
        let suffix = endpoint[endpoint.index(after: separator)...]
        return Int(suffix)
    }

    static func address(from endpoint: String) -> String {
        guard let separator = endpoint.lastIndex(of: ":") else { return endpoint }
        let raw = String(endpoint[..<separator])
        let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
        return trimmed.isEmpty ? "*" : trimmed
    }
}

private struct LocalPortProcessFields {
    var pid: Int?
    var command = ""
    var userID = ""
    var protocolName = "TCP"

    func listener(from endpoint: String) -> LocalPortListener? {
        guard let pid, let port = LocalPortSnapshotParser.port(from: endpoint) else { return nil }
        return LocalPortListener(
            pid: pid,
            command: command.isEmpty ? "unknown" : command,
            userID: userID,
            protocolName: protocolName,
            address: LocalPortSnapshotParser.address(from: endpoint),
            port: port
        )
    }
}

struct LocalPortSnapshotReader {
    var read: @Sendable () async throws -> [LocalPortListener]

    static let live = LocalPortSnapshotReader {
        try await Task.detached(priority: .utility) {
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
            process.arguments = ["-nP", "-iTCP", "-sTCP:LISTEN", "-F", "pcunP"]
            process.standardOutput = pipe
            process.standardError = Pipe()
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return LocalPortSnapshotParser.parse(output)
        }.value
    }
}

@MainActor
@Observable
final class LocalPortMonitor {
    static let shared = LocalPortMonitor()

    private(set) var active: [LocalPortListener] = []
    private(set) var dead: [DeadLocalPortListener] = []
    private(set) var isRefreshing = false
    private(set) var lastRefreshedAt: Date?
    private(set) var errorMessage: String?
    private var snapshotReader: LocalPortSnapshotReader

    init(snapshotReader: LocalPortSnapshotReader = .live) {
        self.snapshotReader = snapshotReader
    }

    func refresh(now: Date = Date()) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let next = try await snapshotReader.read()
            mergeSnapshot(next, now: now)
            lastRefreshedAt = now
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            localPortLogger.error("Failed to refresh local ports: \(error.localizedDescription)")
        }
    }

    func replaceSnapshot(_ next: [LocalPortListener], now: Date = Date()) {
        mergeSnapshot(next, now: now)
        lastRefreshedAt = now
        errorMessage = nil
    }

    func clearDead() {
        dead = []
    }

    private func mergeSnapshot(_ next: [LocalPortListener], now: Date) {
        let nextIDs = Set(next.map(\.id))
        let removed = active.filter { !nextIDs.contains($0.id) }
        let existingDeadIDs = Set(dead.map(\.id))
        let newlyDead = removed
            .filter { !existingDeadIDs.contains($0.id) }
            .map { DeadLocalPortListener(listener: $0, lastSeenAt: now) }
        dead = (newlyDead + dead)
            .filter { !nextIDs.contains($0.id) }
            .prefix(100)
            .map(\.self)
        active = next
    }
}

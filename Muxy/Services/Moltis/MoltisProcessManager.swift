import Foundation
import os

private let processLogger = Logger(subsystem: "app.muxy", category: "MoltisProcessManager")

enum MoltisGatewayStatus: Equatable {
    case stopped
    case starting
    case running(port: Int, version: String?)
    case failed(message: String)
}

@MainActor
@Observable
final class MoltisProcessManager {
    static let shared = MoltisProcessManager()

    private(set) var status: MoltisGatewayStatus = .stopped
    private var process: Process?

    private init() {}

    var isRunning: Bool {
        if case .running = status { return true }
        return false
    }

    var port: Int? {
        if case let .running(port, _) = status { return port }
        return nil
    }

    func ensureRunning() async throws -> Int {
        if case let .running(port, _) = status {
            return port
        }
        stop()
        return try await start()
    }

    func restart() async throws -> Int {
        stop()
        return try await start()
    }

    func stop() {
        process?.terminate()
        process = nil
        status = .stopped
    }

    @discardableResult
    private func start() async throws -> Int {
        guard let executable = MoltisBundledBinary.executableURL(),
              let shareDir = MoltisBundledBinary.shareDirectoryURL()
        else {
            status = .failed(message: "Bundled Moltis binary is missing.")
            throw MoltisGatewayError.binaryUnavailable
        }

        status = .starting
        let port = MoltisPortAllocator.availablePort(
            preferred: MoltisAssistantSettings.shared.preferredGatewayPort
        )
        let commandSettings = NaturalCommandSettings.shared
        try MoltisConfigGenerator.writeConfig(
            port: port,
            ollamaBaseURL: commandSettings.ollamaBaseURL,
            ollamaModel: commandSettings.ollamaModel
        )

        let gateway = Process()
        gateway.executableURL = executable
        gateway.arguments = [
            "gateway",
            "--bind", "127.0.0.1",
            "--port", String(port),
            "--config-dir", MoltisStoragePaths.configDirectory().path,
            "--data-dir", MoltisStoragePaths.dataDirectory().path,
            "--share-dir", shareDir.path,
            "--no-tls",
        ]
        var environment = ProcessInfo.processInfo.environment
        environment["MOLTIS_AUTH_DISABLED"] = "1"
        gateway.environment = environment
        gateway.standardOutput = FileHandle.nullDevice
        gateway.standardError = FileHandle.nullDevice

        do {
            try gateway.run()
        } catch {
            status = .failed(message: error.localizedDescription)
            throw MoltisGatewayError.launchFailed(error.localizedDescription)
        }

        process = gateway

        let health = try await waitForHealth(port: port)
        status = .running(port: port, version: health.version)
        return port
    }

    private func waitForHealth(port: Int) async throws -> MoltisHealthResponse {
        guard let url = URL(string: "http://127.0.0.1:\(port)/health") else {
            throw MoltisGatewayError.healthCheckFailed
        }
        for attempt in 0 ..< 40 {
            if process?.isRunning == false {
                status = .failed(message: "Moltis gateway exited during startup.")
                throw MoltisGatewayError.launchFailed("Gateway exited during startup.")
            }
            var request = URLRequest(url: url)
            request.timeoutInterval = 1.5
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                    throw MoltisGatewayError.healthCheckFailed
                }
                let decoded = try JSONDecoder().decode(MoltisHealthResponse.self, from: data)
                if decoded.status == "ok" {
                    return decoded
                }
            } catch {
                if attempt == 39 {
                    status = .failed(message: "Moltis gateway did not become healthy.")
                    throw MoltisGatewayError.healthCheckFailed
                }
            }
            try await Task.sleep(nanoseconds: 250_000_000)
        }
        throw MoltisGatewayError.healthCheckFailed
    }
}

struct MoltisHealthResponse: Decodable {
    var status: String
    var version: String?
    var protocolVersion: Int?

    enum CodingKeys: String, CodingKey {
        case status
        case version
        case protocolVersion = "protocol"
    }
}

enum MoltisGatewayError: LocalizedError {
    case binaryUnavailable
    case launchFailed(String)
    case healthCheckFailed
    case notConnected
    case rpcFailed(String)
    case streamFailed(String)

    var errorDescription: String? {
        switch self {
        case .binaryUnavailable:
            "Moltis is not bundled with this build."
        case let .launchFailed(message):
            "Failed to start Moltis: \(message)"
        case .healthCheckFailed:
            "Moltis gateway health check failed."
        case .notConnected:
            "Not connected to Moltis gateway."
        case let .rpcFailed(message):
            message
        case let .streamFailed(message):
            message
        }
    }
}

import Foundation

struct MCPStdioSessionConfiguration {
    let pythonPath: String
    let serverScriptPath: String
    let environment: [String: String]
    let timeout: TimeInterval

    init(
        pythonPath: String,
        serverScriptPath: String,
        environment: [String: String],
        timeout: TimeInterval = 20
    ) {
        self.pythonPath = pythonPath
        self.serverScriptPath = serverScriptPath
        self.environment = environment
        self.timeout = timeout
    }
}

private final class MCPOutputCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var lineBuffer = ""
    private var responses: [Int: MCPJSONRPCResponse] = [:]

    func append(chunk: String) {
        lock.lock()
        defer { lock.unlock() }
        lineBuffer.append(chunk)
        while let newlineIndex = lineBuffer.firstIndex(of: "\n") {
            let line = String(lineBuffer[..<newlineIndex])
            lineBuffer = String(lineBuffer[lineBuffer.index(after: newlineIndex)...])
            guard let response = try? MCPJSONRPC.decodeResponseLine(line), !response.isNotification else {
                continue
            }
            if let id = response.id {
                responses[id] = response
            }
        }
    }

    func takeResponse(id: Int) -> MCPJSONRPCResponse? {
        lock.lock()
        defer { lock.unlock() }
        return responses.removeValue(forKey: id)
    }
}

enum MCPStdioSession {
    static func callTool(
        configuration: MCPStdioSessionConfiguration,
        toolName: String,
        encodedArguments: Data
    ) async throws -> [String: Any] {
        let encodedResult = try await Task.detached(priority: .userInitiated) {
            let decodedArguments = try JSONSerialization.jsonObject(with: encodedArguments) as? [String: Any] ?? [:]
            let result = try runSession(configuration: configuration) { sendRequest, waitForResponse in
                try sendRequest(
                    2,
                    "tools/call",
                    [
                        "name": toolName,
                        "arguments": decodedArguments,
                    ]
                )
                let toolResponse = try waitForResponse(2)
                if let error = toolResponse.error {
                    throw MCPClientError.toolFailed(error)
                }
                guard let responseResult = toolResponse.result else {
                    throw MCPClientError.invalidResponse
                }
                return try parseToolResult(responseResult)
            }
            return try JSONSerialization.data(withJSONObject: result)
        }.value
        guard let decodedResult = try JSONSerialization.jsonObject(with: encodedResult) as? [String: Any] else {
            throw MCPClientError.invalidResponse
        }
        return decodedResult
    }

    static func listTools(configuration: MCPStdioSessionConfiguration) async throws -> [MCPToolDescriptor] {
        try await Task.detached(priority: .userInitiated) {
            try runSession(configuration: configuration) { sendRequest, waitForResponse in
                try sendRequest(2, "tools/list", [:])
                let listResponse = try waitForResponse(2)
                if let error = listResponse.error {
                    throw MCPClientError.toolFailed(error)
                }
                guard let result = listResponse.result else {
                    throw MCPClientError.invalidResponse
                }
                let tools = ObsidianMCPToolCatalog.parseListToolsResponse(result)
                if tools.isEmpty {
                    return ObsidianMCPToolCatalog.builtIn
                }
                return tools
            }
        }.value
    }

    private static func runSession<T>(
        configuration: MCPStdioSessionConfiguration,
        operation: (
            _ sendRequest: (_ id: Int, _ method: String, _ params: [String: Any]) throws -> Void,
            _ waitForResponse: (_ id: Int) throws -> MCPJSONRPCResponse
        ) throws -> T
    ) throws -> T {
        let process = Process()
        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: configuration.pythonPath)
        process.arguments = [configuration.serverScriptPath]
        var env = ProcessInfo.processInfo.environment
        for (key, value) in configuration.environment {
            env[key] = value
        }
        process.environment = env
        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        let collector = MCPOutputCollector()

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            collector.append(chunk: chunk)
        }

        defer {
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            if process.isRunning {
                process.terminate()
            }
        }

        do {
            try process.run()
        } catch {
            throw MCPClientError.processLaunchFailed(error.localizedDescription)
        }

        func sendRequest(id: Int, method: String, params: [String: Any]) throws {
            let data = try MCPJSONRPC.encodeRequest(id: id, method: method, params: params)
            try stdinPipe.fileHandleForWriting.write(contentsOf: data)
        }

        func waitForResponse(id: Int) throws -> MCPJSONRPCResponse {
            let deadline = Date().addingTimeInterval(configuration.timeout)
            while Date() < deadline {
                if let response = collector.takeResponse(id: id) {
                    return response
                }
                Thread.sleep(forTimeInterval: 0.02)
            }
            throw MCPClientError.requestTimedOut
        }

        try sendRequest(
            id: 1,
            method: "initialize",
            params: [
                "protocolVersion": "2024-11-05",
                "capabilities": [:] as [String: Any],
                "clientInfo": [
                    "name": AppIdentity.displayName,
                    "version": "1.0.0",
                ],
            ]
        )

        let initializeResponse = try waitForResponse(id: 1)
        if let error = initializeResponse.error {
            throw MCPClientError.toolFailed(error)
        }

        try stdinPipe.fileHandleForWriting.write(
            contentsOf: MCPJSONRPC.encodeNotification(method: "notifications/initialized")
        )

        return try operation(sendRequest, waitForResponse)
    }

    private static func parseToolResult(_ result: Any) throws -> [String: Any] {
        guard let dictionary = result as? [String: Any] else {
            throw MCPClientError.invalidResponse
        }

        if dictionary["isError"] as? Bool == true {
            let message = extractText(from: dictionary) ?? "MCP tool failed"
            throw MCPClientError.toolFailed(message)
        }

        if let structured = dictionary["structuredContent"] as? [String: Any] {
            return try validateToolPayload(structured)
        }

        if let text = extractText(from: dictionary),
           let data = text.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data)
        {
            if let object = parsed as? [String: Any] {
                return try validateToolPayload(object)
            }
            if let array = parsed as? [[String: Any]] {
                if let first = array.first, let error = first["error"] as? String {
                    throw MCPClientError.toolFailed(error)
                }
                return ["notes": array, "count": array.count]
            }
        }

        return try validateToolPayload(dictionary)
    }

    private static func validateToolPayload(_ payload: [String: Any]) throws -> [String: Any] {
        if let success = payload["success"] as? Bool, !success {
            let message = payload["error"] as? String ?? payload["message"] as? String ?? "MCP tool failed"
            throw MCPClientError.toolFailed(message)
        }
        if let error = payload["error"] as? String {
            throw MCPClientError.toolFailed(error)
        }
        return payload
    }

    private static func extractText(from result: [String: Any]) -> String? {
        guard let content = result["content"] as? [[String: Any]] else { return nil }
        return content.compactMap { block in
            guard block["type"] as? String == "text" else { return nil }
            return block["text"] as? String
        }
        .joined(separator: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

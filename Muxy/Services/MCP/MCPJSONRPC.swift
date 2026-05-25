import Foundation

enum MCPJSONRPC {
    static func encodeRequest(id: Int, method: String, params: [String: Any]) throws -> Data {
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
            "params": params,
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        guard var line = String(data: data, encoding: .utf8) else {
            throw MCPClientError.encodingFailed
        }
        line.append("\n")
        guard let encoded = line.data(using: .utf8) else {
            throw MCPClientError.encodingFailed
        }
        return encoded
    }

    static func encodeNotification(method: String, params: [String: Any] = [:]) throws -> Data {
        var payload: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
        ]
        if !params.isEmpty {
            payload["params"] = params
        }
        let data = try JSONSerialization.data(withJSONObject: payload)
        guard var line = String(data: data, encoding: .utf8) else {
            throw MCPClientError.encodingFailed
        }
        line.append("\n")
        guard let encoded = line.data(using: .utf8) else {
            throw MCPClientError.encodingFailed
        }
        return encoded
    }

    static func decodeResponseLine(_ line: String) throws -> MCPJSONRPCResponse {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MCPClientError.invalidResponse
        }
        guard let data = trimmed.data(using: .utf8),
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw MCPClientError.invalidResponse
        }
        if object["method"] is String {
            return MCPJSONRPCResponse(id: nil, result: nil, error: nil, isNotification: true)
        }
        let id = object["id"] as? Int
        if let errorObject = object["error"] as? [String: Any] {
            let message = errorObject["message"] as? String ?? "Unknown MCP error"
            return MCPJSONRPCResponse(id: id, result: nil, error: message, isNotification: false)
        }
        return MCPJSONRPCResponse(id: id, result: object["result"], error: nil, isNotification: false)
    }
}

struct MCPJSONRPCResponse {
    let id: Int?
    let result: Any?
    let error: String?
    let isNotification: Bool
}

enum MCPClientError: LocalizedError {
    case encodingFailed
    case invalidResponse
    case processLaunchFailed(String)
    case processUnavailable
    case requestTimedOut
    case toolFailed(String)
    case notConfigured(String)

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            "Could not encode MCP request"
        case .invalidResponse:
            "Unexpected MCP response"
        case let .processLaunchFailed(message):
            message
        case .processUnavailable:
            "MCP process is not running"
        case .requestTimedOut:
            "MCP request timed out"
        case let .toolFailed(message):
            message
        case let .notConfigured(message):
            message
        }
    }
}

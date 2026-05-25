import Foundation

enum MoltisProtocol {
    static let minVersion = 3
    static let maxVersion = 4

    struct Request: Encodable {
        var type = "req"
        var id: String
        var method: String
        var params: [String: AnyCodable]?
    }

    struct Response: Decodable {
        var type: String?
        var id: String?
        var ok: Bool?
        var payload: [String: AnyCodable]?
        var error: RPCError?

        struct RPCError: Decodable {
            var code: String?
            var message: String?
        }
    }

    struct Event: Decodable {
        var type: String?
        var event: String?
        var payload: ChatPayload?
        var stream: String?
        var done: Bool?
    }

    struct ChatPayload: Decodable {
        var sessionKey: String?
        var state: String?
        var text: String?
        var tool: String?
        var result: String?
        var runId: String?
        var rejected: Bool?
    }

    static func connectParams() -> [String: AnyCodable] {
        [
            "protocol": AnyCodable([
                "min": minVersion,
                "max": maxVersion,
            ]),
            "client": AnyCodable([
                "id": "jade",
                "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0",
                "platform": "macos",
                "mode": "operator",
            ]),
        ]
    }

    static func subscribeParams() -> [String: AnyCodable] {
        ["events": AnyCodable(["chat"])]
    }

    static func chatSendParams(
        message: String,
        sessionKey: String,
        contextPrefix: String?
    ) -> [String: AnyCodable] {
        let body: String = if let contextPrefix, !contextPrefix.isEmpty {
            "\(contextPrefix)\n\n\(message)"
        } else {
            message
        }
        return [
            "message": AnyCodable(body),
            "sessionKey": AnyCodable(sessionKey),
        ]
    }
}

struct AnyCodable: Codable, @unchecked Sendable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map(\.value)
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues(\.value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unsupported JSON value")
            throw EncodingError.invalidValue(value, context)
        }
    }

    var stringValue: String? { value as? String }
    var boolValue: Bool? { value as? Bool }
    var dictionaryValue: [String: Any]? { value as? [String: Any] }
}

extension MoltisProtocol.Response {
    var errorMessage: String? {
        error?.message
    }

    var runID: String? {
        payload?["runId"]?.stringValue
    }
}

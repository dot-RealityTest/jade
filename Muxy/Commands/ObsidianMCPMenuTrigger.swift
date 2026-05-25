import Foundation

enum ObsidianMCPToolUserInfoKey {
    static let action = "action"
    static let query = "query"
}

enum ObsidianMCPMenuTrigger {
    static func run(_ action: ObsidianMCPToolAction, query: String? = nil) {
        var userInfo: [String: Any] = [ObsidianMCPToolUserInfoKey.action: action.rawValue]
        if let query {
            userInfo[ObsidianMCPToolUserInfoKey.query] = query
        }
        NotificationCenter.default.post(name: .runObsidianMCPTool, object: nil, userInfo: userInfo)
    }

    static func promptSearch() {
        NotificationCenter.default.post(name: .promptObsidianSearch, object: nil)
    }

    static func decodedAction(from notification: Notification) -> ObsidianMCPToolAction? {
        guard let raw = notification.userInfo?[ObsidianMCPToolUserInfoKey.action] as? String else { return nil }
        return ObsidianMCPToolAction(rawValue: raw)
    }

    static func decodedQuery(from notification: Notification) -> String? {
        notification.userInfo?[ObsidianMCPToolUserInfoKey.query] as? String
    }
}

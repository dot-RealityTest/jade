import Foundation
import os

private let backendLogger = Logger(subsystem: "app.muxy", category: "MoltisChatBackend")

@MainActor
enum MoltisChatBackend {
    private static let gatewayClient = MoltisGatewayClient()

    static func isAvailable() -> Bool {
        MoltisAssistantSettings.isExperimentalAvailable && MoltisBundledBinary.isAvailable
    }

    static func stream(
        context: InspectorChatContext,
        onUpdate: @escaping (String) -> Void
    ) async throws {
        let port = try await MoltisProcessManager.shared.ensureRunning()
        try await gatewayClient.connect(port: port)

        let sessionKey = MoltisSessionMappingStore.sessionKey(for: context.projectID)
        MoltisSessionMappingStore.record(projectID: context.projectID, sessionKey: sessionKey)

        let contextPrefix = buildContextPrefix(
            projectPath: context.projectPath,
            activeFile: context.activeFile
        )

        var accumulated = ""
        for await event in await gatewayClient.streamChat(
            message: context.prompt,
            sessionKey: sessionKey,
            contextPrefix: contextPrefix
        ) {
            try Task.checkCancellation()
            switch event.kind {
            case let .textDelta(text):
                accumulated += text
                onUpdate(accumulated)
            case .thinking:
                break
            case let .toolStart(name):
                let line = "\n\n🔧 **\(name)** …\n"
                accumulated += line
                onUpdate(accumulated)
            case let .toolEnd(name, rejected):
                let status = rejected ? "rejected" : "done"
                let line = "🔧 **\(name)** \(status)\n\n"
                accumulated += line
                onUpdate(accumulated)
            case let .notice(text):
                accumulated = text
                onUpdate(accumulated)
            case .final:
                break
            }
        }
    }

    static func cancelActiveRun() async {
        await gatewayClient.abortActiveRun()
        await gatewayClient.disconnect()
    }

    private static func buildContextPrefix(
        projectPath: String?,
        activeFile: String?
    ) -> String {
        var lines: [String] = [
            "You are Jade's inspector assistant embedded in a macOS terminal multiplexer.",
            "Never assume terminal pane stdin/stdout access.",
            "Mode: Ask — chat only, no tool execution.",
        ]
        if let projectPath {
            lines.append("Project root: \(projectPath)")
        }
        if let activeFile {
            lines.append("Open file: \(activeFile)")
        }
        return lines.joined(separator: "\n")
    }
}

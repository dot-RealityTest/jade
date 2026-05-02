import Foundation

enum RemoteCommandBuilder {
    static func command(_ command: String, for space: RemoteSpace) -> String {
        let command = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else { return "" }
        var space = space
        space.startupCommands = space.normalizedStartupCommands + [command]
        return space.connectionCommand
    }
}

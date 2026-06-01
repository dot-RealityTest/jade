import Testing

@testable import Muxy

@Suite("RemoteCommandBuilder")
struct RemoteCommandBuilderTests {
    @Test("wraps commands through remote ssh profile")
    func wrapsCommandThroughSSH() {
        let space = RemoteSpace(
            name: "Alienware",
            user: "dev",
            host: "203.0.113.10",
            port: 2222
        )

        let command = RemoteCommandBuilder.command("nvidia-smi", for: space)

        #expect(command.contains("ssh"))
        #expect(command.contains("-t"))
        #expect(command.contains("-p"))
        #expect(command.contains("2222"))
        #expect(command.contains("dev@203.0.113.10"))
        #expect(command.contains("nvidia-smi"))
    }

    @Test("keeps existing startup commands before selected command")
    func keepsExistingStartupCommands() {
        let space = RemoteSpace(
            name: "Zen",
            user: "dev",
            host: "203.0.113.20",
            startupCommands: ["cd ~/projects"]
        )

        let command = RemoteCommandBuilder.command("uptime", for: space)

        #expect(command.contains("cd ~/projects && uptime"))
    }

    @Test("empty commands stay empty")
    func emptyCommandsStayEmpty() {
        let space = RemoteSpace(name: "Zen", user: "dev", host: "203.0.113.20")

        #expect(RemoteCommandBuilder.command("  ", for: space).isEmpty)
    }
}

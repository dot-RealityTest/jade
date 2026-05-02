import Foundation
import Testing

@testable import Muxy

@Suite("RemoteSpace")
struct RemoteSpaceTests {
    @Test("trims name and command")
    func trimsNameAndCommand() {
        let space = RemoteSpace(name: " Zen ", command: " ssh kika@100.86.62.100 ")

        #expect(space.displayName == "Zen")
        #expect(space.trimmedCommand == "ssh kika@100.86.62.100")
        #expect(space.connectionCommand == "ssh kika@100.86.62.100")
        #expect(space.isConnectable)
    }

    @Test("structured profile generates SSH command")
    func structuredProfileGeneratesSSHCommand() {
        let space = RemoteSpace(
            name: "Zen",
            colorID: "blue",
            user: "kika",
            host: "100.86.62.100",
            port: 2222,
            identityFile: "~/.ssh/id_ed25519",
            jumpHost: "bastion",
            startupCommands: ["cd ~/code", "tmux attach || tmux new"]
        )

        #expect(space.connectionSummary == "kika@100.86.62.100:2222")
        #expect(
            space.connectionCommand ==
                "ssh -t -p 2222 -i ~/.ssh/id_ed25519 -J bastion kika@100.86.62.100 'cd ~/code && tmux attach || tmux new; exec ${SHELL:-/bin/sh} -l'"
        )
    }

    @Test("simple SSH command parses into profile fields")
    func simpleSSHCommandParsesIntoProfileFields() throws {
        let parsed = try #require(RemoteSpace.parsedSSHCommand("ssh -p 2222 -i ~/.ssh/id_ed25519 -J bastion kika@100.86.62.100"))

        #expect(parsed.user == "kika")
        #expect(parsed.host == "100.86.62.100")
        #expect(parsed.port == 2222)
        #expect(parsed.identityFile == "~/.ssh/id_ed25519")
        #expect(parsed.jumpHost == "bastion")
    }

    @Test("blank name falls back to Remote")
    func blankNameFallback() {
        let space = RemoteSpace(name: " ", command: "ssh host")

        #expect(space.displayName == "Remote")
    }

    @Test("remote names resolve default themes")
    func remoteNamesResolveDefaultThemes() {
        #expect(RemoteSpace(name: "Zen", command: "ssh host").effectiveThemeName == "Muxy Zen")
        #expect(RemoteSpace(name: "Alienware", command: "ssh host").effectiveThemeName == "Muxy Alienware")
        #expect(RemoteSpace(name: "Server", command: "ssh host").effectiveThemeName == nil)
        #expect(RemoteSpace(name: "Server", command: "ssh host", themeName: "Muxy").effectiveThemeName == "Muxy")
    }

    @Test("storage slug is stable and filesystem safe")
    func storageSlugIsStableAndFilesystemSafe() {
        let space = RemoteSpace(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: " Zen Linux Box ",
            command: "ssh host"
        )

        #expect(space.storageSlug == "zen-linux-box")
        #expect(space.backingDirectory(create: false).lastPathComponent == "zen-linux-box")
        #expect(space.snippetsFileURL.lastPathComponent == "snippets.json")
    }
}

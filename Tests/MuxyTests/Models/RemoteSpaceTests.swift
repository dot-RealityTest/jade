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
        #expect(space.isConnectable)
    }

    @Test("blank name falls back to Remote")
    func blankNameFallback() {
        let space = RemoteSpace(name: " ", command: "ssh host")

        #expect(space.displayName == "Remote")
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

import Foundation
import Testing

@testable import Muxy

@Suite("SnippetScope")
struct SnippetScopeTests {
    @Test("remote scope uses remote snippets file")
    func remoteScopeUsesRemoteSnippetsFile() {
        let space = RemoteSpace(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Zen",
            command: "ssh host"
        )

        let scope = SnippetScope.remote(space)

        #expect(scope.id == "remote-\(space.id.uuidString)")
        #expect(scope.displayName == "Zen Snippets")
        #expect(scope.fileURL.path == space.snippetsFileURL.path)
        #expect(scope.starterSnippets.contains { $0.command.contains("journalctl") })
        #expect(scope.starterSnippets.allSatisfy { $0.tags.contains("linux") })
    }
}

import Foundation
import Testing

@testable import Muxy

@Suite("SnippetScope")
struct SnippetScopeTests {
    @Test("shared scope includes local port starter snippet")
    func sharedScopeIncludesLocalPortStarterSnippet() {
        let scope = SnippetScope.shared

        #expect(scope.starterSnippets.contains {
            $0.name == "Listening Ports" && $0.command == "lsof -nP -iTCP -sTCP:LISTEN"
        })
    }

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

    @Test("project scope uses per-project snippets file")
    func projectScopeUsesProjectSnippetsFile() {
        let project = Project(name: "Muxy", path: "/tmp/muxy")
        let scope = SnippetScope.project(project)

        #expect(scope.id == "project-\(project.id.uuidString)")
        #expect(scope.displayName == "Muxy Snippets")
        #expect(scope.fileURL == SnippetScope.projectSnippetsFileURL(projectID: project.id))
        #expect(scope.starterSnippets.isEmpty)
    }

    @Test("shared scope display name is general")
    func sharedScopeDisplayName() {
        #expect(SnippetScope.shared.displayName == "General Snippets")
    }
}

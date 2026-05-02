import Foundation
import Testing

@testable import Muxy

@Suite("Snippet")
struct SnippetTests {
    @Test("normalizes tag text")
    func normalizesTagText() {
        #expect(Snippet.normalizedTags(from: " Git, #Docker docker\nDeploy ") == ["git", "docker", "deploy"])
    }

    @Test("displayName falls back to command title")
    func displayNameFallback() {
        let snippet = Snippet(name: " ", command: " swift test --filter SnippetTests ")

        #expect(snippet.displayName == "swift test --filter SnippetTests")
    }

    @Test("trims runnable command")
    func trimsRunnableCommand() {
        let snippet = Snippet(name: "Tests", command: " swift test ")

        #expect(snippet.trimmedCommand == "swift test")
        #expect(snippet.isRunnable)
    }

    @Test("decodes legacy snippets without new fields")
    func decodesLegacySnippetsWithoutNewFields() throws {
        let data = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "name": "Status",
          "command": "git status",
          "tags": ["git"]
        }
        """.data(using: .utf8)!

        let snippet = try JSONDecoder().decode(Snippet.self, from: data)

        #expect(snippet.description.isEmpty)
        #expect(snippet.variableDefaults.isEmpty)
        #expect(snippet.displayName == "Status")
    }

    @Test("extracts and resolves command variables")
    func extractsAndResolvesCommandVariables() {
        let snippet = Snippet(
            name: "Service Logs",
            command: "journalctl -u {service} -n {count} && echo {service}",
            variableDefaults: ["service": "ssh", "count": "50", "unused": "x"]
        )

        #expect(snippet.variables == ["service", "count"])
        #expect(snippet.resolvedCommand(values: ["count": "100"]) == "journalctl -u ssh -n 100 && echo ssh")
    }
}

import Foundation

enum OllamaCommand {
    static let installURL = "https://ollama.com"
    static let defaultModel = "llama3.2"

    static var listScript: String {
        ollamaScript(runCommand: "ollama list", keepShellAfterSuccess: true)
    }

    static var serveScript: String {
        ollamaScript(runCommand: "ollama serve", keepShellAfterSuccess: false)
    }

    static func pullScript(model: String) -> String {
        ollamaScript(
            runCommand: "ollama pull \(ShellEscaper.escape(resolvedModel(model)))",
            keepShellAfterSuccess: true
        )
    }

    static func runScript(model: String) -> String {
        ollamaScript(
            runCommand: "ollama run \(ShellEscaper.escape(resolvedModel(model)))",
            keepShellAfterSuccess: false
        )
    }

    static func resolvedModel(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return defaultModel }
        return trimmed
    }

    private static func ollamaScript(runCommand: String, keepShellAfterSuccess: Bool) -> String {
        LocalShellCommand.whenToolAvailable(
            "ollama",
            missingMessage: "Ollama is not installed. Install it from \(installURL)",
            run: runCommand,
            keepShellAfterSuccess: keepShellAfterSuccess
        )
    }
}

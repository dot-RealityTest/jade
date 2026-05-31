import Testing

@testable import Muxy

@Suite("OllamaCommand")
struct OllamaCommandTests {
    @Test("list and serve scripts invoke ollama")
    func listAndServeScriptsInvokeOllama() {
        #expect(OllamaCommand.listScript.contains("ollama list"))
        #expect(OllamaCommand.listScript.contains("exec \"$SHELL\" -l"))
        #expect(OllamaCommand.serveScript.contains("exec ollama serve"))
    }

    @Test("list script bootstraps PATH for GUI shells")
    func listScriptBootstrapsPathForGUIShells() {
        #expect(OllamaCommand.listScript.contains("/opt/homebrew/bin"))
        #expect(OllamaCommand.listScript.contains("/usr/local/bin"))
    }

    @Test("pull and run scripts use resolved model")
    func pullAndRunScriptsUseResolvedModel() {
        let pull = OllamaCommand.pullScript(model: "qwen2.5-coder:7b")
        let run = OllamaCommand.runScript(model: "qwen2.5-coder:7b")
        #expect(pull.contains("ollama pull qwen2.5-coder:7b"))
        #expect(run.contains("ollama run qwen2.5-coder:7b"))
    }

    @Test("resolved model falls back when empty")
    func resolvedModelFallsBackWhenEmpty() {
        #expect(OllamaCommand.resolvedModel("") == OllamaCommand.defaultModel)
        #expect(OllamaCommand.resolvedModel("  ") == OllamaCommand.defaultModel)
        #expect(OllamaCommand.resolvedModel("mistral") == "mistral")
    }

    @Test("shell script explains install when ollama is missing")
    func shellScriptExplainsInstallWhenOllamaIsMissing() {
        #expect(OllamaCommand.listScript.contains(OllamaCommand.installURL))
        #expect(OllamaCommand.listScript.contains("Ollama is not installed"))
    }
}

import Testing
@testable import Muxy

@Test func moltisOllamaBridgeNormalizesBaseURL() {
    #expect(MoltisOllamaBridge.normalizedBaseURL("http://localhost:11434") == "http://localhost:11434/v1")
    #expect(MoltisOllamaBridge.normalizedBaseURL("http://localhost:11434/v1") == "http://localhost:11434/v1")
    #expect(MoltisOllamaBridge.normalizedBaseURL("http://localhost:11434/") == "http://localhost:11434/v1")
}

@Test func moltisOllamaBridgeResolvesEmptyModel() {
    #expect(MoltisOllamaBridge.resolvedModel("") == "llama3.2")
    #expect(MoltisOllamaBridge.resolvedModel("qwen2.5-coder:7b") == "qwen2.5-coder:7b")
}

@Test func moltisOllamaBridgeQuotesTomlStrings() {
    #expect(MoltisOllamaBridge.tomlQuoted("llama3.2") == "\"llama3.2\"")
    #expect(MoltisOllamaBridge.tomlQuoted("qwen2.5-coder:7b") == "\"qwen2.5-coder:7b\"")
}

@Test func moltisAssistantBackendMigratesLegacyStoredValues() {
    #expect(MoltisAssistantBackend.resolved(stored: "Moltis + Ollama") == .both)
    #expect(MoltisAssistantBackend.resolved(stored: "Ollama direct") == .ollamaDirect)
    #expect(MoltisAssistantBackend.resolved(stored: MoltisAssistantBackend.both.rawValue) == .both)
}

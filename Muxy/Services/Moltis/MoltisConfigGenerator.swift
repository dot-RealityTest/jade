import Foundation

enum MoltisConfigGenerator {
    static func writeConfig(
        port: Int,
        ollamaBaseURL: String,
        ollamaModel: String
    ) throws {
        let configURL = MoltisStoragePaths.configDirectory().appendingPathComponent("moltis.toml")
        let baseURL = MoltisOllamaBridge.normalizedBaseURL(ollamaBaseURL)
        let model = MoltisOllamaBridge.resolvedModel(ollamaModel)
        let quotedModel = MoltisOllamaBridge.tomlQuoted(model)
        let quotedBaseURL = MoltisOllamaBridge.tomlQuoted(baseURL)
        let contents = """
        [server]
        bind = "127.0.0.1"
        port = \(port)
        tls = false

        [auth]
        disabled = true

        [providers]
        offered = ["ollama"]

        [providers.ollama]
        enabled = true
        base_url = \(quotedBaseURL)
        models = [\(quotedModel)]
        fetch_models = true

        [chat]
        priority_models = [\(quotedModel)]

        [tools]
        agent_max_iterations = 0
        """
        try contents.write(to: configURL, atomically: true, encoding: .utf8)
    }
}

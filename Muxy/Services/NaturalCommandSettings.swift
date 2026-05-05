import Foundation

enum NaturalCommandBackendMode: String, CaseIterable, Identifiable {
    case automatic = "Automatic"
    case apple = "Apple"
    case ollama = "Ollama"

    var id: String { rawValue }
}

@MainActor
@Observable
final class NaturalCommandSettings {
    static let shared = NaturalCommandSettings()

    private enum Key {
        static let enabled = "naturalCommands.enabled"
        static let backendMode = "naturalCommands.backendMode"
        static let ollamaBaseURL = "naturalCommands.ollamaBaseURL"
        static let ollamaModel = "naturalCommands.ollamaModel"
    }

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Key.enabled, fallback: true) }
        set { UserDefaults.standard.set(newValue, forKey: Key.enabled) }
    }

    var backendMode: String {
        get {
            UserDefaults.standard.string(forKey: Key.backendMode)
                ?? NaturalCommandBackendMode.automatic.rawValue
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.backendMode) }
    }

    var ollamaBaseURL: String {
        get {
            UserDefaults.standard.string(forKey: Key.ollamaBaseURL)
                ?? "http://localhost:11434"
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.ollamaBaseURL) }
    }

    var ollamaModel: String {
        get {
            UserDefaults.standard.string(forKey: Key.ollamaModel)
                ?? "llama3.2"
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.ollamaModel) }
    }

    var resolvedBackendMode: NaturalCommandBackendMode {
        NaturalCommandBackendMode(rawValue: backendMode) ?? .automatic
    }
}

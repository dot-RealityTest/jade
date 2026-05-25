import Foundation

enum MoltisAssistantBackend: String, CaseIterable, Identifiable {
    case both = "Both (Moltis first)"
    case ollamaDirect = "Ollama direct only"

    var id: String { rawValue }

    var helpText: String {
        switch self {
        case .both:
            "Try the bundled Moltis gateway using Ollama, then fall back to direct Ollama chat if needed."
        case .ollamaDirect:
            "Skip Moltis and talk to Ollama only (no agent tools)."
        }
    }

    static func resolved(stored: String) -> MoltisAssistantBackend? {
        if let value = MoltisAssistantBackend(rawValue: stored) {
            return value
        }
        switch stored {
        case "Moltis (bundled)",
             "Moltis + Ollama",
             "moltis":
            return .both
        case "Ollama",
             "Ollama direct",
             "ollama":
            return .ollamaDirect
        default:
            return nil
        }
    }
}

@MainActor
@Observable
final class MoltisAssistantSettings {
    static let shared = MoltisAssistantSettings()

    private static let backendKey = "muxy.moltis.backend"
    private static let fallbackKey = "muxy.moltis.fallbackToOllama"
    private static let portKey = "muxy.moltis.gatewayPort"

    static var isExperimentalAvailable: Bool {
        AppEnvironment.isDevelopment
    }

    var backend: MoltisAssistantBackend {
        didSet { UserDefaults.standard.set(backend.rawValue, forKey: Self.backendKey) }
    }

    var fallbackToOllama: Bool {
        didSet { UserDefaults.standard.set(fallbackToOllama, forKey: Self.fallbackKey) }
    }

    var preferredGatewayPort: Int {
        didSet { UserDefaults.standard.set(preferredGatewayPort, forKey: Self.portKey) }
    }

    private init() {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: Self.backendKey),
           let value = MoltisAssistantBackend.resolved(stored: raw),
           Self.isExperimentalAvailable
        {
            backend = value
        } else {
            backend = .ollamaDirect
        }
        if defaults.object(forKey: Self.fallbackKey) == nil {
            fallbackToOllama = true
        } else {
            fallbackToOllama = defaults.bool(forKey: Self.fallbackKey)
        }
        let storedPort = defaults.integer(forKey: Self.portKey)
        preferredGatewayPort = storedPort > 0 ? storedPort : 4877
    }

    var usesMoltisFirst: Bool {
        Self.isExperimentalAvailable && backend == .both && MoltisBundledBinary.isAvailable
    }

    var usesDirectOllamaOnly: Bool {
        backend == .ollamaDirect || !usesMoltisFirst
    }

    var backendSelection: String {
        get { backend.rawValue }
        set {
            guard Self.isExperimentalAvailable,
                  let value = MoltisAssistantBackend.resolved(stored: newValue)
            else { return }
            backend = value
        }
    }
}

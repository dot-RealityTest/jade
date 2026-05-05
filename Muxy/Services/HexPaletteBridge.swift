import AppKit
import Foundation

enum HexPaletteBridge {
    static let suiteName = "com.kika.colorbar"
    static let customPalettesKey = "kika.customPalettes"
    static let lastPaletteKey = "kika.lastPalette"
    static let importNotificationName = Notification.Name("com.kika.colorbar.importPalette")

    enum BridgeError: Error {
        case defaultsUnavailable
        case notificationPayloadUnavailable
    }

    struct HexPaletteColor: Codable, Equatable {
        let hex: String
        let name: String
    }

    struct HexPalette: Codable, Equatable, Identifiable {
        let id: String
        let name: String
        let category: String
        let style: String
        let description: String
        let colors: [HexPaletteColor]
    }

    @discardableResult
    static func sync(
        theme: ThemePreview,
        defaults: UserDefaults? = UserDefaults(suiteName: suiteName),
        notify: Bool = true
    ) throws -> HexPalette {
        guard let defaults else { throw BridgeError.defaultsUnavailable }

        let palette = makePalette(from: theme)
        var palettes = loadPalettes(from: defaults)
        if let index = palettes.firstIndex(where: { $0.id == palette.id }) {
            palettes[index] = palette
        } else {
            palettes.insert(palette, at: 0)
        }

        try defaults.set(JSONEncoder().encode(palettes), forKey: customPalettesKey)
        defaults.set(palette.id, forKey: lastPaletteKey)
        defaults.synchronize()
        if notify {
            try notifyHex(palette)
        }
        return palette
    }

    static func makePalette(from theme: ThemePreview) -> HexPalette {
        let terminalColors = theme.palette.enumerated().map { index, color in
            HexPaletteColor(hex: hexString(from: color), name: "Terminal \(index)")
        }

        return HexPalette(
            id: "jade-\(slug(from: theme.name))",
            name: "Jade \(theme.name)",
            category: "Jade",
            style: "Terminal Theme",
            description: "Synced from Jade theme picker",
            colors: [
                HexPaletteColor(hex: hexString(from: theme.background), name: "Background"),
                HexPaletteColor(hex: hexString(from: theme.foreground), name: "Foreground"),
            ] + terminalColors
        )
    }

    static func loadPalettes(from defaults: UserDefaults) -> [HexPalette] {
        guard let data = defaults.data(forKey: customPalettesKey),
              let palettes = try? JSONDecoder().decode([HexPalette].self, from: data)
        else { return [] }
        return palettes
    }

    private static func notifyHex(_ palette: HexPalette) throws {
        let data = try JSONEncoder().encode(palette)
        guard let json = String(data: data, encoding: .utf8) else {
            throw BridgeError.notificationPayloadUnavailable
        }

        DistributedNotificationCenter.default().postNotificationName(
            importNotificationName,
            object: nil,
            userInfo: ["paletteJSON": json],
            deliverImmediately: true
        )
    }

    private static func hexString(from color: NSColor) -> String {
        let srgb = color.usingColorSpace(.sRGB) ?? color
        let red = Int((srgb.redComponent * 255).rounded())
        let green = Int((srgb.greenComponent * 255).rounded())
        let blue = Int((srgb.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    private static func slug(from value: String) -> String {
        let raw = value.lowercased().unicodeScalars.map { scalar in
            CharacterSet.alphanumerics.contains(scalar) ? String(scalar) : "-"
        }.joined()
        let collapsed = raw.split(separator: "-").joined(separator: "-")
        return collapsed.isEmpty ? "theme" : collapsed
    }
}

import AppKit
import Foundation
import Testing

@testable import Muxy

struct HexPaletteBridgeTests {
    @Test("theme previews become HEX palettes")
    func themePreviewsBecomeHexPalettes() {
        let preview = ThemePreview(
            name: "Quiet Night",
            background: NSColor(srgbRed: 0.01, green: 0.02, blue: 0.03, alpha: 1),
            foreground: NSColor(srgbRed: 0.9, green: 0.8, blue: 0.7, alpha: 1),
            palette: [
                NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1),
                NSColor(srgbRed: 0, green: 1, blue: 0, alpha: 1),
            ]
        )

        let palette = HexPaletteBridge.makePalette(from: preview)

        #expect(palette.id == "jade-quiet-night")
        #expect(palette.name == "Jade Quiet Night")
        #expect(palette.category == "Jade")
        #expect(palette.style == "Terminal Theme")
        #expect(palette.colors.map(\.hex) == ["#030508", "#E6CCB3", "#FF0000", "#00FF00"])
        #expect(palette.colors.map(\.name) == ["Background", "Foreground", "Terminal 0", "Terminal 1"])
    }

    @Test("sync writes and updates HEX defaults without duplicates")
    func syncWritesAndUpdatesHexDefaultsWithoutDuplicates() throws {
        let suiteName = "com.muxy.tests.hex.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let first = ThemePreview(
            name: "Quiet Night",
            background: .black,
            foreground: .white,
            palette: [.red]
        )
        let second = ThemePreview(
            name: "Quiet Night",
            background: .black,
            foreground: .white,
            palette: [.blue]
        )

        try HexPaletteBridge.sync(theme: first, defaults: defaults, notify: false)
        try HexPaletteBridge.sync(theme: second, defaults: defaults, notify: false)

        let palettes = HexPaletteBridge.loadPalettes(from: defaults)

        #expect(defaults.string(forKey: HexPaletteBridge.lastPaletteKey) == "jade-quiet-night")
        #expect(palettes.count == 1)
        #expect(palettes.first?.colors.last?.hex == "#0000FF")
    }
}

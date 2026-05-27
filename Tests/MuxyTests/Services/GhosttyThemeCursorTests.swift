import Foundation
import Testing

@Suite("GhosttyThemeCursor")
struct GhosttyThemeCursorTests {
    private static let muxyThemeNames = ["Muxy", "Muxy Light", "Muxy Alienware", "Muxy Zen"]

    private static var bundledThemesDirectory: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Muxy/Resources/ghostty/themes", isDirectory: true)
    }

    @Test("Muxy bundled themes use dynamic cursor colors for highlighted cells")
    func muxyThemesUseDynamicCursorColors() throws {
        for name in Self.muxyThemeNames {
            let url = Self.bundledThemesDirectory.appendingPathComponent(name)
            let content = try String(contentsOf: url, encoding: .utf8)
            #expect(content.contains("cursor-color = cell-foreground"), "Missing dynamic cursor-color in \(name)")
            #expect(content.contains("cursor-text = cell-background"), "Missing dynamic cursor-text in \(name)")
        }
    }
}

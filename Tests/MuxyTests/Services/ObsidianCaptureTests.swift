import Foundation
import Testing
@testable import Muxy

@Suite("Obsidian Note Path Builder")
struct ObsidianNotePathBuilderTests {
    @Test("slugify normalizes titles")
    func slugifyNormalizesTitles() {
        #expect(ObsidianNotePathBuilder.slugify("Hello World!") == "hello-world")
        #expect(ObsidianNotePathBuilder.slugify("   ") == "capture")
    }

    @Test("inbox path uses folder and slug")
    func inboxPathUsesFolderAndSlug() {
        let path = ObsidianNotePathBuilder.inboxNotePath(
            inboxFolder: "Jade/Inbox",
            titleHint: "Fix capture wiring"
        )
        #expect(path.hasPrefix("Jade/Inbox/"))
        #expect(path.hasSuffix("-fix-capture-wiring.md"))
    }

    @Test("title uses first line")
    func titleUsesFirstLine() {
        let title = ObsidianNotePathBuilder.title(from: "First line\nSecond line")
        #expect(title == "First line")
    }
}

@Suite("Obsidian Capture Settings")
struct ObsidianCaptureSettingsTests {
    @Test("can send requires an existing folder")
    func canSendRequiresExistingFolder() {
        var settings = ObsidianCaptureSettings.defaults
        #expect(settings.canSendCaptures == false)

        settings.vaultPath = "/tmp/vault-\(UUID().uuidString)"
        #expect(settings.canSendCaptures == false)

        try? FileManager.default.createDirectory(
            atPath: settings.vaultPath,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(atPath: settings.vaultPath) }

        #expect(settings.canSendCaptures)
        #expect(settings.isVaultConfigured)
    }

    @Test("capture actions reflect configuration")
    func captureActionsReflectConfiguration() {
        var settings = ObsidianCaptureSettings.defaults
        #expect(ObsidianCaptureAction.openSettings.isAvailable(for: settings))
        #expect(!ObsidianCaptureAction.sendCapture.isAvailable(for: settings))

        settings.vaultPath = NSTemporaryDirectory()
        #expect(ObsidianCaptureAction.sendCapture.isAvailable(for: settings))
    }

    @Test("validator rejects missing folders")
    func validatorRejectsMissingFolders() {
        #expect(ObsidianVaultPathValidator.validationMessage(for: "") != nil)
        #expect(ObsidianVaultPathValidator.validationMessage(for: "/nonexistent/\(UUID().uuidString)") != nil)
        #expect(ObsidianVaultPathValidator.validationMessage(for: NSTemporaryDirectory()) == nil)
    }
}

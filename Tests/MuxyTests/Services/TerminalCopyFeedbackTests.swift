import AppKit
import Foundation
import Testing

@testable import Muxy

@Suite("GeneralSettingsMigration")
struct GeneralSettingsMigrationTests {
    @Test("Enables auto-copy when preference was never set")
    @MainActor
    func enablesAutoCopyForFreshInstall() {
        let defaults = UserDefaults(suiteName: "GeneralSettingsMigrationTests")!
        defaults.removePersistentDomain(forName: "GeneralSettingsMigrationTests")

        GeneralSettingsMigration.applyIfNeeded(using: defaults)

        #expect(defaults.bool(forKey: GeneralSettingsKeys.autoCopyTerminalSelection))
    }

    @Test("Preserves explicit auto-copy opt-out")
    @MainActor
    func preservesExplicitOptOut() {
        let defaults = UserDefaults(suiteName: "GeneralSettingsMigrationTestsOptOut")!
        defaults.removePersistentDomain(forName: "GeneralSettingsMigrationTestsOptOut")
        defaults.set(false, forKey: GeneralSettingsKeys.autoCopyTerminalSelection)

        GeneralSettingsMigration.applyIfNeeded(using: defaults)

        #expect(defaults.bool(forKey: GeneralSettingsKeys.autoCopyTerminalSelection) == false)
    }
}

@Suite("TerminalCopyFeedback")
struct TerminalCopyFeedbackTests {
    @Test("copyToPasteboard rejects empty text")
    @MainActor
    func rejectsEmptyText() {
        #expect(TerminalCopyFeedback.copyToPasteboard("   ", showIndicator: false) == false)
    }

    @Test("copyToPasteboard writes trimmed text")
    @MainActor
    func writesTextToPasteboard() {
        let copied = TerminalCopyFeedback.copyToPasteboard("hello", showIndicator: false)
        #expect(copied)
        #expect(NSPasteboard.general.string(forType: .string) == "hello")
    }
}

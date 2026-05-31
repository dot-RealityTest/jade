import Foundation
import Testing

@testable import Muxy

@Suite("UpdateService")
struct UpdateServiceTests {
    @Test("debug builds skip update checks by default")
    func debugBuildsSkipUpdateChecksByDefault() {
        #if DEBUG
        let defaults = UserDefaults(suiteName: "UpdateServiceTests.debug")!
        defaults.removePersistentDomain(forName: "UpdateServiceTests.debug")
        defaults.set(true, forKey: GeneralSettingsKeys.automaticUpdateChecks)
        #expect(UpdateService.isUpdateChecksEnabled(defaults: defaults) == false)
        #else
        #expect(Bool(true))
        #endif
    }

    @Test("automatic update preference is respected in release builds")
    func automaticUpdatePreferenceIsRespectedInReleaseBuilds() {
        #if !DEBUG
        let defaults = UserDefaults(suiteName: "UpdateServiceTests.release")!
        defaults.removePersistentDomain(forName: "UpdateServiceTests.release")
        defaults.set(false, forKey: GeneralSettingsKeys.automaticUpdateChecks)
        #expect(UpdateService.isUpdateChecksEnabled(defaults: defaults) == false)
        defaults.set(true, forKey: GeneralSettingsKeys.automaticUpdateChecks)
        #expect(UpdateService.isUpdateChecksEnabled(defaults: defaults) == true)
        #else
        #expect(Bool(true))
        #endif
    }
}

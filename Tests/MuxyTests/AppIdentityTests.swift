import Testing

@testable import Muxy

@Suite("AppIdentity")
struct AppIdentityTests {
    @Test("Jade keeps legacy launch compatibility")
    func jadeKeepsLegacyLaunchCompatibility() {
        #expect(AppIdentity.displayName == "Jade")
        #expect(AppIdentity.cliName == "jade")
        #expect(AppIdentity.legacyDisplayName == "Muxy")
        #expect(AppIdentity.bundleIdentifier == "com.muxy.app")
        #expect(AppIdentity.urlScheme == "muxy")
    }

    @Test("user-facing labels use Jade")
    func userFacingLabelsUseJade() {
        #expect(AppIdentity.helpWindowTitle == "Jade Help")
        #expect(AppIdentity.pickerLabel == "Jade Picker")
        #expect(AppIdentity.themeDisplayName("Muxy") == "Jade")
        #expect(AppIdentity.themeDisplayName("Muxy Light") == "Jade Light")
        #expect(AppIdentity.themeDisplayName("Muxy Zen") == "Jade Zen")
        #expect(AppIdentity.sentence("Quit Muxy?") == "Quit Jade?")
    }
}

import Testing

@testable import Muxy

@Suite("AppIdentity")
struct AppIdentityTests {
    @Test("Jade keeps legacy launch compatibility")
    func jadeKeepsLegacyLaunchCompatibility() {
        #expect(AppIdentity.displayName == "Jade")
        #expect(AppIdentity.cliName == "jade")
        #expect(AppIdentity.legacyCLIName == "muxy")
        #expect(AppIdentity.bundleIdentifier == "com.muxy.app")
        #expect(AppIdentity.urlScheme == "muxy")
    }
}

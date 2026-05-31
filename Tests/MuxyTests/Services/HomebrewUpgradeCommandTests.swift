import Testing

@testable import Muxy

@Suite("HomebrewUpgradeCommand")
struct HomebrewUpgradeCommandTests {
    @Test("shell script upgrades when brew is available")
    func shellScriptUpgradesWhenBrewIsAvailable() {
        let script = HomebrewUpgradeCommand.shellScript
        #expect(script.contains("command -v brew"))
        #expect(script.contains("brew update && brew upgrade"))
        #expect(script.contains("exec \"$SHELL\" -l"))
    }

    @Test("shell script explains install when brew is missing")
    func shellScriptExplainsInstallWhenBrewIsMissing() {
        let script = HomebrewUpgradeCommand.shellScript
        #expect(script.contains(HomebrewUpgradeCommand.installURL))
        #expect(script.contains("Homebrew is not installed"))
    }
}

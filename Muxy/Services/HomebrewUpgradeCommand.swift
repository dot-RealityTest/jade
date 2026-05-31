import Foundation

enum HomebrewUpgradeCommand {
    static let installURL = "https://brew.sh"

    static var shellScript: String {
        LocalShellCommand.whenToolAvailable(
            "brew",
            missingMessage: "Homebrew is not installed. Install it from \(installURL)",
            run: "brew update && brew upgrade",
            keepShellAfterSuccess: true
        )
    }
}

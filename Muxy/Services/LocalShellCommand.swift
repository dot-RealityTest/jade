import Foundation

enum LocalShellCommand {
    static let pathBootstrap = "export PATH=\"$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH\""
    static let reopenLoginShell = "exec \"$SHELL\" -l"

    static func whenToolAvailable(
        _ tool: String,
        missingMessage: String,
        run runCommand: String,
        keepShellAfterSuccess: Bool
    ) -> String {
        let onSuccess = keepShellAfterSuccess
            ? """
            \(runCommand)
            \(reopenLoginShell)
            """
            : "exec \(runCommand)"

        return """
        \(pathBootstrap)
        if command -v \(tool) >/dev/null 2>&1; then
          \(onSuccess)
        else
          printf '%s\\n' "\(missingMessage)"
          \(reopenLoginShell)
        fi
        """
    }
}

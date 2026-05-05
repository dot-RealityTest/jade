import Foundation

enum ShellCommandSafetyClassifier {
    static func risk(for command: String) -> NaturalCommandRiskLevel {
        let normalized = command
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else { return .blocked }
        guard !containsBlockedPrimitive(normalized) else { return .blocked }
        if containsPrivilegedPrimitive(normalized) { return .medium }
        if normalized.contains("find ") || normalized.contains("du ") || normalized.contains("docker ps") {
            return .inspect
        }
        return .low
    }

    static func blockedReason(for command: String) -> String? {
        risk(for: command) == .blocked ? "This command includes destructive shell primitives and will not run from natural language." : nil
    }

    static func inspectFirstPlan(for request: NaturalCommandRequest) -> NaturalCommandPlan? {
        let prompt = request.prompt.lowercased()
        guard containsDestructiveIntent(prompt) else { return nil }

        let command: String
        let title: String
        let summary: String
        let explanation: String

        if prompt.contains("docker") || prompt.contains("container") {
            title = "Inspect Docker Containers"
            summary = "List containers and images before making changes."
            command = "docker ps -a --format 'table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.Ports}}'"
            explanation = "This inspects Docker containers only. It does not restart, stop, remove, or delete anything."
        } else if prompt.contains("large") || prompt.contains("file") || prompt.contains("disk") {
            title = "Inspect Large Files"
            summary = "Find large files so you can review them before deleting anything."
            command = "find . -type f -size +500M -print 2>/dev/null | sort"
            explanation = "This lists large files under the active directory. It does not delete files."
        } else {
            title = "Inspect Before Changes"
            summary = "Show relevant system state before taking a destructive action."
            command = "pwd && ls -la"
            explanation = "This command only inspects the active location. Destructive actions are not generated in v1."
        }

        return NaturalCommandPlan(
            title: title,
            summary: summary,
            targetKind: request.context.targetKind,
            riskLevel: .inspect,
            backend: .localRules,
            steps: [
                NaturalCommandStep(
                    title: title,
                    command: command,
                    explanation: explanation
                ),
            ]
        )
    }

    static func containsDestructiveIntent(_ text: String) -> Bool {
        let terms = [
            "delete",
            "remove",
            "erase",
            "wipe",
            "destroy",
            "clean up",
            "restart",
            "reboot",
            "shutdown",
            "power off",
            "kill",
        ]
        return terms.contains { text.contains($0) }
    }

    private static func containsBlockedPrimitive(_ command: String) -> Bool {
        let patterns = [
            #"(^|[;&|]\s*)rm\s+(-[^\s]*[rf][^\s]*|-r|-f|--recursive|--force)"#,
            #"(^|[;&|]\s*)sudo\s+rm\s+"#,
            #"(^|[;&|]\s*)find\s+.+\s-delete(\s|$)"#,
            #"(^|[;&|]\s*)mkfs(\.|\s)"#,
            #"(^|[;&|]\s*)diskutil\s+erase"#,
            #"(^|[;&|]\s*)dd\s+.*\bof=/dev/"#,
            #"(^|[;&|]\s*)sudo\s+(reboot|shutdown|poweroff|halt)\b"#,
            #"(^|[;&|]\s*)(reboot|shutdown|poweroff|halt)\b"#,
            #"(^|[;&|]\s*)docker\s+(rm|rmi)\b"#,
            #"(^|[;&|]\s*)docker\s+container\s+rm\b"#,
            #"(^|[;&|]\s*)docker\s+system\s+prune\b"#,
            #"(^|[;&|]\s*)kill\s+-9\b"#,
            #":\(\)\s*\{\s*:\|:"#,
        ]
        return patterns.contains { pattern in
            command.range(of: pattern, options: .regularExpression) != nil
        }
    }

    private static func containsPrivilegedPrimitive(_ command: String) -> Bool {
        command.contains("sudo ")
            || command.contains("chmod ")
            || command.contains("chown ")
            || command.contains("launchctl ")
            || command.contains("systemctl ")
            || command.contains("docker restart")
    }
}

import Foundation

struct JourneyRuleCheckResult: Equatable {
    let risk: JourneyStepRisk
    let blockedReason: String?
    let matchedRule: String?
}

enum JadeJourneyRuleChecker {
    static func evaluate(title: String, summary: String, projectPath: String) -> JourneyRuleCheckResult {
        let rulesPath = JadeJourneyLayout.rulesFile(in: projectPath)
        guard FileManager.default.fileExists(atPath: rulesPath),
              let content = try? String(contentsOf: URL(fileURLWithPath: rulesPath), encoding: .utf8)
        else {
            return JourneyRuleCheckResult(risk: .low, blockedReason: nil, matchedRule: nil)
        }

        let forbidden = forbiddenRules(from: content)
        let haystack = "\(title) \(summary)".lowercased()

        for rule in forbidden {
            let clauses = rule.lowercased()
                .components(separatedBy: " or ")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            let matched = clauses.contains { clause in
                if haystack.contains(clause) { return true }
                let trimmed = clause.hasPrefix("add ") ? String(clause.dropFirst(4)) : clause
                return !trimmed.isEmpty && haystack.contains(trimmed)
            }

            guard matched else { continue }
            let reason = """
            \(AppIdentity.displayName) disagrees: “\(rule)” is listed under Not yet in .jade/rules.md. \
            Update the rule or pick a different step.
            """
            return JourneyRuleCheckResult(risk: .blocked, blockedReason: reason, matchedRule: rule)
        }

        if haystack.contains("sudo") || haystack.contains("production") || haystack.contains("delete all") {
            return JourneyRuleCheckResult(
                risk: .medium,
                blockedReason: nil,
                matchedRule: nil
            )
        }

        return JourneyRuleCheckResult(risk: .low, blockedReason: nil, matchedRule: nil)
    }

    static func forbiddenRules(from markdown: String) -> [String] {
        let lines = markdown.components(separatedBy: .newlines)
        var inNotYet = false
        var rules: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased() == "## not yet" {
                inNotYet = true
                continue
            }
            if inNotYet, trimmed.hasPrefix("## ") {
                break
            }
            if inNotYet, trimmed.hasPrefix("- ") {
                let rule = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines)
                if !rule.isEmpty {
                    rules.append(rule)
                }
            }
        }

        return rules
    }
}

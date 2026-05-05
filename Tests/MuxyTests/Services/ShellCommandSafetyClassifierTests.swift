import Testing

@testable import Muxy

@Suite("ShellCommandSafetyClassifier")
struct ShellCommandSafetyClassifierTests {
    @Test("allows read only inspect commands")
    func allowsReadOnlyInspectCommands() {
        #expect(ShellCommandSafetyClassifier.risk(for: "find . -type f -size +500M -print") == .inspect)
        #expect(ShellCommandSafetyClassifier.risk(for: "docker ps -a") == .inspect)
        #expect(ShellCommandSafetyClassifier.risk(for: "ls -la") == .low)
    }

    @Test("blocks destructive primitives")
    func blocksDestructivePrimitives() {
        #expect(ShellCommandSafetyClassifier.risk(for: "rm -rf ./build") == .blocked)
        #expect(ShellCommandSafetyClassifier.risk(for: "find . -type f -delete") == .blocked)
        #expect(ShellCommandSafetyClassifier.risk(for: "sudo reboot") == .blocked)
        #expect(ShellCommandSafetyClassifier.risk(for: "docker system prune -af") == .blocked)
    }

    @Test("creates inspect first plan for delete intent")
    func createsInspectFirstPlanForDeleteIntent() throws {
        let request = NaturalCommandRequest(
            prompt: "find large files and delete them",
            context: .local(projectPath: "/tmp/project")
        )

        let plan = try #require(ShellCommandSafetyClassifier.inspectFirstPlan(for: request))

        #expect(plan.riskLevel == .inspect)
        #expect(plan.backend == .localRules)
        #expect(plan.primaryCommand.contains("find . -type f"))
        #expect(!plan.primaryCommand.contains("rm"))
        #expect(!plan.primaryCommand.contains("-delete"))
    }
}

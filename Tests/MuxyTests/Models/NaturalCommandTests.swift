import Foundation
import Testing

@testable import Muxy

@Suite("NaturalCommand")
struct NaturalCommandTests {
    @Test("parses model JSON wrapped in prose")
    func parsesWrappedJSON() throws {
        let request = NaturalCommandRequest(
            prompt: "show disk usage",
            context: .local(projectPath: "/tmp/project")
        )
        let content = """
        Here is the plan:
        {"title":"Disk Usage","summary":"Show folder sizes","command":"du -sh *","explanation":"Lists sizes only","risk":"inspect"}
        """

        let plan = try NaturalCommandPlanParser.parse(content, request: request, backend: .ollama)

        #expect(plan.title == "Disk Usage")
        #expect(plan.primaryCommand == "du -sh *")
        #expect(plan.riskLevel == .inspect)
        #expect(plan.backend == .ollama)
        #expect(plan.isRunnable)
    }

    @Test("blocks destructive generated commands")
    func blocksDestructiveGeneratedCommands() throws {
        let request = NaturalCommandRequest(
            prompt: "delete logs",
            context: .local(projectPath: "/tmp/project")
        )
        let content = #"{"title":"Delete Logs","summary":"Delete logs","command":"rm -rf ./logs","explanation":"Deletes logs","risk":"medium"}"#

        let plan = try NaturalCommandPlanParser.parse(content, request: request, backend: .ollama)

        #expect(plan.riskLevel == .blocked)
        #expect(!plan.isRunnable)
        #expect(plan.blockedReason != nil)
    }

    @Test("remote context is preserved")
    func remoteContextIsPreserved() {
        let space = RemoteSpace(name: "Alienware", user: "kika", host: "192.168.1.171")
        let context = NaturalCommandContext.remote(space)

        #expect(context.targetKind == .remote)
        #expect(context.displayName == "Alienware")
        #expect(context.remoteSummary == "kika@192.168.1.171")
    }
}

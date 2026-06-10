import Foundation

enum MainWindowJourneyActions {
    static func initialize(project: Project, worktreePath: String) throws {
        try JadeJourneyBootstrapService.bootstrap(projectPath: worktreePath, projectName: project.name)
    }

    static func loadNextStepProposal(projectPath: String) throws -> JourneyStepProposal {
        try JadeJourneyReader.loadNextStepProposal(projectPath: projectPath)
    }

    static func completeStep(project: Project, worktreePath: String) throws -> JourneyStepProposal {
        let proposal = try JadeJourneyReader.loadNextStepProposal(projectPath: worktreePath)
        try JadeJourneyProgressService.completeCurrentStep(projectPath: worktreePath, proposal: proposal)
        return proposal
    }

    static func richInputPrefill(for proposal: JourneyStepProposal) -> String {
        "# \(proposal.title)\n\n\(proposal.why)\n"
    }

    struct SessionLogRequest {
        let outcome: JourneySessionOutcome
        let proposal: JourneyStepProposal
        let project: Project
        let worktreePath: String
        let overrideBlocker: Bool
        let settings: ObsidianMCPSettings
    }

    static func logSession(
        _ request: SessionLogRequest,
        onComplete: @escaping @MainActor (Result<String, Error>, String?) -> Void
    ) {
        Task {
            let result = await ObsidianJourneyLogService.logSession(
                outcome: request.outcome,
                proposal: request.proposal,
                projectName: request.project.name,
                projectPath: request.worktreePath,
                overriddenBlocker: request.overrideBlocker,
                settings: request.settings
            )
            await MainActor.run {
                switch result {
                case let .success(notePath):
                    onComplete(.success(notePath), nil)
                case let .failure(error):
                    onComplete(.failure(error), nil)
                }
            }
        }
    }
}

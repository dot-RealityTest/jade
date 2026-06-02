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

    static func logSession(
        outcome: JourneySessionOutcome,
        proposal: JourneyStepProposal,
        project: Project,
        worktreePath: String,
        overrideBlocker: Bool,
        settings: ObsidianMCPSettings,
        onComplete: @escaping @MainActor (Result<String, Error>, String?) -> Void
    ) {
        Task {
            let result = await ObsidianJourneyLogService.logSession(
                outcome: outcome,
                proposal: proposal,
                projectName: project.name,
                projectPath: worktreePath,
                overriddenBlocker: overrideBlocker,
                settings: settings
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

import Foundation
import Testing

@testable import Muxy

@Suite("VCSTabState file caches")
@MainActor
struct VCSTabStateFileCacheTests {
    private func makeFile(
        path: String,
        xStatus: Character = " ",
        yStatus: Character = " "
    ) -> GitStatusFile {
        GitStatusFile(
            path: path,
            oldPath: nil,
            xStatus: xStatus,
            yStatus: yStatus,
            additions: nil,
            deletions: nil,
            isBinary: false
        )
    }

    @Test("assigning files rebuilds staged and unstaged caches")
    func filesAssignmentRebuildsCaches() {
        let state = VCSTabState(projectPath: NSTemporaryDirectory())

        state.files = [
            makeFile(path: "src/staged.swift", xStatus: "M"),
            makeFile(path: "src/unstaged.swift", yStatus: "M"),
            makeFile(path: "src/untracked.swift", xStatus: "?", yStatus: "?"),
        ]

        #expect(state.stagedFiles.map(\.path) == ["src/staged.swift"])
        #expect(state.unstagedFiles.map(\.path) == ["src/unstaged.swift", "src/untracked.swift"])
        #expect(!state.stagedTreeRows.isEmpty)
        #expect(!state.unstagedTreeRows.isEmpty)
    }

    @Test("clearing files empties all caches")
    func clearingFilesEmptiesCaches() {
        let state = VCSTabState(projectPath: NSTemporaryDirectory())
        state.files = [makeFile(path: "a.swift", xStatus: "M", yStatus: "M")]

        state.files = []

        #expect(state.stagedFiles.isEmpty)
        #expect(state.unstagedFiles.isEmpty)
        #expect(state.stagedTreeRows.isEmpty)
        #expect(state.unstagedTreeRows.isEmpty)
    }

    @Test("expanding a folder rebuilds the tree rows")
    func folderExpansionRebuildsRows() {
        let state = VCSTabState(projectPath: NSTemporaryDirectory())
        state.files = [
            makeFile(path: "src/nested/staged.swift", xStatus: "M"),
            makeFile(path: "src/nested/other.swift", xStatus: "M"),
        ]
        let collapsedStagedRowCount = state.stagedTreeRows.count

        state.expandedStagedFolderPaths = ["src", "src/nested"]

        #expect(state.stagedTreeRows.count > collapsedStagedRowCount)
        #expect(state.stagedTreeRows.contains { row in
            if case let .file(file, _) = row {
                return file.path == "src/nested/staged.swift"
            }
            return false
        })
    }
}

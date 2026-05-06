import SwiftUI

struct UnifiedDiffView: View {
    let rows: [DiffDisplayRow]
    let filePath: String
    var suppressLeadingTopBorder: Bool = false

    @State private var cachedChunks: [DiffChunk] = []
    @State private var cachedSignature: Int = 0

    private var numberColumnWidth: CGFloat {
        lineNumberWidth(for: maxLineNumber(in: rows))
    }

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(cachedChunks.enumerated()), id: \.offset) { index, chunk in
                switch chunk {
                case let .divider(text):
                    DiffSectionDivider(
                        text: text,
                        showsTopBorder: !(index == 0 && suppressLeadingTopBorder)
                    )
                case let .codeBlock(blockRows):
                    unifiedCodeBlock(blockRows)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Unified diff, \(filePath)")
        .onAppear {
            refreshChunksIfNeeded()
        }
        .onChange(of: rowsSignature) { _, _ in
            refreshChunksIfNeeded()
        }
    }

    private var gutterWidth: CGFloat {
        numberColumnWidth * 2 + 2 + DiffGutterNSView.prefixColumnWidth
    }

    private func unifiedCodeBlock(_ blockRows: [DiffDisplayRow]) -> some View {
        let height = CGFloat(blockRows.count) * diffLineHeight
        let metadata = buildDiffMetadata(from: blockRows)
        return HStack(alignment: .top, spacing: 0) {
            DiffGutterBridge(metadata: metadata, filePath: filePath, mode: .unified, columnWidth: numberColumnWidth)
                .frame(width: gutterWidth, height: height)

            ScrollView(.horizontal, showsIndicators: false) {
                DiffContentBridge(
                    rows: blockRows,
                    backgroundSide: .both
                )
                .frame(height: height)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }

    private var rowsSignature: Int {
        var hasher = Hasher()
        hasher.combine(rows.count)
        for row in rows {
            hasher.combine(kindHash(row.kind))
            hasher.combine(row.oldLineNumber)
            hasher.combine(row.newLineNumber)
            hasher.combine(row.oldText)
            hasher.combine(row.newText)
            hasher.combine(row.text)
        }
        return hasher.finalize()
    }

    private func refreshChunksIfNeeded() {
        let signature = rowsSignature
        guard signature != cachedSignature else { return }
        cachedSignature = signature
        cachedChunks = buildDiffChunks(from: rows)
    }

    private func kindHash(_ kind: DiffDisplayRow.Kind) -> Int {
        switch kind {
        case .hunk: 1
        case .context: 2
        case .addition: 3
        case .deletion: 4
        case .collapsed: 5
        }
    }
}

import SwiftUI

import DesignSystem
import DomainInterface

struct ChunkReaderSentenceView: View {
    let chunks: [Indexed<WordDetail.Example.Chunk>]
    let selectedChunkID: Int?
    let onChunkTapped: (Int) -> Void

    private var selectedChunk: Indexed<WordDetail.Example.Chunk>? {
        chunks.first { $0.id == selectedChunkID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ChunkReaderBadge(icon: "bolt.fill", label: "의미 단위 해석")
                .padding(.bottom, 12)

            ChunkChipsRow(
                chunks: chunks,
                selectedChunkID: selectedChunkID,
                onChunkTapped: onChunkTapped
            )

            ChunkReaderMeaningLabel(meaning: selectedChunk?.element.meaning)
                .frame(minHeight: 26, alignment: .leading)
                .padding(.top, 16)
        }
    }
}

import SwiftUI

import DomainInterface

struct ChunkChipsRow: View {
    let chunks: [Indexed<WordDetail.Example.Chunk>]
    let selectedChunkID: Int?
    let onChunkTapped: (Int) -> Void

    var body: some View {
        FlowLayout(horizontalSpacing: 4, verticalSpacing: 5) {
            ForEach(chunks) { chunk in
                ChunkView(
                    chunk: chunk,
                    isSelected: chunk.id == selectedChunkID,
                    onTap: { onChunkTapped(chunk.id) }
                )
            }
        }
    }
}

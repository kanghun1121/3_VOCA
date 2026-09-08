import Foundation

import DomainInterface

@Observable
@MainActor
public final class ChunkReaderViewModel {
    let chunks: [Indexed<WordDetail.Example.Chunk>]
    let wordAnnotations: [Indexed<WordDetail.Example.WordAnnotation>]
    var selectedChunkID: Int?

    public init(chunks: [WordDetail.Example.Chunk], wordAnnotations: [WordDetail.Example.WordAnnotation]) {
        self.chunks = chunks.indexed()
        self.wordAnnotations = wordAnnotations.indexed()
        self.selectedChunkID = self.chunks.first?.id
    }

    func didTapChunk(id: Int) {
        selectedChunkID = (selectedChunkID == id) ? nil : id
    }
}

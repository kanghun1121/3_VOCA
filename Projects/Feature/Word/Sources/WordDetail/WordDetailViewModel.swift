import Foundation

import DomainInterface
import FeatureChatBot
import FeatureChunkReader

import Dependencies
import SwiftUINavigation

@Observable
@MainActor
public final class WordDetailViewModel {
    enum ViewState {
        case loading
        case loaded(WordDetail)
        case error(String)
    }

    @CasePathable
    enum Destination {
        case chunkReader(ChunkReaderViewModel)
        case chatBot(ChatBotViewModel)
    }

    var currentIndex: Int
    var destination: Destination?

    private(set) var viewStates: [Int: ViewState] = [:]
    let wordIDs: [String]

    @ObservationIgnored @Dependency(\.wordRepository) private var wordRepository
    @ObservationIgnored @Dependency(\.audioRepository) private var audioRepository
    @ObservationIgnored @Dependency(\.audioPlayerRepository) private var audioPlayerRepository

    public init(wordIDs: [String], initialIndex: Int) {
        self.wordIDs = wordIDs
        self.currentIndex = initialIndex
    }

    func requestIfNeeded(at index: Int) async {
        guard wordIDs.indices.contains(index), viewStates[index] == nil else { return }
        viewStates[index] = .loading
        do {
            let detail = try await wordRepository.fetchDetail(wordIDs[index])
            viewStates[index] = .loaded(detail)
        } catch {
            print("[WordDetail] 단어 로드 실패 (index: \(index)):", error)
            viewStates[index] = .error("단어 정보를 불러오지 못했습니다.")
        }
    }

    func pronunciationTapped(_ term: String) {
        Task { await didTapPronunciationButton(term: term) }
    }

    func didTapPronunciationButton(term: String) async {
        guard let url = await audioRepository.url(term) else { return }
        await audioPlayerRepository.play(url)
    }

    func didTapChunkReader(example: WordDetail.Example) {
        guard let chunks = example.chunks, !chunks.isEmpty else { return }
        destination = .chunkReader(ChunkReaderViewModel(chunks: chunks, wordAnnotations: example.words ?? []))
    }

    func didTapChatBot(state: WordDetail, example: WordDetail.Example) {
        destination = .chatBot(ChatBotViewModel(context: .init(
            wordID: state.id,
            term: state.term,
            sentence: example.en,
            levelLabel: "Level \(state.level)"
        )))
    }
}

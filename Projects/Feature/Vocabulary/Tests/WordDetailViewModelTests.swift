import XCTest

import DomainInterface

import Dependencies

@testable import FeatureChatBot
@testable import FeatureVocabulary

@MainActor
final class WordDetailViewModelTests: XCTestCase {
    func test_requestIfNeeded_index1_loaded이며_데이터가_올바르다() async {
        let vm = withDependencies {
            $0.wordRepository.fetchDetail = { _ in .previewFixture }
        } operation: {
            WordDetailViewModel(wordIDs: ["word_001", "word_766"], initialIndex: 0)
        }

        await vm.requestIfNeeded(at: 1)

        guard case .loaded(let detail) = vm.viewStates[1] else {
            XCTFail("viewStates[1]이 .loaded여야 합니다. 실제: \(String(describing: vm.viewStates[1]))")
            return
        }
        XCTAssertEqual(detail.term, "dark")
        XCTAssertEqual(detail.level, 1)
        XCTAssertEqual(detail.pronunciation, "/dɑːrk/")
        XCTAssertEqual(detail.groupedDefinitions().count, 2)
        XCTAssertEqual(detail.examples.count, 2)
    }

    func test_requestIfNeeded_실패시_viewState가_error로_전환된다() async {
        let vm = withDependencies {
            $0.wordRepository.fetchDetail = { _ in throw MockError.stub }
        } operation: {
            WordDetailViewModel(wordIDs: ["word_001"], initialIndex: 0)
        }

        await vm.requestIfNeeded(at: 0)

        guard case .error = vm.viewStates[0] else {
            XCTFail("viewStates[0]이 .error여야 합니다. 실제: \(String(describing: vm.viewStates[0]))")
            return
        }
    }

    func test_didTapChatBot_예문컨텍스트로_챗봇destination을_세팅한다() async {
        let vm = withDependencies {
            $0.wordRepository.fetchDetail = { _ in .previewFixture }
        } operation: {
            WordDetailViewModel(wordIDs: ["word_766"], initialIndex: 0)
        }

        await vm.requestIfNeeded(at: 0)
        guard case .loaded(let pm) = vm.viewStates[0] else {
            XCTFail("viewStates[0]이 .loaded여야 합니다. 실제: \(String(describing: vm.viewStates[0]))")
            return
        }

        vm.didTapChatBot(state: pm, example: pm.examples[0])

        guard case .chatBot(let chatBotVM) = vm.destination else {
            XCTFail("destination이 .chatBot이어야 합니다. 실제: \(String(describing: vm.destination))")
            return
        }
        XCTAssertEqual(chatBotVM.context.term, "dark")
        XCTAssertEqual(chatBotVM.context.sentence, pm.examples[0].en)
        XCTAssertEqual(chatBotVM.context.levelLabel, "Level 1")
    }

    func test_requestIfNeeded_index1부터5까지_모두_loaded로_전환된다() async {
        let wordIDs = (0...5).map { "word_\(String(format: "%03d", $0))" }
        let vm = withDependencies {
            $0.wordRepository.fetchDetail = { _ in .previewFixture }
        } operation: {
            WordDetailViewModel(wordIDs: wordIDs, initialIndex: 0)
        }

        for index in 1...5 {
            await vm.requestIfNeeded(at: index)
        }

        for index in 1...5 {
            guard case .loaded = vm.viewStates[index] else {
                XCTFail("viewStates[\(index)]이 .loaded여야 합니다. 실제: \(String(describing: vm.viewStates[index]))")
                return
            }
        }
    }

    func test_pronunciationTapped_탭_시점에_AudioRepository에서_URL을_조회해_재생한다() async {
        let expectedURL = URL(string: "file:///dark.mp3")!
        let playedURLBox = PlayedURLBox()
        let vm = withDependencies {
            $0.wordRepository.fetchDetail = { _ in .previewFixture }
            $0.audioRepository.url = { _ in expectedURL }
            $0.audioPlayerRepository.play = { url in playedURLBox.set(url) }
        } operation: {
            WordDetailViewModel(wordIDs: ["word_766"], initialIndex: 0)
        }

        await vm.requestIfNeeded(at: 0)
        await vm.didTapPronunciationButton(term: "dark")

        XCTAssertEqual(playedURLBox.value, expectedURL)
    }

    func test_pronunciationTapped_audioURL이_없으면_재생하지_않는다() async {
        let playedURLBox = PlayedURLBox()
        let vm = withDependencies {
            $0.wordRepository.fetchDetail = { _ in .previewFixture }
            $0.audioRepository.url = { _ in nil }
            $0.audioPlayerRepository.play = { url in playedURLBox.set(url) }
        } operation: {
            WordDetailViewModel(wordIDs: ["word_766"], initialIndex: 0)
        }

        await vm.requestIfNeeded(at: 0)
        await vm.didTapPronunciationButton(term: "dark")

        XCTAssertNil(playedURLBox.value)
    }

    /// 로드 시점엔 아직 prefetch가 끝나지 않아 오디오가 없었더라도, 그 이후 백그라운드
    /// prefetch가 완료되면 재생 버튼이 그 최신 상태를 즉시 반영해야 한다(§23) — 로드 시점에
    /// 스냅샷해두던 과거 구현에서는 이 케이스에서 영원히 재생되지 않았다.
    func test_pronunciationTapped_로드_이후_prefetch가_완료되면_탭_시점에_반영된다() async {
        let expectedURL = URL(string: "file:///dark.mp3")!
        let audioURLBox = AudioURLBox()
        let playedURLBox = PlayedURLBox()
        let vm = withDependencies {
            $0.wordRepository.fetchDetail = { _ in .previewFixture }
            $0.audioRepository.url = { _ in audioURLBox.value }
            $0.audioPlayerRepository.play = { url in playedURLBox.set(url) }
        } operation: {
            WordDetailViewModel(wordIDs: ["word_766"], initialIndex: 0)
        }

        await vm.requestIfNeeded(at: 0)
        audioURLBox.set(expectedURL)
        await vm.didTapPronunciationButton(term: "dark")

        XCTAssertEqual(playedURLBox.value, expectedURL)
    }
}

private enum MockError: Error {
    case stub
}

/// 테스트 전용 — audioPlayerRepository.play에 전달된 URL을 캡처하기 위한 박스.
private final class PlayedURLBox: @unchecked Sendable {
    private(set) var value: URL?
    func set(_ url: URL) { value = url }
}

/// 테스트 전용 — audioRepository.url이 그때그때 돌려줄 값을 테스트 도중 바꿔치기하기 위한 박스.
private final class AudioURLBox: @unchecked Sendable {
    private(set) var value: URL?
    func set(_ url: URL?) { value = url }
}

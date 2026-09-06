import Foundation

import DomainInterface

/// 발음 URL을 조회하고, 로컬 캐시에 없으면 즉석으로 확보한 뒤 재생한다.
struct WordPronunciationPlayer {
    let audioRepository: AudioRepository
    let audioPlayerRepository: AudioPlayerRepository

    func play(term: String, audioUrl: String) async {
        // 1) 캐시 조회(네트워크 없음) — 보통 WordGameViewModel.load()가 게임 시작 전에 미리
        //    프리페치를 끝내두므로 여기서 바로 찾는 게 정상 경로다.
        // 2) 캐시에 없으면(=프리페치가 이 단어를 못 받았거나 실패한 경우) 안전망으로 지금 당장
        //    이 한 단어만 즉석으로 확보한다 — "여러 개를 미리 받아두는" prefetch가 아니라
        //    "지금 하나가 필요해서 가져오는" fetch다.
        let url: URL?
        if let cached = await audioRepository.url(term) {
            url = cached
        } else {
            url = await audioRepository.fetchURL(term, audioUrl)
        }
        guard let url else { return }
        guard !Task.isCancelled else { return }
        // 3) 로컬 파일 URL(디스크에 저장된 mp3)을 AudioPlayerRepository(AVPlayer)에 넘겨 재생.
        await audioPlayerRepository.play(url)
    }
}

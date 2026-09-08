extension String {
    // 백엔드가 내려주는 축약 품사 코드(n, v, adj ...)를 한글 라벨로 변환.
    // 목록에 없는 코드는 오역 대신 원문 코드를 그대로 보여준다.
    var koreanPartOfSpeechLabel: String {
        let labels: [String: String] = [
            "n": "명사",
            "v": "동사",
            "adj": "형용사",
            "adv": "부사",
            "prep": "전치사",
            "conj": "접속사",
            "pron": "대명사",
            "intj": "감탄사",
            "det": "한정사"
        ]
        return labels[lowercased()] ?? self
    }
}

import DomainInterface

extension PartOfSpeech {
    var koreanLabel: String {
        switch self {
        case .noun:         return "명사"
        case .verb:         return "동사"
        case .adjective:    return "형용사"
        case .adverb:       return "부사"
        case .preposition:  return "전치사"
        case .conjunction:  return "접속사"
        case .interjection: return "감탄사"
        case .pronoun:      return "대명사"
        case .unknown:      return "기타"
        }
    }
}

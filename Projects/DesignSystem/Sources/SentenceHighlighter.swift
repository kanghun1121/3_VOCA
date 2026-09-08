import NaturalLanguage
import SwiftUI

/// 문장 속에서 특정 단어(구)를 찾아 하이라이트 스타일을 입힌 `AttributedString`을 만든다.
///
/// `WordDetailExampleRow`에 있던 NLTagger 렘마 매칭 로직을 그대로 옮긴 것으로, 표층형이
/// 일치하는 경우를 우선 확인한 뒤 렘마(원형) 비교로 폴백한다. 여러 화면(WordDetail 예문 카드,
/// ChatBot ChatBotContextCard)이 같은 하이라이트 규칙을 공유해야 해서 DesignSystem으로 공용화했다.
public enum SentenceHighlighter {
    /// - Parameters:
    ///   - sentence: 하이라이트를 적용할 원문 문장.
    ///   - keyword: 찾을 단어 또는 구(공백 포함 시 구 매칭으로 처리).
    ///   - font: 하이라이트되지 않는 부분에 적용할 폰트.
    ///   - highlightFont: 하이라이트되는 부분에 적용할 폰트(보통 bold 계열).
    /// - Returns: keyword를 찾지 못하면 스타일 없이 원문 그대로인 `AttributedString`.
    public static func highlighted(
        sentence: String,
        keyword: String,
        font: SwiftUI.Font,
        highlightFont: SwiftUI.Font
    ) -> AttributedString {
        let matchRanges = keyword.contains(" ")
            ? findPhraseRanges(in: sentence, phrase: keyword)
            : findTokenRanges(in: sentence, keyword: keyword)

        var attributed = AttributedString(sentence)
        attributed.swiftUI.font = font

        guard !matchRanges.isEmpty else {
            return attributed
        }

        for strRange in matchRanges {
            let startOffset = sentence.distance(from: sentence.startIndex, to: strRange.lowerBound)
            let endOffset = sentence.distance(from: sentence.startIndex, to: strRange.upperBound)
            let attrStart = attributed.index(attributed.startIndex, offsetByCharacters: startOffset)
            let attrEnd = attributed.index(attributed.startIndex, offsetByCharacters: endOffset)
            attributed[attrStart..<attrEnd].swiftUI.foregroundColor = DesignSystemAsset.study300.swiftUIColor
            attributed[attrStart..<attrEnd].swiftUI.backgroundColor = DesignSystemAsset.highlightBg.swiftUIColor
            attributed[attrStart..<attrEnd].swiftUI.font = highlightFont
        }

        return attributed
    }

    private static func computeLemma(of word: String) -> String {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = word
        var result = word.lowercased()
        tagger.enumerateTags(
            in: word.startIndex..<word.endIndex,
            unit: .word,
            scheme: .lemma
        ) { tag, _ in
            if let tag {
                result = tag.rawValue.lowercased()
            }
            return false
        }
        return result
    }

    // 키워드를 문맥 없이 고립시켜 렘마화하면(computeLemma(of:)) 문장 속 문맥 기반 렘마와 품사 추정이 어긋나
    // 같은 단어인데도 다른 렘마가 나올 수 있다 (예: 고립된 "shopping" → "shop", 문장 속 "shopping" → "shopping").
    // 표층형이 그대로 일치하는 절대다수의 경우를 렘마 비교보다 먼저 확인해 이 불일치를 우회한다.
    private static func findTokenRanges(in sentence: String, keyword: String) -> [Range<String.Index>] {
        let keywordLower = keyword.lowercased()
        let keywordLemma = computeLemma(of: keyword)
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = sentence
        var ranges: [Range<String.Index>] = []
        tagger.enumerateTags(
            in: sentence.startIndex..<sentence.endIndex,
            unit: .word,
            scheme: .lemma,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, tokenRange in
            let tokenText = sentence[tokenRange].lowercased()
            let tokenLemma = tag?.rawValue.lowercased() ?? tokenText
            if tokenText == keywordLower || tokenLemma == keywordLemma {
                ranges.append(tokenRange)
            }
            return true
        }
        return ranges
    }

    // "have to", "used to" 같은 구(phrase) 키워드를 연속 토큰 시퀀스로 매칭
    private static func findPhraseRanges(in sentence: String, phrase: String) -> [Range<String.Index>] {
        let literalMatches = findLiteralPhraseRanges(in: sentence, phrase: phrase)
        guard literalMatches.isEmpty else { return literalMatches }

        let phraseLemmas = computeLemmas(of: phrase)
        guard !phraseLemmas.isEmpty else { return [] }

        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = sentence

        var tokens: [(lemma: String, range: Range<String.Index>)] = []
        tagger.enumerateTags(
            in: sentence.startIndex..<sentence.endIndex,
            unit: .word,
            scheme: .lemma,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, tokenRange in
            let tokenLemma = tag?.rawValue.lowercased() ?? String(sentence[tokenRange]).lowercased()
            tokens.append((tokenLemma, tokenRange))
            return true
        }

        var ranges: [Range<String.Index>] = []
        let phraseCount = phraseLemmas.count
        guard tokens.count >= phraseCount else { return [] }
        for i in 0...(tokens.count - phraseCount) {
            let slice = tokens[i..<(i + phraseCount)]
            guard let start = slice.first?.range.lowerBound, let end = slice.last?.range.upperBound else { continue }
            if zip(slice, phraseLemmas).allSatisfy({ $0.lemma == $1 }) {
                ranges.append(start..<end)
            }
        }
        return ranges
    }

    // phrase 표층형이 대소문자만 다르게 문장에 그대로 등장하는 모든 위치를 찾는다.
    // 단어 경계를 넘나드는 오탐(예: "to go"가 "photo goes"의 "oto go" 부분과 매칭)을 막기 위해
    // 매칭 앞뒤가 단어 문자(alphanumeric)가 아닌 경우에만 채택한다.
    private static func findLiteralPhraseRanges(in sentence: String, phrase: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var searchStart = sentence.startIndex
        while let found = sentence.range(
            of: phrase,
            options: .caseInsensitive,
            range: searchStart..<sentence.endIndex
        ) {
            searchStart = found.upperBound
            let hasLeadingBoundary = found.lowerBound == sentence.startIndex
                || !sentence[sentence.index(before: found.lowerBound)].isLetter
            let hasTrailingBoundary = found.upperBound == sentence.endIndex
                || !sentence[found.upperBound].isLetter
            if hasLeadingBoundary, hasTrailingBoundary {
                ranges.append(found)
            }
        }
        return ranges
    }

    private static func computeLemmas(of phrase: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = phrase
        var result: [String] = []
        tagger.enumerateTags(
            in: phrase.startIndex..<phrase.endIndex,
            unit: .word,
            scheme: .lemma,
            options: [.omitWhitespace, .omitPunctuation]
        ) { tag, tokenRange in
            let tokenLemma = tag?.rawValue.lowercased() ?? String(phrase[tokenRange]).lowercased()
            result.append(tokenLemma)
            return true
        }
        return result
    }
}

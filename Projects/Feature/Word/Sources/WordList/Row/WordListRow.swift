import SwiftUI

import DesignSystem
import DomainInterface

struct WordListRow: View {
    let word: Lesson.Word
    let blurMode: BlurMode
    let isRevealed: Bool
    let onTapped: () -> Void
    let onReveal: () -> Void

    private var shouldRevealOnTap: Bool { blurMode != .off && !isRevealed }

    var body: some View {
        Button(action: shouldRevealOnTap ? onReveal : onTapped) {
            HStack(alignment: .center, spacing: 12) {
                WordTextStack(
                    word: word,
                    blurMode: blurMode,
                    isRevealed: isRevealed
                )
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundStyle(DesignSystemAsset.fgSubtle.swiftUIColor)
            }
            .padding(16)
            .background(DesignSystemAsset.background.swiftUIColor)
            .clipShape(.rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(DesignSystemAsset.border.swiftUIColor, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Word Text Stack

private struct WordTextStack: View {
    let word: Lesson.Word
    let blurMode: BlurMode
    let isRevealed: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            WordNameRow(
                term: word.term,
                pronunciation: word.pronunciation,
                isBlurred: blurMode == .word && !isRevealed
            )
            BlurrableText(text: word.primaryMeaning, isBlurred: blurMode == .meaning && !isRevealed)
                .font(DesignSystemFontFamily.Pretendard.regular.swiftUIFont(size: 13))
                .foregroundStyle(DesignSystemAsset.fg.swiftUIColor)
        }
    }
}

private struct WordNameRow: View {
    let term: String
    let pronunciation: String
    let isBlurred: Bool

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            BlurrableText(text: term, isBlurred: isBlurred)
                .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 18))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
                .kerning(-0.012 * 18)
            BlurrableText(text: pronunciation, isBlurred: isBlurred)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(DesignSystemAsset.fgMuted.swiftUIColor)
        }
    }
}

// MARK: - Blurrable Text

private struct BlurrableText: View {
    let text: String
    let isBlurred: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(text)
            .blur(radius: isBlurred ? 6 : 0)
            .animation(reduceMotion ? nil : .easeIn(duration: 0.2), value: isBlurred)
    }
}

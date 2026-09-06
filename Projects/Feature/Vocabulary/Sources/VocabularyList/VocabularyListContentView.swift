import SwiftUI

import DesignSystem
import DomainInterface

struct VocabularyListContentView: View {
    let state: Lesson
    let onWordTapped: (String) -> Void

    @State private var blurMode: BlurMode = .off
    @State private var revealedIDs: Set<String> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VocabularyListHeaderView(
                    level: state.level,
                    lessonNumber: state.lessonNumber,
                    wordCount: state.words.count
                )
                .padding(.bottom, 14)
                BlurModeSelector(selected: $blurMode)
                    .padding(.bottom, 16)
                WordList(
                    words: state.words,
                    blurMode: blurMode,
                    revealedIDs: revealedIDs,
                    onTapped: onWordTapped,
                    onReveal: { revealedIDs.insert($0) }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(DesignSystemAsset.background.swiftUIColor)
        .onChange(of: blurMode) { revealedIDs = [] }
    }
}

// MARK: - Blur Mode Selector

private struct BlurModeSelector: View {
    @Binding var selected: BlurMode

    var body: some View {
        HStack(spacing: 8) {
            BlurModeButton(
                title: "뜻 가림",
                mode: .meaning,
                selected: selected
            ) { selected = .meaning }
            BlurModeButton(
                title: "단어 가림",
                mode: .word,
                selected: selected
            ) { selected = .word }
            BlurModeButton(
                title: "모두 보기",
                mode: .off,
                selected: selected
            ) { selected = .off }
        }
    }
}

private struct BlurModeButton: View {
    let title: String
    let mode: BlurMode
    let selected: BlurMode
    let action: () -> Void

    private var isSelected: Bool { mode == selected }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 13))
                .foregroundStyle(isSelected
                    ? DesignSystemAsset.fgStrong.swiftUIColor
                    : DesignSystemAsset.fgMuted.swiftUIColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected
                    ? DesignSystemAsset.bgSubtle.swiftUIColor
                    : Color.clear)
                .clipShape(Capsule())
                .overlay { Capsule().stroke(DesignSystemAsset.border.swiftUIColor, lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Word List

private struct WordList: View {
    let words: [Lesson.Word]
    let blurMode: BlurMode
    let revealedIDs: Set<String>
    let onTapped: (String) -> Void
    let onReveal: (String) -> Void

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(words) { word in
                VocabularyWordRow(
                    word: word,
                    blurMode: blurMode,
                    isRevealed: revealedIDs.contains(word.id),
                    onTapped: { onTapped(word.id) },
                    onReveal: { onReveal(word.id) }
                )
            }
        }
    }
}

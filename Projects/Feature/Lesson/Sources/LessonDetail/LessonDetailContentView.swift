import SwiftUI

import DesignSystem
import DomainInterface

struct SessionDetailContentView: View {
    let state: Session
    let onGameTapped: () -> Void
    let onVocabularyListTapped: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SessionHeaderSection(
                    level: state.level,
                    sessionNumber: state.sessionNumber,
                    wordCount: state.words.count,
                    estimatedDurationMinutes: state.estimatedDurationMinutes
                )
                RecordCard(record: state.record)
                WordPreviewSection(words: state.words)
                ActionButtonsSection(onGameTapped: onGameTapped, onVocabularyListTapped: onVocabularyListTapped)
            }
            .padding(.horizontal, 20)
            .padding(.vertical)
        }
        .scrollIndicators(.hidden)
        .background(DesignSystemAsset.background.swiftUIColor)
    }
}

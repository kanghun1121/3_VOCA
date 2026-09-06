import SwiftUI

import DesignSystem
import DomainInterface

struct LessonDetailContentView: View {
    let state: Lesson
    let learningHistory: LearningHistory?
    let onGameTapped: () -> Void
    let onVocabularyListTapped: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                LessonHeaderSection(
                    level: state.level,
                    lessonNumber: state.lessonNumber,
                    wordCount: state.words.count,
                    estimatedDurationMinutes: state.estimatedDurationMinutes
                )
                RecordCard(record: learningHistory)
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

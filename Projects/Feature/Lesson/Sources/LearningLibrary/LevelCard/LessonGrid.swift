import SwiftUI

import DomainInterface

struct LessonGrid: View {
    let lessons: [LessonProgress]
    let onLessonTapped: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 6)

    var body: some View {
        let statuses = lessons.cellStatuses
        LazyVGrid(columns: columns, spacing: 7) {
            ForEach(Array(zip(lessons, statuses)), id: \.0.id) { lesson, status in
                Button {
                    onLessonTapped(lesson.id)
                } label: {
                    LessonCell(lessonNumber: lesson.lessonNumber, status: status)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(makeAccessibilityLabel(lessonNumber: lesson.lessonNumber, status: status))
            }
        }
    }

    private func makeAccessibilityLabel(lessonNumber: Int, status: LessonCellStatus) -> String {
        switch status {
        case .done: "\(lessonNumber)번 레슨, 완료"
        case .current: "\(lessonNumber)번 레슨, 진행 중"
        case .todo: "\(lessonNumber)번 레슨, 잠김"
        }
    }
}

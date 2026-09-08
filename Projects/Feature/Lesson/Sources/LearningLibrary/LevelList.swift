import SwiftUI

import DesignSystem
import DomainInterface

struct LevelList: View {
    let levels: [LevelSummary]
    let expandedLevelIDs: Set<String>
    let onLevelTapped: (String) -> Void
    let onLessonTapped: (String) -> Void

    var body: some View {
        LazyVStack(spacing: 14) {
            ForEach(levels) { level in
                LevelCard(level: level, isExpanded: expandedLevelIDs.contains(level.id)) {
                    onLevelTapped(level.id)
                } onLessonTapped: { id in
                    onLessonTapped(id)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 24)
    }
}

import SwiftUI

import DesignSystem
import DomainInterface

struct HomeLevelList: View {
    let levels: [LevelSummary]
    let expandedLevelIDs: Set<String>
    let onLevelTapped: (String) -> Void
    let onSessionTapped: (String) -> Void

    var body: some View {
        LazyVStack(spacing: 14) {
            ForEach(levels) { level in
                LevelCard(level: level, isExpanded: expandedLevelIDs.contains(level.id)) {
                    onLevelTapped(level.id)
                } onSessionTapped: { id in
                    onSessionTapped(id)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 24)
    }
}

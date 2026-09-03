import SwiftUI

import DesignSystem
import DomainInterface

struct LevelCard: View {
    let level: LevelSummary
    let isExpanded: Bool
    let action: () -> Void
    let onSessionTapped: (String) -> Void

    private var isActive: Bool { level.status == .active }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                LevelCardHeader(
                    level: level.level,
                    name: level.name,
                    status: level.status,
                    completedSessions: level.completedSessions,
                    totalSessions: level.totalSessions,
                    isExpanded: isExpanded
                )
            }
            .buttonStyle(.plain)
            LevelProgressBar(progressRatio: level.progressRatio, status: level.status)
            if isExpanded {
                SessionGrid(sessions: level.sessions, onSessionTapped: onSessionTapped)
                    .padding(16)
            }
        }
        .background(LevelCardBackground(isActive: isActive))
        .clipShape(.rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isActive ? DesignSystemAsset.activeBorder.swiftUIColor : DesignSystemAsset.levelCardBorder.swiftUIColor,
                    lineWidth: 1
                )
        }
        .shadow(
            color: isActive
                ? DesignSystemAsset.primary.swiftUIColor.opacity(0.10)
                : Color.clear,
            radius: 12,
            x: 0,
            y: 4
        )
        .animation(.easeOut(duration: 0.2), value: isExpanded)
    }
}

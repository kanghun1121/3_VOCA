import SwiftUI

import DesignSystem

struct LevelCardHeader: View {
    let level: Int
    let name: String
    let status: LevelStatus
    let completedSessions: Int
    let totalSessions: Int
    let isExpanded: Bool

    var body: some View {
        HStack(spacing: 13) {
            LevelIconChip(level: level)
            Text(name)
                .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 15.5))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
            if let badge = status.badgeInfo {
                Text(badge.text)
                    .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 10.5))
                    .foregroundStyle(badge.fg)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(badge.bg)
                    .clipShape(.rect(cornerRadius: 100))
            }
            Spacer()
            Text("\(completedSessions)/\(totalSessions)")
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 13))
                .foregroundStyle(DesignSystemAsset.fgMuted.swiftUIColor)
            Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                .font(.system(size: 17))
                .foregroundStyle(DesignSystemAsset.fgSubtle.swiftUIColor)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
    }
}

extension LevelStatus {
    var badgeInfo: (text: String, fg: Color, bg: Color)? {
        switch self {
        case .active:
            (
                "학습 중",
                DesignSystemAsset.studying.swiftUIColor,
                DesignSystemAsset.studying100.swiftUIColor
            )
        case .completed:
            (
                "완료",
                DesignSystemAsset.positive.swiftUIColor,
                DesignSystemAsset.positive100.swiftUIColor
            )
        case .notStarted:
            nil
        }
    }
}

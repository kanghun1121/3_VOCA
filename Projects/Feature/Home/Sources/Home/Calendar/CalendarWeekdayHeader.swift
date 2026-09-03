import SwiftUI

import DesignSystem

struct CalendarWeekdayHeader: View {
    private let labels = ["월", "화", "수", "목", "금", "토", "일"]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(labels, id: \.self) { label in
                Text(label)
                    .homeTypography(.weekdayHeader)
                    .foregroundStyle(DesignSystemAsset.fgSubtle.swiftUIColor)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

import SwiftUI

import DesignSystem

struct LevelProgressBar: View {
    let progressRatio: Double
    let status: LevelStatus

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(DesignSystemAsset.progressTrack.swiftUIColor)
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    status == .notStarted
                        ? DesignSystemAsset.progressInactive.swiftUIColor
                        : DesignSystemAsset.progressActive.swiftUIColor
                )
                .containerRelativeFrame(.horizontal) { width, _ in
                    width * max(0.03, min(1, progressRatio))
                }
        }
        .frame(height: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
}

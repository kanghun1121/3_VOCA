import SwiftUI

import DesignSystem

struct StageSegmentBar: View {
    let currentStage: Int
    private let totalStages: Int = 3

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalStages, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStage
                          ? DesignSystemAsset.white.swiftUIColor
                          : DesignSystemAsset.white.swiftUIColor.opacity(0.22))
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, 26)
    }
}

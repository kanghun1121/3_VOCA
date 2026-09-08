import SwiftUI

import DesignSystem

struct LevelCardBackground: View {
    let isActive: Bool

    var body: some View {
        if isActive {
            LinearGradient(
                colors: [DesignSystemAsset.activeCardGradientStart.swiftUIColor, DesignSystemAsset.white.swiftUIColor],
                startPoint: UnitPoint(x: 0.2, y: 0.0),
                endPoint: UnitPoint(x: 1.0, y: 1.0)
            )
        } else {
            DesignSystemAsset.white.swiftUIColor
        }
    }
}

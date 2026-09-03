import SwiftUI

import DesignSystem

struct LevelIconChip: View {
    let level: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 13)
                .fill(DesignSystemAsset.heatmap0.swiftUIColor)
                .frame(width: 40, height: 40)
            levelIcon
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
        }
    }

    private var levelIcon: SwiftUI.Image {
        switch level {
        case 1: DesignSystemAsset.levelIcon1.swiftUIImage
        case 2: DesignSystemAsset.levelIcon2.swiftUIImage
        case 3: DesignSystemAsset.levelIcon3.swiftUIImage
        case 4: DesignSystemAsset.levelIcon4.swiftUIImage
        case 5: DesignSystemAsset.levelIcon5.swiftUIImage
        case 6: DesignSystemAsset.levelIcon6.swiftUIImage
        default: DesignSystemAsset.levelIcon1.swiftUIImage
        }
    }
}

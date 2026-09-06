import SwiftUI

import DesignSystem

struct GameBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: DesignSystemAsset.game.swiftUIColor, location: 0),
                .init(color: DesignSystemAsset.gameDark.swiftUIColor, location: 0.55),
                .init(color: DesignSystemAsset.gameDeep.swiftUIColor, location: 1),
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        .ignoresSafeArea()
    }
}

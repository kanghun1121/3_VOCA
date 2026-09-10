import SwiftUI

import DesignSystem

struct SplashView: View {
    var body: some View {
        ZStack {
            DesignSystemAsset.white.swiftUIColor
                .ignoresSafeArea()

            SplashContentView()
        }
    }
}

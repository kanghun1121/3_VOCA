import SwiftUI

import DesignSystem
import DomainInterface

struct MultipleChoiceWordHeader: View {
    let word: Lesson.Word

    var body: some View {
        VStack(spacing: 10) {
            Text(word.term)
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 40))
                .tracking(-0.03 * 40)
                .foregroundStyle(DesignSystemAsset.white.swiftUIColor)
                .multilineTextAlignment(.center)

            Text("알맞은 뜻을 고르세요")
                .font(DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 14))
                .tracking(0.04 * 14)
                .foregroundStyle(DesignSystemAsset.white.swiftUIColor.opacity(0.55))
        }
        .padding(.horizontal, 28)
    }
}

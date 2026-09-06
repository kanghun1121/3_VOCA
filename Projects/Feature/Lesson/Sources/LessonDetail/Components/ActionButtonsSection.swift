import SwiftUI

import DesignSystem

struct ActionButtonsSection: View {
    let onGameTapped: () -> Void
    let onVocabularyListTapped: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onGameTapped) {
                Label("학습 게임 시작", systemImage: "play.fill")
                    .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 17))
                    .foregroundStyle(DesignSystemAsset.white.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DesignSystemAsset.game.swiftUIColor)
                    .clipShape(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button(action: onVocabularyListTapped) {
                Label("단어 보기", systemImage: "book")
                    .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 17))
                    .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DesignSystemAsset.white.swiftUIColor)
                    .clipShape(.rect(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(DesignSystemAsset.border.swiftUIColor, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
    }
}

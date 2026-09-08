import SwiftUI

import DesignSystem
import DomainInterface

struct WordRowView: View {
    let wordAnnotation: Indexed<WordDetail.Example.WordAnnotation>

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(wordAnnotation.element.word)
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 16))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
                .frame(minWidth: 70, alignment: .leading)

            Text(wordAnnotation.element.meaning)
                .font(DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 15))
                .foregroundStyle(DesignSystemAsset.fg.swiftUIColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(wordAnnotation.element.pos.koreanPartOfSpeechLabel)
                .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 11))
                .foregroundStyle(DesignSystemAsset.fgMuted.swiftUIColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(DesignSystemAsset.bgSubtle.swiftUIColor)
                .clipShape(.capsule)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 2)
    }
}

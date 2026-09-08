import SwiftUI

import DesignSystem

struct ChunkReaderMeaningLabel: View {
    let meaning: String?

    var body: some View {
        if let meaning {
            Text(meaning)
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 15))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
        } else {
            Text("청크를 탭하면 뜻이 나와요")
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 14))
                .foregroundStyle(DesignSystemAsset.fgSubtle.swiftUIColor)
        }
    }
}

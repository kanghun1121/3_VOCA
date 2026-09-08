import SwiftUI

import DesignSystem

struct ChunkReaderBadge: View {
    let icon: String
    let label: String

    var body: some View {
        Label {
            Text(label)
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 11))
        } icon: {
            Image(systemName: icon)
                .font(.system(size: 10))
        }
        .foregroundStyle(DesignSystemAsset.study300.swiftUIColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(DesignSystemAsset.study100.swiftUIColor.opacity(0.5))
        .clipShape(.capsule)
        .overlay {
            Capsule()
                .stroke(DesignSystemAsset.study300.swiftUIColor, lineWidth: 1)
        }
    }
}

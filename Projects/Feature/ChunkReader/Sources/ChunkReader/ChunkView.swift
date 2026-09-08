import SwiftUI

import DesignSystem
import DomainInterface

struct ChunkView: View {
    let chunk: Indexed<WordDetail.Example.Chunk>
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(chunk.element.text)
                .font(DesignSystemFontFamily.Pretendard.regular.swiftUIFont(size: 17))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            isSelected
                                ? DesignSystemAsset.study100.swiftUIColor
                                : DesignSystemAsset.study100.swiftUIColor.opacity(0.5)
                        )
                        .stroke(isSelected ? DesignSystemAsset.study300.swiftUIColor : .clear, lineWidth: 2)
                }
        }
        // 실제 레이아웃 크기(FlowLayout 계산)는 그대로 유지하면서 탭 가능 영역만 넓힌다.
        .contentShape(.rect(cornerRadius: 8).inset(by: -6))
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }
}

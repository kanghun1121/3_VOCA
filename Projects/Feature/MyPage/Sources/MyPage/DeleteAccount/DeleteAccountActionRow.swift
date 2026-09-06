import SwiftUI

import DesignSystem

struct DeleteAccountActionRow: View {
    let isConfirmed: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Text("취소")
                    .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 16))
                    .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DesignSystemAsset.border.swiftUIColor)
                    .clipShape(.rect(cornerRadius: 10))
            }

            Button(action: onConfirm) {
                Text("탈퇴")
                    .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        DesignSystemAsset.negative.swiftUIColor
                            .opacity(isConfirmed ? 1 : 0.3)
                    )
                    .clipShape(.rect(cornerRadius: 10))
            }
            .disabled(!isConfirmed)
        }
    }
}

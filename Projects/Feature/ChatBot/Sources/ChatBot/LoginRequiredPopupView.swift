import AuthenticationServices
import SwiftUI

import DesignSystem

struct LoginRequiredPopupView: View {
    let onAppleRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onAppleCompletion: (Result<ASAuthorization, any Error>) -> Void
    let onTapLater: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("로그인이 필요해요")
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 20))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
                .padding(.top, 28)

            Text("이 기능을 사용하려면 로그인해 주세요.")
                .font(DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 14))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor.opacity(0.61))
                .padding(.bottom, 24)

            SignInWithAppleButton(
                .signIn,
                onRequest: onAppleRequest,
                onCompletion: onAppleCompletion
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 54)
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal, 26)

            Button(action: onTapLater) {
                Text("나중에")
                    .font(DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 14))
                    .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor.opacity(0.28))
            }
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity)
        .background(DesignSystemAsset.background.swiftUIColor)
        .clipShape(.rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: -4)
    }
}

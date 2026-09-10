import AuthenticationServices
import SwiftUI

import DesignSystem

struct LoginStatusCardView: View {
    let isAuthenticated: Bool
    let onAppleRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onAppleCompletion: (Result<ASAuthorization, any Error>) -> Void

    var body: some View {
        Group {
            if isAuthenticated {
                authenticatedContent
            } else {
                unauthenticatedContent
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystemAsset.bgMuted.swiftUIColor)
        .clipShape(.rect(cornerRadius: 12))
        .padding(.horizontal, 26)
        .padding(.bottom, 20)
    }

    private var authenticatedContent: some View {
        Text("Apple로 로그인됨")
            .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 15))
            .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
    }

    private var unauthenticatedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("로그인이 필요해요")
                    .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 15))
                    .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)

                Text("로그인하고 더 많은 기능을 이용해 보세요.")
                    .font(DesignSystemFontFamily.Pretendard.medium.swiftUIFont(size: 13))
                    .foregroundStyle(DesignSystemAsset.fgMuted.swiftUIColor)
            }

            SignInWithAppleButton(
                .signIn,
                onRequest: onAppleRequest,
                onCompletion: onAppleCompletion
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 44)
            .clipShape(.rect(cornerRadius: 10))
        }
    }
}

import SwiftUI

import DesignSystem

struct MyPageScrollContent: View {
    let viewModel: MyPageViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                MyPageHeaderView()

                LoginStatusCardView(
                    isAuthenticated: viewModel.isAuthenticated,
                    onAppleRequest: viewModel.appleLoginRequested,
                    onAppleCompletion: viewModel.appleLoginCompleted
                )

                MyPageMenuView(
                    onPrivacyTapped: viewModel.privacyTapped
                )

                Spacer(minLength: 40)

                if viewModel.isAuthenticated {
                    MyPageActionsView(onLogoutTapped: viewModel.logoutTapped, onDeleteAccountTapped: viewModel.deleteAccountTapped)
                }
            }
            .frame(maxWidth: .infinity)
            .containerRelativeFrame(.vertical, alignment: .top)
        }
        .background(DesignSystemAsset.background.swiftUIColor)
    }
}

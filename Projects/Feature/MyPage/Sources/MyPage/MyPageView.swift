import SwiftUI

import DesignSystem

import SwiftUINavigation

public struct MyPageView: View {
    @State private var viewModel: MyPageViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(viewModel: MyPageViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var privacySheetBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isShowingPrivacyWebView },
            set: { if !$0 { viewModel.destination = nil } }
        )
    }

    public var body: some View {
        ZStack {
            MyPageScrollContent(viewModel: viewModel)

            if viewModel.isShowingDeleteSheet {
                Button {
                    viewModel.closeDeleteSheet()
                } label: {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("닫기")
                .transition(.opacity)

                DeleteAccountConfirmSheet(
                    confirmText: $viewModel.deleteConfirmText,
                    isConfirmed: viewModel.isDeleteConfirmed,
                    onConfirm: viewModel.deleteAccountConfirmTapped,
                    onCancel: viewModel.closeDeleteSheet
                )
                .padding(.horizontal, 30)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.isShowingDeleteSheet)
        .sheet(isPresented: privacySheetBinding) {
            if let url = viewModel.privacyPolicyURL {
                PrivacyWebView(url: url)
                    .ignoresSafeArea()
            }
        }
        .alert($viewModel.destination.alert) { action in
            viewModel.alertButtonTapped(action)
        }
        .tint(DesignSystemAsset.white.swiftUIColor)
        .task { viewModel.onAppear() }
    }
}

#Preview {
    MyPageView(viewModel: MyPageViewModel())
}

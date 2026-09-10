import AuthenticationServices
import Foundation
import OSLog

import DomainInterface

import Dependencies
import SwiftUINavigation

private let logger = Logger(subsystem: "com.kangdev.FiveVoca", category: "Auth")

@Observable
@MainActor
public final class MyPageViewModel {
    enum AlertAction {
        case confirmLogout
    }

    @CasePathable
    enum Destination {
        case alert(AlertState<AlertAction>)
        case deleteAccountSheet
        case privacyWebView
    }

    var destination: Destination?
    var deleteConfirmText = ""
    var isAuthenticated = false
    @ObservationIgnored @Dependency(\.authSessionRepository) private var authSessionRepository
    @ObservationIgnored @Dependency(\.checkAuthSessionUseCase) private var checkAuthSessionUseCase
    @ObservationIgnored @Dependency(\.signInWithAppleUseCase) private var signInWithAppleUseCase

    var isDeleteConfirmed: Bool { deleteConfirmText == "회원탈퇴" }
    var isShowingDeleteSheet: Bool {
        if case .deleteAccountSheet = destination { true } else { false }
    }

    var isShowingPrivacyWebView: Bool {
        if case .privacyWebView = destination { true } else { false }
    }

    var privacyPolicyURL: URL? {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "PRIVACY_POLICY_URL") as? String,
            let url = URL(string: raw)
        else { return nil }
        return url
    }

    public init() {
        isAuthenticated = checkAuthSessionUseCase.execute()
    }

    func onAppear() {
        Task { [weak self] in
            guard let self else { return }
            for await state in authSessionRepository.stateStream() {
                isAuthenticated = (state == .authenticated)
            }
        }
    }

    func appleLoginRequested(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func appleLoginCompleted(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else { return }
            Task {
                do {
                    _ = try await signInWithAppleUseCase.execute(identityToken)
                } catch {
                    logger.error("signInWithApple 실패: \(error.localizedDescription)")
                }
            }
        case .failure(let error):
            logger.error("Apple 로그인 실패: \(error.localizedDescription)")
        }
    }

    func privacyTapped() {
        destination = .privacyWebView
    }

    func logoutTapped() {
        destination = .alert(
            AlertState(
                title: TextState("정말로 로그아웃 하시겠습니까?"),
                buttons: [
                    .destructive(TextState("로그아웃"), action: .send(.confirmLogout)),
                    .cancel(TextState("취소"))
                ]
            )
        )
    }

    func alertButtonTapped(_ action: AlertAction?) {
        switch action {
        case .confirmLogout:
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await authSessionRepository.clear()
                } catch {
                    destination = .alert(AlertState(
                        title: TextState("로그아웃에 실패했습니다. 다시 시도해 주세요."),
                        buttons: [.cancel(TextState("확인"))]
                    ))
                }
            }
        case .none:
            break
        }
    }

    func deleteAccountTapped() {
        deleteConfirmText = ""
        destination = .deleteAccountSheet
    }

    func closeDeleteSheet() {
        destination = nil
        deleteConfirmText = ""
    }

    func deleteAccountConfirmTapped() {
        destination = nil
        deleteConfirmText = ""
        Task { [weak self] in
            guard let self else { return }
            do {
                try await authSessionRepository.deleteAccount()
            } catch {
                destination = .alert(AlertState(
                    title: TextState("탈퇴에 실패했습니다. 다시 시도해 주세요."),
                    buttons: [.cancel(TextState("확인"))]
                ))
            }
        }
    }
}

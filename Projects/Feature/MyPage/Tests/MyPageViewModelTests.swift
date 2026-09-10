import XCTest

import DomainInterface

import Dependencies

@testable import FeatureMyPage

@MainActor
final class MyPageViewModelTests: XCTestCase {
    private func waitUntil(timeout: Duration = .seconds(2), _ condition: () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition(), ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    func test_초기_미인증_상태면_isAuthenticated는_false다() {
        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { false }
        } operation: {
            MyPageViewModel()
        }

        XCTAssertFalse(viewModel.isAuthenticated)
    }

    func test_초기_인증_상태면_isAuthenticated는_true다() {
        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { true }
        } operation: {
            MyPageViewModel()
        }

        XCTAssertTrue(viewModel.isAuthenticated)
    }

    func test_스트림이_authenticated를_방출하면_isAuthenticated가_true로_갱신된다() async {
        let (stream, continuation) = AsyncStream<AuthState>.makeStream()
        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { false }
            $0.authSessionRepository.stateStream = { stream }
        } operation: {
            MyPageViewModel()
        }

        viewModel.onAppear()
        continuation.yield(.authenticated)

        await waitUntil { viewModel.isAuthenticated }

        XCTAssertTrue(viewModel.isAuthenticated)
    }

    func test_스트림이_unauthenticated를_방출하면_isAuthenticated가_false로_갱신된다() async {
        let (stream, continuation) = AsyncStream<AuthState>.makeStream()
        let viewModel = withDependencies {
            $0.checkAuthSessionUseCase.execute = { true }
            $0.authSessionRepository.stateStream = { stream }
        } operation: {
            MyPageViewModel()
        }

        viewModel.onAppear()
        continuation.yield(.unauthenticated)

        await waitUntil { !viewModel.isAuthenticated }

        XCTAssertFalse(viewModel.isAuthenticated)
    }
}

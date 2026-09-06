import XCTest

import Dependencies

@testable import FeatureSession

@MainActor
final class SessionDetailViewModelTests: XCTestCase {
    func test_load_성공시_viewState가_loaded로_전환된다() async {
        let vm = withDependencies {
            $0.getSessionDetailUseCase = .previewValue
            $0.prefetchAudioUseCase.execute = { _ in }
        } operation: {
            SessionDetailViewModel(sessionID: "t")
        }

        await vm.load()

        guard case .loaded = vm.viewState else {
            XCTFail("viewState가 .loaded여야 합니다. 실제: \(vm.viewState)")
            return
        }
    }

    func test_load_실패시_viewState가_error로_전환된다() async {
        let vm = withDependencies {
            $0.getSessionDetailUseCase.execute = { _ in throw MockError.stub }
        } operation: {
            SessionDetailViewModel(sessionID: "t")
        }

        await vm.load()

        guard case .error = vm.viewState else {
            XCTFail("viewState가 .error여야 합니다. 실제: \(vm.viewState)")
            return
        }
    }
}

private enum MockError: Error {
    case stub
}

import SwiftUI

import Core
import Data
import Domain
import DomainInterface
import FeatureLogin
import Networking
import NetworkingInterface

import Dependencies

struct RootView: View {
    // 각 UseCase의 liveValue 클로저는 하위 Repository/Client를 @Dependency(\.x) 키패스로만
    // 참조한다. 이 키패스 하나만으로는 static 프레임워크 링크 시 해당 conformance가 어디에서도
    // 이름으로 참조되지 않아 링커가 제외할 수 있으므로, 앱의 유일한 진입점에서 전부 명시적으로
    // liveValue를 지정해 링크를 강제한다.
    @State private var viewModel = withDependencies {
        $0.checkAuthSessionUseCase = .liveValue
        $0.refreshAuthSessionUseCase = .liveValue
        $0.authSessionRepository = .liveValue
        $0.authRepository = .liveValue
        $0.vocabularyLibraryRepository = .liveValue
        $0.lessonRepository = .liveValue
        $0.learningHistoryRepository = .liveValue
        $0.wordRepository = .liveValue
        $0.audioRepository = .liveValue
        $0.audioPlayerRepository = .liveValue
        $0.tokenProvider = .liveValue
        $0.keychainClient = .liveValue
        $0.httpClient = HTTPClientKey.liveValue
        $0.authenticatedHTTPClient = AuthenticatedHTTPClientKey.liveValue
    } operation: {
        AppViewModel()
    }

    var body: some View {
        Group {
            if viewModel.isCheckingSession {
                SplashView()
            } else {
                switch viewModel.authState {
                case .unauthenticated:
                    LoginView(viewModel: withDependencies {
                        $0.signInWithAppleUseCase = .liveValue
                    } operation: {
                        LoginViewModel()
                    })
                case .authenticated:
                    MainTabView()
                }
            }
        }
        .task { viewModel.onAppear() }
    }
}

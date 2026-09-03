import SwiftUI

import DesignSystem
import FeatureHome
import FeatureMyPage

import Dependencies

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("홈", systemImage: "house.fill") {
                HomeView(viewModel: withDependencies {
                    $0.getSessionDetailUseCase = .liveValue
                    $0.completeSessionUseCase = .liveValue
                    $0.getWordDetailUseCase = .liveValue
                    $0.prefetchWordDetailsUseCase = .liveValue
                    $0.prefetchAudioUseCase = .liveValue
                    $0.getAudioURLUseCase = .liveValue
                    $0.playAudioUseCase = .liveValue
                    $0.stopAudioUseCase = .liveValue
                } operation: {
                    HomeViewModel()
                })
            }

            Tab("마이페이지", systemImage: "person.fill") {
                MyPageView(viewModel: withDependencies {
                    $0.logoutUseCase = .liveValue
                    $0.deleteAccountUseCase = .liveValue
                } operation: {
                    MyPageViewModel()
                })
            }
        }
        .tint(DesignSystemAsset.growDeep.swiftUIColor)
    }
}

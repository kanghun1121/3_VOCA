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
                    $0.loadLessonDetailUseCase = .liveValue
                    $0.loadLessonWordsUseCase = .liveValue
                } operation: {
                    HomeViewModel()
                })
            }

            Tab("마이페이지", systemImage: "person.fill") {
                MyPageView(viewModel: MyPageViewModel())
            }
        }
        .tint(DesignSystemAsset.growDeep.swiftUIColor)
    }
}

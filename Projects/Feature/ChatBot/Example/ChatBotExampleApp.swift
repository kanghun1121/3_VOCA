import SwiftUI

import Data
import Domain
import DomainInterface
import FeatureChatBot
import Networking
import NetworkingInterface

import Dependencies

@main
struct ChatBotExampleApp: App {
    init() {
        // ChatRepository/SSEClientKey의 liveValue를 명시적으로 참조해야 한다 — Data/Networking
        // 모듈이 Tuist 의존성에는 있어도 소스에서 심볼을 직접 참조하지 않으면 Xcode의 Debug dylib
        // 빌드가 두 모듈을 링크에서 제외해 testValue(Noop)로 조용히 폴백한다.
        prepareDependencies {
            $0.sseClient = SSEClientKey.liveValue
            $0.chatRepository = .liveValue
        }
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                ChatBotPushDemoView()
                    .tabItem { Label("챗봇", systemImage: "bubble.left.and.bubble.right") }
                MarkdownShowcaseView()
                    .tabItem { Label("응답 전문", systemImage: "doc.text") }
                MarkdownCatalogView()
                    .tabItem { Label("요소 카탈로그", systemImage: "list.bullet.rectangle") }
            }
        }
    }
}

/// 단어 상세 화면에서 문법 분석 화면으로 네비게이션 push되는 실제 흐름을 재현해
/// Figma 디자인과 대조할 수 있게 한다.
private struct ChatBotPushDemoView: View {
    private static let context = ChatBotContext(
        term: "address",
        sentence: "Please write your home address on this form.",
        levelLabel: "초급"
    )

    var body: some View {
        NavigationStack {
            VStack {
                Text(Self.context.term)
                    .font(.system(size: 52, weight: .heavy))
                    .foregroundStyle(.secondary)
                    .padding(.top, 60)
                Spacer()
                NavigationLink("문법 분석 열기") {
                    ChatBotView(viewModel: ChatBotViewModel(context: Self.context))
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

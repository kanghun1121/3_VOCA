import SwiftUI

/// 메시지 역할에 따라 좌/우 정렬과 말풍선 종류를 라우팅한다.
struct ChatBotMessageRow: View {
    let message: ChatBotMessage
    let isActivelyStreaming: Bool

    var body: some View {
        switch message.role {
        case .user:
            ChatBotUserBubbleView(text: message.text)
                .frame(maxWidth: .infinity, alignment: .trailing)

        case .assistant:
            ChatBotAssistantBubbleView(message: message, isActivelyStreaming: isActivelyStreaming)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

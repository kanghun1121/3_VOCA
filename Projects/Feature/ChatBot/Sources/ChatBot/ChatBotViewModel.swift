import AuthenticationServices
import Foundation
import OSLog

import DomainInterface

import Dependencies

private let logger = Logger(subsystem: "com.kangdev.FiveVoca", category: "Auth")

@Observable
@MainActor
public final class ChatBotViewModel {
    let context: ChatBotContext
    var input: String = ""
    private(set) var messages: [ChatBotMessage] = []
    private(set) var isStreaming: Bool = false
    private(set) var isShowingLoginRequiredPopup = false
    /// 히스토리 조회 성공 시에만 true로 세운다 — 실패하면 다음 onAppear에서 자연스럽게
    /// 재시도되게 하기 위함. View가 이 전환(false→true)을 감지해 맨 아래로 스크롤한다.
    private(set) var hasLoadedHistory = false
    /// 히스토리 조회가 실패했는지 — View가 이 값을 보고 재시도 안내를 보여준다. 콘솔 로그만
    /// 남기고 화면엔 아무 표시도 없던 걸 개선했다(swiftui-pro 리뷰).
    private(set) var isHistoryLoadFailed = false

    @ObservationIgnored @Dependency(\.chatRepository) private var chatRepository
    @ObservationIgnored @Dependency(\.checkAuthSessionUseCase) private var checkAuthSessionUseCase
    @ObservationIgnored @Dependency(\.signInWithAppleUseCase) private var signInWithAppleUseCase
    // 테스트에서 스트림 종료를 결정론적으로 기다리기 위해 노출한다
    // (WordGame의 SpellingViewModel.advanceTask와 같은 방식).
    @ObservationIgnored private(set) var streamTask: Task<Void, Never>?

    /// 단어 하나가 공개된 뒤 다음 단어로 넘어가기 전 대기 시간. 이 값이 클수록 타이핑 효과가 느려진다.
    private static let wordRevealDelay: Duration = .milliseconds(10)

    public init(context: ChatBotContext) {
        self.context = context
    }

    var canSend: Bool {
        !isStreaming && !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func didTapSend() {
        let message = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isStreaming, !message.isEmpty else { return }

        input = ""
        isStreaming = true

        // 이전 실패 메시지는 새 전송을 시작하는 순간 히스토리에서 사라진다 — 정상
        // 응답과 달리 대화 기록으로 남기지 않는다.
        messages.removeAll(where: { $0.isError })

        messages.append(ChatBotMessage(role: .user, text: message))
        messages.append(ChatBotMessage(
            role: .assistant,
            text: "",
            isGenerating: true
        ))
        let assistantIndex = messages.count - 1

        streamTask = Task {
            do {
                for try await chunk in chatRepository.streamMessage(message, context.wordID) {
                    // 청크 하나를 통째로 붙이면 그 안의 여러 단어가 한 프레임에 동시 등장한다.
                    // 단어 경계로 쪼개 하나씩 붙이고, 다음 단어로 넘어가기 전 wordRevealDelay만큼
                    // 대기해 타이핑처럼 천천히 펼쳐지게 한다.
                    for word in Self.wordChunks(of: chunk) {
                        messages[assistantIndex].isGenerating = false
                        messages[assistantIndex].text += word
                        // try?로 삼키면 취소된 뒤에도 루프가 멈추지 않고 남은 단어를 계속
                        // 쏟아낸다 — 취소를 그대로 던져 즉시 멈추게 한다.
                        try await Task.sleep(for: Self.wordRevealDelay)
                    }
                }
            } catch {
                // 화면 이탈(onDisappear)로 로컬 Task가 직접 취소된 경우는 실패가 아니다 — 조용히
                // 끝내고 받은 텍스트를 남긴다. 정지 버튼(didTapStop)은 더 이상 이 Task를 취소하지
                // 않으므로(서브플랜 10), 여기 걸리는 취소는 사실상 onDisappear뿐이다.
                if !Task.isCancelled {
                    print("[ChatBot] 스트리밍 실패:", error)
                    // 이미 받은 부분 응답이 있어도 실패 문구로 대체한다 — 어중간하게
                    // 잘린 답변보다 "다시 시도가 필요하다"는 게 명확한 편이 낫다.
                    messages[assistantIndex].isGenerating = false
                    messages[assistantIndex].text = "답변을 가져오지 못했어요"
                    messages[assistantIndex].isError = true
                }
            }
            // 종료 사유(성공/취소)와 무관하게, 한 글자도 못 받은 자리표시는 남기지 않는다.
            // 실패 시엔 위에서 text를 채워 넣으므로 이 분기를 타지 않는다.
            if messages[assistantIndex].text.isEmpty {
                messages.remove(at: assistantIndex)
            }
            isStreaming = false
        }
    }

    /// 정지 버튼 탭 시 호출(서브플랜 10, 구 `didTapCancel`) — 로컬 스트림 `Task`는 취소하지
    /// 않는다. 대신 서버에 `/chat-stop`으로 정지를 요청하고, 서버가 지금까지 생성한 내용을
    /// 마저 SSE로 흘려보낸 뒤 스스로 스트림을 닫을 때까지 `didTapSend()`의 루프가 계속
    /// 소비한다 — 그 동안 화면에도 계속 반영된다(사용자 확정 UX: 드레인 중에도 타이핑
    /// 애니메이션이 자연스럽게 이어지다 멈춘다). 어떤 전송을 멈출지(sse_id)는 이 ViewModel이
    /// 몰라도 된다 — `context.wordID`만 넘기면 Data 레이어(`ChatSessionStore`)가 알아서
    /// 찾는다. stop 요청 실패는 best-effort로 무시한다 — idempotent라 이미 끝난 스트림에
    /// 보내도 문제없고, 실패해도 스트림 자체는 정상 진행/종료된다.
    func didTapStop() {
        Task { try? await chatRepository.stopStreaming(context.wordID) }
    }

    /// 화면을 벗어나면 더 이상 화면에 보여줄 이유가 없으므로 로컬 Task는 즉시 취소한다(정지
    /// 버튼과 달리 드레인까지 기다리지 않음). 서버 쪽 생성도 계속 이어갈 이유가 없어 함께
    /// `/chat-stop`을 호출한다(사용자에게 확인 안 된 가정 — 필요시 조정 가능). 진행 중인
    /// 전송이 없어도 안전하다 — Data 레이어가 조용히 무시한다.
    func onDisappear() {
        Task { try? await chatRepository.stopStreaming(context.wordID) }
        streamTask?.cancel()
    }

    func onAppear() async {
        isShowingLoginRequiredPopup = !checkAuthSessionUseCase.execute()
        guard !isShowingLoginRequiredPopup, !hasLoadedHistory else { return }

        isHistoryLoadFailed = false
        do {
            // 로컬 캐시가 먼저 emit되고, 서버 조회가 끝나면 그 결과가 이어서 emit된다(서브플랜 9).
            for try await history in chatRepository.fetchHistory(context.wordID) {
                apply(history)
            }
            hasLoadedHistory = true
        } catch {
            // 새 화면 자체는 정상 동작해야 하므로 팝업 같은 걸로 막지 않는다 — 대신
            // isHistoryLoadFailed로 View가 인라인 재시도 안내를 보여준다(swiftui-pro 리뷰:
            // 이전엔 print만 하고 화면엔 아무 표시가 없어 사용자가 원인을 알 수 없었다).
            // hasLoadedHistory를 세우지 않으므로 재시도가 다시 시도된다.
            print("[ChatBot] 히스토리 로드 실패:", error)
            isHistoryLoadFailed = true
        }
    }

    /// 히스토리 로드 실패 안내의 "다시 시도" 버튼 탭 시 호출.
    func didTapRetryHistoryLoad() {
        Task { await onAppear() }
    }

    /// `ChatHistory.messages`는 이미 매핑 계층(`ChatHistoryResponseDTO+Mapping.swift`)에서
    /// conversation 단위를 평탄화해 서버가 준 순서 그대로 내려온다 — 여기서 다시 정렬하지
    /// 않는다(서버가 순서를 보장하므로 클라이언트 재검증은 2중 작업). `fetchHistory`가 로컬→서버
    /// 순으로 2번 emit할 수 있어(서브플랜 9), 매번 이전 히스토리 태그 행을 지우고 새로 끼워
    /// 넣는다 — 그렇지 않으면 로컬 스냅샷 위에 서버 스냅샷이 또 추가돼 중복된다. 맨 뒤가 아니라
    /// 맨 앞에 끼워 넣는 이유: onAppear는 비동기라 로드가 끝나기 전에 사용자가 이미 메시지를
    /// 보냈을 수 있는데, 그 경우 통째로 덮어쓰면 방금 보낸 메시지가 사라진다(`isFromHistory ==
    /// false`인 실시간 메시지는 `removeAll`이 건드리지 않아 안전하다).
    private func apply(_ history: ChatHistory) {
        messages.removeAll(where: \.isFromHistory)
        let loadedMessages = history.messages.map { message -> ChatBotMessage in
            let role: ChatBotMessage.Role
            switch message.role {
            case .user: role = .user
            case .assistant: role = .assistant
            }
            return ChatBotMessage(role: role, text: message.content, isFromHistory: true)
        }
        messages.insert(contentsOf: loadedMessages, at: 0)
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
                    isShowingLoginRequiredPopup = false
                } catch {
                    logger.error("signInWithApple 실패: \(error.localizedDescription)")
                }
            }
        case .failure(let error):
            logger.error("Apple 로그인 실패: \(error.localizedDescription)")
        }
    }

    func didTapLater() {
        isShowingLoginRequiredPopup = false
    }

    /// 텍스트를 "단어 + 그 뒤에 붙는 공백"들로 쪼갠다. 순서대로 이어 붙이면 원문과 정확히
    /// 같아지므로, 델타 텍스트를 여러 조각으로 나눠도 내용 손실이나 공백 뭉개짐이 없다.
    private static func wordChunks(of text: String) -> [String] {
        var result: [String] = []
        var current = ""
        for character in text {
            current.append(character)
            if character.isWhitespace {
                result.append(current)
                current = ""
            }
        }
        if !current.isEmpty {
            result.append(current)
        }
        return result
    }
}

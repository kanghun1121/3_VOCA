import SwiftUI

import DesignSystem
import DomainInterface

struct RecognitionView: View {
    let word: Lesson.Word
    let countdown: Int
    let ringProgress: Double
    let isRevealing: Bool
    let onRemembered: () -> Void
    let onForgot: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            RecognitionCenterContent(
                word: word,
                countdown: countdown,
                ringProgress: ringProgress,
                isRevealing: isRevealing
            )

            Spacer()

            RecognitionFooter(
                isRevealing: isRevealing,
                onRemembered: onRemembered,
                onForgot: onForgot
            )
        }
    }
}

// MARK: - 중앙 콘텐츠
// CountdownRingView에 opacity를 적용하여 공개 상태에서도 동일한 공간을 유지,
// 두 상태 간 단어(WordBlock)의 수직 위치를 일정하게 고정한다.

private struct RecognitionCenterContent: View {
    let word: Lesson.Word
    let countdown: Int
    let ringProgress: Double
    let isRevealing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            CountdownRingView(countdown: countdown, progress: ringProgress)
                .padding(.bottom, 40)
                .opacity(isRevealing ? 0 : 1)

            // word.id가 바뀔 때 구 단어는 페이드아웃, 새 단어는 페이드인
            // isRevealing 애니메이션 컨텍스트 안에서 실행되므로 타이밍 하드코딩 불필요
            RecognitionWordBlock(word: word)
                .transition(.opacity)
                .id(word.id)

            Text(word.primaryMeaning)
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 18))
                .foregroundStyle(DesignSystemAsset.white.swiftUIColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(DesignSystemAsset.white.swiftUIColor.opacity(0.12))
                .clipShape(.rect(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(DesignSystemAsset.white.swiftUIColor.opacity(0.28), lineWidth: 1)
                }
                .padding(.top, 24)
                .opacity(isRevealing ? 1 : 0)
                .scaleEffect(isRevealing || reduceMotion ? 1 : 0.95)
                .transition(.opacity)
                .id(word.id)
        }
    }
}

// MARK: - 공통 컴포넌트

private struct RecognitionWordBlock: View {
    let word: Lesson.Word

    var body: some View {
        VStack(spacing: 0) {
            Text(word.term)
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 52))
                .tracking(-0.03 * 52)
                .foregroundStyle(DesignSystemAsset.white.swiftUIColor)

            Text(word.pronunciation)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(DesignSystemAsset.white.swiftUIColor.opacity(0.65))
                .padding(.top, 12)
        }
    }
}

// MARK: - 하단 버튼

private struct RecognitionFooter: View {
    let isRevealing: Bool
    let onRemembered: () -> Void
    let onForgot: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("3초 안에 뜻이 떠올랐나요?")
                .font(DesignSystemFontFamily.Pretendard.regular.swiftUIFont(size: 14))
                .foregroundStyle(DesignSystemAsset.white.swiftUIColor.opacity(0.70))

            RecognitionJudgmentButtons(
                isRevealing: isRevealing,
                onRemembered: onRemembered,
                onForgot: onForgot
            )
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 40)
        .opacity(isRevealing ? 0 : 1)
    }
}

private struct RecognitionJudgmentButtons: View {
    let isRevealing: Bool
    let onRemembered: () -> Void
    let onForgot: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onForgot) {
                Text("기억 안 나요")
                    .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 16))
                    .foregroundStyle(DesignSystemAsset.white.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(DesignSystemAsset.white.swiftUIColor.opacity(0.08))
                    .clipShape(.rect(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(DesignSystemAsset.white.swiftUIColor.opacity(0.28), lineWidth: 1)
                    }
            }
            .disabled(isRevealing)

            Button(action: onRemembered) {
                Text("떠올랐어요")
                    .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 16))
                    .foregroundStyle(DesignSystemAsset.game.swiftUIColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(DesignSystemAsset.white.swiftUIColor)
                    .clipShape(.rect(cornerRadius: 18))
            }
            .disabled(isRevealing)
        }
    }
}

import SwiftUI

import DesignSystem

struct ChoiceButton: View {
    let text: String
    let state: ChoiceButtonState
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 18))
                .tracking(-0.01 * 18)
                .foregroundStyle(DesignSystemAsset.white.swiftUIColor)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 64,
                    alignment: .leading
                )
                .padding(.horizontal, 22)
        }
        .background(backgroundColor)
        .clipShape(.rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(borderColor, lineWidth: borderWidth)
        }
        .overlay(alignment: .trailing) {
            if differentiateWithoutColor {
                if state == .correct {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DesignSystemAsset.positive.swiftUIColor)
                        .accessibilityHidden(true)
                        .padding(.trailing, 16)
                } else if state == .incorrect {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(DesignSystemAsset.cautionary.swiftUIColor)
                        .accessibilityHidden(true)
                        .padding(.trailing, 16)
                }
            }
        }
        .disabled(state != .idle)
        .animation(reduceMotion ? .none : .easeInOut(duration: 0.2), value: state)
        .accessibilityLabel(accessibilityLabel)
    }

    private var backgroundColor: Color {
        switch state {
        case .idle:      DesignSystemAsset.white.swiftUIColor.opacity(0.05)
        case .correct:   DesignSystemAsset.positive.swiftUIColor.opacity(0.15)
        case .incorrect: DesignSystemAsset.cautionary.swiftUIColor.opacity(0.15)
        }
    }

    private var borderColor: Color {
        switch state {
        case .idle:      DesignSystemAsset.white.swiftUIColor.opacity(0.22)
        case .correct:   DesignSystemAsset.positive.swiftUIColor
        case .incorrect: DesignSystemAsset.cautionary.swiftUIColor
        }
    }

    private var borderWidth: Double {
        switch state {
        case .idle:                1
        case .correct, .incorrect: 2
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .idle:      text
        case .correct:   "\(text), 정답"
        case .incorrect: "\(text), 오답"
        }
    }
}

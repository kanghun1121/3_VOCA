import SwiftUI

import DesignSystem

#Preview {
    NavigationStack {
        WordListSkeletonView()
    }
}

struct WordListSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SkeletonHeaderView()
                    .padding(.bottom, 22)
                SkeletonWordList()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .redacted(reason: .placeholder)
        }
        .scrollIndicators(.hidden)
        .background(DesignSystemAsset.background.swiftUIColor)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("단어 목록 불러오는 중")
    }
}

// MARK: - Header

private struct SkeletonHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("15개 단어")
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 28))
                .kerning(-0.025 * 28)
            Text("Level 1 · Lesson 2")
                .font(DesignSystemFontFamily.Pretendard.regular.swiftUIFont(size: 14))
                .padding(.top, 4)
        }
    }
}

// MARK: - Word List

private struct SkeletonWordList: View {
    private let enPool = ["abandon", "beautiful", "calculator"]
    private let koPool = ["버리다, 포기하다", "아름다운, 매력적인", "계산기, 계산하다", "의사소통, 전달하다"]

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(0..<8, id: \.self) { i in
                SkeletonWordRow(en: enPool[i % enPool.count], ko: koPool[i % koPool.count])
            }
        }
    }
}

// MARK: - Word Row

private struct SkeletonWordRow: View {
    let en: String
    let ko: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            SkeletonWordTextStack(en: en, ko: ko)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16))
        }
        .padding(16)
        .background(DesignSystemAsset.background.swiftUIColor)
        .clipShape(.rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(DesignSystemAsset.border.swiftUIColor, lineWidth: 1)
        }
    }
}

private struct SkeletonWordTextStack: View {
    let en: String
    let ko: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            SkeletonWordNameRow(en: en)
            Text(ko)
                .font(DesignSystemFontFamily.Pretendard.regular.swiftUIFont(size: 13))
        }
    }
}

private struct SkeletonWordNameRow: View {
    let en: String

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text(en)
                .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 18))
                .kerning(-0.012 * 18)
            Text("/ˈpɹɒm.ɪs/")
                .font(.system(size: 12, design: .monospaced))
        }
    }
}

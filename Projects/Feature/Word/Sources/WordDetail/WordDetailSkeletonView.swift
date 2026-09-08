import SwiftUI

import DesignSystem

#Preview {
    WordDetailSkeletonView()
}

struct WordDetailSkeletonView: View {
    var body: some View {
        ScrollView {
            WordDetailSkeletonContentView()
        }
        .scrollIndicators(.hidden)
        .background(DesignSystemAsset.background.swiftUIColor)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("단어 정보 불러오는 중")
    }
}

struct WordDetailSkeletonContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonHeaderView()
                .padding(.bottom, 22)
            SkeletonDefinitionsView()
                .padding(.bottom, 28)
            SkeletonExamplesView()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 32)
        .redacted(reason: .placeholder)
    }
}

// MARK: - Header

private struct SkeletonHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("promise")
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 40))
                .kerning(-0.025 * 40)
            SkeletonPronunciationRow()
                .padding(.top, 8)
        }
    }
}

private struct SkeletonPronunciationRow: View {
    var body: some View {
        HStack(spacing: 10) {
            Text("/ˈprɒm.ɪs/")
                .font(.system(size: 14, design: .monospaced))
            Circle()
                .frame(width: 32, height: 32)
        }
    }
}

// MARK: - Definitions

private struct SkeletonDefinitionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(0..<2, id: \.self) { _ in
                SkeletonDefinitionGroupView()
            }
        }
    }
}

private struct SkeletonDefinitionGroupView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("동사")
                .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 12))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(DesignSystemAsset.study100.swiftUIColor)
                .clipShape(.rect(cornerRadius: 6))
            SkeletonMeaningList()
        }
    }
}

private struct SkeletonMeaningList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(0..<2, id: \.self) { _ in
                SkeletonMeaningRow()
            }
        }
    }
}

private struct SkeletonMeaningRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .frame(width: 4, height: 4)
                .padding(.top, 11)
            Text("약속하다, 다짐하다")
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 17))
                .lineSpacing(26 - 17)
                .kerning(-0.012 * 17)
        }
    }
}

// MARK: - Examples

private struct SkeletonExamplesView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .background(DesignSystemAsset.borderSubtle.swiftUIColor)
                .padding(.bottom, 22)
            SkeletonExamplesSection()
        }
    }
}

private struct SkeletonExamplesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("예문")
                .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 13))
            SkeletonExampleList()
        }
    }
}

private struct SkeletonExampleList: View {
    var body: some View {
        VStack(spacing: 10) {
            ForEach(0..<2, id: \.self) { _ in
                SkeletonExampleRow()
            }
        }
    }
}

private struct SkeletonExampleRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("I promise I will call you tomorrow.")
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 16))
            Text("나는 내일 너에게 전화할 것을 약속해.")
                .font(DesignSystemFontFamily.Pretendard.regular.swiftUIFont(size: 13))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystemAsset.study100.swiftUIColor.opacity(0.5))
        .clipShape(.rect(cornerRadius: 14))
    }
}

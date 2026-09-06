import SwiftUI

import DesignSystem
import DomainInterface

struct WordDetailDefinitionsView: View {
    let groups: [WordDetail.DefinitionGroup]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(groups) { group in
                WordDetailDefinitionGroupView(group: group)
            }
        }
    }
}

private struct WordDetailDefinitionGroupView: View {
    let group: WordDetail.DefinitionGroup

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            PartOfSpeechChip(label: group.partOfSpeech)
            MeaningList(meanings: group.meanings)
        }
    }
}

private struct MeaningList: View {
    let meanings: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(meanings, id: \.self) { MeaningRow(meaning: $0) }
        }
    }
}

private struct MeaningRow: View {
    let meaning: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(DesignSystemAsset.study300.swiftUIColor)
                .frame(width: 4, height: 4)
                .padding(.top, 11)
            Text(meaning)
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 17))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
                .lineSpacing(26 - 17)
                .kerning(-0.012 * 17)
        }
    }
}

private struct PartOfSpeechChip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(DesignSystemFontFamily.Pretendard.extraBold.swiftUIFont(size: 12))
            .foregroundStyle(DesignSystemAsset.study300.swiftUIColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(DesignSystemAsset.study100.swiftUIColor)
            .clipShape(.rect(cornerRadius: 6))
    }
}

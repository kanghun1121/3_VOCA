import SwiftUI

import DesignSystem
import DomainInterface

struct RecordCard: View {
    let record: Session.Record?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("학습 기록")
                .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 14))
                .foregroundStyle(DesignSystemAsset.fgMuted.swiftUIColor)

            RecordCellsRow(record: record)
        }
        .padding()
        .background(DesignSystemAsset.bgMuted.swiftUIColor)
        .clipShape(.rect(cornerRadius: 12))
    }
}

private struct RecordCellsRow: View {
    let record: Session.Record?

    var body: some View {
        HStack(spacing: 0) {
            RecordCell(label: "처음 완료", value: record?.firstCompletedAt ?? "-")
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 36)

            RecordCell(label: "학습 횟수", value: record.map { "\($0.studyCount)회" } ?? "-")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
        }
    }
}

private struct RecordCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(DesignSystemFontFamily.Pretendard.semiBold.swiftUIFont(size: 12))
                .foregroundStyle(DesignSystemAsset.fgMuted.swiftUIColor)
            Text(value)
                .font(DesignSystemFontFamily.Pretendard.bold.swiftUIFont(size: 16))
                .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
        }
    }
}

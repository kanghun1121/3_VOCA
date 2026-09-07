import SwiftUI

import DesignSystem

struct HomeContentView: View {
    let viewModel: HomeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HomeTopBar(onTapped: viewModel.didTapCTA)
                MonthlyCalendarCard(viewModel: viewModel)
                    .padding(.top, 18)
                divider
                SelectedDateContextRow(
                    date: viewModel.selectedDate,
                    isToday: viewModel.isSelectedDateToday,
                    recordCount: viewModel.selectedDayRecords.count
                )
                DayStateContent(viewModel: viewModel)
            }
            .padding(.bottom, 40)
        }
        .background(DesignSystemAsset.background.swiftUIColor)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var divider: some View {
        Rectangle()
            .fill(DesignSystemAsset.line.swiftUIColor)
            .frame(height: 1)
            .padding(.horizontal, 24)
            .padding(.top, 34)
    }

    private struct DayStateContent: View {
        let viewModel: HomeViewModel

        var body: some View {
            if viewModel.isSelectedDateToday {
                VStack(spacing: 8) {
                    StudyCTACard(onTapped: viewModel.didTapCTA)
                        .padding(.horizontal, 24)
                    RecordList(records: viewModel.selectedDayRecords, viewModel: viewModel)
                }
                .padding(.top, 16)
            } else if viewModel.selectedDayRecords.isEmpty {
                EmptyDayView(isFuture: viewModel.isSelectedDateFuture, onGoToToday: viewModel.selectToday)
            } else {
                RecordList(records: viewModel.selectedDayRecords, viewModel: viewModel)
                    .padding(.top, 8)
            }
        }
    }

    private struct RecordList: View {
        let records: [DayRecord]
        let viewModel: HomeViewModel

        var body: some View {
            LazyVStack(spacing: 0) {
                ForEach(records) { record in
                    RecordRow(record: record) {
                        viewModel.didTapLesson(id: record.lessonID)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeContentView(viewModel: HomeViewModel())
}

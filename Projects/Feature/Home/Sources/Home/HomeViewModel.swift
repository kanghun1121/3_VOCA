import Foundation

import DomainInterface
import FeatureLesson

import Dependencies
import SwiftUINavigation

@Observable
@MainActor
public final class HomeViewModel {
    @CasePathable
    public enum Destination {
        case lesson(LessonDetailViewModel)
        case levelLibrary(LevelLibraryViewModel)
    }

    var destination: Destination?

    let today: Date
    private(set) var dayRecordsByDate: [Date: [DayRecord]] = [:]
    private(set) var selectedDate: Date
    @ObservationIgnored private(set) var observationTask: Task<Void, Never>?

    var isSelectedDateToday: Bool { cal.isDate(selectedDate, inSameDayAs: today) }
    var isSelectedDateFuture: Bool { cal.startOfDay(for: selectedDate) > today }
    var selectedDayRecords: [DayRecord] { dayRecordsByDate[cal.startOfDay(for: selectedDate)] ?? [] }
    private var cal: Calendar { .current }
    
    @ObservationIgnored @Dependency(\.learningHistoryRepository) private var learningHistoryRepository

    public init(
        destination: Destination? = nil,
        today: Date = Calendar.current.startOfDay(for: .now)
    ) {
        self.destination = destination
        self.today = today
        self.selectedDate = today
    }

    public func onAppear() async {
        guard observationTask == nil else { return }

        observationTask = Task {
            for await records in learningHistoryRepository.streamAllCompletions() {
                self.apply(records)
            }
        }
    }
    
    public func didTapLesson(id: String) {
        destination = .lesson(LessonDetailViewModel(lessonID: id))
    }

    func didTapDate(_ date: Date) {
        selectedDate = date
    }

    func selectToday() {
        selectedDate = today
    }

    func didTapCTA() {
        destination = .levelLibrary(LevelLibraryViewModel())
    }
    
    private func apply(_ records: [LessonCompletionRecord]) {
        dayRecordsByDate = records.dayRecords(calendar: cal)
    }

    deinit {
        observationTask?.cancel()
    }
}

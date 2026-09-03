import Foundation

import DomainInterface
import FeatureSession

import Dependencies
import SwiftUINavigation

@Observable
@MainActor
public final class HomeViewModel {
    enum HomeUIState: Equatable {
        case loading
        case success(VocabularyLibrary)
        case error(String)
        case empty
    }
    
    @CasePathable
    public enum Destination {
        case session(SessionDetailViewModel)
        case levelLibrary(LevelLibraryViewModel)
    }
    
    var destination: Destination?
    
    let today: Date
    private(set) var uiState: HomeUIState = .loading
    private(set) var dayRecordsByDate: [Date: [DayRecord]] = [:]
    private(set) var selectedDate: Date
    private(set) var observationTask: Task<Void, Never>?

    var isSelectedDateToday: Bool { cal.isDate(selectedDate, inSameDayAs: today) }
    var isSelectedDateFuture: Bool { cal.startOfDay(for: selectedDate) > today }
    var selectedDayRecords: [DayRecord] { dayRecordsByDate[cal.startOfDay(for: selectedDate)] ?? [] }
    private var cal: Calendar { .current }
    
    @ObservationIgnored @Dependency(\.vocabularyLibraryRepository) private var vocabularyLibraryRepository

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
            for await library in vocabularyLibraryRepository.stream() {
                self.apply(library)
            }
        }
    }
    
    public func didTapSession(id: String) {
        destination = .session(SessionDetailViewModel(sessionID: id))
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
    
    private func apply(_ library: VocabularyLibrary) {
        dayRecordsByDate = library.dayRecords(calendar: cal)
        uiState = library.levels.isEmpty ? .empty : .success(library)
    }

    deinit {
        observationTask?.cancel()
    }
}

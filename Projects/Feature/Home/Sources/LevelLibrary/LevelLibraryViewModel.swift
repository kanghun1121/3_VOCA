import Foundation

import DomainInterface
import FeatureSession

import Dependencies
import SwiftUINavigation

@Observable
@MainActor
public final class LevelLibraryViewModel {
    enum LevelLibraryUIState: Equatable {
        case loading
        case success(VocabularyLibrary)
        case error(String)
    }

    private(set) var uiState: LevelLibraryUIState = .loading
    private(set) var expandedLevelIDs: Set<String> = []
    var destination: Destination?
    private(set) var observationTask: Task<Void, Never>?

    @ObservationIgnored @Dependency(\.vocabularyLibraryRepository) private var vocabularyLibraryRepository

    @CasePathable
    public enum Destination {
        case session(SessionDetailViewModel)
    }

    public init() {}

    public func onAppear() async {
        guard observationTask == nil else { return }

        observationTask = Task {
            for await library in vocabularyLibraryRepository.stream() {
                self.apply(library)
            }
        }
    }

    private func apply(_ library: VocabularyLibrary) {
        if expandedLevelIDs.isEmpty, let activeID = library.levels.first(where: { $0.status == .active })?.id {
            expandedLevelIDs.insert(activeID)
        }
        uiState = .success(library)
    }

    func didTapLevel(id: String) {
        if expandedLevelIDs.contains(id) {
            expandedLevelIDs.remove(id)
        } else {
            expandedLevelIDs.insert(id)
        }
    }

    func didTapSession(id: String) {
        destination = .session(SessionDetailViewModel(sessionID: id))
    }

    deinit {
        observationTask?.cancel()
    }
}

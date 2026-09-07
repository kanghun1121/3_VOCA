import Foundation
import SwiftData

import Dependencies

struct LearningHistoryLocalDataSource: Sendable {
    @Dependency(\.localDatabaseContext) private var context

    func allCompletions() async throws -> [LearningHistoryEntity] {
        try await context.fetch(FetchDescriptor<LearningHistoryEntity>())
    }

    func completion(lessonID: Int) async throws -> LearningHistoryEntity? {
        try await context.fetch(FetchDescriptor<LearningHistoryEntity>(
            predicate: #Predicate { $0.lessonID == lessonID }
        )).first
    }

    /// 이미 완료 기록이 있으면 studyCount 증가 + lastStudiedAt 갱신(firstCompletedAt은 보존),
    /// 없으면 새로 생성한다. fetch→분기→save를 하나의 액터 격리 안에서 수행해 원자성을 보장한다.
    func recordCompletion(lessonID: Int, at date: Date) async throws {
        try await context.withContext { modelContext in
            let existing = try modelContext.fetch(FetchDescriptor<LearningHistoryEntity>(
                predicate: #Predicate { $0.lessonID == lessonID }
            )).first
            if let existing {
                existing.lastStudiedAt = date
                existing.studyCount += 1
            } else {
                modelContext.insert(LearningHistoryEntity(lessonID: lessonID, firstCompletedAt: date, lastStudiedAt: date, studyCount: 1))
            }
            try modelContext.save()
        }
    }
}

extension LearningHistoryLocalDataSource: DependencyKey {
    static let liveValue = LearningHistoryLocalDataSource()
}

extension LearningHistoryLocalDataSource: TestDependencyKey {
    static let testValue = LearningHistoryLocalDataSource()
}

extension DependencyValues {
    var learningHistoryLocalDataSource: LearningHistoryLocalDataSource {
        get { self[LearningHistoryLocalDataSource.self] }
        set { self[LearningHistoryLocalDataSource.self] = newValue }
    }
}

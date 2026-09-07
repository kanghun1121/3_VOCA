import Foundation

import DomainInterface

import Dependencies

let firstCompletedAtFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy.MM.dd"
    formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
    return formatter
}()

extension LearningHistoryRepository: DependencyKey {
    public static let liveValue: LearningHistoryRepository = {
        @Dependency(\.learningHistoryLocalDataSource) var historyDataSource
        @Dependency(\.lessonLocalDataSource) var lessonDataSource
        @Dependency(\.levelLocalDataSource) var levelDataSource
        @Dependency(\.learningHistoryStore) var historyStore
        @Dependency(\.learningHistoryFeedStore) var feedStore

        return LearningHistoryRepository(
            stream: { lessonID in
                AsyncStream { continuation in
                    Task {
                        let subscriberID = UUID()
                        await historyStore.register(id: lessonID, subscriberID: subscriberID, continuation: continuation)

                        guard let intID = Int(lessonID),
                              let entity = try? await historyDataSource.completion(lessonID: intID) else { return }

                        await historyStore.set(id: lessonID, LearningHistory(
                            firstCompletedAt: firstCompletedAtFormatter.string(from: entity.firstCompletedAt),
                            studyCount: entity.studyCount
                        ))
                    }
                }
            },
            streamAllCompletions: {
                AsyncStream { continuation in
                    Task {
                        let id = UUID()
                        await feedStore.register(id: id, continuation: continuation)

                        guard let completions = try? await historyDataSource.allCompletions() else { return }
                        var records: [LessonCompletionRecord] = []
                        for entity in completions {
                            guard let lessonEntity = try? await lessonDataSource.lesson(id: entity.lessonID),
                                  let levelEntity = try? await levelDataSource.level(id: lessonEntity.levelID) else { continue }
                            records.append(LessonCompletionRecord(
                                lessonID: String(entity.lessonID),
                                levelName: levelEntity.nameKo,
                                lessonNumber: lessonEntity.lessonNumber,
                                totalWords: lessonEntity.wordCount,
                                lastStudiedAt: entity.lastStudiedAt
                            ))
                        }

                        await feedStore.set(records)
                    }
                }
            },
            complete: { lessonID in
                try await historyDataSource.recordCompletion(lessonID: lessonID, at: Date())

                // TODO: 아래 2개는 함수로 분리.
                // Home 캘린더 구독자에게 갱신된 전체 목록을 push한다.
                if let completions = try? await historyDataSource.allCompletions() {
                    var records: [LessonCompletionRecord] = []
                    for entity in completions {
                        guard let lessonEntity = try? await lessonDataSource.lesson(id: entity.lessonID),
                              let levelEntity = try? await levelDataSource.level(id: lessonEntity.levelID) else { continue }
                        records.append(LessonCompletionRecord(
                            lessonID: String(entity.lessonID),
                            levelName: levelEntity.nameKo,
                            lessonNumber: lessonEntity.lessonNumber,
                            totalWords: lessonEntity.wordCount,
                            lastStudiedAt: entity.lastStudiedAt
                        ))
                    }
                    await feedStore.set(records)
                }

                // 레슨 상세 뱃지 구독자에게도 갱신된 값을 push한다.
                if let entity = try? await historyDataSource.completion(lessonID: lessonID) {
                    await historyStore.set(id: String(lessonID), LearningHistory(
                        firstCompletedAt: firstCompletedAtFormatter.string(from: entity.firstCompletedAt),
                        studyCount: entity.studyCount
                    ))
                }
            }
        )
    }()
}

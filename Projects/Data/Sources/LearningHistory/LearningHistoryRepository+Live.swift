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

        @Sendable
        func pushCompletionsUpdate() async {
            guard let completions = try? await historyDataSource.allCompletions() else { return }
            var records: [LessonCompletionRecord] = []
            for entity in completions {
                guard let lessonEntity = try? await lessonDataSource.lesson(id: entity.lessonID),
                      let levelEntity = try? await levelDataSource.level(id: lessonEntity.levelID) else { continue }
                records.append(LessonCompletionRecord(
                    lessonID: String(entity.lessonID),
                    levelName: levelEntity.nameKo,
                    lessonNumber: lessonEntity.lessonNumber,
                    totalWords: lessonEntity.orderedWordIDs.count,
                    lastStudiedAt: entity.lastStudiedAt
                ))
            }
            await feedStore.set(records)
        }

        @Sendable
        func pushHistoryUpdate(lessonID: Int) async {
            guard let entity = try? await historyDataSource.completion(lessonID: lessonID) else { return }
            await historyStore.set(id: String(lessonID), LearningHistory(
                firstCompletedAt: firstCompletedAtFormatter.string(from: entity.firstCompletedAt),
                studyCount: entity.studyCount
            ))
        }

        return LearningHistoryRepository(
            stream: { lessonID in
                AsyncStream { continuation in
                    Task {
                        let subscriberID = UUID()
                        await historyStore.register(id: lessonID, subscriberID: subscriberID, continuation: continuation)

                        guard let intID = Int(lessonID) else { return }
                        await pushHistoryUpdate(lessonID: intID)
                    }
                }
            },
            streamAllCompletions: {
                AsyncStream { continuation in
                    Task {
                        let id = UUID()
                        await feedStore.register(id: id, continuation: continuation)
                        await pushCompletionsUpdate()
                    }
                }
            },
            complete: { lessonID in
                try await historyDataSource.recordCompletion(lessonID: lessonID, at: Date())
                await pushCompletionsUpdate()
                await pushHistoryUpdate(lessonID: lessonID)
            }
        )
    }()
}

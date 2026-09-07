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

        // 로컬 완료 기록 전체를 레슨/레벨 정적 데이터와 조인해 Home 캘린더 구독자(feedStore)에게
        // 갱신된 전체 목록을 push한다. streamAllCompletions(최초 스냅샷)와 complete(완료 직후 갱신)
        // 둘 다에서 쓰인다.
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
                    totalWords: lessonEntity.wordCount,
                    lastStudiedAt: entity.lastStudiedAt
                ))
            }
            await feedStore.set(records)
        }

        // 레슨 하나의 완료 이력을 다시 조회해 그 레슨 상세 뱃지 구독자(historyStore)에게
        // 갱신된 값을 push한다. stream(최초 스냅샷)과 complete(완료 직후 갱신) 둘 다에서 쓰인다.
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

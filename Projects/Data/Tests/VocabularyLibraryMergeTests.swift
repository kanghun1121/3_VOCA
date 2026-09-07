import XCTest

import DomainInterface
@testable import Data

final class VocabularyLibraryMergeTests: XCTestCase {
    func test_정상_병합하면_로컬_스켈레톤에_원격_진행상태가_덧입혀진다() {
        let local = [makeLocalLevel(level: 1, name: "씨앗", lessonNumbers: [1, 2])]
        let remote = VocabularyLibrary(levels: [
            makeRemoteLevel(level: 1, completedLessons: 1, lessons: [
                makeRemoteLesson(lessonNumber: 1, status: .completed, accuracy: 0.9, wordsCompleted: 20),
                makeRemoteLesson(lessonNumber: 2, status: .notStarted, accuracy: nil, wordsCompleted: 0),
            ]),
        ])

        let merged = VocabularyLibraryMerge.mergeProgress(local: local, remote: remote)

        XCTAssertEqual(merged.levels.count, 1)
        let level = merged.levels[0]
        XCTAssertEqual(level.name, "씨앗") // 로컬 스켈레톤의 정적 필드 유지
        XCTAssertEqual(level.completedLessons, 1) // 원격 진행상태로 갱신
        XCTAssertEqual(level.lessons[0].status, .completed)
        XCTAssertEqual(level.lessons[0].accuracy, 0.9)
        XCTAssertEqual(level.lessons[1].status, .notStarted)
    }

    func test_원격에_없는_레벨은_로컬_기본값_그대로_유지된다() {
        let local = [makeLocalLevel(level: 99, name: "미지의 레벨", lessonNumbers: [1])]
        let remote = VocabularyLibrary(levels: [
            makeRemoteLevel(level: 1, completedLessons: 5, lessons: []),
        ])

        let merged = VocabularyLibraryMerge.mergeProgress(local: local, remote: remote)

        XCTAssertEqual(merged.levels[0].completedLessons, 0)
        XCTAssertEqual(merged.levels[0].lessons[0].status, .notStarted)
    }

    func test_원격에_없는_레슨번호는_로컬_기본값_그대로_유지된다() {
        let local = [makeLocalLevel(level: 1, name: "씨앗", lessonNumbers: [1, 2])]
        let remote = VocabularyLibrary(levels: [
            makeRemoteLevel(level: 1, completedLessons: 1, lessons: [
                makeRemoteLesson(lessonNumber: 1, status: .completed, accuracy: 0.9, wordsCompleted: 20),
                // lessonNumber 2는 원격 응답에 없음(예: 신규 레슨이 로컬 시드에만 있는 경우).
            ]),
        ])

        let merged = VocabularyLibraryMerge.mergeProgress(local: local, remote: remote)

        XCTAssertEqual(merged.levels[0].lessons[0].status, .completed)
        XCTAssertEqual(merged.levels[0].lessons[1].status, .notStarted)
        XCTAssertEqual(merged.levels[0].lessons[1].wordsCompleted, 0)
    }

    func test_로컬이_비어있으면_결과도_비어있다() {
        let remote = VocabularyLibrary(levels: [makeRemoteLevel(level: 1, completedLessons: 1, lessons: [])])

        let merged = VocabularyLibraryMerge.mergeProgress(local: [], remote: remote)

        XCTAssertTrue(merged.levels.isEmpty)
    }

    func test_원격에_같은_레슨번호가_중복이면_마지막_값으로_수렴하고_크래시하지_않는다() {
        let local = [makeLocalLevel(level: 1, name: "씨앗", lessonNumbers: [1])]
        let remote = VocabularyLibrary(levels: [
            makeRemoteLevel(level: 1, completedLessons: 1, lessons: [
                makeRemoteLesson(lessonNumber: 1, status: .notStarted, accuracy: nil, wordsCompleted: 0),
                makeRemoteLesson(lessonNumber: 1, status: .completed, accuracy: 1.0, wordsCompleted: 20),
            ]),
        ])

        let merged = VocabularyLibraryMerge.mergeProgress(local: local, remote: remote)

        XCTAssertEqual(merged.levels[0].lessons[0].status, .completed)
    }

    // 로컬 스켈레톤의 id는 항상 로컬 값이 우선한다 — 원격 id 체계와 무관해야 한다는 것을 확인한다.
    func test_id는_원격이_아닌_로컬_값을_그대로_유지한다() {
        let local = [makeLocalLevel(level: 1, name: "씨앗", lessonNumbers: [1], idPrefix: "local")]
        let remote = VocabularyLibrary(levels: [
            makeRemoteLevel(level: 1, completedLessons: 1, lessons: [
                makeRemoteLesson(lessonNumber: 1, status: .completed, accuracy: 1.0, wordsCompleted: 20, id: "remote-999"),
            ], id: "remote-level-999"),
        ])

        let merged = VocabularyLibraryMerge.mergeProgress(local: local, remote: remote)

        XCTAssertEqual(merged.levels[0].id, "local-level-1")
        XCTAssertEqual(merged.levels[0].lessons[0].id, "local-lesson-1")
    }
}

private func makeLocalLevel(
    level: Int,
    name: String,
    lessonNumbers: [Int],
    idPrefix: String = "local"
) -> LevelSummary {
    LevelSummary(
        id: "\(idPrefix)-level-\(level)",
        level: level,
        name: name,
        difficulty: "A1",
        totalLessons: lessonNumbers.count,
        completedLessons: 0,
        lessons: lessonNumbers.map { number in
            LessonProgress(
                id: "\(idPrefix)-lesson-\(number)",
                lessonNumber: number,
                totalWords: 20,
                status: .notStarted,
                lastStudiedAt: nil,
                accuracy: nil,
                wordsCompleted: 0
            )
        }
    )
}

private func makeRemoteLevel(
    level: Int,
    completedLessons: Int,
    lessons: [LessonProgress],
    id: String = "remote"
) -> LevelSummary {
    LevelSummary(
        id: id,
        level: level,
        name: "remote-name",
        difficulty: "remote-difficulty",
        totalLessons: lessons.count,
        completedLessons: completedLessons,
        lessons: lessons
    )
}

private func makeRemoteLesson(
    lessonNumber: Int,
    status: LessonProgressStatus,
    accuracy: Double?,
    wordsCompleted: Int,
    id: String = "remote"
) -> LessonProgress {
    LessonProgress(
        id: id,
        lessonNumber: lessonNumber,
        totalWords: 20,
        status: status,
        lastStudiedAt: nil,
        accuracy: accuracy,
        wordsCompleted: wordsCompleted
    )
}

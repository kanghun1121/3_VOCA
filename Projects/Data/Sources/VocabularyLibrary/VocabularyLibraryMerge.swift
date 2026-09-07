import DomainInterface

enum VocabularyLibraryMerge {
    /// 로컬 정적 스켈레톤(레벨/레슨 구조, 진행 상태는 전부 0/시작 전)에 원격 진행 상태를
    /// 덧입힌다.
    ///
    /// 매칭 키로 원본 DB row id 대신 "레벨 번호"와 "레벨 내 레슨 번호"를 쓴다 — 로컬 시드와
    /// 원격 RPC가 같은 테이블에서 뽑혀 나왔더라도 서로 다른 id 체계(예: 로컬은 원본 PK,
    /// 원격은 별도 세션 테이블 PK)를 쓸 가능성을 배제할 수 없어, 사람이 보는 업무 키로
    /// 맞추는 편이 안전하다. 반환되는 `id`는 항상 로컬(자체 소유) 값을 쓴다.
    static func mergeProgress(local: [LevelSummary], remote: VocabularyLibrary) -> VocabularyLibrary {
        let remoteLevelsByLevel = remote.levels.reduce(into: [Int: LevelSummary]()) { result, level in
            result[level.level] = level
        }

        let mergedLevels = local.map { level -> LevelSummary in
            guard let remoteLevel = remoteLevelsByLevel[level.level] else { return level }

            let remoteLessonsByNumber = remoteLevel.lessons.reduce(into: [Int: LessonProgress]()) { result, lesson in
                result[lesson.lessonNumber] = lesson
            }

            let mergedLessons = level.lessons.map { lesson -> LessonProgress in
                guard let remoteLesson = remoteLessonsByNumber[lesson.lessonNumber] else { return lesson }
                return LessonProgress(
                    id: lesson.id,
                    lessonNumber: lesson.lessonNumber,
                    totalWords: lesson.totalWords,
                    status: remoteLesson.status,
                    lastStudiedAt: remoteLesson.lastStudiedAt,
                    accuracy: remoteLesson.accuracy,
                    wordsCompleted: remoteLesson.wordsCompleted
                )
            }

            return LevelSummary(
                id: level.id,
                level: level.level,
                name: level.name,
                difficulty: level.difficulty,
                totalLessons: level.totalLessons,
                completedLessons: remoteLevel.completedLessons,
                lessons: mergedLessons
            )
        }

        return VocabularyLibrary(levels: mergedLevels)
    }
}

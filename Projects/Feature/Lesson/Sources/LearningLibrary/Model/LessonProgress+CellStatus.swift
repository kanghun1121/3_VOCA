import DomainInterface

extension [LessonProgress] {
    /// 완료된 레슨은 done, 완료되지 않은 첫 레슨은 current, 나머지는 todo로 표시.
    var cellStatuses: [LessonCellStatus] {
        var currentAssigned = false
        return map { lesson in
            if lesson.status == .completed {
                return .done
            } else if !currentAssigned {
                currentAssigned = true
                return .current
            } else {
                return .todo
            }
        }
    }
}

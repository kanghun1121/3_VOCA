import DomainInterface

extension [SessionProgress] {
    /// 완료된 세션은 done, 완료되지 않은 첫 세션은 current, 나머지는 todo로 표시.
    var cellStatuses: [SessionCellStatus] {
        var currentAssigned = false
        return map { session in
            if session.status == .completed {
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

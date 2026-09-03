enum CalendarDayCellKind {
    case empty
    case future(day: Int)
    case past(day: Int, dotCount: Int)
    case today(day: Int, dotCount: Int)
    case selected(day: Int, dotCount: Int)

    /// 캘린더 셀에 표시하는 점 인디케이터 최대 개수. 리스트(RecordRow)는 이 캡을 적용하지 않는다.
    static let maxDotCount = 3
}

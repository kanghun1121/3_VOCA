public extension Lesson.Word {
    /// definitions는 순서가 있고 첫 번째가 대표 뜻이라는 도메인 불변식을 표현한다.
    var primaryMeaning: String { definitions.first?.meaning ?? "" }
}

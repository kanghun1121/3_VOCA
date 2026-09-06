import DomainInterface

extension Lesson.Word {
    var primaryMeaning: String { definitions.first?.meaning ?? "" }
}

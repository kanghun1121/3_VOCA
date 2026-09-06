import DomainInterface

extension Session.Word {
    var primaryMeaning: String { definitions.first?.meaning ?? "" }
}

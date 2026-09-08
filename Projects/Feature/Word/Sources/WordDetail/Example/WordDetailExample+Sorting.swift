import DomainInterface

extension WordDetail.Example: Identifiable {
    public var id: Int { order }
}

extension WordDetail {
    var sortedExamples: [Example] {
        examples.sorted { $0.order < $1.order }
    }
}

struct Indexed<Element>: Identifiable {
    let id: Int
    let element: Element
}

extension Indexed: Equatable where Element: Equatable {}

extension Array {
    /// Domain 타입에 id가 없어 SwiftUI ForEach에 필요한 Identifiable을 순서 기반으로 부여한다.
    func indexed() -> [Indexed<Element>] {
        enumerated().map { Indexed(id: $0.offset, element: $0.element) }
    }
}

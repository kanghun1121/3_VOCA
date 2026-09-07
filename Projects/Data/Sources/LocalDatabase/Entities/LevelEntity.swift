import SwiftData

@Model
final class LevelEntity {
    @Attribute(.unique) var id: Int
    var nameKo: String
    var cefrLabel: String
    var sortOrder: Int

    init(id: Int, nameKo: String, cefrLabel: String, sortOrder: Int) {
        self.id = id
        self.nameKo = nameKo
        self.cefrLabel = cefrLabel
        self.sortOrder = sortOrder
    }
}

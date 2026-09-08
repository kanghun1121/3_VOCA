import DomainInterface

extension WordDetail {
    struct DefinitionGroup: Equatable, Identifiable {
        let partOfSpeech: String
        let meanings: [String]

        var id: String { partOfSpeech }
    }

    func groupedDefinitions() -> [DefinitionGroup] {
        var seen: [PartOfSpeech: Int] = [:]
        var groups: [DefinitionGroup] = []

        for definition in definitions {
            let label = definition.partOfSpeech.koreanLabel
            if let index = seen[definition.partOfSpeech] {
                let existing = groups[index]
                groups[index] = DefinitionGroup(
                    partOfSpeech: existing.partOfSpeech,
                    meanings: existing.meanings + [definition.meaning]
                )
            } else {
                seen[definition.partOfSpeech] = groups.count
                groups.append(
                    DefinitionGroup(partOfSpeech: label, meanings: [definition.meaning])
                )
            }
        }
        return groups
    }
}

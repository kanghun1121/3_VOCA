import Foundation

struct DayRecord: Identifiable, Equatable {
    let id: String
    let sessionID: String
    let time: Date
    let title: String
    let wordCount: Int
}

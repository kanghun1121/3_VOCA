import Foundation

struct DayRecord: Identifiable, Equatable {
    let id: String
    let lessonID: String
    let time: Date
    let title: String
    let wordCount: Int
}

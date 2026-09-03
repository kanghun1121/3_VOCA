import SwiftUI

struct CalendarGridSection: View {
    let rows: [[CalendarDay]]
    let onDateTapped: (Date) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                CalendarWeekRow(days: rows[rowIndex], onDateTapped: onDateTapped)
            }
        }
    }
}

import SwiftUI

import DomainInterface

struct SessionGrid: View {
    let sessions: [SessionProgress]
    let onSessionTapped: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 7), count: 6)

    var body: some View {
        let statuses = sessions.cellStatuses
        LazyVGrid(columns: columns, spacing: 7) {
            ForEach(Array(zip(sessions, statuses)), id: \.0.id) { session, status in
                Button {
                    onSessionTapped(session.id)
                } label: {
                    SessionCell(sessionNumber: session.sessionNumber, status: status)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(makeAccessibilityLabel(sessionNumber: session.sessionNumber, status: status))
            }
        }
    }

    private func makeAccessibilityLabel(sessionNumber: Int, status: SessionCellStatus) -> String {
        switch status {
        case .done: "\(sessionNumber)번 세션, 완료"
        case .current: "\(sessionNumber)번 세션, 진행 중"
        case .todo: "\(sessionNumber)번 세션, 잠김"
        }
    }
}

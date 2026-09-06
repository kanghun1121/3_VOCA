import SwiftUI

struct MultipleChoiceGameHeader: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            StageSegmentBar(currentStage: 1)
                .padding(.top, 6)
            MultipleChoiceCloseRow(onDismiss: onDismiss)
        }
    }
}

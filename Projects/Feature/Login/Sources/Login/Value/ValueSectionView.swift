import SwiftUI

struct ValueSectionView: View {
    var body: some View {
        VStack(spacing: 0) {
            HeadlineView()
            SubheadView()
                .padding(.top, 14)
            Spacer()
        }
        .multilineTextAlignment(.center)
    }
}

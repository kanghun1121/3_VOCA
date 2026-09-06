import SwiftUI

struct HeroView: View {
    var body: some View {
        GeometryReader { geometry in
            HeroContentView(width: geometry.size.width)
        }
        .frame(height: 460)
        .clipped()
    }
}

import SwiftUI

import DesignSystem
import DomainInterface

struct ChunkReaderWordRows: View {
    let wordAnnotations: [Indexed<WordDetail.Example.WordAnnotation>]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(wordAnnotations) { wordAnnotation in
                if wordAnnotation.id > 0 {
                    Divider()
                        .background(DesignSystemAsset.borderSubtle.swiftUIColor)
                }
                WordRowView(wordAnnotation: wordAnnotation)
            }
        }
    }
}

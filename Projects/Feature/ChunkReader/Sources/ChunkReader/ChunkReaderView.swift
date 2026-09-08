import SwiftUI

import DesignSystem

public struct ChunkReaderView: View {
    @Bindable private var viewModel: ChunkReaderViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: ChunkReaderViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ChunkReaderSentenceView(
                    chunks: viewModel.chunks,
                    selectedChunkID: viewModel.selectedChunkID,
                    onChunkTapped: viewModel.didTapChunk
                )

                ChunkReaderWordListView(wordAnnotations: viewModel.wordAnnotations)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .background(DesignSystemAsset.background.swiftUIColor)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(DesignSystemAsset.background.swiftUIColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("뒤로", systemImage: "chevron.left", action: dismiss.callAsFunction)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystemAsset.fgStrong.swiftUIColor)
            }
        }
    }
}

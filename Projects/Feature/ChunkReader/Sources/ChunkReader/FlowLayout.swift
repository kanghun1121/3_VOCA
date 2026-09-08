import SwiftUI

/// 하위 뷰를 줄바꿈하며 좌측 정렬로 배치하는 레이아웃 (청크 span처럼 인라인 흐름이 필요할 때 사용).
struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 4
    var verticalSpacing: CGFloat = 5

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = arrangeRows(subviews: subviews, maxWidth: maxWidth)
        let height = rows.reduce(CGFloat.zero) { partial, row in
            partial + row.height + (partial > 0 ? verticalSpacing : 0)
        }
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = arrangeRows(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    private struct RowItem {
        let subview: LayoutSubview
        let size: CGSize
    }

    private struct Row {
        let items: [RowItem]
        let width: CGFloat
        let height: CGFloat
    }

    private func arrangeRows(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var currentItems: [RowItem] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let neededWidth = currentWidth + (currentItems.isEmpty ? 0 : horizontalSpacing) + size.width

            if !currentItems.isEmpty, neededWidth > maxWidth {
                rows.append(
                    Row(
                        items: currentItems,
                        width: currentWidth,
                        height: currentHeight
                    )
                )
                currentItems = []
                currentWidth = 0
                currentHeight = 0
            }

            currentWidth += (currentItems.isEmpty ? 0 : horizontalSpacing) + size.width
            currentHeight = max(currentHeight, size.height)
            currentItems.append(RowItem(subview: subview, size: size))
        }

        if !currentItems.isEmpty {
            rows.append(
                Row(
                    items: currentItems,
                    width: currentWidth,
                    height: currentHeight
                )
            )
        }

        return rows
    }
}

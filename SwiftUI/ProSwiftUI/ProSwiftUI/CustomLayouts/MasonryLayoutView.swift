import SwiftUI

// MARK: - MasonryLayout (with Cache)
// sizeThatFits()에서 계산한 frames를 캐시에 저장하여 placeSubviews()에서 재사용
// 주의: bounds 너비 변경(회전 등)은 SwiftUI가 감지 못하므로 직접 검증 필요

private struct MasonryLayout: Layout {
    var columns: Int
    var spacing: Double

    struct Cache {
        var width = 0.0
        var frames: [CGRect]
    }

    init(columns: Int = 3, spacing: Double = 5) {
        self.columns = max(1, columns)
        self.spacing = spacing
    }

    func makeCache(subviews: Subviews) -> Cache {
        Cache(frames: [])
    }

    func frames(for subviews: Subviews, in totalWidth: Double) -> [CGRect] {
        let totalSpacing = spacing * Double(columns - 1)
        let columnWidth = (totalWidth - totalSpacing) / Double(columns)
        let columnWidthWithSpacing = columnWidth + spacing
        let proposedSize = ProposedViewSize(width: columnWidth, height: nil)

        var viewFrames = [CGRect]()
        var columnHeights = Array(repeating: 0.0, count: columns)

        for subview in subviews {
            var selectedColumn = 0
            var selectedHeight = Double.greatestFiniteMagnitude

            for (columnIndex, height) in columnHeights.enumerated() {
                if height < selectedHeight {
                    selectedColumn = columnIndex
                    selectedHeight = height
                }
            }

            let x = Double(selectedColumn) * columnWidthWithSpacing
            let y = columnHeights[selectedColumn]
            let size = subview.sizeThatFits(proposedSize)
            let frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            columnHeights[selectedColumn] += size.height + spacing
            viewFrames.append(frame)
        }

        return viewFrames
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let viewFrames = frames(for: subviews, in: width)
        let height = viewFrames.max { $0.maxY < $1.maxY } ?? .zero

        cache.frames = viewFrames
        cache.width = width

        return CGSize(width: width, height: height.maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        // bounds 너비가 캐시와 다르면 재계산 (회전 등)
        if cache.width != bounds.width {
            cache.frames = frames(for: subviews, in: bounds.width)
            cache.width = bounds.width
        }

        for index in subviews.indices {
            let frame = cache.frames[index]
            let position = CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY)
            subviews[index].place(at: position, proposal: ProposedViewSize(frame.size))
        }
    }

    static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .vertical
        return properties
    }
}

// MARK: - PlaceholderView

private struct PlaceholderView: View {
    let color: Color = [.blue, .cyan, .green, .indigo, .mint, .orange, .pink, .purple, .red].randomElement()!
    let size: CGSize

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)

            Text("\(Int(size.width))x\(Int(size.height))")
                .foregroundColor(.white)
                .font(.headline)
        }
        .aspectRatio(size, contentMode: .fill)
    }
}

// MARK: - View

struct MasonryLayoutView: View {
    @State private var columns = 3

    @State private var views = (0..<20).map { _ in
        CGSize(width: .random(in: 100...500), height: .random(in: 100...500))
    }

    var body: some View {
        ScrollView {
            MasonryLayout(columns: columns) {
                ForEach(0..<20) { i in
                    PlaceholderView(size: views[i])
                }
            }
            .padding(.horizontal, 5)
        }
        .safeAreaInset(edge: .bottom) {
            Stepper("Columns: \(columns)", value: $columns.animation(), in: 1...5)
                .padding()
                .background(.regularMaterial)
        }
        .navigationTitle("Masonry Layout (with Cache)")
    }
}

#Preview {
    NavigationStack {
        MasonryLayoutView()
    }
}

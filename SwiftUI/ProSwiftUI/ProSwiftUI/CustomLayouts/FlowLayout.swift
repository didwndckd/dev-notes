import SwiftUI

// MARK: - FlowLayout
// 컨텐츠 크기만큼 가로로 채우고, 넘치면 다음 줄로 배치하는 레이아웃
private struct FlowLayout: Layout {
    let itemSpacing: CGFloat
    let lineSpacing: CGFloat
    
    /// 각 뷰의 프레임을 한 번에 계산하는 헬퍼
    /// sizeThatFits()와 placeSubviews() 양쪽에서 재사용
    func frames(for subviews: Subviews, in totalWidth: CGFloat) -> [CGRect] {
        var frames = [CGRect]()

        var lineX = 0.0
        var lineY = 0.0
        var lineHeight = 0.0
        var maxLineWidth = 0.0

        for subview in subviews {
            let viewSize = subview.sizeThatFits(.unspecified)

            let requiredSpacing = lineX > 0 ? itemSpacing : 0
            let requiredWidth = lineX + requiredSpacing + viewSize.width

            if requiredWidth > totalWidth {
                // 가로 범위 초과 시 다음 줄로
                if lineHeight > 0 {
                    lineY += lineHeight + lineSpacing
                }
                lineX = 0
                lineHeight = 0
            } else if lineX > 0 {
                lineX += itemSpacing
            }

            let frame = CGRect(x: lineX, y: lineY, width: viewSize.width, height: viewSize.height)
            frames.append(frame)

            lineHeight = max(lineHeight, viewSize.height)
            lineX += viewSize.width
            maxLineWidth = max(maxLineWidth, lineX)
        }

        return frames
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let frames = frames(for: subviews, in: width)
        let maxX = frames.map(\.maxX).max() ?? 0
        let maxY = frames.map(\.maxY).max() ?? 0
        return CGSize(width: maxX, height: maxY)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let frames = frames(for: subviews, in: bounds.width)

        for index in frames.indices {
            let frame = frames[index]
            
            let position = CGPoint(
                x: bounds.minX + frame.midX,
                y: bounds.minY + frame.midY
            )
            subviews[index].place(
                at: position,
                anchor: .center,
                proposal: ProposedViewSize(frame.size)
            )
        }
    }
}

// MARK: - View

struct FlowLayoutView: View {
    let tags = ["SwiftUI", "Layout", "Flow", "Custom", "ViewBuilder", "Cache",
                "ProposedViewSize", "LayoutSubview", "Animation", "Transition",
                "Environment", "Preference", "GeometryReader", "ScrollView", "LazyVStack"]

    var body: some View {
        VStack(spacing: 24) {
            Text("가로 공간을 채운 뒤 넘치면 다음 줄로 배치")
                .font(.caption)
                .foregroundStyle(.secondary)

            FlowLayout(itemSpacing: 10, lineSpacing: 10) {
                Color.green.frame(width: 100, height: 50)
                Color.green.frame(width: 100, height: 50)
                Color.green.frame(width: 80, height: 50)
                
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.accentColor.opacity(0.15))
                        )
                }
            }
            .frame(width: 300)
            .border(.pink)
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Flow Layout")
    }
}

#Preview {
    NavigationStack {
        FlowLayoutView()
    }
}

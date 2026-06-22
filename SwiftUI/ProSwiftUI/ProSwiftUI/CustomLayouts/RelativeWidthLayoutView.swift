import SwiftUI

// MARK: - RelativeHStack

private struct RelativeHStack: Layout {
    var spacing = 0.0

    func frames(for subviews: Subviews, in totalWidth: Double) -> [CGRect] {
        let totalSpacing = spacing * Double(subviews.count - 1)
        let availableWidth = totalWidth - totalSpacing
        let totalPriorities = subviews.reduce(0) { $0 + $1.priority }

        var viewFrames = [CGRect]()
        var x = 0.0

        for subview in subviews {
            let subviewWidth = availableWidth * subview.priority / totalPriorities
            let proposal = ProposedViewSize(width: subviewWidth, height: nil)
            let size = subview.sizeThatFits(proposal)
            let frame = CGRect(x: x, y: 0, width: size.width, height: size.height)
            viewFrames.append(frame)
            x += size.width + spacing
        }

        return viewFrames
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let viewFrames = frames(for: subviews, in: width)
        let height = viewFrames.max { $0.maxY < $1.maxY } ?? .zero
        return CGSize(width: width, height: height.maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let viewFrames = frames(for: subviews, in: bounds.width)

        for index in subviews.indices {
            let frame = viewFrames[index]
            let position = CGPoint(x: bounds.minX + frame.minX, y: bounds.midY)
            subviews[index].place(at: position, anchor: .leading, proposal: ProposedViewSize(frame.size))
        }
    }
}

// MARK: - View

struct RelativeWidthLayoutView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("layoutPriority를 비율로 활용하여 1:2:3 비율로 너비 배분")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            RelativeHStack(spacing: 50) {
                Text("First")
                    .frame(maxWidth: .infinity)
                    .background(.red)
                    .layoutPriority(1)

                Text("Second")
                    .frame(maxWidth: .infinity)
                    .background(.green)
                    .layoutPriority(2)

                Text("Third")
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .layoutPriority(3)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Relative Width Layout")
    }
}

#Preview {
    NavigationStack {
        RelativeWidthLayoutView()
    }
}

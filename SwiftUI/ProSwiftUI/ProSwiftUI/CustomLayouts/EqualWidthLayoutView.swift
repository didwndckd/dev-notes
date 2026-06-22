import SwiftUI

// MARK: - EqualWidthHStack

private struct EqualWidthHStack: Layout {
    private func maximumSize(across subviews: Subviews) -> CGSize {
        var maximumSize = CGSize.zero

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if size.width > maximumSize.width {
                maximumSize.width = size.width
            }
            if size.height > maximumSize.height {
                maximumSize.height = size.height
            }
        }

        return maximumSize
    }

    private func spacing(for subviews: Subviews) -> [Double] {
        var spacing = [Double]()

        for index in subviews.indices {
            if index == subviews.count - 1 {
                spacing.append(0)
            } else {
                let distance = subviews[index].spacing.distance(to: subviews[index + 1].spacing, along: .horizontal)
                spacing.append(distance)
            }
        }

        return spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxSize = maximumSize(across: subviews)
        let spacing = spacing(for: subviews)
        let totalSpacing = spacing.reduce(0, +)
        return CGSize(width: maxSize.width * Double(subviews.count) + totalSpacing, height: maxSize.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let maxSize = maximumSize(across: subviews)
        let spacing = spacing(for: subviews)
        let proposal = ProposedViewSize(width: maxSize.width, height: maxSize.height)

        var x = bounds.minX + maxSize.width / 2

        for index in subviews.indices {
            subviews[index].place(
                at: CGPoint(x: x, y: bounds.midY),
                anchor: .center,
                proposal: proposal
            )
            x += maxSize.width + spacing[index]
        }
    }
}

// MARK: - View

struct EqualWidthLayoutView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("가장 큰 자식 뷰의 너비를 기준으로 모든 뷰에 동일한 공간 배분")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            EqualWidthHStack {
                Text("Short")
                    .background(.red)

                Text("This is long")
                    .background(.green)

                Text("This is longest")
                    .background(.blue)
            }
            .border(.yellow)
        }
        .navigationTitle("Equal Width Layout")
    }
}

#Preview {
    NavigationStack {
        EqualWidthLayoutView()
    }
}

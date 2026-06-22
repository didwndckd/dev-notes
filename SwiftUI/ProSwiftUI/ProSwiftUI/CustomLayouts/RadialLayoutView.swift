import SwiftUI

// MARK: - RadialLayout (with animatableData)
// rollOut 프로퍼티에 animatableData를 적용하여 원호를 따라 펼쳐지는 경로 애니메이션 구현
// animatableData 없으면 시작→끝 직선 이동, 있으면 매 중간값마다 placeSubviews() 호출

private struct RadialLayout: Layout {
    var rollOut = 0.0

    var animatableData: Double {
        get { rollOut }
        set { rollOut = newValue }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let radius = min(bounds.size.width, bounds.size.height) / 2
        let angle = Angle.degrees(360 / Double(subviews.count)).radians * rollOut

        for (index, subview) in subviews.enumerated() {
            let viewSize = subview.sizeThatFits(.unspecified)
            let xPos = cos(angle * Double(index) - .pi / 2) * (radius - viewSize.width / 2)
            let yPos = sin(angle * Double(index) - .pi / 2) * (radius - viewSize.height / 2)
            let point = CGPoint(x: bounds.midX + xPos, y: bounds.midY + yPos)
            subview.place(at: point, anchor: .center, proposal: .unspecified)
        }
    }
}

// MARK: - View

struct RadialLayoutView: View {
    @State private var count = 16
    @State private var isExpanded = false

    var body: some View {
        RadialLayout(rollOut: isExpanded ? 1 : 0) {
            ForEach(0..<count, id: \.self) { _ in
                Circle()
                    .frame(width: 32, height: 32)
            }
        }
        .padding()
        .safeAreaInset(edge: .bottom) {
            VStack {
                Stepper("Count: \(count)", value: $count.animation(), in: 0...36)
                    .padding(.horizontal)

                Button("Expand") {
                    withAnimation(.easeInOut(duration: 1)) {
                        isExpanded.toggle()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.regularMaterial)
        }
        .navigationTitle("Radial Layout (with Animations)")
    }
}

#Preview {
    NavigationStack {
        RadialLayoutView()
    }
}

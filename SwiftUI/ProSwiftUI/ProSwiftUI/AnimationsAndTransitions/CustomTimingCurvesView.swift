import SwiftUI

// MARK: - Custom Animation Extensions

extension Animation {
    static var edgeBounce: Animation {
        Animation.timingCurve(0, 1, 1, 0)
    }

    static func edgeBounce(duration: TimeInterval = 0.2) -> Animation {
        Animation.timingCurve(0, 1, 1, 0, duration: duration)
    }

    static var easeInOutBack: Animation {
        Animation.timingCurve(0.5, -0.5, 0.5, 1.5)
    }

    static func easeInOutBack(duration: TimeInterval = 0.2) -> Animation {
        Animation.timingCurve(0.5, -0.5, 0.5, 1.5, duration: duration)
    }

    static var easeInOutBackSteep: Animation {
        Animation.timingCurve(0.7, -0.5, 0.3, 1.5)
    }

    static func easeInOutBackSteep(duration: TimeInterval = 0.2) -> Animation {
        Animation.timingCurve(0.7, -0.5, 0.3, 1.5, duration: duration)
    }
}

// MARK: - View

struct CustomTimingCurvesView: View {
    @State private var edgeBounceOffset: CGFloat = 0
    @State private var easeInOutBackScale: CGFloat = 1.0
    @State private var steepOffset: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // MARK: - Edge Bounce
                VStack {
                    Text("Edge Bounce")
                        .font(.headline)
                    Text("중앙에서 느리고 가장자리에서 빠름")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(.blue)
                        .frame(width: 60, height: 60)
                        .offset(y: edgeBounceOffset)
                        .onAppear {
                            withAnimation(.edgeBounce(duration: 2).repeatForever(autoreverses: true)) {
                                edgeBounceOffset = 100
                            }
                        }
                        .frame(height: 160)
                }

                Divider()

                // MARK: - Ease In Out Back
                VStack {
                    Text("Ease In Out Back")
                        .font(.headline)
                    Text("시작과 끝에서 반대 방향으로 살짝 이동")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(.green)
                        .frame(width: 60, height: 60)
                        .scaleEffect(easeInOutBackScale)

                    Button("Animate") {
                        withAnimation(.easeInOutBack(duration: 1)) {
                            easeInOutBackScale = easeInOutBackScale == 1.0 ? 1.5 : 1.0
                        }
                    }
                }

                Divider()

                // MARK: - Ease In Out Back Steep
                VStack {
                    Text("Ease In Out Back (Steep)")
                        .font(.headline)
                    Text("더 강한 overshoot 효과")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(.orange)
                        .frame(width: 60, height: 60)
                        .offset(x: steepOffset)

                    Button("Animate") {
                        withAnimation(.easeInOutBackSteep(duration: 1)) {
                            steepOffset = steepOffset == 0 ? 100 : 0
                        }
                    }
                }

                Divider()

                // MARK: - Comparison
                VStack {
                    Text("비교: 같은 동작, 다른 곡선")
                        .font(.headline)

                    TimingCurveComparisonRow(label: "linear", animation: .linear(duration: 1))
                    TimingCurveComparisonRow(label: "easeInOut", animation: .easeInOut(duration: 1))
                    TimingCurveComparisonRow(label: "edgeBounce", animation: .edgeBounce(duration: 1))
                    TimingCurveComparisonRow(label: "easeInOutBack", animation: .easeInOutBack(duration: 1))
                }
            }
            .padding()
        }
        .navigationTitle("Custom Timing Curves")
    }
}

struct TimingCurveComparisonRow: View {
    let label: String
    let animation: Animation
    @State private var offset: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Circle()
                    .fill(.purple)
                    .frame(width: 30, height: 30)
                    .offset(x: offset)

                Spacer()
            }
            .frame(height: 30)
            .onTapGesture {
                withAnimation(animation) {
                    offset = offset == 0 ? 200 : 0
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CustomTimingCurvesView()
    }
}

import SwiftUI

// MARK: - Helper Functions

func withMotionAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result
) rethrows -> Result {
    if UIAccessibility.isReduceMotionEnabled {
        return try body()
    } else {
        return try withAnimation(animation, body)
    }
}

func withoutAnimation<Result>(_ body: () throws -> Result) rethrows -> Result {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    return try withTransaction(transaction, body)
}

func withHighPriorityAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result
) rethrows -> Result {
    var transaction = Transaction(animation: animation)
    transaction.disablesAnimations = true
    return try withTransaction(transaction, body)
}

// MARK: - Motion Animation Modifier

struct MotionAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var accessibilityReduceMotion

    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        if accessibilityReduceMotion {
            content
        } else {
            content.animation(animation, value: value)
        }
    }
}

extension View {
    func motionAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        self.modifier(MotionAnimationModifier(animation: animation, value: value))
    }
}

// MARK: - Wave Animation (CircleGrid)

struct CircleGrid: View {
    var useRedFill = false

    var body: some View {
        LazyVGrid(columns: [.init(.adaptive(minimum: 64))]) {
            ForEach(0..<30, id: \.self) { i in
                Circle()
                    .fill(useRedFill ? .red : .blue)
                    .frame(height: 64)
                    .transaction { transaction in
                        transaction.animation = transaction.animation?.delay(Double(i) / 10)
                    }
            }
        }
    }
}

// MARK: - View

struct OverridingAnimationsView: View {
    @State private var scale = 1.0
    @State private var implicitScale = 1.0
    @State private var highPriorityScale = 1.0
    @State private var useRedFill = false

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // MARK: - withMotionAnimation
                VStack {
                    Text("withMotionAnimation")
                        .font(.headline)
                    Text("Reduce Motion 설정 존중")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(.blue)
                        .frame(width: 60, height: 60)
                        .scaleEffect(scale)

                    Button("Scale Up") {
                        withMotionAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                            scale += 0.3
                        }
                    }

                    Button("Reset") {
                        scale = 1.0
                    }
                    .font(.caption)
                }

                Divider()

                // MARK: - withoutAnimation
                VStack {
                    Text("withoutAnimation")
                        .font(.headline)
                    Text("암묵적 애니메이션 비활성화")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(.green)
                        .frame(width: 60, height: 60)
                        .scaleEffect(implicitScale)
                        .animation(.default, value: implicitScale)

                    HStack {
                        Button("With Animation") {
                            implicitScale += 0.3
                        }

                        Button("Without Animation") {
                            withoutAnimation {
                                implicitScale += 0.3
                            }
                        }
                    }

                    Button("Reset") {
                        implicitScale = 1.0
                    }
                    .font(.caption)
                }

                Divider()

                // MARK: - withHighPriorityAnimation
                VStack {
                    Text("withHighPriorityAnimation")
                        .font(.headline)
                    Text("암묵적 애니메이션을 다른 애니메이션으로 교체")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    RoundedRectangle(cornerRadius: 10)
                        .fill(.orange)
                        .frame(width: 60, height: 60)
                        .scaleEffect(highPriorityScale)
                        .animation(.default, value: highPriorityScale)

                    HStack {
                        Button("Default") {
                            highPriorityScale += 0.3
                        }

                        Button("3s Linear") {
                            withHighPriorityAnimation(.linear(duration: 3)) {
                                highPriorityScale += 0.3
                            }
                        }
                    }

                    Button("Reset") {
                        highPriorityScale = 1.0
                    }
                    .font(.caption)
                }

                Divider()

                // MARK: - Wave Animation with transaction()
                VStack {
                    Text("Wave Animation (transaction modifier)")
                        .font(.headline)
                    Text("각 원에 인덱스 기반 딜레이 적용")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    CircleGrid(useRedFill: useRedFill)

                    Button("Toggle Color") {
                        withAnimation(.easeInOut) {
                            useRedFill.toggle()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Overriding Animations")
    }
}

#Preview {
    NavigationStack {
        OverridingAnimationsView()
    }
}

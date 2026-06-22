import SwiftUI

// Identity 문제를 보여주는 카운터 뷰
private struct CounterView: View {
    @State private var counter = 0
    var scale: Double = 1

    var body: some View {
        Button("Tap Count: \(counter)") {
            counter += 1
        }
        .scaleEffect(scale)
        .font(.title2)
        .buttonStyle(.borderedProminent)
    }
}

struct UnderstandingIdentityView: View {
    @State private var scaleUp = false
    @State private var items = Array(1...20)
    @State private var iconId = UUID()

    let colors: [Color] = [.blue, .cyan, .green, .indigo, .mint, .orange, .pink, .purple, .red]
    let symbols = ["run", "archery", "basketball", "bowling", "dance", "golf", "hiking", "jumprope", "tennis", "volleyball", "yoga"]

    var body: some View {
        List {
            // 조건문과 Identity 문제
            Section("if 분기 → Identity 소멸") {
                VStack {
                    if scaleUp {
                        CounterView()
                            .scaleEffect(2)
                    } else {
                        CounterView()
                    }

                    Toggle("Scale Up", isOn: $scaleUp.animation())
                }
                .padding(.vertical)
            }

            // 삼항 연산자로 해결
            Section("삼항 연산자 → Identity 유지") {
                VStack {
                    CounterView(scale: scaleUp ? 2 : 1)

                    Toggle("Scale Up", isOn: $scaleUp.animation())
                }
                .padding(.vertical)
            }

            // .id()로 Identity 폐기
            Section(".id(UUID()) → 셔플 전환") {
                VStack {
                    ForEach(items.prefix(5), id: \.self) {
                        Text("Item \($0)")
                    }
                    .id(UUID())
                    .transition(.slide)

                    Button("Shuffle") {
                        withAnimation {
                            items.shuffle()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical)
            }

            // 랜덤 아이콘 생성기
            Section("랜덤 아이콘 (.id로 폐기)") {
                VStack {
                    ZStack {
                        Circle()
                            .fill(colors.randomElement()!)
                            .frame(width: 150, height: 150)

                        Image(systemName: "figure.\(symbols.randomElement()!)")
                            .font(.system(size: 64))
                            .foregroundColor(.white)
                    }
                    .transition(.slide)
                    .id(iconId)

                    Button("Change") {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            iconId = UUID()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }
        }
        .navigationTitle("Understanding Identity")
    }
}

#Preview {
    NavigationStack {
        UnderstandingIdentityView()
    }
}

import SwiftUI

// MARK: - ExampleView (상태를 가진 자식 뷰)

private struct ExampleView: View {
    @State private var counter = 0
    let color: Color

    var body: some View {
        Button { counter += 1 } label: {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .overlay(
                    Text(String(counter))
                        .foregroundColor(.white)
                        .font(.largeTitle)
                )
        }
        .frame(width: 100, height: 100)
        .rotationEffect(.degrees(.random(in: -20...20)))
    }
}

// MARK: - View

struct AdaptiveLayoutsView: View {
    let layouts = [
        AnyLayout(VStackLayout()),
        AnyLayout(HStackLayout()),
        AnyLayout(ZStackLayout()),
        AnyLayout(GridLayout())
    ]
    @State private var currentLayout = 0

    var layout: AnyLayout { layouts[currentLayout] }

    var body: some View {
        VStack {
            Spacer()

            Text("레이아웃 전환 시 각 뷰의 상태(카운터)가 유지됨")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Spacer()

            layout {
                GridRow {
                    ExampleView(color: .red)
                    ExampleView(color: .green)
                }
                GridRow {
                    ExampleView(color: .blue)
                    ExampleView(color: .orange)
                }
            }

            Spacer()

            Button("Change Layout") {
                withAnimation {
                    currentLayout = (currentLayout + 1) % layouts.count
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray.opacity(0.2))
        .navigationTitle("Adaptive Layouts")
    }
}

#Preview {
    NavigationStack {
        AdaptiveLayoutsView()
    }
}

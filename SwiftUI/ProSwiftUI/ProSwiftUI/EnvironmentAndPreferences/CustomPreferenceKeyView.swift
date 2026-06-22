import SwiftUI

// MARK: - WidthPreferenceKey

struct WidthPreferenceKey: PreferenceKey {
    static let defaultValue = 0.0

    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = nextValue()
    }
}

// MARK: - SizingView

struct SizingView: View {
    @State private var width = 50.0

    var body: some View {
        Color.red
            .frame(width: width, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                withAnimation {
                    width = Double.random(in: 50...160)
                }
            }
            .preference(key: WidthPreferenceKey.self, value: width)
    }
}

// MARK: - View

struct CustomPreferenceKeyView: View {
    @State private var width = 50.0

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    Text("Custom PreferenceKey")
                        .font(.headline)
                    Text("빨간 사각형을 탭하면 너비가 랜덤 변경되고\n자식→부모로 preference 값이 전달됨")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    SizingView()

                    Text("100%")
                        .frame(width: width)
                        .background(.red.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Text("150%")
                        .frame(width: width * 1.5)
                        .background(.green.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Text("200%")
                        .frame(width: width * 2)
                        .background(.blue.opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .onPreferenceChange(WidthPreferenceKey.self) { width = $0 }

                Text("Width: \(width, specifier: "%.0f")")
                    .font(.title2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Custom PreferenceKey")
    }
}

#Preview {
    NavigationStack {
        CustomPreferenceKeyView()
    }
}

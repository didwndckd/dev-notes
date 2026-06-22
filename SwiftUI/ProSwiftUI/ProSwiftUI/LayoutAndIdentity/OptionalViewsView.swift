import SwiftUI

struct OptionalViewsView: View {
    @State private var showBackground = true
    @State private var enableGesture = true
    @State private var tapCount = 0

    var body: some View {
        List {
            // Optional background
            Section("Optional Background") {
                VStack {
                    Text("Hello, World!")
                        .padding()
                        .background(showBackground ? Color.blue : nil)
                        .foregroundColor(showBackground ? .white : .primary)

                    Toggle("Show Background", isOn: $showBackground.animation())
                }
                .padding(.vertical)
            }

            // Optional gesture
            Section("Optional Gesture") {
                VStack {
                    let gesture = TapGesture()
                        .onEnded { tapCount += 1 }

                    Text("Tap me! Count: \(tapCount)")
                        .padding()
                        .background(.orange.opacity(0.3))
                        .cornerRadius(8)
                        .gesture(enableGesture ? gesture : nil)

                    Toggle("Enable Gesture", isOn: $enableGesture)
                }
                .padding(.vertical)
            }

            // 조건부 프로토콜 준수 설명
            Section("Optional의 조건부 프로토콜 준수") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Optional: View where Wrapped: View")
                        .font(.caption.monospaced())
                    Text("Optional: Gesture where Wrapped: Gesture")
                        .font(.caption.monospaced())
                    Text("Optional: Commands where Wrapped: Commands")
                        .font(.caption.monospaced())
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Optional Views")
    }
}

#Preview {
    NavigationStack {
        OptionalViewsView()
    }
}

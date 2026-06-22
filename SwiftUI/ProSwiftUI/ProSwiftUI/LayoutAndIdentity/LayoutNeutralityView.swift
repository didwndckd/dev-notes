import SwiftUI

struct LayoutNeutralityView: View {
    @State private var usesFixedSize = false

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Color는 완전히 layout neutral
                VStack {
                    Text("Color: layout neutral")
                        .font(.headline)

                    Text("Hello, World!")
                        .background(.red)

                    Color.red
                        .frame(height: 50)
                        .overlay(Text("Color.red (50pt)").foregroundColor(.white))
                }

                // idealWidth/idealHeight
                VStack {
                    Text("idealWidth/idealHeight")
                        .font(.headline)

                    Text("Hello, World!")
                        .frame(idealWidth: 300, idealHeight: 200)
                        .background(.red)
                }

                // nil을 사용한 동적 Layout Neutrality
                VStack {
                    Text("동적 Layout Neutrality (nil)")
                        .font(.headline)

                    Text("Hello, World!")
                        .frame(width: usesFixedSize ? 300 : nil)
                        .background(.red)

                    Toggle("Fixed sizes", isOn: $usesFixedSize.animation())
                        .padding(.horizontal)
                }

                // ScrollView 내부의 Layout Neutral 뷰
                VStack {
                    Text("ScrollView + Color")
                        .font(.headline)

                    ScrollView {
                        Color.red
                            .frame(idealHeight: 400, maxHeight: 400)
                    }
                    .frame(height: 200)
                    .border(.gray)
                }
            }
            .padding()
        }
        .navigationTitle("Layout Neutrality")
    }
}

#Preview {
    NavigationStack {
        LayoutNeutralityView()
    }
}

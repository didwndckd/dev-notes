import SwiftUI

struct MultipleFramesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // 중첩 frame
                VStack {
                    Text("중첩 frame")
                        .font(.headline)

                    Text("Hello, World!")
                        .frame(width: 200, height: 200)
                        .background(.blue)
                        .frame(width: 300, height: 300)
                        .background(.red)
                        .foregroundColor(.white)
                }

                // background로 시각화
                VStack {
                    Text("frame 크기 시각화")
                        .font(.headline)

                    Text("Hello, World!")
                        .background(.blue)
                        .frame(width: 250)
                        .background(.red)
                        .frame(minWidth: 400)
                        .background(.yellow)
                }

                // Fixed + Flexible frame 조합
                VStack {
                    Text("Fixed Width + Flexible Height")
                        .font(.headline)

                    Text("Hello, World!\nLine 2\nLine 3")
                        .frame(width: 250)
                        .frame(minHeight: 150)
                        .background(.green.opacity(0.3))
                        .border(.green)
                }

                // 모순처럼 보이는 frame 조합
                VStack {
                    Text("width: 250 + minWidth: 400")
                        .font(.headline)

                    Text("Hello, World!")
                        .frame(width: 250)
                        .background(.red.opacity(0.3))
                        .frame(minWidth: 400)
                        .background(.yellow.opacity(0.3))
                        .border(.orange)
                }
            }
            .padding()
        }
        .navigationTitle("Multiple Frames")
    }
}

#Preview {
    NavigationStack {
        MultipleFramesView()
    }
}

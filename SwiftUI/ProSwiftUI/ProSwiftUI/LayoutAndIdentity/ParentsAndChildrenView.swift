import SwiftUI

struct ParentsAndChildrenView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // Modifier = 새로운 뷰 생성
                VStack {
                    Text("Modifier = 새로운 뷰 생성")
                        .font(.headline)

                    Text("Hello, world!")
                        .frame(width: 300, height: 100)
                        .background(.blue.opacity(0.3))
                        .border(.blue)
                }

                // alignment 동작
                VStack {
                    Text("alignment: .bottomTrailing")
                        .font(.headline)

                    Text("Hello, world!")
                        .frame(width: 300, height: 100, alignment: .bottomTrailing)
                        .background(.green.opacity(0.3))
                        .border(.green)
                }

                // 뷰 타입 확인
                VStack {
                    Text("탭하면 body 타입 출력")
                        .font(.headline)

                    Text("Hello, world!")
                        .frame(width: 300, height: 100)
                        .background(.orange.opacity(0.3))
                        .border(.orange)
                        .onTapGesture {
                            print(type(of: self.body))
                        }
                }
            }
            .padding()
        }
        .navigationTitle("Parents and Children")
    }
}

#Preview {
    NavigationStack {
        ParentsAndChildrenView()
    }
}

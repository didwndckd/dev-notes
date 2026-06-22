import SwiftUI

struct InsideTupleViewView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // TupleView 타입 확인
                VStack {
                    Text("탭하면 body 타입 출력")
                        .font(.headline)

                    VStack {
                        Text("Hello")
                        Text("World")
                    }
                    .padding()
                    .background(.blue.opacity(0.2))
                    .onTapGesture {
                        print(type(of: self.body))
                    }
                }

                // TupleView 직접 생성
                VStack {
                    Text("TupleView 직접 생성")
                        .font(.headline)

                    VStack {
                        TupleView((
                            Text("1"),
                            Text("2"),
                            Text("3"),
                            Text("4"),
                            Text("5")
                        ))
                    }
                    .padding()
                    .background(.green.opacity(0.2))
                }

                // buildPartialBlock 설명
                VStack {
                    Text("buildPartialBlock으로 10개 제한 해제")
                        .font(.headline)

                    Text("buildPartialBlock(first:)로 첫 뷰 처리")
                        .font(.caption)
                    Text("buildPartialBlock(accumulated:next:)로 누적")
                        .font(.caption)
                    Text("→ 중첩된 TupleView 구조 생성")
                        .font(.caption)
                }
                .padding()
                .background(.orange.opacity(0.2))
                .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Inside TupleView")
    }
}

#Preview {
    NavigationStack {
        InsideTupleViewView()
    }
}

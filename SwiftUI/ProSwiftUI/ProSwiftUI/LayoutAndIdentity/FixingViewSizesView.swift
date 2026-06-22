import SwiftUI

struct FixingViewSizesView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // fixedSize 비교
                VStack {
                    Text("fixedSize() 비교")
                        .font(.headline)

                    Text("Without fixedSize")
                        .frame(width: 30, height: 100)
                        .background(.red.opacity(0.3))
                        .border(.red)

                    Text("With fixedSize")
                        .fixedSize()
                        .frame(width: 30, height: 100)
                        .background(.blue.opacity(0.3))
                        .border(.blue)
                }

                // 두 뷰의 높이 동일하게 맞추기
                VStack {
                    Text("높이 맞추기: fixedSize(vertical: true)")
                        .font(.headline)

                    HStack {
                        Text("Forecast")
                            .padding()
                            .frame(maxHeight: .infinity)
                            .background(.yellow)

                        Text("The rain in Spain falls mainly on the Spaniards")
                            .padding()
                            .frame(maxHeight: .infinity)
                            .background(.cyan)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }

                // Image의 크기
                VStack(spacing: 20) {
                    Text("Image: ideal size = 원본 크기")
                        .font(.headline)

                    // frame을 적용해도 이미지는 원본 크기로 overflow
                    Image("test")
                        .frame(width: 300, height: 100)
                        .background(.mint.opacity(0.3))
                        .border(.mint)
                        .padding(.top, 150)
                        .padding(.bottom, 150)

                    Text("clipped()로 overflow 잘라내기")
                        .font(.caption)

                    Image("test")
                        .frame(width: 300, height: 100)
                        .clipped()
                        .background(.mint.opacity(0.3))
                        .border(.mint)
                }

                // resizable Image
                VStack(spacing: 20) {
                    Text("Image.resizable()")
                        .font(.headline)

                    // resizable()은 frame에 맞게 축소/확대
                    Image("test")
                        .resizable()
                        .frame(width: 300, height: 100)
                        .background(.teal.opacity(0.3))
                        .border(.teal)

                    Text("resizable + fixedSize → 원본 크기 복원")
                        .font(.caption)

                    Image("test")
                        .resizable()
                        .fixedSize()
                        .frame(width: 300, height: 100)
                        .background(.teal.opacity(0.3))
                        .border(.teal)
                        .padding(.top, 150)
                        .padding(.bottom, 150)
                }

                // fixedSize 축 방향
                VStack {
                    Text("fixedSize 축 방향 비교")
                        .font(.headline)

                    Text("horizontal: true (한 줄 유지)")
                        .fixedSize(horizontal: true, vertical: false)
                        .frame(width: 50, height: 50)
                        .background(.green.opacity(0.3))
                        .border(.green)

                    Text("horizontal: false, vertical: true")
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(width: 50, height: 50)
                        .background(.purple.opacity(0.3))
                        .border(.purple)
                        .padding(.top, 60)
                }
            }
            .padding()
        }
        .navigationTitle("Fixing View Sizes")
    }
}

#Preview {
    NavigationStack {
        FixingViewSizesView()
    }
}

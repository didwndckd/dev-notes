import SwiftUI

// MARK: - WelcomeView (transformEnvironment)

struct WelcomeView: View {
    var body: some View {
        VStack {
            Image(systemName: "sun.max")
                .transformEnvironment(\.font) { font in
                    font = font?.weight(.black)
                }

            Text("Welcome!")
        }
    }
}

// MARK: - View

struct OverridingEnvironmentView: View {
    @State private var selectedFont = 0
    private let fonts: [(String, Font)] = [
        ("Large Title", .largeTitle),
        ("Title", .title),
        ("Headline", .headline),
        ("Body", .body),
        ("Caption", .caption),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                VStack(spacing: 16) {
                    Text("transformEnvironment")
                        .font(.headline)
                    Text("부모의 폰트를 완전히 덮어쓰지 않고 weight만 변형")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Picker("Font", selection: $selectedFont) {
                    ForEach(0..<fonts.count, id: \.self) { index in
                        Text(fonts[index].0).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                VStack(spacing: 20) {
                    Text("Override (.font(.largeTitle.weight(.black)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack {
                        Image(systemName: "sun.max")
                            .font(.largeTitle.weight(.black))
                        Text("Welcome!")
                    }
                    .font(fonts[selectedFont].1)
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))

                    Text("Transform (.transformEnvironment)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    WelcomeView()
                        .font(fonts[selectedFont].1)
                        .padding()
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                }

                Text("위: 부모 폰트가 바뀌어도 이미지는 항상 largeTitle.black\n아래: 부모 폰트에 weight(.black)만 추가")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .navigationTitle("Overriding Environment")
    }
}

#Preview {
    NavigationStack {
        OverridingEnvironmentView()
    }
}

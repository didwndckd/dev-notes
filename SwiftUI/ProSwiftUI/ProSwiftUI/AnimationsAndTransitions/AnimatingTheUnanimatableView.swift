import SwiftUI

// MARK: - Animatable ZIndex

struct AnimatableZIndexModifier: ViewModifier, Animatable {
    var index: Double

    var animatableData: Double {
        get { index }
        set { index = newValue }
    }

    func body(content: Content) -> some View {
        content
            .zIndex(index)
    }
}

extension View {
    func animatableZIndex(_ index: Double) -> some View {
        self.modifier(AnimatableZIndexModifier(index: index))
    }
}

// MARK: - Animatable Font

struct AnimatableFontModifier: ViewModifier, Animatable {
    var size: Double

    var animatableData: Double {
        get { size }
        set { size = newValue }
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: size))
    }
}

extension View {
    func animatableFont(size: Double) -> some View {
        self.modifier(AnimatableFontModifier(size: size))
    }
}

// MARK: - CountingText

struct CountingText: View, Animatable {
    var value: Double
    var fractionLength = 2

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(value.formatted(.number.precision(.fractionLength(fractionLength))))
    }
}

// MARK: - TypewriterText

struct TypewriterText: View, Animatable {
    var string: String
    var count = 0

    var animatableData: Double {
        get { Double(count) }
        set { count = Int(max(0, newValue)) }
    }

    var body: some View {
        let stringToShow = String(string.prefix(count))
        ZStack {
            Text(string)
                .hidden()
                .overlay(
                    Text(stringToShow),
                    alignment: .topLeading
                )
        }
    }
}

// MARK: - View

struct AnimatingTheUnanimatableView: View {
    @State private var redAtFront = false
    @State private var scaleUp = false
    @State private var countValue = 0.0
    @State private var typewriterValue = 0
    let message = "This is a very long piece of text that appears letter by letter."
    let colors: [Color] = [.blue, .green, .orange, .purple, .mint]

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // MARK: - Animatable zIndex
                VStack {
                    Text("Animatable zIndex")
                        .font(.headline)

                    Button("Toggle zIndex") {
                        withAnimation(.linear(duration: 1)) {
                            redAtFront.toggle()
                        }
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(.red)
                            .animatableZIndex(redAtFront ? 6 : 0)

                        ForEach(0..<5, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 25)
                                .fill(colors[i])
                                .offset(x: Double(i + 1) * 20, y: Double(i + 1) * 20)
                                .zIndex(Double(i))
                        }
                    }
                    .frame(width: 200, height: 200)
                }
                .padding(.bottom, 80)

                Divider()

                // MARK: - Animatable Font Size
                VStack {
                    Text("Animatable Font Size")
                        .font(.headline)

                    Text("Hello, World!")
                        .animatableFont(size: scaleUp ? 56 : 24)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                                scaleUp.toggle()
                            }
                        }

                    Text("Tap the text above")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // MARK: - CountingText
                VStack {
                    Text("Counting Text")
                        .font(.headline)

                    CountingText(value: countValue)
                        .font(.largeTitle.monospacedDigit())

                    Button("Random Number") {
                        withAnimation(.linear) {
                            countValue = Double.random(in: 1...1000)
                        }
                    }
                }

                Divider()

                // MARK: - TypewriterText
                VStack {
                    Text("Typewriter Text")
                        .font(.headline)

                    TypewriterText(string: message, count: typewriterValue)
                        .frame(width: 300, alignment: .leading)

                    HStack {
                        Button("Type!") {
                            withAnimation(.linear(duration: 2)) {
                                typewriterValue = message.count
                            }
                        }

                        Button("Reset") {
                            typewriterValue = 0
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Animating the Unanimatable")
    }
}

#Preview {
    NavigationStack {
        AnimatingTheUnanimatableView()
    }
}

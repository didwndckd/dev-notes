import SwiftUI

// MARK: - RequirableTextField (Custom Environment Key)

struct FormElementIsRequiredKey: EnvironmentKey {
    static var defaultValue = false
}

extension EnvironmentValues {
    var required: Bool {
        get { self[FormElementIsRequiredKey.self] }
        set { self[FormElementIsRequiredKey.self] = newValue }
    }
}

extension View {
    func required(_ makeRequired: Bool = true) -> some View {
        environment(\.required, makeRequired)
    }
}

struct RequirableTextField: View {
    @Environment(\.required) var required

    let title: String
    @Binding var text: String

    var body: some View {
        HStack {
            TextField(title, text: $text)
            if required {
                Image(systemName: "asterisk")
                    .imageScale(.small)
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - CirclesView (strokeWidth Environment Key)

struct StrokeWidthKey: EnvironmentKey {
    static var defaultValue = 1.0
}

extension EnvironmentValues {
    var strokeWidth: Double {
        get { self[StrokeWidthKey.self] }
        set { self[StrokeWidthKey.self] = newValue }
    }
}

extension View {
    func strokeWidth(_ width: Double) -> some View {
        environment(\.strokeWidth, width)
    }
}

struct CirclesView: View {
    @Environment(\.strokeWidth) var strokeWidth

    var body: some View {
        ForEach(0..<3, id: \.self) { _ in
            Circle()
                .stroke(.red, lineWidth: strokeWidth)
        }
    }
}

// MARK: - View

struct CustomEnvironmentKeyView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var makeRequired = false
    @State private var sliderValue = 1.0

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // MARK: - RequirableTextField Demo
                VStack(spacing: 16) {
                    Text("Custom Environment Key: required")
                        .font(.headline)
                    Text("컨테이너에 .required() 적용 시 모든 자식 뷰에 전파")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Form {
                        RequirableTextField(title: "First name", text: $firstName)
                        RequirableTextField(title: "Last name", text: $lastName)
                        Toggle("Make required", isOn: $makeRequired.animation())
                    }
                    .required(makeRequired)
                    .frame(height: 200)
                }

                Divider()

                // MARK: - CirclesView Demo
                VStack(spacing: 16) {
                    Text("Custom Environment Key: strokeWidth")
                        .font(.headline)
                    Text("Slider로 strokeWidth 값을 변경하면 CirclesView에 전파")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    CirclesView()
                        .frame(height: 200)

                    Slider(value: $sliderValue, in: 1...10)
                        .padding(.horizontal)

                    Text("strokeWidth: \(sliderValue, specifier: "%.1f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .strokeWidth(sliderValue)
            }
            .padding()
        }
        .navigationTitle("Custom Environment Key")
    }
}

#Preview {
    NavigationStack {
        CustomEnvironmentKeyView()
    }
}

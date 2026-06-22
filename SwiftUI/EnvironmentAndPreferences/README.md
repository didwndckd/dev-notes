# Environment and Preferences

## Environment

SwiftUI의 Environment는 뷰 계층 구조를 따라 **위에서 아래로 데이터를 전파**하는 시스템이다. `.font()`, `.foregroundColor()` 같은 modifier들이 자식 뷰 전체에 영향을 줄 수 있는 이유가 바로 Environment 덕분이다. 뷰는 자신이 관심 있는 Environment 값만 `@Environment`로 읽으면 되고, 커스텀 키를 정의하여 직접 만든 데이터도 동일한 방식으로 전파할 수 있다.

---

### 커스텀 Environment Key 만들기

필수 입력 필드 옆에 빨간 별표를 표시하는 `TextField` 래퍼를 예시로, 커스텀 Environment Key를 만드는 과정을 살펴본다.

```swift
// 1단계: EnvironmentKey 프로토콜 채택 — defaultValue가 필수
struct FormElementIsRequiredKey: EnvironmentKey {
    static var defaultValue = false
}

// 2단계: EnvironmentValues 확장 — subscript로 키에 접근
extension EnvironmentValues {
    var required: Bool {
        get { self[FormElementIsRequiredKey.self] }
        set { self[FormElementIsRequiredKey.self] = newValue }
    }
}

// 3단계: View Extension — .font()가 environment(\.font)의 래퍼인 것처럼
//        커스텀 키도 동일한 패턴으로 사용성을 높인다
//        Boolean 파라미터의 기본값을 true로 설정하면 .required()만으로 사용 가능
extension View {
    func required(_ makeRequired: Bool = true) -> some View {
        environment(\.required, makeRequired)
    }
}

// 4단계: Environment 값을 읽는 뷰
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

// 5단계: 사용 — 컨테이너에 적용하면 내부의 모든 자식 뷰에 자동 전파
struct ContentView: View {
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var makeRequired = false

    var body: some View {
        Form {
            RequirableTextField(title: "First name", text: $firstName)
            RequirableTextField(title: "Last name", text: $lastName)
            Toggle("Make required", isOn: $makeRequired.animation())
        }
        .required(makeRequired)  // 개별 뷰가 아닌 컨테이너에 적용
    }
}
```

**같은 패턴의 다른 예제: strokeWidth**

도형의 선 두께를 Environment로 관리하는 예제. 동일한 3단계 패턴을 따른다.

```swift
// 동일한 3단계 패턴: EnvironmentKey → EnvironmentValues → View Extension
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

// Environment 값을 읽는 뷰 — 이후 섹션에서도 재사용
struct CirclesView: View {
    @Environment(\.strokeWidth) var strokeWidth

    var body: some View {
        ForEach(0..<3) { _ in
            Circle()
                .stroke(.red, lineWidth: strokeWidth)
        }
    }
}

// 상위 뷰에서 값 설정
struct ContentView: View {
    @State private var sliderValue = 1.0

    var body: some View {
        VStack {
            CirclesView()
            Slider(value: $sliderValue, in: 1...10)
        }
        .strokeWidth(sliderValue)
    }
}
```

> **Tip**: `StrokeWidthKey`와 `CirclesView`는 다음 챕터에서도 사용되므로 코드를 보관해 두는 것이 좋다.

---

### @Environment vs @EnvironmentObject

Environment는 observable object의 변경을 감시하지 않는다. 클래스를 저장하고 업데이트해도 뷰가 갱신되지 않으므로, `@Environment`는 값 타입에, `@EnvironmentObject`는 클래스 인스턴스에 적합하다.

가능하다면 `@Environment` 키를 사용하는 것이 유리한 두 가지 이유가 있다:

#### 1. 안전성: 기본값 보장

| | `@Environment` | `@EnvironmentObject` |
|--|-----------------|----------------------|
| **기본값** | `EnvironmentKey`에서 `defaultValue` 필수 제공 | 없음 |
| **누락 시** | 기본값 사용 | **런타임 크래시** |

#### 2. 성능: 세밀한 업데이트

`ObservableObject`의 문서화된 동작에 따르면, `@Published` 프로퍼티가 변경되면 `objectWillChange.send()`가 객체 단위로 호출되어 해당 객체를 관찰하는 모든 뷰가 갱신 대상이 된다.

위에서 정의한 `CirclesView`는 `@Environment(\.strokeWidth)`만 의존하므로 해당 키가 변경될 때만 갱신된다. 반면 `@EnvironmentObject`를 사용하면 객체의 어떤 프로퍼티든 변경 시 전체 갱신이 발생한다:

```swift
class ThemeManager: ObservableObject {
    @Published var strokeWidth = 1.0
    @Published var titleFont = TitleFontKey.defaultValue
}

// @EnvironmentObject 방식 — theme.titleFont가 변경되어도 이 뷰의 body가 재호출됨
struct CirclesView_EnvironmentObject: View {
    @EnvironmentObject var theme: ThemeManager

    var body: some View {
        ForEach(0..<3) { _ in
            Circle()
                .stroke(.red, lineWidth: theme.strokeWidth)
        }
    }
}
```

> **참고**: `ObservableObject`는 프로퍼티 단위가 아닌 **객체 단위**로 변경을 알린다. `@Environment` 키는 해당 키를 사용하는 뷰만 갱신하므로 불필요한 `body` 재호출을 줄일 수 있다. 단, iOS 18+ 에서는 내부 최적화가 추가되어 실제 `body` 재호출 빈도가 다를 수 있다.

> **참고: iOS 17+의 `@Observable`** — iOS 17에서 도입된 `@Observable` 매크로는 프로퍼티 단위 추적을 지원한다. `@Observable` + `@Environment`를 사용하면 `@EnvironmentObject`의 두 가지 단점(기본값 없음, 객체 단위 갱신)이 모두 해결된다. Apple도 `ObservableObject` → `@Observable` 마이그레이션을 권장하고 있다.

---

### 공유 객체 + Environment Key

데이터를 하나의 객체에서 읽고 쓰되, 누락 시 크래시를 방지하고 싶다면 공유 객체의 프로퍼티를 Environment Key로 노출하는 방식을 사용할 수 있다.

```swift
// === 구조: Theme 프로토콜 → 구체 구현 → ObservableObject 싱글턴 → Environment Key ===

// 1. Theme 프로토콜과 기본 구현
protocol Theme {
    var strokeWidth: Double { get set }
    var titleFont: Font { get set }
}

struct DefaultTheme: Theme {
    var strokeWidth = 1.0
    var titleFont = TitleFontKey.defaultValue
}

// 2. 싱글턴 ThemeManager
class ThemeManager: ObservableObject {
    @Published var activeTheme: any Theme = DefaultTheme()
    static var shared = ThemeManager()
    private init() { }
}

// 3. Environment Key로 노출 — defaultValue가 보장되어 누락 시에도 안전
struct ThemeKey: EnvironmentKey {
    static var defaultValue: any Theme = ThemeManager.shared.activeTheme
}

extension EnvironmentValues {
    var theme: any Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// 4. ViewModifier로 ThemeManager 변경 감시 → Environment에 주입
struct ThemeModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content.environment(\.theme, themeManager.activeTheme)
    }
}

extension View {
    func themed() -> some View {
        modifier(ThemeModifier())
    }
}

// 5. 사용 — key path로 프로퍼티 단위 의존성 설정
//    theme 전체가 아닌 strokeWidth만 의존하므로
//    titleFont가 변경되어도 이 뷰의 body는 재호출되지 않음
struct CirclesView_Themed: View {
    @Environment(\.theme.strokeWidth) var strokeWidth

    var body: some View {
        ForEach(0..<3) { _ in
            Circle()
                .stroke(.red, lineWidth: strokeWidth)
        }
    }
}
```

---

### Overriding the environment

자식 뷰에서 동일한 Environment 키에 새 값을 설정하면 부모의 값을 **완전히 대체(override)**한다. 값을 대체하는 것이 아니라 **변형**하고 싶을 때는 `transformEnvironment()`를 사용한다. 특정 Environment 키의 현재 값을 `inout` 참조로 전달받아, 상위에서 어떤 값이 내려오든 클로저를 통해 변형할 수 있다.

```swift
// 환영 뷰 — 이미지와 텍스트로 구성
struct WelcomeView: View {
    var body: some View {
        VStack {
            Image(systemName: "sun.max")
                // ❌ .font(.largeTitle.weight(.black))
                // → Environment 값을 완전히 덮어써서 부모의 폰트 변경이 무시됨

                // ✅ transformEnvironment로 현재 폰트를 변형
                // → 부모가 어떤 폰트를 설정하든 weight만 black으로 변경
                .transformEnvironment(\.font) { font in
                    font = font?.weight(.black)
                }

            Text("Welcome!")
        }
    }
}

// 부모 뷰 — 폰트를 .headline로 바꿔도 이미지는 headline.weight(.black)이 적용됨
struct ContentView: View {
    var body: some View {
        WelcomeView()
            .font(.largeTitle)
    }
}
```

`transaction()` modifier와 유사한 접근법으로, 어떤 폰트가 적용되든 커스텀 클로저를 통해 자동으로 변형된다.

---

### 부록: Text modifier 흡수와 font()의 이중 동작

뷰에 modifier를 적용하면 대부분 원래 뷰를 감싸는 새로운 뷰가 생성된다. 하지만 항상 그런 것은 아니다.

```swift
// === Text는 modifier를 자체적으로 흡수한다 ===
// 시뮬레이터에서 탭하면 타입이 여전히 Text — modifier들이 뷰에 직접 흡수됨
// SwiftUI 인터페이스에서 "internal var modifiers"를 검색하면
// 모든 Text 뷰가 modifier용 enum 케이스 배열을 저장하고 있음을 확인 가능
Text("Tap")
    .font(.title)
    .foregroundColor(.red)
    .fontWeight(.black)
    .onTapGesture {
        print(type(of: self.body))  // → Text
    }

// === font()를 VStack 등 일반 View에 적용하면 ===
// 결과 타입에 _EnvironmentKeyWritingModifier가 포함됨
// font()가 호출 위치에 따라 다르게 동작하기 때문이다
VStack {
    Text("Tap")
}
.font(.title)
.onTapGesture {
    print(type(of: self.body))  // → _EnvironmentKeyWritingModifier 포함
}

// === font()의 이중 동작 원리 ===
// View.font()는 @inlinable로 표시되어 실제 구현을 볼 수 있다:
//   @inlinable public func font(_ font: SwiftUI.Font?) -> some SwiftUI.View {
//       return environment(\.font, font)
//   }
// 즉, View.font(.title)은 .environment(\.font, .title)의 래퍼
// Environment 값은 하위 뷰 계층 전체로 전파되므로
// VStack 내부의 모든 자식 뷰가 해당 폰트를 자동으로 적용받는다
```

| 호출 위치 | 결과 | 이유 |
|----------|------|------|
| `Text`에 직접 | 내부 enum 배열에 흡수 | 더 제약된 타입이 우선 (overload resolution) |
| 다른 `View`에 | `environment(\.font, .title)`로 변환 | 프로토콜 수준의 메서드 |

> **Tip**: `Text` 뷰가 폰트 변경 시 다른 자연 크기를 가지는 이유가 바로 이것이다. 폰트가 뷰에 직접 흡수되어 크기 계산에 사용된다.

> **Tip**: SwiftUI 인터페이스에서 `return environment(\`를 검색하면 이 동작의 다른 사례들을 볼 수 있다.

> **참고: `@inlinable`** — 컴파일러가 함수 호출을 함수 본문 코드로 직접 대체할 수 있게 허용하는 속성이다. 일반적으로 프레임워크의 함수는 컴파일된 바이너리로만 제공되어 내부 구현을 볼 수 없지만, `@inlinable`로 표시된 함수는 소스 코드가 모듈 외부에 공개된다. 덕분에 SwiftUI 인터페이스 파일에서 `View.font()`의 실제 구현(`environment(\.font, font)`)을 확인할 수 있다.

---

### 핵심 정리

| 항목 | 설명 |
|------|------|
| **Environment 전파** | 적용 지점의 모든 하위 뷰로 자동 전파 |
| **선택적 읽기** | 뷰는 관심 있는 값만 `@Environment`로 읽으면 됨 |
| **커스텀 키 3단계** | `EnvironmentKey` → `EnvironmentValues` 확장 → (선택) `View` Extension |
| **일괄 적용** | 컨테이너에 적용하면 모든 자식 뷰에 자동 전파 |
| **@Environment** | 값 타입에 적합. 기본값 보장, 키별 세밀한 갱신 |
| **@EnvironmentObject** | 클래스 인스턴스에 적합. 누락 시 크래시, 객체 단위 전체 갱신 |
| **공유 객체 + Environment Key** | 공유 상태 + 안전성 + key path로 프로퍼티 단위 갱신 |
| **Overriding** | 같은 키에 값 설정 시 완전 대체. `transformEnvironment()`로 변형 가능 |
| **Text modifier 흡수** | `Text`는 modifier를 내부 enum 배열에 흡수. `font()`는 호출 위치에 따라 이중 동작 |



## Preferences

Environment가 **위→아래**로 데이터를 전파한다면, Preferences는 **아래→위**로 데이터를 전파하는 시스템이다. 자식 뷰가 자신의 정보를 상위 뷰에 보고할 때 사용한다. 대표적인 예가 `navigationTitle()`이다.

---

### Preferences의 동작 방식

```swift
NavigationStack {
    VStack {
        Image(systemName: "sun.max")
            .navigationTitle("Image")   // ← 첫 번째로 발견되어 이 값이 사용됨

        Text("Welcome!")
            .navigationTitle("Text")    // ← 무시됨
    }
    .navigationTitle("VStack")          // ← 무시됨
}
// navigationTitle은 preference로 구현되어 있다
// 값이 여러 개일 때 NavigationStack은 첫 번째 값을 선택한다
// Environment와 마찬가지로 중간 컨테이너에서 멈추지 않고 최상위까지 계속 올라간다
```

커스텀 Preference도 동일한 원리로 동작한다:

- 어떤 뷰든 preference 값을 설정할 수 있다
- 값은 뷰 계층을 따라 위로 흐른다
- 여러 값이 올라올 때 **어떤 값을 사용할지 직접 결정**해야 한다 (첫 번째 선택, 합산 등)

> **참고**: 데이터가 위아래로 자유롭게 흐르면 스파게티 코드가 될 수 있으므로 Preferences 사용은 신중해야 한다.

---

### 커스텀 PreferenceKey 만들기

`PreferenceKey`는 `EnvironmentKey`와 유사하지만, `defaultValue` 외에 **reducer 함수**(`reduce`)를 추가로 요구한다. 여러 자식 뷰에서 값이 올라올 때 이를 하나로 합치는 방법을 정의하는 것이다.

자식 뷰의 너비를 상위 뷰에 보고하는 예제로 전체 흐름을 살펴본다.

```swift
// 1. PreferenceKey 정의 — defaultValue + reduce 필수
struct WidthPreferenceKey: PreferenceKey {
    static let defaultValue = 0.0

    // reducer: 여러 값이 올라올 때 어떤 값을 사용할지 결정
    // 마지막 값 사용 (value = nextValue())
    // 합산하려면: value += nextValue()
    // 첫 번째 값만 사용하려면: 빈 구현 (nextValue()를 호출하지 않음)
    static func reduce(value: inout Double, nextValue: () -> Double) {
        value = nextValue()
    }
}

// 2. 자식 뷰 — .preference()로 값을 위로 보고
struct SizingView: View {
    @State private var width = 50.0

    var body: some View {
        Color.red
            .frame(width: width, height: 100)
            .onTapGesture {
                width = Double.random(in: 50...160)
            }
            .preference(key: WidthPreferenceKey.self, value: width)
    }
}

// 3. 상위 뷰 — .onPreferenceChange()로 값을 수신
struct ContentView: View {
    @State private var width = 0.0

    var body: some View {
        NavigationStack {
            VStack {
                SizingView()

                // 수신한 preference 값을 다른 뷰에 활용
                Text("100%")
                    .frame(width: width)
                    .background(.red)
                Text("150%")
                    .frame(width: width * 1.5)
                    .background(.green)
                Text("200%")
                    .frame(width: width * 2)
                    .background(.blue)
            }
            .onPreferenceChange(WidthPreferenceKey.self) { width = $0 }
            .navigationTitle("Width: \(width)")
        }
    }
}
```

`SizingView`를 여러 개 배치하면 `reduce()`에 정의한 전략에 따라 값이 결정된다:

| reduce 구현 | 결과 |
|-------------|------|
| `value = nextValue()` | 마지막 자식의 값 사용 |
| `value += nextValue()` | 모든 자식의 값 합산 |
| 빈 구현 (`nextValue()` 미호출) | 첫 번째 자식의 값만 사용 (`navigationTitle`과 동일) |

---

### Anchor Preferences

일반 `PreferenceKey`는 단순한 값(숫자, 문자열 등)을 위로 전달하지만, **기하 정보(위치·크기)**를 전달하려면 `Anchor<CGRect>`를 사용해야 한다. `Anchor`는 좌표 공간에 독립적인 **불투명(opaque) 기하 저장소**로, `GeometryProxy`를 통해서만 실제 좌표로 변환할 수 있다. 이 덕분에 서로 다른 좌표 공간 간의 변환을 SwiftUI가 자동으로 처리해 준다.

Airbnb 앱처럼 선택된 카테고리 아래에 밑줄이 이동하는 UI를 예제로 살펴본다.

```swift
// === 데이터 모델 ===
struct Category: Identifiable, Equatable {
    let id: String
    let symbol: String
}

// Anchor<CGRect>를 포함하는 preference 데이터
// Anchor는 불투명 기하 저장소 — 직접 읽을 수 없고 GeometryProxy를 통해서만 좌표로 변환
struct CategoryPreference: Equatable {
    let category: Category
    let anchor: Anchor<CGRect>
}

// 여러 자식에서 올라오는 preference를 배열로 수집
struct CategoryPreferenceKey: PreferenceKey {
    static let defaultValue = [CategoryPreference]()

    static func reduce(value: inout [CategoryPreference], nextValue: () -> [CategoryPreference]) {
        value.append(contentsOf: nextValue())
    }
}

// === 카테고리 버튼 ===
struct CategoryButton: View {
    var category: Category
    @Binding var selection: Category?

    var body: some View {
        Button {
            withAnimation { selection = category }
        } label: {
            VStack {
                Image(systemName: category.symbol)
                Text(category.id)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement()
        .accessibilityLabel(category.id)
        // anchorPreference: 이 버튼의 bounds를 Anchor로 감싸서 위로 전달
        // key: 어떤 PreferenceKey에 저장할지
        // value: 어떤 기하 정보를 보낼지 (.bounds = 전체 프레임)
        // transform: Anchor를 PreferenceKey가 기대하는 타입으로 변환
        .anchorPreference(
            key: CategoryPreferenceKey.self,
            value: .bounds,
            transform: { [CategoryPreference(category: category, anchor: $0)] }
        )
    }
}

// === ContentView ===
struct ContentView: View {
    @State private var selectedCategory: Category?

    let categories = [
        Category(id: "Arctic", symbol: "snowflake"),
        Category(id: "Beach", symbol: "beach.umbrella"),
        Category(id: "Shared Homes", symbol: "house")
    ]

    var body: some View {
        VStack {
            HStack(spacing: 20) {
                ForEach(categories) { category in
                    CategoryButton(category: category, selection: $selectedCategory)
                }
            }
            // overlayPreferenceValue: preference를 읽어서 오버레이 뷰로 변환
            // onPreferenceChange + overlay를 합친 것
            .overlayPreferenceValue(CategoryPreferenceKey.self) { preferences in
                GeometryReader { proxy in
                    if let selected = preferences.first(where: { $0.category == selectedCategory }) {
                        // proxy[anchor]로 Anchor를 현재 좌표 공간의 CGRect로 변환
                        // 서로 다른 좌표 공간 간의 변환을 SwiftUI가 자동 처리
                        let frame = proxy[selected.anchor]

                        Rectangle()
                            .fill(.primary)
                            .frame(width: frame.width, height: 2)
                            .position(x: frame.midX, y: frame.maxY)
                    }
                }
            }

            List(categories, id: \.id) { category in
                HStack {
                    Button(category.id) {
                        withAnimation { selectedCategory = category }
                    }
                    if selectedCategory == category {
                        Spacer()
                        Image(systemName: "checkmark")
                    }
                }
            }

            if let selectedCategory {
                Text("Selected: \(selectedCategory.id)")
            }
        }
    }
}
```

| 항목 | 설명 |
|------|------|
| `Anchor<CGRect>` | 좌표 공간에 독립적인 불투명 기하 저장소 |
| `anchorPreference()` | 뷰의 기하 정보를 `Anchor`로 감싸서 preference로 전달 |
| `overlayPreferenceValue()` | preference를 읽어서 오버레이 뷰로 변환 (`onPreferenceChange` + `overlay`) |
| `proxy[anchor]` | `Anchor`를 현재 `GeometryReader` 좌표 공간의 `CGRect`로 변환 |

# Layout and Identity

## Parents and children

SwiftUI 레이아웃의 3단계 프로세스:

1. 부모 뷰가 자식에게 크기를 제안
2. 자식이 자신의 크기를 결정하고, 부모는 이를 존중
3. 부모가 자신의 좌표 공간에 자식을 배치

### 부모 뷰란?

```swift
VStack {
    Text("Hello, world!")
        .frame(width: 300, height: 100)  // Text의 실제 부모는 VStack이 아닌 .frame()
    Image(systemName: "person")
}
```

### Modifier = 새로운 뷰 생성

```swift
// 1개의 뷰
Text("Hello, world!")

// 2개의 뷰 (Text를 감싸는 Frame ModifiedContent)
Text("Hello, world!")
    .frame(width: 300, height: 100)
```

- Modifier 적용 시 원본 뷰를 감싸는 새로운 뷰 생성
- 부모(frame)가 300x100 컨테이너로서 Text를 중앙에 배치

### 뷰 타입 확인

```swift
Text("Hello, world!")
    .frame(width: 300, height: 100)
    .onTapGesture {
        print(type(of: self.body))
        // 출력: ModifiedContent<ModifiedContent<Text, _FrameLayout>, TapGestureModifier>
    }
```

- `ModifiedContent`: View 프로토콜을 준수하는 struct
- 모든 modifier가 새 뷰를 생성하는 것은 아님

### ModifiedContent

Xcode Open Quickly(Shift+Cmd+O)에서 확인 가능한 정의:

```swift
@frozen public struct ModifiedContent<Content, Modifier>

extension ModifiedContent: View where Content: View, Modifier: ViewModifier
```

Public API로 직접 사용 가능:

```swift
// ViewModifier 정의
struct CustomFont: ViewModifier {
    func body(content: Content) -> some View {
        content.font(.largeTitle)
    }
}

// 동일한 결과를 생성하는 두 방식
ModifiedContent(content: Text("Hello"), modifier: CustomFont())  // 직접 사용
Text("Hello").modifier(CustomFont())                              // .modifier() 사용
```

- SwiftUI result builder가 컴파일 타임에 modifier를 `ModifiedContent`로 중첩 변환
- 런타임이 아닌 컴파일 타임 처리로 두 방식의 실제 타입 동일

### 원본 Frame 유지

```swift
// Text의 원본 frame(자연스러운 크기) + 300x100 ModifiedContent 생성
Text("Hello, world!")
    .frame(width: 300, height: 100)

// alignment 동작을 위해 Text는 자신의 원본 frame 정보 유지
Text("Hello, world!")
    .frame(width: 300, height: 100, alignment: .bottomTrailing)
```

- Text의 bounds는 텍스트의 자연스러운 너비/높이를 초과하여 확장 불가
- `.frame()` modifier는 Text 주변에 더 큰 공간을 가진 새로운 `ModifiedContent` 뷰 생성

---

## Fixing view sizes

뷰의 최종 크기 결정에 사용되는 6가지 값:

| 속성 | 설명 |
|------|------|
| Minimum width/height | 뷰가 수용하는 최소 공간. 이보다 작은 값은 무시되어 뷰가 제안된 공간 밖으로 "leak" |
| Maximum width/height | 뷰가 수용하는 최대 공간. 이보다 큰 값은 무시되어 부모가 남은 공간에 뷰를 배치 |
| Ideal width/height | 뷰가 원하는 선호 공간 (UIKit의 intrinsic content size와 유사). min~max 범위 내에서 다른 값 제공 가능 |

### Text의 크기 결정

```swift
// Text의 ideal size: 한 줄에 모든 문자를 표시하는 크기
Text("Hello, world!")
    .frame(width: 300, height: 100)

// 너비가 부족하면 자동 줄바꿈
Text("Hello, world!")
    .frame(width: 30, height: 100)  // 여러 줄로 wrap
```

- Text의 ideal width/height: 한 줄에 모든 문자를 표시하는 크기
- Text의 minimum size: 없음 (제한된 너비에서 자동 줄바꿈)
- "자식이 자신의 크기를 결정" 규칙 위반처럼 보이지만, Text는 minimum size가 없어 좁은 공간 수용 가능

### fixedSize()

뷰의 ideal size를 minimum/maximum size로 승격시키는 modifier:

```swift
// fixedSize()가 ideal size를 고정 크기로 변환
// frame(30, 100)이 제안해도 Text는 원래 크기 유지
Text("Hello, world!")
    .fixedSize()
    .frame(width: 30, height: 100)
```

실행 순서:
1. frame이 30x100 공간을 fixedSize() 자식에게 제안
2. fixedSize()가 Text에게 동일 크기 제안
3. Text가 "ideal size는 95x20, 더 작은 공간도 수용 가능" 응답
4. fixedSize()가 ideal size를 fixed size로 변환하여 반환
5. frame이 자신보다 큰 자식을 배치 (선택의 여지 없음)

```swift
// 파라미터 없이: 양축 고정
.fixedSize()

// 특정 축만 고정
.fixedSize(horizontal: true, vertical: false)   // 가로만 고정 (한 줄 유지)
.fixedSize(horizontal: false, vertical: true)   // 세로만 고정 (가로 압축 허용, 높이는 필요한 만큼)
```

### Image의 크기

```swift
// Image의 ideal size = 이미지 데이터의 원본 크기
// frame을 적용해도 이미지는 원본 크기로 overflow
Image("singapore")
    .frame(width: 300, height: 100)

// clipped()로 overflow 확인
Image("singapore")
    .frame(width: 300, height: 100)
    .clipped()  // 300x100 영역만 표시

// resizable()은 새로운 뷰를 생성하지 않음
// ideal size는 그대로 유지
Image("singapore")
    .resizable()
    .fixedSize()  // 다시 원본 크기로
    .frame(width: 300, height: 100)
```

- `resizable()`: 새 뷰 생성 없이 유연한 width/height 설정
- 기본 ideal size는 유지됨
- frame에 명시적으로 지정하지 않은 값은 이미지의 값을 상속

### 큰 이미지로 인한 레이아웃 문제

```swift
// 문제: 2000x1000 이미지가 VStack 너비를 화면 밖으로 확장
// Text도 화면 밖으로 밀려남
VStack(alignment: .leading) {
    Image("wide-image")
    Text("Hello, World! This is a layout test.")
}

// 해결: 완전히 유연한 frame으로 감싸기 -> Text는 그대로 아래에 밀려있는데??
VStack(alignment: .leading) {
    Image("wide-image")
        .frame(minWidth: 0, maxWidth: .infinity)  // minWidth: 0 필수
    Text("Hello, World! This is a layout test.")
}
```

- `minWidth` 생략 시: 이미지의 minimum width(원본 크기) 상속
- `minWidth: 0, maxWidth: .infinity` 지정해도 ideal size는 유지됨
- `fixedSize()` 적용 시 다시 원본 크기로 복원

### 두 뷰의 높이 동일하게 맞추기

```swift
// 문제: 서로 다른 컨텐츠 크기로 인해 높이가 다름
HStack {
    Text("Forecast")
        .padding()
        .background(.yellow)
    Text("The rain in Spain falls mainly on the Spaniards")
        .padding()
        .background(.cyan)
}

// 해결: maxHeight: .infinity + HStack에 fixedSize(vertical: true)
HStack {
    Text("Forecast")
        .padding()
        .frame(maxHeight: .infinity)  // 무한대 높이 허용
        .background(.yellow)
    Text("The rain in Spain falls mainly on the Spaniards")
        .padding()
        .frame(maxHeight: .infinity)  // 무한대 높이 허용
        .background(.cyan)
}
.fixedSize(horizontal: false, vertical: true)  // HStack의 ideal height로 고정
```

동작 원리:
1. 각 Text의 ideal height → background가 상속 → HStack의 ideal height = 자식들 중 최대값
2. `maxHeight: .infinity`로 Text들이 무한대까지 확장 가능
3. HStack에 `fixedSize(vertical: true)` 적용 → HStack의 ideal height(= 가장 긴 텍스트 높이)로 고정
4. 모든 자식이 동일한 높이로 확장

- 개별 Text에 `fixedSize()` 적용과 다름: 컨테이너의 ideal size를 상한으로 자식들이 확장
- Apple 문서: fixedSize()는 "부모가 제안한 뷰 크기에 대한 counter proposal 생성"

---

## Layout neutrality(레이아웃 중립성)

뷰가 6가지 크기 차원 중 일부에 대해 특별한 선호 없이 다른 뷰에 맞춰 적응하는 특성

```swift
// Color는 완전히 layout neutral
// 사용 가능한 모든 공간을 채움
struct ContentView: View {
    var body: some View {
        Color.red  // 전체 화면을 빨간색으로 채움
    }
}

// background로 사용 시: 자식(Text)의 크기에 맞춤
Text("Hello, World!")
    .background(.red)  // Text 크기만큼만 빨간색
```

- Color가 background로 사용될 때: 자식의 ideal/maximum size를 상속
- minimum size는 상속하지 않음 (Text 자체가 minimum에 대해 layout neutral)
- 결과: Text를 꼭 맞게 감싸되, 필요시 더 작게 압축 가능

| 뷰 | Layout Neutral 차원 |
|---|---|
| Text | minimum width, minimum height |
| Color | 모든 6가지 차원 (사용 맥락에 따라 적응) |
| background(.red) | minimum width, minimum height (자식으로부터 ideal/max 상속) |

### idealWidth/idealHeight와 Layout Neutral 조합

```swift
struct ContentView: View {
    var body: some View {
        Text("Hello, World!")
            .frame(idealWidth: 300, idealHeight: 200)
            .background(.red)
    }
}
```

**레이아웃 순서** (바깥에서 안쪽으로):

1. `background(.red)`: 전체 화면 공간을 가짐. Color.red는 완전히 layout neutral → 사용 가능한 모든 공간 채움 가능
2. `background` → `frame()`에 전체 화면 크기 제안. frame은 min/max width/height에 대해 layout neutral
3. `frame()` → `Text`에 전체 화면 크기 제안. Text는 min width/height에 대해 layout neutral, ideal/max에는 관심 있음
4. `Text`가 frame에 응답: 자신이 관심 있는 4가지 값 반환. **하지만** frame이 자체 ideal width/height(300x200)를 지정했으므로 Text의 ideal은 무시됨. frame의 max width/height는 layout neutral이라 Text의 max를 상속
5. `frame` → `background`에 최종 크기 반환: ideal size 300x200 + max size는 Text의 값(예: 95x20)
6. 결과: **95x20 영역만 빨간색으로 채워짐** (max size가 제한)

### 핵심 포인트

- 6가지 크기 값(min/ideal/max × width/height)이 **조합**되어 동작
- `idealWidth/idealHeight`만 지정 시: frame의 ideal은 설정되지만 **max는 자식으로부터 상속**
- 최종 크기는 min ≤ actual ≤ max 범위 내에서 결정
- 각 modifier가 어떤 값에 대해 layout neutral인지 파악하는 것이 중요

### nil을 사용한 동적 Layout Neutrality

6가지 크기 값은 모두 **optional**이며, `nil`을 전달하면 해당 차원에 대해 layout neutral이 된다:

```swift
struct ContentView: View {
    @State private var usesFixedSize = false

    var body: some View {
        VStack {
            Text("Hello, World!")
                .frame(width: usesFixedSize ? 300 : nil)  // nil = layout neutral
                .background(.red)

            Toggle("Fixed sizes", isOn: $usesFixedSize.animation())
        }
    }
}
```

**런타임 동작:**
- `usesFixedSize == true`: frame이 Text에 300pt 너비 제안
- `usesFixedSize == false`: frame이 VStack에서 받은 크기를 그대로 전달 (사실상 아무 역할 없음)

### 모든 차원이 Layout Neutral인 경우

`nil`로 모든 차원을 layout neutral로 만들 수 있지만, 모든 뷰는 최소한 **nominal ideal size**를 가진다. 이는 레이아웃이 무한히 확장되는 것을 방지한다.

### ScrollView 내부의 Layout Neutral 뷰

```swift
// Color.red는 무한히 확장될 수 없음 → nominal 10pt 높이로 제한
ScrollView {
    Color.red  // 10pt 높이의 얇은 빨간 줄만 표시됨
}
```

ScrollView는 자식에게 **무한한 공간**을 제안할 수 있다. 하지만 Color.red가 무한히 확장되면 의미 없는 레이아웃이 되므로, **nominal ideal size(10pt)** 가 적용된다.

```swift
// ❌ maxHeight만 지정: ideal height가 여전히 10pt
ScrollView {
    Color.red
        .frame(maxHeight: 400)  // 여전히 10pt 높이
}

// ❌ background로 확인: frame도 10pt
ScrollView {
    Color.red
        .frame(maxHeight: 400)
        .background(.blue)  // 파란색 안 보임 - frame도 10pt
}

// ✅ idealHeight 지정: 400pt로 확장
ScrollView {
    Color.red
        .frame(idealHeight: 400, maxHeight: 400)  // 400pt 높이로 확장
}
```

**핵심**:
- Color의 내부 max height는 무한대지만, frame의 400pt로 제한됨
- `idealHeight`를 지정해야 frame이 Color의 10pt ideal을 무시하고 400pt 사용
- `maxHeight`만으로는 ideal height를 변경할 수 없음


## Multiple frames

여러 SwiftUI modifier를 쌓아 흥미로운 효과를 만들 수 있다.

```swift
Text("Hello, World!")
    .frame(width: 200, height: 200)
    .background(.blue)
    .frame(width: 300, height: 300)
    .background(.red)
    .foregroundColor(.white)
// 결과: 빨간 300x300 박스 안에 파란 200x200 박스, 중앙에 텍스트
```

### Fixed Frame vs Flexible Frame

SwiftUI는 **fixed frame**과 **flexible frame**을 분리한다:
- 하나의 뷰는 고정된 width/height를 가지거나
- 유연한 차원(min/ideal/max)을 가질 수 있지만
- **둘 다 동시에 가질 수는 없다**

```swift
// ❌ 하나의 frame에서 fixed와 flexible 동시 사용 불가
.frame(width: 200, minWidth: 100, maxWidth: 300)  // 의미 없음

// ✅ 두 개의 frame으로 분리
.frame(minWidth: 100, maxWidth: 300)  // flexible frame
.frame(width: 200)                      // fixed frame

// ✅ 실용적 예제: Fixed Width + Flexible Height (macOS)
Text("Hello, World!")
    .frame(width: 250)      // 고정 너비 250pt
    .frame(minHeight: 400)  // 최소 높이 400pt
```

**중요한 원칙**: frame은 Text 자체를 유연하게 만드는 것이 아니라, **새 뷰로 감싸는 것**이다. Text의 bounds는 자연스러운 크기를 넘어 확장되지 않는다.

### 모순처럼 보이는 frame 조합

```swift
Text("Hello, World!")
    .frame(width: 250)
    .frame(minWidth: 400)
```

SwiftUI 관점에서 분석:
1. Text의 ideal size = 텍스트 콘텐츠 크기
2. 첫 번째 frame: 250pt 너비의 새 뷰
3. 두 번째 frame: 최소 400pt 너비의 새 뷰

**결과**: 400pt 외부 frame 안에 250pt 내부 frame이 **중앙 정렬**됨.

background로 시각화:
```swift
Text("Hello, World!")
    .background(.blue)      // Text 크기
    .frame(width: 250)
    .background(.red)       // 250pt
    .frame(minWidth: 400)
    .background(.yellow)    // 400pt
// 시각적 결과: 노란색(400pt) > 빨간색(250pt) > 파란색(Text)
```

---

## Inside TupleView

SwiftUI가 여러 뷰를 어떻게 처리하는지 이해하기.

### TupleView란?

```swift
VStack {
    Text("Hello")
    Text("World")
}
.onTapGesture {
    print(type(of: self.body))
}
// 출력: ModifiedContent<VStack<TupleView<(Text, Text)>>, AddGestureModifier<_EndedGesture<TapGesture>>>
```

**핵심**: `TupleView<(Text, Text)>` - SwiftUI가 여러 뷰를 인코딩하는 방식

- `TupleView`는 underscored가 아닌 **public API**
- 다른 뷰들을 튜플로 감싸는 특수한 뷰 타입

### 10개 뷰 제한의 원인

Xcode의 Open Quickly(Shift+Cmd+O)에서 `TupleView`를 검색하면:

```swift
public static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7, C8, C9>(
    _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4,
    _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9
) -> TupleView<(C0, C1, C2, C3, C4, C5, C6, C7, C8, C9)>
where C0: View, C1: View, C2: View, C3: View, C4: View,
      C5: View, C6: View, C7: View, C8: View, C9: View
```

- 10개 뷰를 받는 generic result builder 메서드
- 9개, 8개 등의 버전도 존재하지만 **11개 버전은 없음**
- 소프트웨어 제한이 아닌 **실용적 선택** (SwiftUI 팀이 적절한 선에서 끊음)

### 10개 제한 우회하기

**방법 1: ViewBuilder 확장**

```swift
extension ViewBuilder {
    public static func buildBlock<C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10>(
        _ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4,
        _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9, _ c10: C10
    ) -> TupleView<(C0, C1, C2, C3, C4, C5, C6, C7, C8, C9, C10)>
    where C0: View, C1: View, C2: View, C3: View, C4: View,
          C5: View, C6: View, C7: View, C8: View, C9: View, C10: View {
        TupleView((c0, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10))
    }
}
```

**방법 2: TupleView 직접 생성**

```swift
TupleView((
    Text("1"),
    Text("2"),
    Text("3"),
    // ... 원하는 만큼 추가 가능
    Text("15")
))
```

> **Tip**: 이중 괄호 - 첫 번째는 initializer 호출, 두 번째는 튜플 생성. 각 뷰는 쉼표로 구분.

### SwiftUI 내부 구현 확인

SwiftUI의 swiftinterface 파일에서 실제 구현 확인 가능:

```bash
xed /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule/x86_64-apple-ios-simulator.swiftinterface
```

`extension SwiftUI.ViewBuilder {` 검색 시:

```swift
extension SwiftUI.ViewBuilder {
    @_alwaysEmitIntoClient public static func buildBlock<C0, C1>(
        _ c0: C0, _ c1: C1
    ) -> SwiftUI.TupleView<(C0, C1)> where C0: SwiftUI.View, C1: SwiftUI.View {
        return .init((c0, c1))
    }
}
```

- 우리가 작성한 코드와 동일한 방식
- `.init(())`는 반환 타입을 알기에 가능한 축약형

### 중첩된 TupleView

SwiftUI는 TupleView의 구조에 상관없이 동작:

- TupleView 안에 TupleView 안에 TupleView가 있어도 **단일 컬렉션으로 평탄화**
- 런타임 reflection으로 타입 메타데이터를 검사해 자식 수 파악

### Partial Block Result Builders

Swift의 partial block result builder로 10개 제한 영구 해제:

```swift
extension ViewBuilder {
    static func buildPartialBlock<Content>(
        first content: Content
    ) -> Content where Content: View {
        content
    }

    static func buildPartialBlock<C0, C1>(
        accumulated: C0, next: C1
    ) -> TupleView<(C0, C1)> where C0: View, C1: View {
        TupleView((accumulated, next))
    }
}
```

**동작 원리**:
1. 첫 번째 뷰: `buildPartialBlock(first:)`로 처리
2. 이후 뷰들: `buildPartialBlock(accumulated:next:)`로 누적
3. 결과: 중첩된 `TupleView<(TupleView<(...)>, NextView)>` 구조

- 여러 TupleView가 중첩되지만 SwiftUI는 신경 쓰지 않음
- 기본 SwiftUI와 동일한 평탄 구조를 원하면 C0~C9까지 처리하는 `buildPartialBlock()` 추가 필요

---

## Result Builder 이해하기

SwiftUI의 선언적 문법을 가능하게 하는 Swift의 핵심 기능.

### Result Builder란?

```swift
// 일반적인 Swift 코드
let views = [Text("Hello"), Text("World")]

// Result Builder를 사용한 SwiftUI 코드
VStack {
    Text("Hello")
    Text("World")
}
```

- **SE-0289**에서 도입된 Swift 기능
- 여러 표현식을 하나의 결과로 결합하는 DSL(Domain Specific Language) 생성
- `@ViewBuilder`, `@SceneBuilder`, `@CommandsBuilder` 등이 result builder

### @resultBuilder 기본 구조

```swift
@resultBuilder
struct SimpleBuilder {
    // 필수: 여러 컴포넌트를 하나로 결합
    static func buildBlock(_ components: String...) -> String {
        components.joined(separator: "\n")
    }
}

// 사용
@SimpleBuilder
func makeGreeting() -> String {
    "Hello"
    "World"
    "!"
}
// 결과: "Hello\nWorld\n!"
```

### ViewBuilder의 핵심 메서드들

```swift
@resultBuilder
struct ViewBuilder {
    // 1. 단일 뷰 처리
    static func buildBlock<Content>(_ content: Content) -> Content
        where Content: View

    // 2. 여러 뷰를 TupleView로 결합
    static func buildBlock<C0, C1>(_ c0: C0, _ c1: C1) -> TupleView<(C0, C1)>
        where C0: View, C1: View

    // 3. 조건부 뷰 (if-else)
    static func buildEither<TrueContent, FalseContent>(
        first component: TrueContent
    ) -> _ConditionalContent<TrueContent, FalseContent>

    static func buildEither<TrueContent, FalseContent>(
        second component: FalseContent
    ) -> _ConditionalContent<TrueContent, FalseContent>

    // 4. 옵셔널 뷰 (if without else)
    static func buildOptional<Content>(_ component: Content?) -> Content?
        where Content: View

    // 5. 빈 뷰
    static func buildBlock() -> EmptyView
}
```

### 조건문이 변환되는 방식

```swift
// 작성한 코드
VStack {
    if isLoggedIn {
        Text("Welcome")
    } else {
        Text("Please log in")
    }
}

// 컴파일러가 변환한 코드
VStack {
    ViewBuilder.buildEither(
        first: Text("Welcome"),    // isLoggedIn == true
        second: Text("Please log in")  // isLoggedIn == false
    )
}
```

**결과 타입**: `_ConditionalContent<Text, Text>`

- 두 분기의 타입이 달라도 됨 (`_ConditionalContent<Text, Image>`)
- 런타임에 조건에 따라 적절한 뷰 표시

### 반복문 처리: buildArray

```swift
// 작성한 코드
VStack {
    ForEach(items) { item in
        Text(item.name)
    }
}

// ForEach는 특별한 뷰 타입
// 내부적으로 buildArray 사용 가능
static func buildArray(_ components: [Content]) -> TupleView<[Content]>
```

### buildExpression: 타입 변환

```swift
@resultBuilder
struct AttributedStringBuilder {
    static func buildBlock(_ components: AttributedString...) -> AttributedString {
        components.reduce(AttributedString(), +)
    }

    // String을 자동으로 AttributedString으로 변환
    static func buildExpression(_ expression: String) -> AttributedString {
        AttributedString(expression)
    }

    static func buildExpression(_ expression: AttributedString) -> AttributedString {
        expression
    }
}

// 사용: String과 AttributedString 혼용 가능
@AttributedStringBuilder
func makeText() -> AttributedString {
    "Plain text"           // String → AttributedString 자동 변환
    AttributedString("Styled")
}
```

### buildPartialBlock: 유연한 결합 (Swift 5.7+)

기존 `buildBlock`의 한계:
- 파라미터 수만큼 오버로드 필요 (2개용, 3개용, ... 10개용)

`buildPartialBlock`의 장점:
- 두 개의 메서드로 무제한 뷰 지원

```swift
extension ViewBuilder {
    // 첫 번째 요소 처리
    static func buildPartialBlock<Content>(
        first content: Content
    ) -> Content where Content: View {
        content
    }

    // 누적: 이전 결과 + 다음 요소
    static func buildPartialBlock<Accumulated, Next>(
        accumulated: Accumulated,
        next: Next
    ) -> TupleView<(Accumulated, Next)>
    where Accumulated: View, Next: View {
        TupleView((accumulated, next))
    }
}
```

**변환 과정** (뷰 4개 예시):

```swift
// 원본
VStack {
    Text("A")
    Text("B")
    Text("C")
    Text("D")
}

// 변환 단계
let step1 = buildPartialBlock(first: Text("A"))           // Text
let step2 = buildPartialBlock(accumulated: step1, next: Text("B"))  // TupleView<(Text, Text)>
let step3 = buildPartialBlock(accumulated: step2, next: Text("C"))  // TupleView<(TupleView<...>, Text)>
let step4 = buildPartialBlock(accumulated: step3, next: Text("D"))  // TupleView<(TupleView<...>, Text)>
```

### Result Builder 메서드 우선순위

컴파일러가 메서드를 선택하는 순서:

1. `buildPartialBlock(first:)` / `buildPartialBlock(accumulated:next:)` (있으면 우선)
2. `buildBlock(_:_:...)` (없으면 fallback)
3. `buildExpression(_:)` (각 표현식 변환 시)
4. `buildOptional(_:)` / `buildEither(first:)` / `buildEither(second:)` (조건문)
5. `buildArray(_:)` (for-in 루프)
6. `buildFinalResult(_:)` (최종 결과 변환)

### 커스텀 Result Builder 예제

```swift
@resultBuilder
struct HTMLBuilder {
    static func buildBlock(_ components: String...) -> String {
        components.joined()
    }

    static func buildOptional(_ component: String?) -> String {
        component ?? ""
    }

    static func buildEither(first component: String) -> String {
        component
    }

    static func buildEither(second component: String) -> String {
        component
    }

    static func buildArray(_ components: [String]) -> String {
        components.joined()
    }
}

func div(@HTMLBuilder content: () -> String) -> String {
    "<div>\(content())</div>"
}

func p(_ text: String) -> String {
    "<p>\(text)</p>"
}

// 사용
let html = div {
    p("Hello")
    if showSubtitle {
        p("Subtitle")
    }
    for item in items {
        p(item)
    }
}
```

### 핵심 정리

| 메서드 | 용도 |
|--------|------|
| `buildBlock` | 여러 표현식을 하나로 결합 |
| `buildPartialBlock` | 점진적 결합 (무제한 요소) |
| `buildExpression` | 개별 표현식 타입 변환 |
| `buildOptional` | `if` (else 없음) 처리 |
| `buildEither` | `if-else` / `switch` 처리 |
| `buildArray` | `for-in` 루프 처리 |
| `buildFinalResult` | 최종 결과 변환 |

- SwiftUI의 선언적 문법은 모두 result builder가 컴파일 타임에 변환한 결과
- 각 뷰의 정확한 타입이 컴파일 타임에 결정됨 → 런타임 오버헤드 없음

---

## Understanding Identity

SwiftUI의 모든 뷰는 고유하게 식별 가능해야 한다. SwiftUI는 항상 어떤 뷰가 어디에 있는지 정확히 알아야 한다.

---

### 1. Identity의 두 가지 형태

| 종류 | 설명 | 사용 시점 |
|------|------|----------|
| **Explicit Identity** | 개발자가 직접 뷰의 identity 지정 | 동적 데이터(배열 순회), 특정 뷰 참조(스크롤 위치) |
| **Structural Identity** | SwiftUI가 코드 위치 기반으로 암묵적 생성 | 대부분의 정적 뷰 |

---

### 2. 타입 시스템을 통한 Identity 구현

#### 2.1 Tree Diffing에 대한 오해

| 오해 | 실제 |
|------|------|
| "SwiftUI는 뷰 계층 변경 시 tree diffing으로 변경사항을 파악한다" | Tree diffing은 **발생하지 않는다** |

- 컴파일러가 모든 서브뷰, modifier, 조건문, 루프를 **타입에 직접 인코딩**
- Identity 덕분에 런타임 비교 불필요

#### 2.2 조건문의 타입 인코딩

```swift
VStack {
    if Bool.random() {
        Text("Hello")
    } else {
        Text("Goodbye")
    }
}
.onTapGesture {
    print(type(of: self.body))
}
// 출력: ModifiedContent<VStack<_ConditionalContent<Text, Text>>, AddGestureModifier<...>>
```

**타입 분석**:
- 최상위: `ModifiedContent` (VStack + AddGestureModifier)
- VStack 내부: `_ConditionalContent<Text, Text>`

**`_ConditionalContent`의 특징**:
- if문이 타입 시스템에 인코딩된 것
- underscored (private API)
- `ViewBuilder`의 `buildEither`가 생성
- 조건 변경 시 view diffing 없이 TrueContent ↔ FalseContent 전환

#### 2.3 Switch문의 이진 트리 변환

```swift
enum ViewState { case a, b, c, d, e, f }

@ViewBuilder var state: some View {
    switch loadState {
    case .a: Text("a")
    case .b: Image(systemName: "plus")
    case .c: Circle()
    case .d: Rectangle()
    case .e: Capsule()
    case .f: RoundedRectangle(cornerRadius: 25)
    }
}

// 생성되는 타입:
// _ConditionalContent<
//     _ConditionalContent<
//         _ConditionalContent<Text, Image>,
//         _ConditionalContent<Circle, Rectangle>
//     >,
//     _ConditionalContent<Capsule, RoundedRectangle>
// >
```

**이진 트리 탐색 경로**:

| case | 뷰 | 경로 |
|------|-----|------|
| `.a` | Text | true → true → true |
| `.b` | Image | true → true → false |
| `.c` | Circle | true → false → true |
| `.d` | Rectangle | true → false → false |
| `.e` | Capsule | false → true |
| `.f` | RoundedRectangle | false → false |

#### 2.4 로직의 타입 변환이 미치는 영향

1. **정적 표현**: SwiftUI는 복잡한 뷰 레이아웃을 **컴파일 타임**에 표현해야 함
2. **실제 타입**: 복잡한 뷰 레이아웃이 body의 **실제 underlying 타입**이 됨

---

### 3. some View의 역할

```swift
var body: some View {
    // 복잡한 뷰 계층...
}
```

**Opaque Return Type (`some View`)의 의미**:
- 반환 타입을 명시적으로 작성하지 않아도 됨
- 단, Swift에게 타입 정보를 **숨기는 것이 아님**

| 반환 타입 | 의미 | SwiftUI 호환성 |
|----------|------|---------------|
| `View` (프로토콜) | 타입 정보를 숨김 | ❌ 사용 불가 |
| `some View` (opaque) | 구체적 타입 존재, 명시만 생략 | ✅ 필수 |

- SwiftUI는 **타입과 위치 기반**으로 모든 뷰를 식별
- 타입 정보가 숨겨지면 효율적인 레이아웃 업데이트 불가능

---

### 4. @ViewBuilder와 구조적 Identity

View 프로토콜의 정의:

```swift
@ViewBuilder var body: Self.Body { get }
```

- `body` 프로퍼티에 `@ViewBuilder`가 **자동 적용**됨
- Result builder가 레이아웃을 `TupleView`, `ModifiedContent`, `_ConditionalContent` 등으로 변환
- VStack 내용물도 조건문과 루프를 포함해 **컴파일 타임에 타입이 확정**됨
- 이로 인해 모든 뷰가 **명확한 structural identity**를 가짐

---

### 5. Identity와 뷰의 수명

**핵심 원칙**: 뷰의 identity가 변경되면 뷰가 **소멸**된다

| 상황 | 결과 |
|------|------|
| Identity 유지 | 뷰와 상태 보존 |
| Identity 변경 | 뷰 소멸, 상태 초기화 |

**성능 및 상태 영향**:
- 플랫폼 뷰(UIView/NSView) 폐기 → **성능 저하**
- 뷰에 저장된 **모든 데이터 소멸** (@State 등)

---

### 6. 조건문과 Identity 문제

#### 6.1 문제의 원인

`_ConditionalContent`는 true/false 콘텐츠에 대해 **제네릭**이다:

```swift
_ConditionalContent<TrueContent, FalseContent>
```

조건이 바뀔 때마다:
1. 현재 뷰의 플랫폼 뷰가 **폐기**됨
2. 현재 뷰의 **상태가 소멸**됨
3. 새 뷰가 **처음부터 생성**됨

#### 6.2 문제 예시

```swift
struct ExampleView: View {
    @State private var counter = 0

    var body: some View {
        Button("Tap Count: \(counter)") {
            counter += 1
        }
    }
}

struct ContentView: View {
    @State private var scaleUp = false

    var body: some View {
        VStack {
            if scaleUp {
                ExampleView()
                    .scaleEffect(2)
            } else {
                ExampleView()
            }
            Toggle("Scale Up", isOn: $scaleUp.animation())
        }
        .padding()
    }
}
```

**발생하는 문제**:

| 현상 | 원인 |
|------|------|
| 크기 변경이 **페이드 전환**으로 보임 | 애니메이션이 아닌 **뷰 교체** 발생 |
| 탭 카운트가 **0으로 초기화** | @State가 뷰와 함께 **소멸** |

**문제 흐름**:
```
_ConditionalContent 전환 발생
    ↓
SwiftUI가 원래 ExampleView를 "소멸"로 판단
    ↓
플랫폼 렌더링(UIView/NSView) 폐기
    ↓
모든 저장 데이터(@State) 제거
    ↓
새로운 ExampleView 생성 (처음부터)
```

---

### 7. 해결 시도와 한계

#### 7.1 Modifier 제거 - 효과 없음

문제는 modifier가 아니라 **`if` 분기 자체**에 있다:

```swift
// 여전히 문제 발생
if scaleUp {
    ExampleView(scale: 2)
} else {
    ExampleView(scale: 1)
}
```

#### 7.2 `.id()` modifier - 효과 없음

```swift
if scaleUp {
    ExampleView(scale: 2).id("Example")
} else {
    ExampleView(scale: 1).id("Example")
}
```

**이유**: `.id()`는 structural identity **내부에서** 적용됨

```
_ConditionalContent<
    ModifiedContent<ExampleView, _IdentifiedModifier<String>>,  // TrueContent
    ModifiedContent<ExampleView, _IdentifiedModifier<String>>   // FalseContent
>
```

Explicit identity는 structural identity를 **대체하지 않고** 그 위에 추가될 뿐이다.

#### 7.3 별도 computed property - 해결

`@ViewBuilder` 없이 **명시적 return** 사용:

```swift
var exampleView: some View {
    if scaleUp {
        return ExampleView(scale: 2)
    } else {
        return ExampleView(scale: 1)
    }
}
```

| 항목 | 결과 |
|------|------|
| 애니메이션 | ✅ 부드러운 스케일 전환 |
| @State 유지 | ✅ 보존됨 |

**작동 원리**: `@ViewBuilder`가 없으면 `_ConditionalContent`가 생성되지 않아 **동일한 structural identity**를 유지한다.

---

### 8. 권장 해결책: 삼항 연산자 사용

```swift
struct ContentView: View {
    @State private var scaleUp = false

    var body: some View {
        VStack {
            ExampleView(scale: scaleUp ? 2 : 1)
            Toggle("Scale Up", isOn: $scaleUp.animation())
        }
        .padding()
    }
}
```

| 항목 | 결과 |
|------|------|
| 애니메이션 | ✅ 부드러운 스케일 전환 |
| @State 유지 | ✅ 보존됨 |

**작동 원리**:
- `scaleUp` 값에 관계없이 VStack의 첫 번째 자식은 항상 `ExampleView`
- **동일한 structural identity** 유지
- `if` 분기가 없으므로 `_ConditionalContent` 생성 안 됨

---

### 9. Modifier와 Identity 문제

#### 9.1 조건부 modifier 문제

```swift
// 문제 발생
if isNewMessage {
    Text("Message title here").bold()
} else {
    Text("Message title here")
}
```

#### 9.2 해결책

**iOS 16+: Boolean 파라미터**
```swift
Text("Message title here").bold(isNewMessage)
```

**iOS 15 이하: fontWeight() 사용**
```swift
Text("Message title here").fontWeight(isNewMessage ? .bold : .regular)
// 또는
Text("Message title here").fontWeight(isNewMessage ? .bold : nil)
```

---

### 10. 커스텀 조건부 Modifier 구현

#### 10.1 hidden() modifier의 한계

`hidden()`은 파라미터를 받지 않아 `if` 분기가 불가피:

```swift
// 문제 발생
if shouldHide {
    ExampleView().hidden()
} else {
    ExampleView()
}
```

#### 10.2 잘못된 접근: @ViewBuilder 사용

```swift
extension View {
    @ViewBuilder func hidden(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }
}
```

**문제**: `@ViewBuilder` → `_ConditionalContent` 생성 → identity 문제 재발생

#### 10.3 올바른 접근: 삼항 연산자 사용

```swift
extension View {
    func hidden(_ hidden: Bool) -> some View {
        self.opacity(hidden ? 0 : 1)
    }
}
```

**결과**: `hidden` 값에 관계없이 **동일한 identity 유지**

---

### 11. 핵심 정리

#### Identity 기본 개념
- 모든 뷰는 identity를 가짐 (explicit 또는 structural)
- 조건문/switch문은 `_ConditionalContent`로 타입에 인코딩
- Tree diffing 없이 타입 기반으로 뷰 전환
- `some View`는 타입을 숨기지 않고 명시만 생략

#### Identity 변경의 영향
- 뷰 소멸 → 플랫폼 뷰 폐기 (성능 저하)
- @State 등 모든 저장 데이터 소멸
- 부드러운 애니메이션 대신 페이드 전환

#### Identity 유지 방법
| 방법 | 설명 |
|------|------|
| 삼항 연산자 | `condition ? value1 : value2` |
| Boolean 파라미터 modifier | `.bold(isActive)` (iOS 16+) |
| 값 기반 modifier | `.fontWeight(condition ? .bold : nil)` |

#### Identity 관리의 이점

| 이점 | 설명 |
|------|------|
| **성능 향상** | 뷰 재생성 비용 절감 |
| **상태 보존** | @State 등 프로그램 상태 유지 |
| **애니메이션 개선** | 페이드 전환 대신 부드러운 애니메이션 |

**결론**: 약간의 추가 작업이 필요하더라도 **identity를 올바르게 사용**하면 성능, 상태 보존, 애니메이션 모두 개선된다.

---

### 12. 의도적으로 Identity 폐기하기

때로는 SwiftUI에게 두 뷰 인스턴스가 **다르다**고 명시적으로 알려야 할 때가 있다.

#### 12.1 문제 상황: List 애니메이션

```swift
struct ContentView: View {
    @State private var items = Array(1...20)

    var body: some View {
        VStack(spacing: 0) {
            List(items, id: \.self) {
                Text("Item \($0)")
            }

            Button("Shuffle") {
                withAnimation {
                    items.shuffle()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(5)
        }
    }
}
```

**문제**: `withAnimation()`으로 리스트를 섞으면 모든 행이 슬라이드하는 기본 애니메이션이 적용되어 **시각적으로 어지럽다**.

#### 12.2 해결책: `.id(UUID())`로 Identity 폐기

```swift
List(items, id: \.self) {
    Text("Item \($0)")
}
.id(UUID())
```

**작동 원리**:
- 뷰가 평가될 때마다 **새로운 UUID** 생성
- SwiftUI는 같은 structural 위치지만 **다른 explicit identity**로 인식
- 기존 리스트 제거 → 새 리스트 삽입 (페이드 전환)

#### 12.3 커스텀 애니메이션 적용

Identity를 폐기하면 **애니메이션을 완전히 제어**할 수 있다:

**애니메이션 속도 조절**:
```swift
Button("Shuffle") {
    withAnimation(.easeInOut(duration: 1)) {
        items.shuffle()
    }
}
```

**커스텀 전환 효과**:
```swift
List(items, id: \.self) {
    Text("Item \($0)")
}
.id(UUID())
.transition(.asymmetric(
    insertion: .move(edge: .trailing),
    removal: .move(edge: .leading)
))
```

#### 12.4 활용 예시: 랜덤 아이콘 생성기

```swift
struct ContentView: View {
    let colors: [Color] = [.blue, .cyan, .gray, .green, .indigo, .mint, .orange, .pink, .purple, .red]
    let symbols = ["run", "archery", "basketball", "bowling", "dance", "golf", "hiking", "jumprope", "rugby", "tennis", "volleyball", "yoga"]
    @State private var id = UUID()

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(colors.randomElement()!)
                    .padding()

                Image(systemName: "figure.\(symbols.randomElement()!)")
                    .font(.system(size: 144))
                    .foregroundColor(.white)
            }
            .transition(.slide)
            .id(id)

            Button("Change") {
                withAnimation(.easeInOut(duration: 1)) {
                    id = UUID()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
    }
}
```

**효과**: `id` 값만 변경하면 새로운 랜덤 색상/심볼이 **애니메이션과 함께** 표시된다.

#### 12.5 주의사항

| 장점 | 단점 |
|------|------|
| 애니메이션 완전 제어 | 저장 데이터(@State 등) 소멸 |
| 커스텀 전환 효과 적용 | 플랫폼 뷰(UIView/NSView) 재생성 |
| 간단한 구현 | 복잡한 뷰(List 등)에서 성능 비용 |

**결론**: Identity 폐기는 **의도적인 뷰 교체**가 필요할 때 유용하지만, 성능 비용을 고려해야 한다.

---

## Optional Views, Gestures 등

SwiftUI에서 Optional은 핵심적인 역할을 한다.

### Optional Background

**일반적인 background**:
```swift
Text("Hello")
    .background(Color.blue)
    .onTapGesture {
        print(type(of: self.body))
    }
// 타입: _BackgroundStyleModifier<Color>
```

**Optional background**:
```swift
.background(Bool.random() ? Color.blue : nil)
// 타입: _BackgroundModifier<Optional<Color>>
```

배경이 `Color?`가 되어 조건에 따라 **있을 수도, 없을 수도** 있다.

### Optional의 조건부 프로토콜 준수

SwiftUI는 `Optional`을 확장하여 **조건부 프로토콜 준수**를 구현한다:

```swift
extension Optional : Commands where Wrapped : Commands
extension Optional : Gesture where Wrapped : Gesture
extension Optional : View where Wrapped : View
```

**의미**: `Optional`이 감싸는 타입이 해당 프로토콜을 준수하면, `Optional` 자체도 그 프로토콜을 준수한다.

### 활용 사례

| 활용 | 설명 |
|------|------|
| 조건부 background/overlay | 상태에 따라 배경/오버레이 적용 여부 결정 |
| 조건부 gesture | 상태가 true면 제스처 적용, false면 `nil`로 제거 |

**예시: 조건부 제스처**
```swift
.gesture(isEnabled ? someTapGesture : nil)
```

이를 통해 **프로그램 상태에 따라** background, overlay, gesture 등을 유연하게 적용하거나 제거할 수 있다.
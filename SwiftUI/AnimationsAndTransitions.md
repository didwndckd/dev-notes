# Animations and Transitions

## Animating the unanimatable

SwiftUI에서 거의 모든 것을 애니메이션할 수 있지만, 일부 속성은 약간의 추가 작업이 필요하다.

---

### 애니메이션의 두 가지 방식

| 방식 | 설명 | 예시 |
|------|------|------|
| **명시적 애니메이션** | `withAnimation` 블록으로 상태 변경을 감싸서 애니메이션 트리거 | `withAnimation { scale += 1 }` |
| **암묵적 애니메이션** | `.animation()` modifier로 값 변경 시 자동 애니메이션 | `.animation(.default, value: scale)` |

**명시적 애니메이션**:
```swift
struct ContentView: View {
    @State private var scale = 1.0

    var body: some View {
        Text("Hello, World!")
            .scaleEffect(scale)
            .onTapGesture {
                withAnimation {
                    scale += 1
                }
            }
    }
}
```

**암묵적 애니메이션**:
```swift
struct ContentView: View {
    @State private var scale = 1.0

    var body: some View {
        Text("Hello, World!")
            .scaleEffect(scale)
            .onTapGesture {
                scale += 1
            }
            .animation(.default, value: scale)
    }
}
```

> **Tip**: iOS 15부터 `value` 파라미터 없이 `.animation()` 사용은 deprecated. 모든 변경에 애니메이션이 적용되어 의도치 않은 결과 발생 가능.

---

### 애니메이션되지 않는 속성: zIndex

`zIndex`는 기본적으로 애니메이션되지 않는다:

```swift
struct ContentView: View {
    @State private var redAtFront = false
    let colors: [Color] = [.blue, .green, .orange, .purple, .mint]

    var body: some View {
        VStack {
            Button("Toggle zIndex") {
                withAnimation(.linear(duration: 1)) {
                    redAtFront.toggle()
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(.red)
                    .zIndex(redAtFront ? 6 : 0)  // ❌ 애니메이션 안 됨

                ForEach(0..<5) { i in
                    RoundedRectangle(cornerRadius: 25)
                        .fill(colors[i])
                        .offset(x: Double(i + 1) * 20, y: Double(i + 1) * 20)
                        .zIndex(Double(i))
                }
            }
            .frame(width: 200, height: 200)
        }
    }
}
```

**문제**: `withAnimation`을 사용해도 빨간 박스가 즉시 앞으로 점프한다.

---

### 해결책: Animatable 프로토콜

`ViewModifier`와 `Animatable` 프로토콜을 결합하여 애니메이션되지 않는 속성을 애니메이션 가능하게 만든다.

#### 1. AnimatableZIndexModifier 생성

```swift
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
```

> **Tip**: modifier 이름이 "animatable"(애니메이션 가능)이지 "animated"(애니메이션된)가 아님. 실제 애니메이션 여부는 사용 방식에 따라 결정됨.

#### 2. View Extension 추가

```swift
extension View {
    func animatableZIndex(_ index: Double) -> some View {
        self.modifier(AnimatableZIndexModifier(index: index))
    }
}
```

#### 3. 사용

```swift
RoundedRectangle(cornerRadius: 25)
    .fill(.red)
    .animatableZIndex(redAtFront ? 6 : 0)  // ✅ 애니메이션 됨
```

---

### Animatable 프로토콜의 동작 원리

| 구성 요소 | 역할 |
|----------|------|
| `animatableData` | 애니메이션 중 보간된 값을 읽고 쓰는 프로퍼티 |
| `get` | 현재 애니메이션 값 반환 |
| `set` | SwiftUI가 보간된 값 전달 (0.1, 1.35, 4.825, ...) |

**동작 흐름**:
```
0 → 6 애니메이션 요청
    ↓
SwiftUI가 타이밍 곡선에 따라 보간값 계산
    ↓
animatableData setter로 값 전달 (0.1, 1.35, 4.825, ...)
    ↓
전달받은 값을 zIndex에 적용
    ↓
부드러운 Z축 애니메이션 완성
```

**디버깅**:
```swift
var animatableData: Double {
    get { index }
    set {
        print(newValue)  // 보간값 확인
        index = newValue
    }
}
// 출력: 0.0, 0.1, 0.35, 1.2, 2.5, 4.1, 5.4, 5.9, 6.0, ...
```

---

### iOS 15.6 이하 호환성

#### Font Size 애니메이션

iOS 16 이전 버전에서는 시스템 폰트 크기 애니메이션이 기본 지원되지 않았다. `Animatable` 프로토콜로 해결 가능:

```swift
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
```

**사용 예시**:
```swift
struct ContentView: View {
    @State private var scaleUp = false

    var body: some View {
        Text("Hello, World!")
            .animatableFont(size: scaleUp ? 56 : 24)
            .onTapGesture {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                    scaleUp.toggle()
                }
            }
    }
}
```

> **주의**: 애니메이션 중 매 프레임마다 새로운 크기의 시스템 폰트를 생성한다. 효과는 훌륭하지만 과도하게 사용하면 성능에 영향을 줄 수 있다. Apple의 iOS 16+ 구현이 더 최적화되어 있을 가능성이 높다.

#### foregroundColor 애니메이션

`foregroundColor()`는 iOS 15.6 이하에서 애니메이션되지 않는다:

```swift
// ❌ iOS 15.6 이하에서 작동 안 함
struct ContentView: View {
    @State private var isRed = false

    var body: some View {
        Text("Hello, World!")
            .foregroundColor(isRed ? .red : .blue)
            .font(.largeTitle.bold())
            .onTapGesture {
                withAnimation {
                    isRed.toggle()
                }
            }
    }
}
```

색상 애니메이션을 `Animatable`로 구현하려면 before/after 색상을 저장하고 RGBA 값을 수동으로 보간해야 해서 복잡하다.

**해결책: colorMultiply() 활용**

`colorMultiply()`는 애니메이션이 가능하다. 원본 색상과 다른 색상의 RGBA 값을 각각 곱한다.

**원리**: 흰색(1, 1, 1, 1)에 어떤 색상을 곱하면 그 색상 그대로 반환된다.

```swift
// ✅ iOS 15.6 이하에서도 작동
Text("Hello, World!")
    .foregroundColor(.white)
    .colorMultiply(isRed ? .red : .blue)
```

**Extension으로 정리**:

```swift
extension View {
    func animatableForegroundColor(_ color: Color) -> some View {
        self
            .foregroundColor(.white)
            .colorMultiply(color)
    }
}
```

#### iOS 버전별 지원 현황

| 속성 | iOS 16+ | iOS 15.6 이하 |
|------|---------|--------------|
| Font Size | 기본 지원 | `Animatable` 필요 |
| foregroundColor | 기본 지원 | `colorMultiply()` 우회 |
| zIndex | ❌ | `Animatable` 필요 |

---

### Creating animated views

`Animatable` 프로토콜은 `ViewModifier`에만 제한되지 않는다. 일반 `View`에서도 동일하게 작동한다.

#### 예시 1: CountingText

숫자가 애니메이션되며 변하는 텍스트:

```swift
struct CountingText: View, Animatable {
    var value: Double
    var fractionLength = 8

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        Text(value.formatted(.number.precision(.fractionLength(fractionLength))))
    }
}

// 사용
struct ContentView: View {
    @State private var value = 0.0

    var body: some View {
        CountingText(value: value)
            .onTapGesture {
                withAnimation(.linear) {
                    value = Double.random(in: 1...1000)
                }
            }
    }
}
```

**핵심**: `Animatable`은 보간된 값을 전달할 뿐, 그 값을 어떻게 사용할지는 개발자가 결정한다.

#### 예시 2: TypewriterText

글자가 하나씩 나타나는 타이프라이터 효과:

```swift
struct TypewriterText: View, Animatable {
    var string: String
    var count = 0

    var animatableData: Double {
        get { Double(count) }
        set { count = Int(max(0, newValue)) }
    }

    var body: some View {
        let stringToShow = String(string.prefix(count))
        Text(stringToShow)
    }
}
```

**레이아웃 개선**: 텍스트 공간을 미리 확보하려면 hidden된 전체 텍스트를 사용:

```swift
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
```

**사용 예시**:

```swift
struct ContentView: View {
    @State private var value = 0
    let message = "This is a very long piece of text that appears letter by letter."

    var body: some View {
        VStack {
            TypewriterText(string: message, count: value)
                .frame(width: 300, alignment: .leading)

            Button("Type!") {
                withAnimation(.linear(duration: 2)) {
                    value = message.count
                }
            }

            Button("Reset") {
                value = 0
            }
        }
    }
}
```

#### 접근성 고려

VoiceOver 사용자나 애니메이션 줄이기를 설정한 사용자를 위한 대응:

```swift
struct TypewriterText: View, Animatable {
    @Environment(\.accessibilityVoiceOverEnabled) var accessibilityVoiceOverEnabled
    @Environment(\.accessibilityReduceMotion) var accessibilityReduceMotion

    var string: String
    var count = 0

    var animatableData: Double {
        get { Double(count) }
        set { count = Int(max(0, newValue)) }
    }

    var body: some View {
        if accessibilityVoiceOverEnabled || accessibilityReduceMotion {
            Text(string)  // 애니메이션 없이 전체 텍스트 표시
        } else {
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
}
```

| 환경 변수 | 용도 |
|----------|------|
| `accessibilityVoiceOverEnabled` | VoiceOver 활성화 여부 |
| `accessibilityReduceMotion` | 동작 줄이기 설정 여부 |

---

### 핵심 정리

| 항목 | 설명 |
|------|------|
| **Animatable 프로토콜** | 보간된 값을 시간에 따라 읽고 쓸 수 있게 해줌 |
| **animatableData** | 애니메이션 값을 처리하는 핵심 프로퍼티 |
| **적용 범위** | zIndex, font size 등 기본적으로 애니메이션되지 않는 속성에 사용 |
| **작동 원리** | 단순히 보간값을 전달할 뿐, 실제 처리는 개발자가 결정 |

**결론**: `Animatable` 프로토콜을 사용하면 SwiftUI에서 거의 모든 속성을 애니메이션할 수 있다. 마법처럼 보이지만 내부적으로는 매우 단순한 구조다.

---

## Custom timing curves

SwiftUI의 내장 타이밍 곡선(linear, easeIn, easeOut 등) 외에 커스텀 cubic Bézier 곡선을 만들 수 있다.

### 기본 구조

Apple 스타일에 맞게 property와 method 두 가지 버전을 제공:

```swift
extension Animation {
    // property 버전
    static var edgeBounce: Animation {
        Animation.timingCurve(0, 1, 1, 0)
    }

    // method 버전 (duration 지정 가능)
    static func edgeBounce(duration: TimeInterval = 0.2) -> Animation {
        Animation.timingCurve(0, 1, 1, 0, duration: duration)
    }
}
```

**사용**:
```swift
Text("Hello, world!")
    .offset(y: offset)
    .animation(.edgeBounce(duration: 2).repeatForever(autoreverses: true), value: offset)
```

---

### 예시: Ease In Out Back

시작과 끝에서 반대 방향으로 살짝 움직이는 효과 (App Store Today 탭의 카드 애니메이션과 유사):

```swift
extension Animation {
    static var easeInOutBack: Animation {
        Animation.timingCurve(0.5, -0.5, 0.5, 1.5)
    }

    static func easeInOutBack(duration: TimeInterval = 0.2) -> Animation {
        Animation.timingCurve(0.5, -0.5, 0.5, 1.5, duration: duration)
    }
}
```

**더 강한 효과**:
```swift
extension Animation {
    static var easeInOutBackSteep: Animation {
        Animation.timingCurve(0.7, -0.5, 0.3, 1.5)
    }

    static func easeInOutBackSteep(duration: TimeInterval = 0.2) -> Animation {
        Animation.timingCurve(0.7, -0.5, 0.3, 1.5, duration: duration)
    }
}
```

---

### timingCurve 파라미터

`Animation.timingCurve(c0x, c0y, c1x, c1y)`는 cubic Bézier 곡선의 두 제어점을 정의한다:
- `(c0x, c0y)`: 첫 번째 제어점
- `(c1x, c1y)`: 두 번째 제어점

| 곡선 | 제어점 | 효과 |
|------|--------|------|
| edgeBounce | `(0, 1, 1, 0)` | 중앙에서 느리고 가장자리에서 빠름 |
| easeInOutBack | `(0.5, -0.5, 0.5, 1.5)` | 시작/끝에서 반대 방향으로 살짝 이동 |
| easeInOutBackSteep | `(0.7, -0.5, 0.3, 1.5)` | easeInOutBack의 강화 버전 |

> **Tip**: Bézier 곡선 값을 직접 추측하기보다 https://cubic-bezier.com 같은 도구를 사용하면 시각적으로 곡선을 조정하고 다른 곡선과 비교할 수 있다.

---

## Overriding animations

SwiftUI에서 애니메이션은 다양한 방식으로 트리거될 수 있지만, 애니메이션을 제어하고 재정의하는 API도 제공된다.

---

### Reduce Motion 설정 존중하기

SwiftUI는 Reduce Motion 설정을 자동으로 처리하지 않으므로, 직접 헬퍼 함수를 만들어야 한다.

#### 명시적 애니메이션용 커스텀 함수: withMotionAnimation

`withAnimation()` 대신 사용할 수 있는 전역 함수를 직접 정의:

```swift
func withMotionAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result
) rethrows -> Result {
    if UIAccessibility.isReduceMotionEnabled {
        return try body()
    } else {
        return try withAnimation(animation, body)
    }
}
```

**사용 구분**:

| 함수 | 용도 | 예시 |
|------|------|------|
| `withAnimation()` | 비움직임 애니메이션 (opacity 등) | 페이드 인/아웃 |
| `withMotionAnimation()` | 움직임 애니메이션 | 이동, 스케일 |

```swift
Button("Tap Me") {
    withMotionAnimation {
        scale += 1
    }
}
.scaleEffect(scale)
```

#### 암묵적 애니메이션용 커스텀 modifier: motionAnimation

암묵적 애니메이션(`.animation()`)은 명시적 애니메이션을 무시하므로, `withMotionAnimation()`만으로는 해결되지 않는다. 별도의 커스텀 modifier를 정의해야 한다:

```swift
struct MotionAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var accessibilityReduceMotion

    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        if accessibilityReduceMotion {
            content
        } else {
            content.animation(animation, value: value)
        }
    }
}

extension View {
    func motionAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        self.modifier(MotionAnimationModifier(animation: animation, value: value))
    }
}
```

**사용**:
```swift
Button("Tap Me") {
    scale += 1
}
.scaleEffect(scale)
.motionAnimation(.default, value: scale)
```

---

### Transaction을 사용한 애니메이션 제어

#### Transaction이란?

Transaction은 **현재 진행 중인 애니메이션의 모든 컨텍스트를 저장하는 컨테이너**다. 뷰 계층 구조를 따라 전달되며, 각 뷰가 애니메이션 정보에 접근할 수 있게 해준다.

**withAnimation()의 실체**:

`withAnimation()`은 사실 Transaction을 생성하는 편의 함수다:
- `withAnimation(.easeInOut) { ... }`를 호출하면
- 내부적으로 새 Transaction을 생성하고 애니메이션을 설정한 뒤
- 해당 Transaction 컨텍스트 내에서 상태 변경을 실행한다

```swift
// withAnimation()이 하는 일 (개념적으로)
var transaction = Transaction(animation: .easeInOut)
withTransaction(transaction) {
    // 상태 변경
}
```

#### Transaction의 핵심 프로퍼티

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| `animation` | `Animation?` | 현재 트랜잭션의 애니메이션 |
| `disablesAnimations` | `Bool` | `true`면 암묵적 애니메이션 무시 |
| `isContinuous` | `Bool` | 연속적인 제스처 중인지 여부 |

#### 왜 Transaction이 필요한가?

암묵적 애니메이션(`.animation()`)은 명시적 애니메이션(`withAnimation()`)을 **덮어쓴다**:

```swift
Button("Tap Me") {
    withAnimation(.linear(duration: 3)) {  // 3초 linear 요청
        scale += 1
    }
}
.scaleEffect(scale)
.animation(.default, value: scale)  // ❌ .default가 적용됨
```

이 문제를 해결하려면 Transaction의 `disablesAnimations`를 사용해야 한다.

---

#### 커스텀 함수: withoutAnimation

특정 상황에서 암묵적 애니메이션을 비활성화하는 헬퍼 함수:

```swift
func withoutAnimation<Result>(_ body: () throws -> Result) rethrows -> Result {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    return try withTransaction(transaction, body)
}
```

**사용**:
```swift
Button("Tap Me") {
    withoutAnimation {
        scale += 1  // 암묵적 애니메이션이 무시됨
    }
}
.scaleEffect(scale)
.animation(.default, value: scale)
```

#### 커스텀 함수: withHighPriorityAnimation

암묵적 애니메이션을 다른 애니메이션으로 교체하는 헬퍼 함수:

```swift
func withHighPriorityAnimation<Result>(
    _ animation: Animation? = .default,
    _ body: () throws -> Result
) rethrows -> Result {
    var transaction = Transaction(animation: animation)
    transaction.disablesAnimations = true
    return try withTransaction(transaction, body)
}
```

**사용**:
```swift
Button("Tap Me") {
    withHighPriorityAnimation(.linear(duration: 3)) {
        scale += 1  // 기본 애니메이션 대신 3초 linear 애니메이션
    }
}
.scaleEffect(scale)
.animation(.default, value: scale)  // 평소에는 이 애니메이션 사용
```

---

### transaction() modifier (SwiftUI 제공)

앞서 살펴본 `withTransaction()`은 **새로운 Transaction을 생성**해서 전역적으로 적용한다. 반면 `transaction()` modifier는 **기존 Transaction을 수정**해서 특정 뷰에만 적용한다.

#### 동작 방식

```swift
.transaction { transaction in
    // inout으로 전달됨 - 직접 수정 가능
    transaction.animation = transaction.animation?.delay(0.5)
}
```

- 부모에서 전달된 Transaction을 `inout`으로 받아 수정
- 수정된 Transaction은 **해당 뷰에만** 적용됨
- 뷰 자체는 어떤 애니메이션이 적용되는지 몰라도 됨

#### withTransaction vs transaction() modifier

| 구분 | `withTransaction()` | `.transaction { }` |
|------|---------------------|---------------------|
| 적용 범위 | 전역 (모든 영향받는 뷰) | 해당 뷰만 |
| 동작 | 새 Transaction 생성 | 기존 Transaction 수정 |
| 사용 위치 | 이벤트 핸들러 내부 | View modifier |

> **주의**: Apple은 컨테이너 뷰가 아닌 **leaf 뷰**(자식이 없는 뷰)에서만 사용할 것을 강력히 권장한다. 컨테이너 뷰에 사용하면 엄청난 양의 작업이 발생할 수 있다.

**예시: 웨이브 애니메이션**

```swift
struct CircleGrid: View {
    var useRedFill = false

    var body: some View {
        LazyVGrid(columns: [.init(.adaptive(minimum: 64))]) {
            ForEach(0..<30) { i in
                Circle()
                    .fill(useRedFill ? .red : .blue)
                    .frame(height: 64)
                    .transaction { transaction in
                        transaction.animation = transaction.animation?.delay(Double(i) / 10)
                    }
            }
        }
    }
}

struct ContentView: View {
    @State var useRedFill = false

    var body: some View {
        VStack {
            CircleGrid(useRedFill: useRedFill)
            Spacer()
            Button("Toggle Color") {
                withAnimation(.easeInOut) {
                    useRedFill.toggle()
                }
            }
        }
    }
}
```

**동작 흐름**:
1. `withAnimation(.easeInOut)`이 새 Transaction 생성
2. Transaction이 뷰 계층 구조를 따라 전파
3. 각 `Circle`의 `.transaction` modifier가 전달받은 Transaction 수정
4. `transaction.animation?.delay(Double(i) / 10)`로 인덱스에 따른 딜레이 추가
5. 결과: 웨이브처럼 순차적으로 색상이 변하는 효과

**핵심**: `CircleGrid`는 외부에서 어떤 애니메이션이 적용될지 전혀 모른다. 하지만 `transaction` modifier 덕분에 **어떤 애니메이션이든** 자신만의 딜레이를 추가할 수 있다.

---

### 애니메이션 제어 함수 요약

| 함수 | 용도 | 제공 |
|------|------|------|
| `withMotionAnimation()` | Reduce Motion 설정을 존중하는 명시적 애니메이션 | 커스텀 |
| `motionAnimation()` | Reduce Motion 설정을 존중하는 암묵적 애니메이션 | 커스텀 |
| `withoutAnimation()` | 암묵적 애니메이션 비활성화 | 커스텀 |
| `withHighPriorityAnimation()` | 암묵적 애니메이션을 다른 애니메이션으로 교체 | 커스텀 |
| `withTransaction()` | Transaction을 사용한 애니메이션 제어 | SwiftUI |
| `.transaction { }` | 개별 뷰에서 애니메이션 선택적 수정 | SwiftUI |

---

### 핵심 정리

1. **Reduce Motion 대응**: SwiftUI가 자동 처리하지 않으므로 커스텀 헬퍼 함수 필요
2. **Transaction**: 애니메이션 컨텍스트를 담는 컨테이너. `withAnimation()`도 내부적으로 Transaction 생성
3. **암묵적 > 명시적**: `.animation()` modifier가 `withAnimation()`을 덮어쓰므로, `disablesAnimations`로 제어 필요
4. **withTransaction()**: 새 Transaction을 생성하여 전역 적용
5. **transaction() modifier**: 기존 Transaction을 수정하여 특정 뷰에만 적용 (leaf 뷰에서만 사용 권장)

---

## Advanced transitions

SwiftUI의 transition 시스템은 뷰가 삽입되거나 제거될 때 커스터마이징할 수 있게 해준다. 내장 transition(`.opacity`, `.scale` 등)만 보면 기능이 제한적으로 보일 수 있지만, 실제로는 매우 강력하다.

### Transition의 핵심 개념

| 개념 | 설명 |
|------|------|
| **ViewModifier 기반** | Transition은 `ViewModifier`를 활용해 뷰의 상태를 변경 |
| **active vs identity** | `active`는 뷰가 나타나기 전/사라진 후 상태, `identity`는 완전히 보이는 상태 |
| **복합 애니메이션** | 여러 애니메이션을 조합하여 복잡한 효과 구현 가능 |
| **재사용성** | 한 번 정의하면 어떤 뷰에도 적용 가능 |

### AnyTransition 확장 패턴

Apple 스타일에 맞게 property와 method 두 가지 버전을 제공하는 것이 좋다:

```swift
extension AnyTransition {
    // property 버전 - 기본값 사용
    static var confetti: AnyTransition {
        .modifier(
            active: ConfettiModifier(color: .blue, size: 3),
            identity: ConfettiModifier(color: .blue, size: 3)
        )
    }

    // method 버전 - 커스터마이징 가능
    static func confetti(color: Color = .blue, size: Double = 3.0) -> AnyTransition {
        .modifier(
            active: ConfettiModifier(color: color, size: size),
            identity: ConfettiModifier(color: color, size: size)
        )
    }
}
```

### 예시: Twitter Heart 애니메이션

Twitter의 좋아요 애니메이션을 재현한 복잡한 transition 예제:

**애니메이션 단계**:
1. 원이 중앙에서 바깥으로 확장
2. 원이 안쪽에서부터 축소 (속이 비워짐)
3. 다채로운 confetti가 원 가장자리에서 바깥으로 날아감
4. 채워진 하트 아이콘이 중앙에서 스프링 애니메이션으로 나타남

```swift
import SwiftUI

// MARK: - Confetti Transition Modifier
struct ConfettiModifier: ViewModifier {
    // 애니메이션 속도 (지속 시간과 딜레이에 사용)
    private let speed = 0.3

    // 사용자 정의 속성
    var color: Color      // 원과 confetti의 색상
    var size: Double      // confetti 크기

    // MARK: - 애니메이션 상태 프로퍼티

    // 1단계: 원 확장 (0.00001 → 1.0)
    @State private var circleSize = 0.00001

    // 2단계: 원 테두리 축소 (1.0 → 0.00001)
    @State private var strokeMultiplier = 1.0

    // 3단계: Confetti 상태
    @State private var confettiIsHidden = true    // 표시 여부
    @State private var confettiMovement = 0.7     // 이동 거리 (반지름 대비 비율)
    @State private var confettiScale = 1.0        // 크기 (사라질 때 축소)

    // 4단계: 콘텐츠(하트) 크기
    @State private var contentsScale = 0.00001

    func body(content: Content) -> some View {
        content
            // 실제 콘텐츠는 숨기고 공간만 확보 (마지막에 별도로 애니메이션됨)
            .hidden()
            // 원이 콘텐츠보다 크게 그려지도록 패딩 추가
            .padding(10)
            .overlay(
                ZStack {
                    // MARK: - 확장/축소하는 원
                    GeometryReader { proxy in
                        Circle()
                            // strokeBorder: 테두리가 원 안쪽에 그려짐
                            // lineWidth를 줄이면 자연스럽게 속이 빔
                            .strokeBorder(color, lineWidth: proxy.size.width / 2 * strokeMultiplier)
                            .scaleEffect(circleSize)
                    }

                    // MARK: - Confetti 파티클
                    GeometryReader { proxy in
                        ForEach(0..<15) { i in
                            Circle()
                                .fill(color)
                                // sin()으로 크기에 약간의 변화 부여
                                .frame(
                                    width: size + sin(Double(i)),
                                    height: size + sin(Double(i))
                                )
                                // 사라질 때 축소
                                .scaleEffect(confettiScale)
                                // 바깥으로 이동 (짝수 인덱스는 추가 거리)
                                .offset(x: proxy.size.width / 2 * confettiMovement + (i.isMultiple(of: 2) ? size : 0))
                                // 360도에 걸쳐 균등 분포 (24 * 15 = 360)
                                .rotationEffect(.degrees(24 * Double(i)))
                                // 중앙 정렬 (confetti 크기의 절반만큼 보정)
                                .offset(
                                    x: (proxy.size.width - size) / 2,
                                    y: (proxy.size.height - size) / 2
                                )
                                .opacity(confettiIsHidden ? 0 : 1)
                        }
                    }

                    // MARK: - 최종 콘텐츠 (하트 아이콘)
                    content
                        .scaleEffect(contentsScale)
                }
            )
            // 추가했던 패딩 제거 (레이아웃 유지)
            .padding(-10)
            // MARK: - 애니메이션 시퀀스
            .onAppear {
                // 1단계: 원 확장
                withAnimation(.easeIn(duration: speed)) {
                    circleSize = 1
                }

                // 2단계: 원 테두리 축소 (1단계 완료 후)
                withAnimation(.easeOut(duration: speed).delay(speed)) {
                    strokeMultiplier = 0.00001
                }

                // 3단계-1: Confetti 표시 및 바깥으로 이동
                withAnimation(.easeOut(duration: speed).delay(speed * 1.25)) {
                    confettiIsHidden = false
                    confettiMovement = 1.2
                }

                // 3단계-2: Confetti 축소하며 사라짐
                withAnimation(.easeOut(duration: speed).delay(speed * 2)) {
                    confettiScale = 0.00001
                }

                // 4단계: 콘텐츠 스프링 애니메이션 (1단계 완료 후)
                withAnimation(.interpolatingSpring(stiffness: 50, damping: 5).delay(speed)) {
                    contentsScale = 1
                }
            }
    }
}

// MARK: - AnyTransition 확장
extension AnyTransition {
    // 기본값 사용
    static var confetti: AnyTransition {
        .modifier(
            active: ConfettiModifier(color: .blue, size: 3),
            identity: ConfettiModifier(color: .blue, size: 3)
        )
    }

    // 커스텀 색상과 크기 지정 가능
    static func confetti(color: Color = .blue, size: Double = 3.0) -> AnyTransition {
        .modifier(
            active: ConfettiModifier(color: color, size: size),
            identity: ConfettiModifier(color: color, size: size)
        )
    }
}

// MARK: - 사용 예시
struct ContentView: View {
    @State private var isFavorite = false

    var body: some View {
        VStack(spacing: 60) {
            // 다양한 크기로 테스트
            ForEach([Font.body, Font.largeTitle, Font.system(size: 72)], id: \.self) { font in
                Button {
                    isFavorite.toggle()
                } label: {
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            // confetti transition 적용
                            .transition(.confetti(color: .red, size: 3))
                    } else {
                        Image(systemName: "heart")
                            .foregroundStyle(.gray)
                    }
                }
                .font(font)
            }
        }
    }
}
```

### 핵심 테크닉 정리

| 테크닉 | 설명 |
|--------|------|
| **hidden() + overlay** | 원본 콘텐츠 공간 확보 후 커스텀 뷰로 대체 |
| **strokeBorder** | lineWidth 조절로 원이 안에서부터 비워지는 효과 |
| **GeometryReader** | 부모 크기 기반으로 정확한 위치/크기 계산 |
| **scaleEffect(0.00001)** | 0.0 대신 사용하여 SwiftUI 경고 방지 |
| **연쇄 delay** | speed 값을 기반으로 애니메이션 순서 조율 |
| **interpolatingSpring** | 바운스 효과가 있는 자연스러운 스프링 애니메이션 |

> **Tip**: 복잡한 애니메이션 작업 시 시뮬레이터의 Debug > Slow Animations 메뉴를 활용하면 각 단계를 정확히 확인할 수 있다.

---

### 확장: ShapeStyle을 사용한 제네릭 버전

단순 `Color` 대신 그라디언트 등 다양한 `ShapeStyle`을 지원하도록 확장할 수 있다.

#### 변경 사항

```swift
// 1. Modifier를 ShapeStyle 제네릭으로 변경
struct ConfettiModifier<T: ShapeStyle>: ViewModifier {
    // ...
    var color: T  // Color → T로 변경
    // ...
}

// 2. AnyTransition 확장도 제네릭으로 변경
extension AnyTransition {
    static func confetti<T: ShapeStyle>(color: T = .blue, size: Double = 3.0) -> AnyTransition {
        .modifier(
            active: ConfettiModifier(color: color, size: size),
            identity: ConfettiModifier(color: color, size: size)
        )
    }
}
```

#### 사용 예시

```swift
// 기본 그라디언트
.transition(.confetti(color: .red.gradient))

// 커스텀 Angular 그라디언트 (무지개 효과)
.transition(.confetti(color: .angularGradient(
    colors: [.red, .yellow, .green, .blue, .purple, .red],
    center: .center,
    startAngle: .zero,
    endAngle: .degrees(360)
)))
```

| ShapeStyle 종류 | 예시 |
|----------------|------|
| **Color** | `.red`, `.blue` |
| **Gradient** | `.red.gradient` |
| **LinearGradient** | `LinearGradient(colors:startPoint:endPoint:)` |
| **RadialGradient** | `RadialGradient(colors:center:startRadius:endRadius:)` |
| **AngularGradient** | `AngularGradient(colors:center:startAngle:endAngle:)` |

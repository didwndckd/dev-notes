# Custom Layouts

## 핵심 타입 정리

### `Layout` 프로토콜

커스텀 레이아웃을 만들기 위한 프로토콜. `Animatable`을 상속하므로 `animatableData` 구현 가능. 필수 메서드 2개:

| 메서드 | 역할 |
|---|---|
| `sizeThatFits(proposal:subviews:cache:)` | 이 레이아웃 컨테이너가 원하는 **크기를 반환**. 부모가 다양한 proposal로 여러 번 호출할 수 있음 |
| `placeSubviews(in:proposal:subviews:cache:)` | 확정된 `bounds` 안에서 각 자식 뷰를 **실제로 배치** |

선택 메서드:

| 메서드/프로퍼티 | 역할 |
|---|---|
| `makeCache(subviews:)` | 캐시 타입을 `Void` 대신 커스텀 구조체로 지정. 레이아웃·서브뷰 변경 시 자동 무효화 |
| `static layoutProperties` | 레이아웃의 축 방향(`stackOrientation`) 등을 SwiftUI에 알림. `Divider` 방향 등에 영향 |
| `animatableData` | 레이아웃 프로퍼티의 중간값 보간을 활성화하여 경로 애니메이션 구현 |

### `ProposedViewSize`

부모가 자식에게 **"이 정도 공간이 있어"** 라고 전달하는 제안. `CGSize`와 달리 width/height 각각 독립적으로 `nil`이 될 수 있음.

| 값 | 의미 | 용도 |
|---|---|---|
| `.unspecified` (nil) | "이상적인 크기가 얼마야?" | 자식의 자연 크기 조회 |
| `.zero` | "최소 얼마나 필요해?" | 최소 크기 조회 |
| `.infinity` | "최대 얼마나 쓸 수 있어?" | 최대 크기 조회 |
| 구체적 값 (e.g. 300×200) | "이 크기로 맞춰봐" | 실제 배치 |
| 부분 값 (e.g. 300×nil) | "가로만 정해졌어" | 한 축만 제약 |

- `replacingUnspecifiedDimensions()`: `nil` 값을 기본값(10pt)으로 대체하여 `CGSize` 반환

### `Layout.Subviews` (LayoutSubviews)

`placeSubviews()`와 `sizeThatFits()`에 전달되는 **자식 뷰 프록시들의 컬렉션**. `RandomAccessCollection` 준수. 직접 뷰를 수정할 수는 없고, 크기 조회·배치만 가능.

### `LayoutSubview`

컬렉션의 개별 요소. 실제 `View`가 아닌 **프록시**로, 레이아웃에 필요한 정보만 노출:

| 멤버 | 역할 |
|---|---|
| `sizeThatFits(_:)` | 주어진 `ProposedViewSize`에 대해 자식이 원하는 크기(`CGSize`) 반환 |
| `place(at:anchor:proposal:)` | 자식을 특정 좌표에 배치. `anchor`는 좌표가 뷰의 어느 지점인지 지정 (`.center`, `.topLeading` 등) |
| `spacing` | 인접 뷰와의 preferred spacing 정보. `distance(to:along:)`으로 조회 |
| `priority` | `layoutPriority()` modifier로 설정한 값. 공간 배분 비율 등에 활용 |

---

## Adaptive Layouts

### 핵심 개념

- **`AnyLayout`**: 레이아웃 타입을 type-erase하는 래퍼. `AnyView`와 달리, 동적으로 레이아웃을 전환할 때 **상태(state), 애니메이션, 플랫폼 뷰를 유지**하도록 설계됨
- **`HStackLayout` / `VStackLayout` / `ZStackLayout`**: `HStack` 등과 동일하게 동작하지만 `AnyLayout`과 함께 사용하기 위해 별도로 존재 (컴파일러 성능 이유)
- **`GridLayout`**: 그리드 형태 배치. `GridRow`로 행을 나눔
- **`Layout` 프로토콜**: 위 레이아웃들이 모두 준수하는 프로토콜. 커스텀 레이아웃을 만들어 `AnyLayout`에 사용 가능

### 레이아웃 전환 패턴

**상태를 가진 자식 뷰** — 레이아웃이 바뀌어도 `counter` 값이 유지됨:

```swift
struct ExampleView: View {
    @State private var counter = 0
    let color: Color

    var body: some View {
        Button { counter += 1 } label: {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)
                .overlay(
                    Text(String(counter))
                        .foregroundColor(.white)
                        .font(.largeTitle)
                )
        }
        .frame(width: 100, height: 100)
        .rotationEffect(.degrees(.random(in: -20...20)))
    }
}
```

**레이아웃 배열 + 인덱스로 동적 전환**:

```swift
struct ContentView: View {
    let layouts = [
        AnyLayout(VStackLayout()),
        AnyLayout(HStackLayout()),
        AnyLayout(ZStackLayout()),
        AnyLayout(GridLayout())
    ]
    @State private var currentLayout = 0

    var layout: AnyLayout { layouts[currentLayout] }

    var body: some View {
        VStack {
            Spacer()

            // GridRow는 Grid 외 레이아웃에서 Group처럼 동작
            layout {
                GridRow {
                    ExampleView(color: .red)
                    ExampleView(color: .green)
                }
                GridRow {
                    ExampleView(color: .blue)
                    ExampleView(color: .orange)
                }
            }

            Spacer()

            Button("Change Layout") {
                withAnimation {
                    currentLayout = (currentLayout + 1) % layouts.count
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray)
    }
}
```

### 주요 특징

- 레이아웃 전환 시 **각 뷰의 상태가 유지**됨 (카운터 값 등)
- `withAnimation` 안에서 전환하면 SwiftUI가 자동으로 **레이아웃 변경을 애니메이션**으로 처리
- `GridRow`는 Grid 외의 레이아웃에서는 `Group`처럼 동작 — 에러 없이 무시됨
- **커스텀 `Layout`** 타입도 `AnyLayout`으로 감싸 기본 레이아웃과 자유롭게 전환 가능

---

## Implementing a Radial Layout

### 핵심 개념

- **`Layout` 프로토콜** 구현 시 두 메서드가 필수:
  - `sizeThatFits()`: 컨테이너가 원하는 크기 반환. 부모가 여러 번 호출할 수 있음
  - `placeSubviews()`: 각 자식 뷰를 실제로 배치
- **`ProposedViewSize`**: 단순한 width/height가 아닌 **의도**를 담은 제안
- **`replacingUnspecifiedDimensions()`**: `nil` 값을 기본값(10pt)으로 대체해 완전한 `CGSize` 반환
  - `Color.red`가 ScrollView 안에서 10pt 높이를 갖는 이유가 바로 이 메서드 때문

### ProposedViewSize 종류

| 값 | 의미 |
|---|---|
| `.unspecified` (nil) | "이상적인 크기가 얼마야?" |
| `.infinity` | "최대 얼마나 쓸 수 있어?" |
| `.zero` | "최소 얼마나 필요해?" |
| 구체적 값 (e.g. 300×200) | "이 크기로 배치해, 맞춰봐" |
| 부분 값 (e.g. 300×nil) | "가로만 정해졌어, 세로는 네가 결정해" |

> width/height 각각 독립적으로 nil이 될 수 있으므로, `CGSize`가 아닌 별도 타입으로 존재

### `sizeThatFits` — 제안된 공간 그대로 사용

```swift
func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
    // nil → 10pt로 대체. 원형 레이아웃은 공간을 알아야 배치 가능하므로 제안 크기를 그대로 수용
    proposal.replacingUnspecifiedDimensions()
}
```

### `placeSubviews` — 원형 배치 계산

```swift
func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
    let radius = min(bounds.size.width, bounds.size.height) / 2
    let angle = Angle.degrees(360 / Double(subviews.count)).radians

    for (index, subview) in subviews.enumerated() {
        let viewSize = subview.sizeThatFits(.unspecified)

        // 뷰 크기의 절반만큼 안쪽으로 당겨 원 안에 완전히 들어오게 함
        // .pi / 2 빼기: 0도를 오른쪽(SwiftUI 기본)이 아닌 위쪽으로 보정
        let xPos = cos(angle * Double(index) - .pi / 2) * (radius - viewSize.width / 2)
        let yPos = sin(angle * Double(index) - .pi / 2) * (radius - viewSize.height / 2)

        let point = CGPoint(x: bounds.midX + xPos, y: bounds.midY + yPos)
        subview.place(at: point, anchor: .center, proposal: .unspecified)
    }
}
```

### 전체 코드

```swift
struct RadialLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let radius = min(bounds.size.width, bounds.size.height) / 2
        let angle = Angle.degrees(360 / Double(subviews.count)).radians
        for (index, subview) in subviews.enumerated() {
            let viewSize = subview.sizeThatFits(.unspecified)
            let xPos = cos(angle * Double(index) - .pi / 2) * (radius - viewSize.width / 2)
            let yPos = sin(angle * Double(index) - .pi / 2) * (radius - viewSize.height / 2)
            let point = CGPoint(x: bounds.midX + xPos, y: bounds.midY + yPos)
            subview.place(at: point, anchor: .center, proposal: .unspecified)
        }
    }
}

struct ContentView: View {
    @State private var count = 16

    var body: some View {
        RadialLayout {
            ForEach(0..<count, id: \.self) { _ in
                Circle()
                    .frame(width: 32, height: 32)
            }
        }
        .padding()
        .safeAreaInset(edge: .bottom) {
            Stepper("Count: \(count)", value: $count.animation(), in: 0...100)
                .padding()
        }
    }
}
```

### 주요 포인트

- `subview.sizeThatFits(.unspecified)`: 자식 뷰의 이상적인 크기 조회
- `bounds.midX / midY` 더하기: 원점(top-left)이 아닌 **컨테이너 중앙** 기준으로 배치
- `anchor: .center`: 계산한 point가 뷰의 중심임을 명시
- `$count.animation()`: Stepper 값 변경 시 자동 애니메이션 적용

## Implementing an equal width layout

### 목표

모든 자식 뷰가 **동일한 너비**를 갖는 HStack 구현. 단순히 `.frame(maxWidth: .infinity)`를 쓰면 HStack 전체가 불필요하게 커지므로, **가장 큰 자식 뷰의 너비**를 기준으로 모든 뷰에 동일한 공간을 배분한다.

### 전체 코드

```swift
struct EqualWidthHStack: Layout {

    /// 모든 자식 뷰 중 최대 너비·높이를 구한다
    /// 이 값이 모든 뷰에 동일하게 적용될 크기의 기준이 된다
    private func maximumSize(across subviews: Subviews) -> CGSize {
        var maximumSize = CGSize.zero

        for view in subviews {
            // .unspecified → "네 이상적인 크기가 뭐야?"
            let size = view.sizeThatFits(.unspecified)

            if size.width > maximumSize.width {
                maximumSize.width = size.width
            }

            if size.height > maximumSize.height {
                maximumSize.height = size.height
            }
        }

        return maximumSize
    }

    /// 인접 뷰 간 자동 간격 배열 생성
    /// SwiftUI는 뷰 종류(Text-Text, Text-Image 등)와 플랫폼에 따라 자동 간격을 다르게 제공한다
    /// 마지막 뷰는 다음 이웃이 없으므로 0
    private func spacing(for subviews: Subviews) -> [Double] {
        var spacing = [Double]()

        for index in subviews.indices {
            if index == subviews.count - 1 {
                spacing.append(0)
            } else {
                let distance = subviews[index].spacing.distance(to: subviews[index + 1].spacing, along: .horizontal)
                spacing.append(distance)
            }
        }

        return spacing
    }

    /// 컨테이너 크기 결정
    /// 너비 = 최대 너비 × 자식 수 + 총 간격, 높이 = 최대 높이
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxSize = maximumSize(across: subviews)
        let spacing = spacing(for: subviews)
        let totalSpacing = spacing.reduce(0, +)

        return CGSize(width: maxSize.width * Double(subviews.count) + totalSpacing, height: maxSize.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let maxSize = maximumSize(across: subviews)
        let spacing = spacing(for: subviews)

        // 모든 자식에게 동일한 크기를 제안 (최대 너비 × 최대 높이)
        // RadialLayout은 .unspecified였지만, 여기서는 동일 크기 강제가 목적이므로 구체적 값 사용
        let proposal = ProposedViewSize(width: maxSize.width, height: maxSize.height)

        // 첫 뷰의 중심 X 좌표. anchor가 .center이므로 반 너비만큼 오프셋
        var x = bounds.minX + maxSize.width / 2

        for index in subviews.indices {
            subviews[index].place(
                at: CGPoint(x: x, y: bounds.midY),
                anchor: .center, // 계산한 좌표가 뷰의 중심임을 명시
                proposal: proposal
            )
            // 다음 뷰 위치 = 현재 뷰 너비 + 뷰 간 간격
            x += maxSize.width + spacing[index]
        }
    }
}

struct ContentView: View {
    var body: some View {
        EqualWidthHStack {
            Text("Short")
                .background(.red)

            Text("This is long")
                .background(.green)

            Text("This is longest")
                .background(.blue)
        }
        .border(.yellow)
    }
}
```

### Radial Layout과의 차이

| | RadialLayout | EqualWidthHStack |
|---|---|---|
| proposal | `.unspecified` (자연 크기) | 공유 `ProposedViewSize` (최대 크기 강제) |
| spacing 처리 | 불필요 (원형 배치) | `spacing.distance(to:along:)` 사용 |
| sizeThatFits | 제안 크기 그대로 수용 | 자식 크기 기반으로 직접 계산 |

## Implementing a relative width layout

### 핵심 개념

- **`layoutPriority()`를 비율 지정에 활용**: SwiftUI의 `layoutPriority()`를 hijack하여 각 뷰의 **상대적 공간 비율**을 지정. 우선순위 합계 대비 개별 비율로 너비 계산
- 비율 값은 1/2/3, 30/50/20, 4/4/8 등 **어떤 숫자든 상대적으로 동작** — 합이 1이나 100일 필요 없음

### 전체 코드

```swift
struct RelativeHStack: Layout {
    var spacing = 0.0

    /// 모든 프레임을 한 번에 계산하는 헬퍼 메서드
    /// sizeThatFits()와 placeSubviews() 양쪽에서 재사용
    func frames(for subviews: Subviews, in totalWidth: Double) -> [CGRect] {
        // 1. 총 간격 = 개별 간격 × (뷰 수 - 1)
        let totalSpacing = spacing * Double(subviews.count - 1)
        // 2. 뷰에 배분할 수 있는 실제 너비
        let availableWidth = totalWidth - totalSpacing
        // 3. 모든 뷰의 layoutPriority 합계
        let totalPriorities = subviews.reduce(0) { $0 + $1.priority }

        var viewFrames = [CGRect]()
        var x = 0.0

        for subview in subviews {
            // 비율에 따른 너비 계산: availableWidth × (개별 priority / 전체 priority)
            let subviewWidth = availableWidth * subview.priority / totalPriorities
            // 너비는 지정, 높이는 자유(nil)
            let proposal = ProposedViewSize(width: subviewWidth, height: nil)
            let size = subview.sizeThatFits(proposal)
            let frame = CGRect(x: x, y: 0, width: size.width, height: size.height)
            viewFrames.append(frame)
            x += size.width + spacing
        }

        return viewFrames
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let viewFrames = frames(for: subviews, in: width)
        let height = viewFrames.max { $0.maxY < $1.maxY } ?? .zero
        return CGSize(width: width, height: height.maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let viewFrames = frames(for: subviews, in: bounds.width)

        for index in subviews.indices {
            let frame = viewFrames[index]
            let position = CGPoint(x: bounds.minX + frame.minX, y: bounds.midY)
            subviews[index].place(at: position, anchor: .leading, proposal: ProposedViewSize(frame.size))
        }
    }
}

struct ContentView: View {
    var body: some View {
        RelativeHStack(spacing: 50) {
            Text("First")
                .frame(maxWidth: .infinity)
                .background(.red)
                .layoutPriority(1)

            Text("Second")
                .frame(maxWidth: .infinity)
                .background(.green)
                .layoutPriority(2)

            Text("Third")
                .frame(maxWidth: .infinity)
                .background(.blue)
                .layoutPriority(3)
        }
    }
}
```

### EqualWidthHStack과의 차이

| | EqualWidthHStack | RelativeHStack |
|---|---|---|
| 너비 결정 | 가장 큰 자식 기준 **동일 너비** | `layoutPriority` 비율로 **차등 배분** |
| spacing | `spacing.distance(to:along:)` 자동 계산 | 고정값 하나를 직접 지정 |
| sizeThatFits | 자식 크기 기반 직접 계산 | 제안된 width를 그대로 수용 |
| proposal 방식 | 공유 크기 강제 | 뷰별 비율 너비 제안, 높이는 `nil` |
| anchor | `.center` | `.leading` |

## Implementing a masonry layout

### 핵심 개념

- **Masonry(Waterfall) 레이아웃**: 열(column)은 고정이지만 행(row)은 없는 ragged grid. 각 뷰를 **가장 짧은 열**에 배치하여 균형을 맞춤 (Pinterest 스타일)
- `frames(for:in:)` 헬퍼 패턴은 RelativeHStack과 거의 동일 — `sizeThatFits()`와 `placeSubviews()` 양쪽에서 재사용
- **`layoutProperties`**: 레이아웃의 축 방향을 SwiftUI에 알려줌. `Divider` 등이 올바른 방향으로 렌더링되도록 함

### 전체 코드

```swift
struct MasonryLayout: Layout {
    var columns: Int
    var spacing: Double

    init(columns: Int = 3, spacing: Double = 5) {
        self.columns = max(1, columns)
        self.spacing = spacing
    }

    func frames(for subviews: Subviews, in totalWidth: Double) -> [CGRect] {
        // 열 간 총 간격
        let totalSpacing = spacing * Double(columns - 1)
        // 각 열의 너비
        let columnWidth = (totalWidth - totalSpacing) / Double(columns)
        let columnWidthWithSpacing = columnWidth + spacing
        // 모든 뷰에 동일한 너비 제안, 높이는 자유
        let proposedSize = ProposedViewSize(width: columnWidth, height: nil)

        var viewFrames = [CGRect]()
        // 각 열의 현재 높이를 추적
        var columnHeights = Array(repeating: 0.0, count: columns)

        for subview in subviews {
            // 가장 짧은 열 찾기
            var selectedColumn = 0
            var selectedHeight = Double.greatestFiniteMagnitude

            for (columnIndex, height) in columnHeights.enumerated() {
                if height < selectedHeight {
                    selectedColumn = columnIndex
                    selectedHeight = height
                }
            }

            let x = Double(selectedColumn) * columnWidthWithSpacing
            let y = columnHeights[selectedColumn]
            let size = subview.sizeThatFits(proposedSize)
            let frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            // 해당 열 높이 갱신 (뷰 높이 + 간격)
            columnHeights[selectedColumn] += size.height + spacing
            viewFrames.append(frame)
        }

        return viewFrames
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let viewFrames = frames(for: subviews, in: width)
        let height = viewFrames.max { $0.maxY < $1.maxY } ?? .zero
        return CGSize(width: width, height: height.maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let viewFrames = frames(for: subviews, in: bounds.width)

        for index in subviews.indices {
            let frame = viewFrames[index]
            // RelativeHStack과 달리 y는 bounds.minY + frame.minY, anchor는 기본값(.topLeading)
            let position = CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY)
            subviews[index].place(at: position, proposal: ProposedViewSize(frame.size))
        }
    }

    /// 레이아웃 축 방향을 SwiftUI에 알림
    /// Divider가 올바른 방향(수평)으로 렌더링됨
    static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .vertical
        return properties
    }
}

struct PlaceholderView: View {
    let color: Color = [.blue, .cyan, .green, .indigo, .mint, .orange, .pink, .purple, .red].randomElement()!
    let size: CGSize

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(color)

            Text("\(Int(size.width))x\(Int(size.height))")
                .foregroundColor(.white)
                .font(.headline)
        }
        .aspectRatio(size, contentMode: .fill)
    }
}

struct ContentView: View {
    @State private var columns = 3

    @State private var views = (0..<20).map { _ in
        CGSize(width: .random(in: 100...500), height: .random(in: 100...500))
    }

    var body: some View {
        ScrollView {
            MasonryLayout(columns: columns) {
                ForEach(0..<20) { i in
                    PlaceholderView(size: views[i])
                }
            }
            .padding(.horizontal, 5)
        }
        .safeAreaInset(edge: .bottom) {
            Stepper("Columns: \(columns)", value: $columns.animation(), in: 1...5)
                .padding()
                .background(.regularMaterial)
        }
    }
}
```

### RelativeHStack과의 차이

| | RelativeHStack | MasonryLayout |
|---|---|---|
| 방향 | 수평 1행 | 수직 다열 (열 수 지정) |
| 열 배치 | 순서대로 | **가장 짧은 열**에 배치 |
| 너비 결정 | `layoutPriority` 비율 | `totalWidth / columns` 균등 분배 |
| anchor | `.leading` (수직 중앙 정렬) | 기본값 `.topLeading` |
| y 좌표 | `bounds.midY` (한 줄) | `bounds.minY + frame.minY` (누적) |
| `layoutProperties` | 미지정 | `.vertical` — Divider 방향 제어 |

## Layout caching

### 핵심 개념

- **캐시는 프로파일링으로 성능 문제가 확인된 후에만 추가** — 나쁜 캐싱은 흔한 버그 원인
- `Cache` 구조체를 레이아웃 안에 중첩 정의하면 SwiftUI가 자동으로 사용
- SwiftUI는 레이아웃/서브뷰가 변경되면 캐시를 자동 무효화하지만, **할당된 공간(bounds) 변경은 감지 못함** → `width` 프로퍼티로 직접 검증 필요

### 캐시 무효화 문제

1. Portrait 진입 → `sizeThatFits()` 호출, 캐시 설정
2. Landscape 회전 → `sizeThatFits()` 호출, 캐시 갱신
3. Portrait 복귀 → `sizeThatFits()` **재호출 안 됨** (이미 호출된 적 있으므로), landscape 캐시가 잘못 사용됨

→ `placeSubviews()`에서 `cache.width != bounds.width`를 체크하여 캐시 재생성

### 적용 코드

```swift
struct MasonryLayout: Layout {
    var columns: Int
    var spacing: Double

    // 캐시: 계산된 프레임 + 해당 너비를 저장
    struct Cache {
        var width = 0.0
        var frames: [CGRect]
    }

    init(columns: Int = 3, spacing: Double = 5) {
        self.columns = max(1, columns)
        self.spacing = spacing
    }

    // SwiftUI가 캐시 생성 시 호출
    func makeCache(subviews: Subviews) -> Cache {
        Cache(frames: [])
    }

    func frames(for subviews: Subviews, in totalWidth: Double) -> [CGRect] {
        // ... 기존 frames 로직 동일 ...
    }

    // cache 타입이 Void → Cache로 변경
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        let width = proposal.replacingUnspecifiedDimensions().width
        let viewFrames = frames(for: subviews, in: width)
        let height = viewFrames.max { $0.maxY < $1.maxY } ?? .zero

        // 캐시에 계산 결과 저장
        cache.frames = viewFrames
        cache.width = width

        return CGSize(width: width, height: height.maxY)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        // bounds 너비가 캐시와 다르면 재계산 (회전 등)
        if cache.width != bounds.width {
            cache.frames = frames(for: subviews, in: bounds.width)
            cache.width = bounds.width
        }

        for index in subviews.indices {
            let frame = cache.frames[index]  // viewFrames → cache.frames
            let position = CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY)
            subviews[index].place(at: position, proposal: ProposedViewSize(frame.size))
        }
    }
}
```

### 캐시 적용 전후 비교

| | 캐시 없음 | 캐시 있음 |
|---|---|---|
| `cache` 타입 | `Void` | 커스텀 `Cache` 구조체 |
| `makeCache` | 불필요 | 빈 `Cache` 반환 |
| `frames()` 호출 | `sizeThatFits` + `placeSubviews` 매번 (2회) | `sizeThatFits`에서 1회, `placeSubviews`는 캐시 사용 |
| 회전 대응 | 자동 (매번 재계산) | `cache.width != bounds.width` 체크 필요 |

## Customizing layout animations

### 핵심 개념

- SwiftUI는 레이아웃 변경 시 **시작/끝 위치만 계산**하여 직선 보간 애니메이션을 적용 (spacing, columns 등)
- **중간 상태가 중요한 경우** (원형 배치에서 펼쳐지는 효과 등) `animatableData`를 구현해야 SwiftUI가 모든 중간값을 전달
- `Layout` 프로토콜은 `Animatable`을 상속 → `animatableData` 구현 가능

### animatableData 없이 vs 있을 때

| | `animatableData` 없음 | `animatableData` 있음 |
|---|---|---|
| 애니메이션 | 시작→끝 **직선 이동** | 원호를 따라 **경로 애니메이션** |
| `sizeThatFits` / `placeSubviews` 호출 | 각 2회 (시작, 끝) | **매 중간값마다 2회씩** (0.01, 0.02, ...) |
| 성능 | 가벼움 | 호출 횟수 급증 — 캐시 고려 필요 |

### 적용 코드

```swift
struct RadialLayout: Layout {
    var rollOut = 0.0

    // Layout은 Animatable 상속 → animatableData 구현 가능
    // SwiftUI가 0→1 사이 모든 중간값을 전달하여 placeSubviews()를 반복 호출
    var animatableData: Double {
        get { rollOut }
        set { rollOut = newValue }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        let radius = min(bounds.size.width, bounds.size.height) / 2
        // rollOut을 곱하여 0(모두 겹침) → 1(완전 펼침)까지 제어
        let angle = Angle.degrees(360 / Double(subviews.count)).radians * rollOut

        for (index, subview) in subviews.enumerated() {
            let viewSize = subview.sizeThatFits(.unspecified)
            let xPos = cos(angle * Double(index) - .pi / 2) * (radius - viewSize.width / 2)
            let yPos = sin(angle * Double(index) - .pi / 2) * (radius - viewSize.height / 2)
            let point = CGPoint(x: bounds.midX + xPos, y: bounds.midY + yPos)
            subview.place(at: point, anchor: .center, proposal: .unspecified)
        }
    }
}

struct ContentView: View {
    @State private var count = 16
    @State private var isExpanded = false

    var body: some View {
        RadialLayout(rollOut: isExpanded ? 1 : 0) {
            ForEach(0..<count, id: \.self) { _ in
                Circle()
                    .frame(width: 32, height: 32)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Stepper("Count: \(count)", value: $count.animation(), in: 0...36)
                    .padding()

                Button("Expand") {
                    withAnimation(.easeInOut(duration: 1)) {
                        isExpanded.toggle()
                    }
                }
            }
        }
    }
}
```

### 주요 포인트

- `rollOut = 0`: 모든 뷰가 같은 위치(중앙)에 겹침. `rollOut = 1`: 완전히 펼쳐진 원형 배치
- `animatableData` 없으면 뷰가 직선으로 슬라이드, 있으면 원호를 따라 펼쳐짐
- 애니메이션 중 `sizeThatFits()` + `placeSubviews()`가 **매 프레임마다 호출**되므로 비용이 큰 계산은 캐시 활용 권장

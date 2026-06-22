# Drawing and Effects

## 핵심 타입 정리

### `Canvas`

SwiftUI에서 자유롭게 2D 드로잉을 수행하는 뷰. `GraphicsContext`와 `CGSize`를 클로저로 제공받아 직접 그리기. SwiftUI 뷰 시스템을 우회하여 고성능 렌더링 가능.

| 파라미터 | 역할 |
|----------|------|
| `{ ctx, size in }` | 메인 드로잉 클로저. `ctx`는 `GraphicsContext`, `size`는 캔버스 크기 |
| `symbols: { }` | SwiftUI 뷰를 심볼로 전달. `ForEach`로 `Identifiable` 뷰 생성 → `resolveSymbol(id:)`로 조회 |

### `GraphicsContext`

Canvas 내부에서 실제 드로잉을 수행하는 컨텍스트. 필터, 블렌딩, 레이어 합성 등 저수준 그래픽 제어 제공.

| 멤버 | 역할 |
|------|------|
| `addFilter(.blur(radius:))` | 가우시안 블러 적용 |
| `addFilter(.alphaThreshold(min:color:))` | 지정 알파 범위의 픽셀만 단색으로 치환. `blur`와 조합하면 메타볼 효과 |
| `drawLayer { ctx in }` | 별도 레이어에 먼저 합성 후 메인 컨텍스트에 반영. 메타볼 효과의 전제조건 |
| `resolveSymbol(id:)` | `symbols:` 클로저에서 전달된 SwiftUI 뷰를 id로 조회 |
| `draw(symbol, at:)` | 조회한 심볼을 특정 좌표에 배치 |
| `fill(path, with:)` | Shape 경로를 색상/그라디언트로 채우기 |
| `blendMode` | 겹치는 픽셀의 합성 방식. `.plusLighter`는 가산 블렌딩(밝아짐) |
| `opacity` | 이후 드로잉의 투명도 설정. 수명 기반 페이드아웃 등에 활용 |

- `alphaThreshold`와 `blur`의 **선언 순서가 중요**: 필터는 선언 역순으로 적용됨. `alphaThreshold` → `blur` 순으로 선언해야 blur 먼저 → alphaThreshold 적용
- `drawLayer`가 없으면 각 도형이 개별적으로 알파 테스트를 받아 메타볼 합성 불가

### `TimelineView`

지정 스케줄에 따라 뷰를 반복 갱신하는 컨테이너. 매 프레임 렌더링이 필요한 애니메이션에 사용.

| 스케줄 | 동작 |
|--------|------|
| `.animation` | 디스플레이 주사율에 맞춰 매 프레임 호출 (60fps/120fps ProMotion) |
| `.animation(minimumInterval:)` | 최소 간격을 지정하여 프레임 호출 빈도 제한 |
| `.everyMinute` | 매 분 정각에 호출. 시계 UI 등에 활용 |
| `.periodic(from:by:)` | 지정 시작 시점부터 일정 간격(`TimeInterval`)으로 반복 호출 |
| `.explicit(sequence)` | `Date` 시퀀스를 직접 전달하여 특정 시점에만 호출 |

- `timeline.date.timeIntervalSinceReferenceDate`로 현재 시간을 `TimeInterval`로 변환하여 사용

### `ImageRenderer`

SwiftUI 뷰를 래스터 이미지(`UIImage`)로 렌더링하는 브릿지. SpriteKit 텍스처 변환 등에 활용.

| 멤버 | 역할 |
|------|------|
| `init(content:)` | 렌더링할 SwiftUI 뷰 지정 |
| `scale` | 렌더링 스케일. 기본 1.0이면 Retina에서 흐릿함 → `@Environment(\.displayScale)`로 2x/3x 적용 필요 |
| `uiImage` | 렌더링 결과를 `UIImage?`로 반환 |

### `VectorArithmetic` / `AdditiveArithmetic`

SwiftUI 애니메이션이 중간값을 보간하기 위해 요구하는 프로토콜. 커스텀 타입(예: `[Double]`)을 `animatableData`로 사용하려면 적합성 추가 필요.

| 필수 멤버 | 역할 |
|-----------|------|
| `scale(by:)` | 스칼라 곱. SwiftUI가 보간 비율을 곱할 때 호출 |
| `+=` / `-=` | 요소별 덧셈/뺄셈. 시작값과 끝값 사이 차이 계산에 사용 |
| `static var zero` | 영벡터. 보간 시작점 |
| `var magnitudeSquared` | 벡터 크기의 제곱. 애니메이션 수렴 판단용 |
| `static func -` | 두 값의 차이 반환 (`AdditiveArithmetic` 요구) |

- `magnitudeSquared`와 `-` 연산자는 **더미 구현도 가능** — 라바램프 등 단순 보간에서는 실제 호출되지 않음
- `[Double]` 확장 시 각 요소가 독립적으로 보간되어 다각형 꼭짓점 등의 자연스러운 변형 가능

### SpriteKit 타입

SpriteKit + Metal 셰이더를 SwiftUI에 통합하기 위한 타입들.

| 타입 | 역할 |
|------|------|
| `SKScene` | SpriteKit 씬. `sceneDidLoad()`에서 노드 구성, `didMove(to:)`에서 뷰 연결 시 초기화 |
| `SKSpriteNode` | 텍스처를 표시하는 노드. `shader` 프로퍼티에 `SKShader` 할당하여 셰이더 적용 |
| `SKShader` | GLSL 소스 코드를 로드·실행. GLSL → MSL(Metal) 자동 변환 |
| `SKUniform` | 셰이더에 외부 값을 전달하는 유니폼 변수. `u_` 접두사 관례 (`u_speed`, `u_strength` 등) |
| `SKTexture` | `UIImage` → SpriteKit 텍스처 변환. `SKSpriteNode`에 할당하여 표시 |
| `SpriteView` | SpriteKit 씬을 SwiftUI 뷰 계층에 임베딩. `options: .allowsTransparency`로 투명 배경 지원 |

---

## Drawing with Canvas

### 핵심 개념

- **`Canvas`**: SwiftUI에서 자유롭게 2D 드로잉을 수행하는 뷰. `GraphicsContext`와 `CGSize`를 제공받아 직접 그리기
- **`TimelineView(.animation)`**: 매 프레임마다 뷰를 다시 그리도록 스케줄링. 애니메이션에 최적화된 주기로 호출
- **`ParticleSystem`**: 클래스로 구현하여 SwiftUI 업데이트 없이 자유롭게 상태 변경. `@State`로 유지 (`ObservableObject` 불필요)
- **`GraphicsContext` 효과**:
  - `blendMode = .plusLighter`: 겹치는 색상이 밝아지는 가산 블렌딩
  - `addFilter(.blur(radius:))`: 가우시안 블러로 부드러운 글로우 효과
  - `opacity`: 파티클의 남은 수명에 비례하여 페이드아웃

### 파티클 시스템 구조

| 구성 요소 | 역할 |
|---|---|
| `Particle` | 위치(`CGPoint`)와 소멸 시간(`deathDate`) 저장. 생성 시 1초 후 소멸 설정 |
| `ParticleSystem` | 파티클 배열 관리. `update()`에서 만료 파티클 제거 + 새 파티클 생성 |
| `DragGesture(minimumDistance: 0)` | 터치 즉시 반응하여 파티클 생성 위치 갱신 |

### 전체 코드

```swift
struct Particle {
    let position: CGPoint
    let deathDate = Date.now.timeIntervalSinceReferenceDate + 1
}

class ParticleSystem {
    var particles = [Particle]()
    var position = CGPoint.zero

    func update(date: TimeInterval) {
        particles = particles.filter { $0.deathDate > date }
        particles.append(Particle(position: position))
    }
}

struct DrawingWithCanvasView: View {
    @State private var particleSystem = ParticleSystem()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let timelineDate = timeline.date.timeIntervalSinceReferenceDate
                particleSystem.update(date: timelineDate)
                ctx.blendMode = .plusLighter
                ctx.addFilter(.blur(radius: 10))

                for particle in particleSystem.particles {
                    let frame = CGRect(
                        x: particle.position.x - 16,
                        y: particle.position.y - 16,
                        width: 32,
                        height: 32
                    )

                    ctx.opacity = particle.deathDate - timelineDate
                    ctx.fill(
                        Circle().path(in: frame),
                        with: .color(.cyan)
                    )
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    particleSystem.position = drag.location
                }
        )
        .ignoresSafeArea()
        .background(.black)
    }
}
```

### 주요 포인트

- `ParticleSystem`이 **class**인 이유: struct면 값 변경마다 SwiftUI가 불필요하게 뷰를 재생성. class는 참조 타입이므로 `Canvas` 내부에서 자유롭게 변경 가능
- `@State`로 생성하는 이유: `ObservableObject`가 아니므로 `@StateObject` 불필요. `@State`만으로 객체 수명 유지 가능
- `deathDate - timelineDate`를 opacity로 사용: 1초 수명 중 남은 시간이 곧 투명도 (1.0→0.0 자연 페이드아웃)
- `DragGesture(minimumDistance: 0)`: 기본값은 10pt 이동 후 시작이지만, 0으로 설정하면 터치 즉시 반응

## Falling Snow

### 핵심 개념

- **Frame-independent movement**: `delta = 현재 시간 - 마지막 업데이트 시간`을 계산하여 이동량에 곱함. 60fps든 120fps(ProMotion)든 동일한 속도로 이동
- **`Particle`이 class인 이유**: 생성 후에도 `x`, `y`를 매 프레임 갱신해야 하므로 참조 타입 필요. 이전 예제의 `Particle`은 struct(생성 후 불변)
- **`drawLayer`**: 모든 파티클을 별도 레이어에 먼저 합성한 뒤 메인 컨텍스트에 한 번에 그림. 겹치는 영역이 하나의 연속된 도형으로 취급됨
- **`alphaThreshold(min:color:)`**: 지정 알파 범위(0.5~1.0) 안의 픽셀만 단색으로 치환, 나머지는 투명 처리. blur와 조합하면 **메타볼(metaball)** 효과 — 가까운 파티클이 유기적으로 합쳐짐

### Drawing with Canvas와의 차이

| | Drawing with Canvas | Falling Snow |
|---|---|---|
| `Particle` 타입 | struct (불변) | class (매 프레임 위치 갱신) |
| 이동 방식 | 없음 (생성 위치 고정) | frame-independent movement (`delta × speed`) |
| 생성 위치 | 드래그 위치 | 화면 상단 랜덤 X좌표 |
| 수명 | 1초 | 2초 |
| blendMode | `.plusLighter` | 미사용 |
| drawLayer | 미사용 | 사용 (메타볼 효과의 전제 조건) |


### 공통 데이터 모델

```swift
class Particle {
    var x: Double
    var y: Double
    let xSpeed: Double
    let ySpeed: Double
    let deathDate = Date.now.timeIntervalSinceReferenceDate + 2

    init(x: Double, y: Double, xSpeed: Double, ySpeed: Double) {
        self.x = x; self.y = y; self.xSpeed = xSpeed; self.ySpeed = ySpeed
    }
}

class ParticleSystem {
    var particles = [Particle]()
    var lastUpdate = Date.now.timeIntervalSinceReferenceDate

    func update(date: TimeInterval, size: CGSize) {
        let delta = date - lastUpdate
        lastUpdate = date

        for (index, particle) in particles.enumerated() {
            if particle.deathDate < date {
                particles.remove(at: index)
            } else {
                particle.x += particle.xSpeed * delta
                particle.y += particle.ySpeed * delta
            }
        }

        particles.append(Particle(
            x: .random(in: -32...size.width), y: -32,
            xSpeed: .random(in: -50...50), ySpeed: .random(in: 100...500)
        ))
    }
}
```

### 버전별 진화

**V1 — 기본 눈 효과**: blur만 적용하여 부드러운 눈송이

```swift
struct FallingSnowView1: View {
    @State private var particleSystem = ParticleSystem()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let timelineDate = timeline.date.timeIntervalSinceReferenceDate
                particleSystem.update(date: timelineDate, size: size)
                ctx.addFilter(.blur(radius: 10))

                ctx.drawLayer { ctx in
                    for particle in particleSystem.particles {
                        ctx.opacity = particle.deathDate - timelineDate
                        let frame = CGRect(x: particle.x, y: particle.y, width: 32, height: 32)
                        ctx.fill(Circle().path(in: frame), with: .color(.white))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .background(.black)
    }
}
```

**V2 — 메타볼 + 그라디언트 마스크**: `alphaThreshold` 추가로 메타볼 효과, `LinearGradient.mask`로 높이에 따른 색상 변화 (라바램프 느낌)

```swift
struct FallingSnowView2: View {
    @State private var particleSystem = ParticleSystem()

    var body: some View {
        LinearGradient(colors: [.red, .indigo], startPoint: .top, endPoint: .bottom).mask {
            TimelineView(.animation) { timeline in
                Canvas { ctx, size in
                    let timelineDate = timeline.date.timeIntervalSinceReferenceDate
                    particleSystem.update(date: timelineDate, size: size)
                    ctx.addFilter(.alphaThreshold(min: 0.5, color: .white))
                    ctx.addFilter(.blur(radius: 10))

                    ctx.drawLayer { ctx in
                        for particle in particleSystem.particles {
                            ctx.opacity = particle.deathDate - timelineDate
                            let frame = CGRect(x: particle.x, y: particle.y, width: 32, height: 32)
                            ctx.fill(Circle().path(in: frame), with: .color(.white))
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .background(.black)
    }
}
```

### 주요 포인트

- `alphaThreshold`와 `blur`의 **순서가 중요**: `alphaThreshold` → `blur` 순으로 적용해야 메타볼 효과 발생. 필터는 선언 역순으로 적용됨 (blur 먼저 → alphaThreshold)
- `drawLayer`가 없으면 각 원이 개별적으로 알파 테스트를 받아 메타볼 합성이 일어나지 않음
- `LinearGradient.mask`: TimelineView 전체를 마스크로 사용 — 흰색(불투명) 영역만 그라디언트가 보임
- `xSpeed: -50...50` 범위의 작은 수평 이동이 자연스러운 낙하감을 줌
- `ySpeed: 100...500` 범위의 큰 편차가 깊이감(depth) 생성

## Lava Lamp (Creating a Lava Lamp + Wouldn't it be lava-ly?)

### 핵심 개념

- **Canvas `symbols`**: SwiftUI 뷰를 Canvas에 심볼로 전달하여 `resolveSymbol(id:)`로 조회 후 그리기. `ctx.fill(Circle().path(...))`와 달리 **임의의 SwiftUI 뷰**를 Canvas에 배치 가능
- **상대 좌표 (0~1)**: 파티클 생성 시 캔버스 크기를 모르므로, 절대 좌표 대신 비율로 저장. 렌더링 시 `particle.x * size.width`로 변환
- **파티클 재활용**: 이전 예제는 파티클을 생성/소멸 반복. 라바램프는 **고정 개수**를 초기화 시 생성하고 방향만 뒤집으며 영구 재사용
- **`AnimatablePolygonShape`**: `[Double]`을 `animatableData`로 받아 불규칙 다각형 생성. `VectorArithmetic` 확장으로 SwiftUI가 배열 요소를 보간
- **타이머-애니메이션 비동기 트릭**: 타이머 1초 간격, 애니메이션 3초 duration — 완료 전 새 값이 들어와 끊김 없이 자연스러운 보간 유지

### Falling Snow와의 차이

| | Falling Snow | Lava Lamp |
|---|---|---|
| 파티클 수명 | 2초 후 소멸 | 영구 (방향 전환으로 재활용) |
| 좌표 체계 | 절대 좌표 (px) | 상대 좌표 (0~1) |
| 이동 방향 | 위→아래 (일방향) | 위↔아래 (양방향 전환) |
| 파티클 크기 | 고정 32pt | 랜덤 100~250pt |
| 생성 방식 | 매 프레임 1개씩 추가 | 초기화 시 고정 개수 일괄 생성 |
| 그리기 방식 | `ctx.fill(Circle().path(...))` | Canvas `symbols` + `resolveSymbol(id:)` |
| `Identifiable` | 불필요 | 필수 (심볼 조회용) |
| 블롭 형태 | 원 | `Circle()` 또는 `AnimatingPolygon` (토글) |

### 불규칙 다각형 수학 (AnimatablePolygonShape)

1. 중심점과 최대 반지름 계산
2. 꼭짓점 개수(8개)에 대해 0~2π를 균등 분할하여 각도 산출
3. `cos(angle) × radius`, `sin(angle) × radius`로 정다각형 좌표 계산
4. 각 좌표에 `animatableData[i]` (0.8~1.2)를 곱하여 변 길이 변형

### 전체 코드

```swift
class LavaLampParticle: Identifiable {
    let id = UUID()
    var size = Double.random(in: 100...250)
    var x = Double.random(in: -0.1...1.1)
    var y = Double.random(in: -0.25...1.25)
    var isMovingDown = Bool.random()
    var speed = Double.random(in: 0.01...0.1)
}

class LavaLampParticleSystem {
    let particles: [LavaLampParticle]
    var lastUpdate = Date.now.timeIntervalSinceReferenceDate

    init(count: Int) {
        particles = (0..<count).map { _ in LavaLampParticle() }
    }

    func update(date: TimeInterval) {
        let delta = date - lastUpdate
        lastUpdate = date

        for particle in particles {
            if particle.isMovingDown {
                particle.y += particle.speed * delta
                if particle.y > 1.25 { particle.isMovingDown = false }
            } else {
                particle.y -= particle.speed * delta
                if particle.y < -0.25 { particle.isMovingDown = true }
            }
        }
    }
}

// [Double]을 SwiftUI 애니메이션 가능 타입으로 확장
extension Array: @retroactive VectorArithmetic, @retroactive AdditiveArithmetic where Element == Double {
    public mutating func scale(by rhs: Double) {
        for (index, item) in self.enumerated() {
            guard index < self.count else { return }
            self[index] = item * rhs
        }
    }
    public static func +=(lhs: inout [Double], rhs: [Double]) {
        for (index, item) in rhs.enumerated() {
            guard index < lhs.count else { return }
            lhs[index] += item
        }
    }
    public static func -=(lhs: inout [Double], rhs: [Double]) {
        for (index, item) in rhs.enumerated() {
            guard index < lhs.count else { return }
            lhs[index] -= item
        }
    }
    public static func -(lhs: [Double], rhs: [Double]) -> [Double] { [] }
    public static var zero: [Double] { [0] }
    public var magnitudeSquared: Double { 0 }
}

// 불규칙 다각형 Shape
struct AnimatablePolygonShape: Shape {
    var animatableData: [Double]

    init(points: [Double]) { animatableData = points }

    func path(in rect: CGRect) -> Path {
        Path { path in
            let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
            let radius = min(center.x, center.y)
            let lines = animatableData.enumerated().map { index, value in
                let fraction = Double(index) / Double(animatableData.count)
                let xPos = center.x + radius * cos(fraction * .pi * 2)
                let yPos = center.y + radius * sin(fraction * .pi * 2)
                return CGPoint(x: xPos * value, y: yPos * value)
            }
            path.addLines(lines)
        }
    }
}

struct AnimatingPolygon: View {
    @State private var points = Self.makePoints()
    @State private var timer = Timer.publish(every: 1, tolerance: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        AnimatablePolygonShape(points: points)
            .animation(.easeInOut(duration: 3), value: points)
            .onReceive(timer) { _ in points = Self.makePoints() }
    }

    static func makePoints() -> [Double] {
        (0..<8).map { _ in .random(in: 0.8...1.2) }
    }
}

struct LavaLampView: View {
    @State private var particleSystem = LavaLampParticleSystem(count: 15)
    @State private var threshold = 0.5
    @State private var blur = 30.0
    @State private var usePolygon = false

    var body: some View {
        VStack {
            LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom).mask {
                TimelineView(.animation) { timeline in
                    Canvas { ctx, size in
                        particleSystem.update(date: timeline.date.timeIntervalSinceReferenceDate)
                        ctx.addFilter(.alphaThreshold(min: threshold))
                        ctx.addFilter(.blur(radius: blur))

                        ctx.drawLayer { ctx in
                            for particle in particleSystem.particles {
                                guard let symbol = ctx.resolveSymbol(id: particle.id) else { continue }
                                let point = CGPoint(x: particle.x * size.width, y: particle.y * size.height)
                                ctx.draw(symbol, at: point)
                            }
                        }
                    } symbols: {
                        ForEach(particleSystem.particles) { particle in
                            symbol(particle: particle)
                                .frame(width: particle.size, height: particle.size)
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .background(.indigo)

            LabeledContent("Use Polygon") {
                Toggle("", isOn: $usePolygon)
            }
            .padding(.horizontal)

            LabeledContent("Threshold") {
                Slider(value: $threshold, in: 0.01...0.99)
            }
            .padding(.horizontal)

            LabeledContent("Blur") {
                Slider(value: $blur, in: 0...40)
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func symbol(particle: LavaLampParticle) -> some View {
        if usePolygon {
            AnimatingPolygon()
        } else {
            Circle()
        }
    }
}
```

### 주요 포인트

- **Canvas `symbols` 패턴**: `symbols:` 클로저에서 `ForEach`로 뷰 생성 → `resolveSymbol(id:)`로 조회 → `ctx.draw(symbol, at:)`로 배치
- 상대 좌표 범위가 0~1을 약간 초과 (`-0.1...1.1`, `-0.25...1.25`): 화면 밖에서 자연스럽게 진입/퇴장하기 위함
- `usePolygon` 토글로 `Circle()` ↔ `AnimatingPolygon()` 전환 — `@ViewBuilder` 함수로 심볼만 교체하면 파티클 시스템은 수정 불필요
- **`-` 연산자와 `magnitudeSquared`는 더미 구현**: 프로토콜 요구사항이지만 실제 애니메이션에서 호출되지 않음
- **`tolerance: 1`**: 타이머에 1초 허용 오차를 줘서 iOS가 타이머를 합쳐(coalesce) 실행 — 배터리 효율 개선
- blur 슬라이더를 0으로 내리면 불규칙 다각형 원본 형태를 확인 가능

## Blurred backgrounds

Canvas 없이 기본 Shape + 애니메이션 + blur만으로 부드러운 배경 효과를 만드는 기법.

### 핵심 구조

**BackgroundBlob** — 랜덤 위치·크기·색상의 타원(Ellipse)을 회전 애니메이션으로 움직이는 단일 뷰

```swift
struct BackgroundBlob: View {
    @State private var rotationAmount = 0.0
    let alignment: Alignment = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing].randomElement()!
    let color: Color = [.blue, .cyan, .indigo, .mint, .purple, .teal].randomElement()!

    var body: some View {
        Ellipse()
            .fill(color)
            .frame(width: .random(in: 200...500), height: .random(in: 200...500))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .offset(x: .random(in: -400...400), y: .random(in: -400...400))
            .rotationEffect(.degrees(rotationAmount))
            .animation(.linear(duration: .random(in: 20...40)).repeatForever(), value: rotationAmount)
            .onAppear { rotationAmount = .random(in: -360...360) }
            .blur(radius: 75)
    }
}
```

**사용**: `ZStack` + `ForEach(0..<15)`로 15개 겹쳐서 배경색(`.blue`) 위에 배치

### 모디파이어 적용 순서와 역할

| 순서 | 모디파이어 | 역할 |
|------|-----------|------|
| 1 | `.frame(width:height:)` | 타원 크기 랜덤 설정 (200~500) |
| 2 | `.frame(maxWidth:maxHeight:alignment:)` | 화면 코너 중 하나에 배치 |
| 3 | `.offset(x:y:)` | 추가 랜덤 위치 이동 (-400~+400) |
| 4 | `.rotationEffect()` | **offset 뒤에 적용** → 원래 위치를 중심으로 공전 |
| 5 | `.blur(radius: 75)` | 색상이 자연스럽게 섞이는 핵심 효과 |

### 주요 포인트

- **`rotationEffect`를 `offset` 뒤에 적용**하는 것이 핵심 — 뷰가 원래 위치를 중심으로 원형 궤도를 그리며 움직임
- `.onAppear`에서 `rotationAmount`를 변경하면 `.animation` 모디파이어가 자동으로 반복 애니메이션 시작
- `blur(radius: 75)` 한 줄로 날카로운 타원들이 부드럽게 블렌딩됨
- 배경색과 같은 색(`.blue`)의 blob이 다른 색을 잘라내는(cut out) 효과를 만듦
- 애니메이션 duration `2...4`는 데모용, 실제 사용 시 `20...40`으로 느리게 설정 권장

## Magic with SpriteKit

SpriteKit + Metal 셰이더를 활용하여 SwiftUI 뷰에 물결(water ripple) 효과를 적용하는 기법.

### 핵심 개념

- **Fragment Shader (GLSL)**: 텍스처의 각 픽셀에 대해 실행되는 GPU 프로그램. 요청된 좌표 대신 **근처 좌표의 픽셀을 반환**하여 물 굴절 효과 시뮬레이션
- **`SKShader`**: SpriteKit에서 GLSL 셰이더를 로드·실행. GLSL → MSL(Metal) 자동 변환으로 성능 최적화
- **`SKUniform`**: 셰이더에 외부 값(speed, strength, frequency)을 전달하는 유니폼 변수. `u_` 접두사 관례
- **`ImageRenderer`**: SwiftUI 뷰를 `UIImage`로 렌더링. SpriteKit 텍스처로 변환하기 위한 브릿지
- **`SpriteView(options: .allowsTransparency)`**: SpriteKit 씬을 SwiftUI 뷰 계층에 투명 배경으로 임베딩

### 아키텍처 구조

| 계층 | 역할 |
|------|------|
| **GLSL 셰이더** | 픽셀 단위 물결 왜곡 계산 (cos/sin으로 X/Y 오프셋) |
| **`WaterScene` (SKScene)** | 셰이더를 SKSpriteNode에 적용, 텍스처 관리 |
| **`WaterEffect<Content>` (SwiftUI View)** | SwiftUI 뷰 → UIImage → SpriteKit 텍스처 변환 브릿지 |
| **`ContentView`** | 슬라이더로 speed/strength/frequency 실시간 조절 |

### 셰이더 코드

```glsl
void main() {
    float speed = u_time * u_speed;

    v_tex_coord.x += cos((v_tex_coord.x + speed) * u_frequency) * u_strength;
    v_tex_coord.y += sin((v_tex_coord.y + speed) * u_frequency) * u_strength;

    gl_FragColor = texture2D(u_texture, v_tex_coord);
}
```

**동작 원리**: 각 픽셀의 원래 좌표에 `cos`/`sin` 기반 오프셋을 더해 인접 픽셀을 읽음 → 물결 굴절 효과. `u_frequency`가 높으면 잔잔한 파문이 많아지고, `u_strength`가 크면 왜곡이 강해짐

### 전체 코드

```swift
// MARK: - WaterScene (SpriteKit)
class WaterScene: SKScene {
    private let spriteNode = SKSpriteNode()
    var image: UIImage?

    let waterShader = SKShader(source: """
    void main() {
        float speed = u_time * u_speed;
        v_tex_coord.x += cos((v_tex_coord.x + speed) * u_frequency) * u_strength;
        v_tex_coord.y += sin((v_tex_coord.y + speed) * u_frequency) * u_strength;
        gl_FragColor = texture2D(u_texture, v_tex_coord);
    }
    """)

    override func sceneDidLoad() {
        backgroundColor = .clear
        scaleMode = .resizeFill
        spriteNode.shader = waterShader
        addChild(spriteNode)
    }

    func updateTexture() {
        guard view != nil else { return }
        guard let image else { return }

        let texture = SKTexture(image: image)
        spriteNode.texture = texture
        spriteNode.size = texture.size()
        spriteNode.position.x = frame.midX
        spriteNode.position.y = frame.midY
    }

    override func didMove(to view: SKView) {
        updateTexture()
    }
}

// MARK: - WaterEffect (SwiftUI Bridge)
struct WaterEffect<Content: View>: View {
    @State private var scene = WaterScene()
    @Environment(\.displayScale) var displayScale

    var speed: Double
    var strength: Double
    var frequency: Double
    @ViewBuilder var content: () -> Content

    var body: some View {
        let renderer = ImageRenderer(content: content())
        renderer.scale = displayScale
        let image = renderer.uiImage
        let size = image?.size ?? .zero

        scene.waterShader.uniforms = [
            SKUniform(name: "u_speed", float: Float(speed)),
            SKUniform(name: "u_strength", float: Float(strength) / 20.0),
            SKUniform(name: "u_frequency", float: Float(frequency))
        ]

        scene.image = image
        scene.updateTexture()

        return SpriteView(scene: scene, options: .allowsTransparency)
            .frame(width: size.width, height: size.height)
    }
}

// MARK: - ContentView
struct ContentView: View {
    @State private var text = "Hello"
    @State private var speed = 0.5
    @State private var strength = 0.5
    @State private var frequency = 5.0

    var body: some View {
        VStack {
            WaterEffect(speed: speed, strength: strength, frequency: frequency) {
                Circle()
                    .fill(.red)
                    .frame(width: 150, height: 150)
                    .padding()
                    .overlay(Circle().stroke(.red, lineWidth: 4))
                    .overlay(Text(text).font(.title).foregroundColor(.white))
                    .padding()
            }

            TextField("Enter a message", text: $text)
                .textFieldStyle(.roundedBorder)

            LabeledContent("Speed") {
                Slider(value: $speed)
            }
            LabeledContent("Strength") {
                Slider(value: $strength)
            }
            LabeledContent("Frequency") {
                Slider(value: $frequency, in: 5...25)
            }
        }
        .padding()
    }
}
```

### 주요 포인트

- **`strength / 20.0`**: 사용자가 0~1 범위로 조절하지만, 셰이더에는 매우 작은 오프셋만 필요하므로 20으로 나눠서 전달
- **`renderer.scale = displayScale`**: 기본 1.0 스케일이면 Retina 디스플레이에서 흐릿하게 보임. `@Environment(\.displayScale)`로 2x/3x 스케일 적용
- **SwiftUI 뷰에 padding 필수**: 셰이더가 경계 밖 픽셀을 읽으면 Metal이 반대편 좌표로 래핑하므로, 여백이 있어야 자연스러움
- **`WaterScene`이 class인 이유**: SpriteKit의 `SKScene`을 상속해야 하므로 class 필수. `@State`로 참조 유지
- **CPU 부하 최소**: 셰이더는 GPU에서 병렬 실행되므로 CPU 사용량이 극히 낮음











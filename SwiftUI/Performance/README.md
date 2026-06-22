# Performance

## Delaying work…

- 가장 빠른 코드는 실행되지 않는 코드 — 작업을 건너뛰거나 지연시키기
- **Debounce** = 입력이 일정 시간 멈춘 후에야 작업 수행. 0.1초만으로도 큰 성능 향상
- **Combine 방식**: `$input.debounce(for:scheduler:).sink` → `@Published output`으로 전파. 바인딩에 적합
- **Task 방식**: `Task.sleep` 후 작업 실행, 재호출 시 기존 Task `cancel()` → 새로 스케줄

### 예시 1: Combine 기반 Debouncer

```swift
import SwiftUI
internal import Combine

class Debouncer<T>: ObservableObject {
    @Published var input: T
    @Published var output: T

    private var debounce: AnyCancellable?

    init(initialValue: T, delay: Double = 1) {
        self.input = initialValue
        self.output = initialValue

        debounce = $input
            .debounce(for: .seconds(delay), scheduler: DispatchQueue.main)
            .sink { [weak self] in
                self?.output = $0
            }
    }
}

struct DelayingWork1: View {
    @StateObject private var text = Debouncer(initialValue: "", delay: 0.5)
    @StateObject private var slider = Debouncer(initialValue: 0.0, delay: 0.1)

    var body: some View {
        VStack {
            TextField("Search for something", text: $text.input)
                .textFieldStyle(.roundedBorder)
            Text(text.output)

            Spacer().frame(height: 50)

            Slider(value: $slider.input, in: 0...100)
            Text(slider.output.formatted())
        }
    }
}
```

### 예시 2: Task 기반 debounce

```swift
import SwiftUI

extension DelayingWork2 {
    class ViewModel: ObservableObject {
        private var refreshTask: Task<Void, Error>?
        var workCounter = 0

        func doWorkNow() {
            workCounter += 1
            print("Work done: \(workCounter)")
        }

        func scheduleWork() {
            refreshTask?.cancel()

            refreshTask = Task {
                try await Task.sleep(until: .now + .seconds(3), clock: .continuous)
                doWorkNow()
            }
        }
    }
}

struct DelayingWork2: View {
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack {
            Button("Do Work Soon", action: viewModel.scheduleWork)
            Button("Do Work Now", action: viewModel.doWorkNow)
        }
    }
}
```

## ...or skipping it entirely

- 작업을 지연시키는 것보다 더 좋은 건 **아예 건너뛰는 것**
- 클래스를 `@StateObject`로 감시할 필요 없으면 **`@State`로 저장** → 변경 추적 없이 캐시처럼 활용 (예: `CIContext` 같은 무거운 객체)
- `let`으로 저장하면 뷰 재생성마다 인스턴스가 파괴·재할당되므로 주의
- **`onAppear()`는 뷰가 표시될 때마다 호출됨** → TabView 탭 전환 시 반복 실행
- 초기화를 한 번만 수행하고 싶다면 **`onFirstAppear()` 커스텀 modifier** 사용

### 예시 1: @State를 캐시로 활용 (CIContext)

```swift
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct SkippingWork1: View {
    @State private var context = CIContext()
    @State private var name = "Paul"

    var body: some View {
        VStack {
            TextField("Enter your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding()

            Image(uiImage: generateQRCode(from: "\(name)"))
                .resizable()
                .interpolation(.none)
                .frame(width: 200, height: 200)
        }
    }

    func generateQRCode(from string: String) -> UIImage {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)

        if let output = filter.outputImage {
            if let cgImage = context.createCGImage(output, from: output.extent) {
                return UIImage(cgImage: cgImage)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
```

### 예시 2: onAppear()의 반복 호출 문제

```swift
struct SkippingWork2: View {
    var body: some View {
        TabView {
            ForEach(1..<6) { i in
                ExampleView(number: i)
                    .tabItem { Label(String(i), systemImage: "\(i).circle") }
            }
        }
    }
}

struct ExampleView: View {
    let number: Int

    var body: some View {
        Text("View \(number)")
            .onAppear {
                print("View \(number) appearing")
            }
    }
}
```

### 예시 3: onFirstAppear() modifier

```swift
struct OnFirstAppearModifier: ViewModifier {
    @State private var hasLoaded = false
    var perform: () -> Void

    func body(content: Content) -> some View {
        content.onAppear {
            guard hasLoaded == false else { return }
            hasLoaded = true
            perform()
        }
    }
}

extension View {
    func onFirstAppear(perform: @escaping () -> Void) -> some View {
        modifier(OnFirstAppearModifier(perform: perform))
    }
}

// 사용
Text("View \(number)")
    .onFirstAppear {
        print("View \(number) appearing")
    }
```

### 플랫폼별 modifier로 불필요한 코드 제거

```swift
public extension View {
    func watchOS<Content: View>(_ modifier: @escaping (Self) -> Content) -> some View {
        #if os(watchOS)
        modifier(self)
        #else
        self
        #endif
    }
}

// 사용 — watchOS 외 플랫폼에서는 컴파일러가 최적화로 제거
Text("Hello, world!")
    .watchOS { $0.padding(0) }
```

## Watching for changes

- SwiftUI 성능 저하의 가장 흔한 원인: **외부 객체 변경으로 인한 불필요한 뷰 재계산**
- `@State` 변경은 명확하지만, `@ObservedObject`/`@EnvironmentObject` 변경은 원인 추적이 어려움

### Apple 제공 디버깅 API

1. **`Self._printChanges()`** — Apple이 SwiftUI에 내장한 디버깅 메서드. `body` 안에서 호출하면 **어떤 프로퍼티가 변경을 유발했는지** 콘솔에 출력해준다. 언더스코어 접두사(`_`)가 붙어 있어 private API처럼 보이지만, WWDC21에서 공식 소개된 디버깅 도구다. 릴리즈 빌드에서는 사용하지 않는 것을 권장.
   - `let _ = Self._printChanges()` 또는 `Self._printChanges(); return ...` 형태로 사용
   - 출력 예: `ContentView: _viewModel changed`

```swift
class AutorefreshingObject: ObservableObject {
    var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.objectWillChange.send()
        }
    }
}

struct WatchingForChanges2: View {
    @StateObject private var viewModel = AutorefreshingObject()

    var body: some View {
        let _ = Self._printChanges()
        Text("Example View Here")
    }
}
// 콘솔 출력 예: "WatchingForChanges2: _viewModel changed"
```

### 커스텀 디버깅 기법

2. **`.background(.random)`** — `Color.random` extension을 만들어 뷰가 재계산될 때마다 배경색이 바뀌도록 함. 시각적으로 즉시 확인 가능

```swift
extension ShapeStyle where Self == Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

class AutorefreshingObject: ObservableObject {
    var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.objectWillChange.send()
        }
    }
}

struct WatchingForChanges1: View {
    @StateObject private var viewModel = AutorefreshingObject()

    var body: some View {
        Text("Example View Here")
            .background(.random)
    }
}
```

3. **`debugPrint()` / `debugExecute()`** — View extension으로 진단 코드 주입. `#if DEBUG`로 감싸서 릴리즈 빌드에서 자동 제거
4. **`.assert()` modifier** — View에 조건 검증을 추가. 조건 위반 시 Xcode가 실행 중단. `@autoclosure` + `Swift.assert()`로 릴리즈에서 컴파일 아웃

```swift
extension View {
    func debugPrint(_ value: @autoclosure () -> Any) -> some View {
        #if DEBUG
        print(value())
        #endif
        return self
    }

    func debugExecute(_ function: () -> Void) -> some View {
        #if DEBUG
        function()
        #endif
        return self
    }

    func debugExecute(_ function: (Self) -> Void) -> some View {
        #if DEBUG
        function(self)
        #endif
        return self
    }

    public func assert(
      _ condition: @autoclosure () -> Bool,
      _ message: @autoclosure () -> String = String(),
      file: StaticString = #file, line: UInt = #line
    ) -> some View {
        Swift.assert(condition(), message(), file: file, line: line)
        return self
    }
}

// 사용 — counter가 100 이상이면 assert로 실행 중단
struct WatchingForChanges3: View {
    @State private var counter = 0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Text("⚠️ Xcode will trigger a crash when the number below reaches 100")
                .multilineTextAlignment(.center)
            Text(String(counter))
                .font(.largeTitle)
        }
        .onReceive(timer) { _ in
            counter += 1
        }
        .assert(counter < 100, "Timer exceeded")
    }
}
```

### 근본 원인과 해결

- `@ObservedObject`를 사용하면 해당 객체의 **모든 프로퍼티** 변경에 뷰가 반응 → 필요한 부분만 구독하도록 분리
- 앱이 커지면서 공유 ViewModel의 작은 변경이 연쇄 리프레시를 일으키는 패턴이 흔함
- 해결: environment key를 활용해 필요한 데이터만 선택적으로 의존


## The SwiftUI cycle of events

- SwiftUI의 뷰 생성·갱신 순서를 직접 print로 찍어보면 예상 밖의 동작을 확인할 수 있음

### 주요 발견 사항

- **`@State` 프로퍼티 초기화가 `init()`보다 먼저** 실행됨
- **화면에 보이지 않는 뷰의 `init()`도 즉시 호출됨** — `NavigationLink`의 destination인 `DetailView.init()`이 앱 시작 시 호출
- **`body`는 여러 번 재호출될 수 있음** — SwiftUI가 원할 때 언제든 호출
- **실행 순서**: `onAppear()` → `task()` 순서로 실행. 같은 종류의 modifier끼리는 코드 순서대로 실행
- **`onAppear()` / `task()`는 뷰가 화면에 표시될 때만 실행** — `init()`/`body`와 달리 실제로 필요한 시점

### 예시: 라이프사이클 이벤트 순서 확인

```swift
//@main
struct TestApp: App {
    @State private var property = ExampleProperty(location: "App")

    var body: some Scene {
        print("In App.body")

        return WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
    }

    init() {
        print("In App.init")
    }
}

extension TestApp {
    struct ExampleProperty {
        init(location: String) {
            print("Creating ExampleProperty from \(location)")
        }
    }

    struct ExampleModifier: ViewModifier {
        init(location: String) {
            print("Creating ExampleModifier from \(location)")
        }

        func body(content: Content) -> some View {
            print("In ExampleModifier.body()")
            return content
        }
    }

    struct ContentView: View {
        @State private var property = ExampleProperty(location: "ContentView")

        var body: some View {
            print("In ContentView.body")

            return NavigationLink("Hello, world!") {
                DetailView()
            }
            .modifier(ExampleModifier(location: "ContentView"))
            .task { print("In first task") }
            .task { print("In second task") }
            .onAppear { print("In first onAppear") }
            .onAppear { print("In second onAppear") }
        }

        init() {
            print("In ContentView.init")
        }
    }

    struct DetailView: View {
        @State private var property = ExampleProperty(location: "DetailView")

        var body: some View {
            print("In DetailView.body")

            return Text("Hello, world!")
                .modifier(ExampleModifier(location: "DetailView"))
                .task { print("In detail task") }
                .onAppear { print("In detail onAppear") }
        }

        init() {
            print("In DetailView.init")
        }
    }
}
```

### 핵심 원칙

- **`init()`은 가볍게 유지** — 네트워크 호출이나 무거운 작업 금지. SwiftUI가 언제든 빈번하게 호출할 수 있음
- **실제 작업은 `onAppear()` 또는 `task()`로** — 뷰가 화면에 추가되는 시점에 실행되므로 불필요한 작업을 방지

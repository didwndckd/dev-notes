# Sendable

> data race 없이 임의의 동시 컨텍스트에서 값을 공유할 수 있는 스레드 안전 유형.

## References

### WWDC
- [Protect mutable state with Swift actors (WWDC21)](https://developer.apple.com/videos/play/wwdc2021/10133/) — actor와 함께 Sendable이 처음 소개된 세션
- [Eliminate data races using Swift Concurrency (WWDC22)](https://developer.apple.com/videos/play/wwdc2022/110351/) — Sendable 검사의 동작 원리와 isolation을 가장 깊게 다룸

### 공식 문서
- [Sendable | Apple Developer Documentation](https://developer.apple.com/documentation/swift/sendable)
- [Concurrency — The Swift Programming Language](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency)

### Swift Evolution
- [SE-0302: Sendable and @Sendable closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)

## 기본 개념

``` swift
protocol Sendable : SendableMetatype
```

- **Sendable**은 데이터 레이스(data race)의 위험 없이 동시성 컨텍스트 간에(서로 다른 Task나 actor 사이) 안전하게 전달·공유할 수 있는 타입임을 나타내는 **마커 프로토콜(marker protocol)** 이다.
- 메서드나 프로퍼티 요구사항이 없으며, 컴파일러에게 "이 타입은 동시성 경계를 넘어도 안전하다"는 의미만 전달한다. 컴파일 타임에 검사되고 런타임 비용은 없다.
- 어떤 값을 actor의 격리 경계 밖으로 넘기거나(예: actor 메서드의 인자/반환값), `Task` 클로저로 캡처하려면 그 값의 타입이 `Sendable`이어야 한다.

> **`SendableMetatype`은 뭔가?** Swift 6.2부터 `Sendable`은 `SendableMetatype`을 상위 프로토콜로 갖는다([SE-0470](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0470-isolated-conformances.md)). 값이 아니라 **타입(메타타입) 자체를 동시성 경계 너머로 넘겨도 안전한가**를 표현하며, 제네릭에서 `T.self`를 actor 사이로 전달하거나 actor에 격리된 conformance를 쓸 때 검사에 쓰인다. 거의 모든 `Sendable` 타입이 자동으로 만족하므로 직접 채택할 일은 드물고, "`Sendable`이면 그 메타타입도 보낼 수 있다"는 보장을 분리해 둔 것 정도로 이해하면 된다.

### Sendable한 타입의 조건

**값 타입(struct, enum)**: 저장된 모든 프로퍼티 / 연관값이 `Sendable`이면 안전하다. 값은 복사되어 전달되므로 공유 상태가 생기지 않는다.

``` swift
struct User: Sendable {
    let id: Int
    let name: String
}

enum State: Sendable {
    case idle
    case loaded(User)   // 연관값 User가 Sendable
}
```

**불변 클래스**: `final` 클래스이고 모든 저장 프로퍼티가 불변(`let`)이며 그 타입들이 `Sendable`이면 안전하다.

``` swift
final class Token: Sendable {
    let value: String
    init(value: String) { self.value = value }
}

// var 프로퍼티가 있으면 컴파일 에러 → 공유 시 변경될 수 있어 안전하지 않음
final class Mutable: Sendable {
    var count = 0   // ❌ stored property 'count' is mutable
}
```

**actor**: 자신의 격리(isolation)로 가변 상태를 보호하므로 항상 암묵적으로 `Sendable`이다. 별도 선언 없이도 actor 인스턴스는 경계를 넘길 수 있다.

``` swift
actor BankAccount {
    private var balance = 0          // 가변 상태지만 actor 격리로 보호됨
    func deposit(_ amount: Int) { balance += amount }
}

let account = BankAccount()
Task { await account.deposit(100) } // Sendable 이므로 클로저로 캡처 가능
```

**global actor로 격리된 클래스**: `@MainActor`(또는 임의의 global actor)로 격리된 타입은 **가변 `var` 프로퍼티가 있어도 암묵적으로 `Sendable`** 이다. actor와 마찬가지로 격리가 동시 접근을 막아주기 때문이다. SwiftUI의 ViewModel 패턴이 바로 이 경우다.

``` swift
@MainActor
class ViewModel {           // Sendable 선언 없이도 Sendable
    var items: [Item] = []  // var지만 main actor 격리로 보호됨
}

// @MainActor 격리이므로 Task로 캡처 가능
let vm = ViewModel()
Task { await print(vm.items.count) }
```

> 일반 `final class`는 `var`가 있으면 Sendable이 될 수 없지만(위 `Mutable` 예시), 격리가 걸린 클래스는 예외다. 보호 주체가 "불변성"에서 "격리"로 바뀐 것이다. → global actor 자세한 내용은 [Actor.md의 @MainActor](./Actor.md#mainactor) 참고

**내부 동기화를 직접 보장하는 클래스**: 락(`NSLock`, `DispatchQueue` 등)으로 가변 상태를 보호한다면 `@unchecked Sendable`로 직접 안전을 보장할 수 있다. → [@unchecked Sendable](#unchecked-sendable) 참고

**함수/클로저**: 타입 자체가 아니라 `@Sendable` 속성으로 표시한다. → [@Sendable 함수/클로저](#sendable-함수클로저) 참고

### 암묵적 적합성(implicit conformance)

`public`이 아닌 struct/enum은 조건을 만족하면 컴파일러가 자동으로 `Sendable` 적합성을 부여한다.

``` swift
// 모든 프로퍼티가 Sendable → 자동으로 Sendable
struct Point {
    let x: Int
    let y: Int
}
```

단, 모듈 밖으로 공개되는 `public` 타입은 의도를 명시해야 하므로 직접 `Sendable`을 채택해야 한다. 제네릭 타입은 타입 파라미터가 `Sendable`일 때만 조건부로 `Sendable`이 된다.

``` swift
struct Box<T: Sendable>: Sendable {
    let value: T
}
```

### 표준 라이브러리의 조건부 Sendable

컬렉션·`Optional` 같은 표준 타입은 그 자체로 항상 Sendable인 게 아니라, **담고 있는 원소(element)가 Sendable일 때만 조건부로(conditionally)** Sendable이다. `[NonSendable]`이 왜 경계를 못 넘는지 헷갈릴 때 이 규칙을 떠올리면 된다.

``` swift
let a: [Int]            // ✅ Int가 Sendable → [Int]도 Sendable
let b: [String: User]   // ✅ Key/Value 모두 Sendable
let c: [NonSendable]    // ❌ 원소가 non-Sendable → 배열도 non-Sendable, 경계 못 넘음
```

| 타입 | 조건 |
|---|---|
| `Optional<Wrapped>` | `Wrapped: Sendable` |
| `Array<Element>` / `Set<Element>` | `Element: Sendable` |
| `Dictionary<Key, Value>` | `Key: Sendable`, `Value: Sendable` |
| `Result<Success, Failure>` | `Success`, `Failure` 모두 `Sendable` |
| 튜플 `(A, B, ...)` | 모든 구성 요소가 `Sendable` |
| `Range`, `ClosedRange` 등 | `Bound: Sendable` |

> `Int`, `String`, `Bool`, `Double`, `UUID`, `Date` 등 대부분의 값 타입은 이미 `Sendable`이다. 반면 `NSObject` 계열(예: `NSMutableArray`)이나 클로저를 담은 박스 타입은 non-Sendable인 경우가 많다.

### @unchecked Sendable

컴파일러가 안전성을 검증할 수 없지만 개발자가 스레드 안전을 직접 보장하는 경우 사용한다.

``` swift
final class Cache: @unchecked Sendable {
    private var storage: [String: Int] = [:]
    private let lock = NSLock()

    func value(for key: String) -> Int? {
        lock.lock(); defer { lock.unlock() }
        return storage[key]
    }
}
```

> ⚠️ **`@unchecked`는 컴파일러 검사를 통째로 끄는 약속**이다. 안전 보장은 전적으로 개발자 몫이고, 흔한 실수가 컴파일은 되지만 런타임 데이터 레이스로 이어진다.
> - 모든 가변 접근 경로에 락을 걸지 않음 (한 군데라도 빠지면 무효)
> - 값 타입(struct)에 `@unchecked`를 남용 — 보통 불필요하며, 정말 필요하면 설계가 잘못됐다는 신호
> - 락 없이 그냥 검사만 통과시키려고 붙이는 경우
> 가능하면 `actor`나 격리(`@MainActor`)로 해결하고, `@unchecked`는 그것이 불가능한 마지막 수단으로만 쓴다.

### nonisolated(unsafe)

`@unchecked Sendable`이 **타입 전체**의 검사를 끄는 것이라면, `nonisolated(unsafe)`는 **저장 프로퍼티/전역 변수 하나**만 동시성 검사에서 제외하는 핀포인트 탈출구다([SE-0412](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0412-strict-concurrency-for-global-variables.md)). 마찬가지로 안전은 개발자가 보장해야 한다.

``` swift
// 전역 변수: Swift 6에서는 Sendable이 아니면 기본적으로 접근이 막힌다
nonisolated(unsafe) var sharedCounter = 0   // "내가 동기화를 책임진다"고 선언

// non-Sendable 타입을 어쩔 수 없이 프로퍼티로 둘 때
final class Wrapper: @unchecked Sendable {
    nonisolated(unsafe) var legacy: NonSendableThing
    private let lock = NSLock()
    // ... lock으로 legacy 접근 보호 ...
}
```

> `@unchecked Sendable`은 "이 **타입**은 보내도 된다", `nonisolated(unsafe)`는 "이 **저장 위치**는 격리/Sendable 검사에서 빼라"는 의미다. 둘 다 컴파일러의 안전망을 끄는 것이므로 범위를 최소로 좁혀서 쓴다.

### @Sendable 함수/클로저

함수나 클로저 타입에 `@Sendable`을 붙이면, 그 안에서 캡처하는 값들이 모두 `Sendable`이어야 한다는 제약이 걸린다. `@Sendable`을 적용하는 위치는 두 가지다.

**① 파라미터 타입에 붙이기 — 함수가 요구**

함수 시그니처가 "Sendable 클로저만 받는다"고 선언하면, 호출 측은 `@Sendable`을 직접 쓰지 않아도 컴파일러가 자동으로 추론·검사한다. 같은 클로저를 여러 동시성 컨텍스트에서 **공유**할 때 필요하다(소유권을 한 번만 넘기는 `sending`과 달리).

``` swift
func runConcurrently(_ work: @Sendable @escaping () -> Void) {
    for _ in 0..<3 {
        Task { work() }   // 같은 클로저를 여러 Task에서 동시 실행 → 공유되므로 @Sendable 필요
    }
}

runConcurrently {
    print("hello")   // 자동으로 @Sendable. 여기서 non-Sendable 캡처하면 컴파일 에러
}
```

**② 클로저 리터럴에 붙이기 `{ @Sendable in ... }` — 작성자가 명시**

받는 쪽이 `@Sendable`을 요구하지 않는 상황에서, 그 클로저를 Sendable로 만들고 싶을 때 직접 표시한다. 예를 들어 Sendable 타입의 프로퍼티로 클로저를 저장할 때 그 클로저도 `@Sendable`이어야 한다.

``` swift
struct Job: Sendable {
    let work: @Sendable () -> Void   // Sendable 타입의 프로퍼티 → 클로저도 @Sendable
}

// @Sendable in 이 없으면 일반 클로저로 추론되어 Job에 넣을 수 없음
let work = { @Sendable in
    print("hello")
}
// work의 타입: @Sendable () -> Void

let job = Job(work: work)
```

> 결과(클로저가 `@Sendable`이라는 사실)는 같고, 차이는 그 제약을 **함수 시그니처가 거는지** vs **클로저 리터럴에 내가 직접 다는지**다. 파라미터에서 이미 `@Sendable`을 요구하면 리터럴에 다시 `@Sendable in`을 쓸 필요는 없다.

## @preconcurrency import — 아직 Sendable이 안 붙은 모듈 다루기

아직 동시성 어노테이션이 없는(=Sendable 적합성이 정리되지 않은) 구버전 라이브러리 타입을 쓰면, 경계를 넘을 때마다 Sendable 경고가 쏟아진다. 그 모듈이 곧 업데이트될 것이라 믿고 **경고만 일시적으로 억제**하고 싶을 때 `@preconcurrency import`를 쓴다.

``` swift
@preconcurrency import LegacyKit

// LegacyKit의 타입을 경계 너머로 넘겨도 Sendable 경고가 나지 않음
func use(_ value: LegacyType) {
    Task { process(value) }   // @preconcurrency 없으면 경고/에러
}
```

- 해당 모듈에서 온 타입을 **"Sendable 검사 이전(pre-concurrency) 코드"** 로 간주해 경고를 죽인다.
- 나중에 그 모듈이 정식으로 `Sendable`을 채택하면, 컴파일러가 **"이제 `@preconcurrency`가 불필요하다"** 고 알려준다 → 그때 떼면 된다.
- 어디까지나 **마이그레이션 도구**다. 안전을 보장해주는 게 아니라 "아직 정리 안 된 모듈이니 일단 믿고 넘어간다"는 표시이므로, 실제로 그 타입이 thread-safe한지는 직접 확인해야 한다.

> 특정 선언 하나에만 적용하고 싶으면 `@preconcurrency`를 함수/프로토콜 준수 등에 직접 붙일 수도 있다. import 전체에 거는 것은 가장 넓은(모듈 단위) 적용이다.

## 관련 문서

- [sending](./sending.md) — non-Sendable 값을 경계 너머로 **이동(transfer)** 시키는 키워드. Sendable 요구를 완화하는 보완 개념이며, strict concurrency checking 모드(minimal/targeted/complete)와 region-based isolation도 여기서 다룬다.
- [Actor.md](./Actor.md) — actor·`@MainActor`·global actor 격리. 격리가 어떻게 Sendable을 대체하는지의 배경.


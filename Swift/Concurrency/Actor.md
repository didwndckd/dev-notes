# Actor

## Actor란?

Actor는 **동시성 환경에서 안전하게 사용할 수 있는 참조 타입**이다. 컴파일러가 두 개 이상의 코드가 동시에 actor의 데이터에 접근하는 것을 원천적으로 차단한다.

## 주요 특징

- `actor` 키워드로 생성
- **참조 타입** (class처럼 상태 공유에 유용)
- 프로퍼티, 메서드, 이니셜라이저, 서브스크립트 지원
- 프로토콜 준수 가능, 제네릭 지원
- **상속 불가** → `convenience init`, `final`, `override` 사용 불가
- 모든 actor는 자동으로 `Actor` 프로토콜 준수

## 외부에서 접근 시 await 필요

Actor 외부에서 가변 프로퍼티를 읽거나 메서드를 호출할 때는 반드시 `await`를 사용해야 한다.

```swift
actor User {
    var score = 10

    func printScore() {
        print("My score is \(score)")  // 내부 접근: await 불필요
    }

    func copyScore(from other: User) async {
        score = await other.score  // 다른 actor 접근: await 필요
    }
}

let user = User()
print(await user.score)  // 외부 접근: await 필요
```

## 동작 원리

- Actor는 내부적으로 **메시지 큐(inbox)** 를 운영
- 요청을 순서대로 하나씩 처리 (task priority로 우선순위 조정 가능)
- 한 번에 하나의 코드만 가변 상태에 접근 가능 → **Actor Isolation**
- 상수(`let`) 프로퍼티는 `await` 없이 접근 가능
- 외부에서 프로퍼티 **쓰기는 불가** (`await` 여부와 무관)

## 왜 필요한가?

- **특정 객체에 대한 접근을 한 번에 하나의 task로 제한**해야 할 때 유용
- 예: UI 작업(메인 스레드), 데이터베이스 접근(SwiftData의 model actor)
- **Data Race 방지**: 동시 접근으로 인한 예측 불가능한 결과를 원천 차단

## 참고

- Actor 함수는 **재진입(reentrant)** 가능 → 하나의 task가 실행 중일 때 다른 task가 시작될 수 있음
- Actor 인스턴스 생성 비용은 class와 동일
- 보호된 상태 접근 시에만 task 일시 중단이 발생할 수 있음

## Actor vs Class vs Struct 비교

| 특성 | Actor | Class | Struct |
|------|-------|-------|--------|
| **타입** | 참조 타입 | 참조 타입 | 값 타입 |
| **상속** | ❌ | ✅ | ❌ |
| **Actor 프로토콜** | 자동 준수 | ❌ | ❌ |
| **AnyObject 프로토콜** | 자동 준수 | 자동 준수 | ❌ |
| **Deinitializer** | ✅ | ✅ | ❌ |
| **외부 직접 접근** | ❌ (await 필요) | ✅ | ✅ |
| **동시 메서드 실행** | ❌ (한 번에 하나) | ✅ | ✅ |

### 언제 Actor를 사용하는가?

**적합한 경우:**
- Serial queue를 대체할 때 (순차적 작업 필요)
- 데이터베이스 접근 관리
- 공유 상태의 thread-safe 접근이 필요할 때

**부적합한 경우:**
- SwiftUI 데이터 모델 → `@Observable` 또는 `ObservableObject` class 사용
- 상속이 필요한 경우 → class 사용
- 복사 의미론이 필요한 경우 → struct 사용

### SwiftUI에서의 사용

```swift
// ❌ 잘못된 사용: SwiftUI 데이터 모델에 actor 사용
actor BadViewModel {
    var items: [Item] = []  // 모든 접근에 await 필요 → 불편
}

// ✅ 올바른 사용: @Observable class + @MainActor
@MainActor
@Observable
class GoodViewModel {
    var items: [Item] = []  // UI 업데이트에 적합
}

// ✅ 비동기 작업이 필요하면 별도의 sibling actor 생성
actor DataService {
    func fetchItems() async -> [Item] {
        // 백그라운드에서 데이터 로드
    }
}
```

## 사용 예시

### 기본 사용법

1. `actor` 키워드로 타입 생성
2. 외부에서 프로퍼티/메서드 접근 시 `await` 사용

```swift
actor AuthenticationManager {
    // Actor 내부의 가변 상태 - 외부에서 직접 접근 불가
    var token: String?

    // 연산 프로퍼티도 actor isolation 적용
    var isAuthenticated: Bool {
        token != nil
    }

    // 네트워크 요청을 통한 인증 처리
    func authenticate(username: String, password: String) async throws {
        let url = URL(string: "https://example.com/auth")!
        // async 작업 수행 - actor 내부에서 await 사용 가능
        let (data, _) = try await URLSession.shared.data(from: url)
        // actor 내부에서 자신의 프로퍼티 수정 - await 불필요
        token = String(decoding: data, as: UTF8.self)
    }
}

// Actor 인스턴스 생성 - class와 동일한 비용
let manager = AuthenticationManager()

// 첫 번째 Task: 로그인 시도
Task {
    // actor의 메서드 호출 - await 필요
    try await manager.authenticate(username: "user", password: "pass")
    // actor의 프로퍼티 읽기 - await 필요
    if let token = await manager.token {
        print("Token: \(token)")
    }
}

// 두 번째 Task: 인증 상태 확인 (동시에 실행되어도 안전)
Task {
    // 연산 프로퍼티 접근도 await 필요
    let authenticated = await manager.isAuthenticated
    print("Authenticated: \(authenticated)")
}
```

### Data Race 문제 해결 예시

**Class 사용 시 문제점 (Data Race 발생 가능)**

```swift
class BankAccount {
    var balance: Decimal

    func transfer(amount: Decimal, to other: BankAccount) {
        // 문제 1: 잔액 확인과 차감 사이에 다른 스레드가 끼어들 수 있음
        guard balance >= amount else { return }
        // 문제 2: 여러 스레드가 동시에 이 줄을 실행할 수 있음
        balance = balance - amount
        // 문제 3: other도 동시에 접근될 수 있음
        other.deposit(amount: amount)
    }
}
```

두 개의 `transfer()` 호출이 동시에 실행되면:
1. 첫 번째 호출: 잔액 확인 → 충분함
2. 두 번째 호출: 잔액 확인 → 아직 충분함 (첫 번째가 아직 차감 안 함)
3. 둘 다 차감 실행 → **마이너스 잔액 발생!**

**Actor로 해결**

```swift
actor BankAccount {
    // Actor가 보호하는 가변 상태
    var balance: Decimal

    init(initialBalance: Decimal) {
        balance = initialBalance
    }

    // 내부 메서드 - 자신의 balance 접근 시 await 불필요
    func deposit(amount: Decimal) {
        balance = balance + amount
    }

    // 다른 actor와 상호작용하므로 async 필요
    func transfer(amount: Decimal, to other: BankAccount) async {
        // Actor isolation: 이 검사와 차감이 원자적으로 실행됨
        guard balance > amount else { return }
        balance = balance - amount
        // 다른 actor의 메서드 호출 - await 필요
        // other의 메시지 큐에 요청이 들어감
        await other.deposit(amount: amount)
    }
}

// Actor 인스턴스 생성
let first = BankAccount(initialBalance: 500)
let second = BankAccount(initialBalance: 0)

// Actor의 메서드 호출 - await 필요
await first.transfer(amount: 500, to: second)
```

Actor를 사용하면 한 번에 하나의 요청만 처리되므로 Data Race가 원천 차단된다.

## Actor 초기화

Actor는 자체 executor에서 실행되지만, **초기화 중에는 executor가 아직 준비되지 않은 상태**이다.

### async 이니셜라이저의 특징

- 모든 프로퍼티가 초기화되면 자동으로 actor의 executor로 전환됨
- 초기화 전후로 **다른 스레드에서 실행될 수 있음** (암시적 actor hop 발생)

```swift
actor Actor {
    var name: String

    // async 이니셜라이저
    init(name: String) async {
        // 이 시점: actor executor 준비 안 됨 (임의의 스레드)
        print(name)

        // 프로퍼티 초기화 완료
        self.name = name

        // 이 시점: actor executor로 전환됨 (다른 스레드일 수 있음)
        print(name)
    }
}

// async init 호출 - await 필요
let actor = await Actor(name: "Meryl")
```

> 두 `print()` 호출이 서로 다른 스레드에서 실행될 수 있다.

## Executor

**Executor**는 actor의 코드가 실행되는 **실행 컨텍스트**이다.

### 개념

- 각 actor 인스턴스는 자체 **serial executor**를 가짐
- Serial executor는 작업을 **한 번에 하나씩** 순차적으로 실행
- `DispatchQueue`와 유사하지만, 우선순위 기반 스케줄링 지원 (FIFO가 아님)

### 기본 동작

```swift
actor Counter {
    var count = 0

    // 이 메서드는 Counter의 executor에서 실행됨
    func increment() {
        count += 1
    }
}
```

- 일반 actor: Swift 런타임이 제공하는 기본 executor 사용
- `@MainActor`: 메인 스레드의 executor 사용
- Custom executor: `SerialExecutor` 프로토콜 구현으로 직접 정의 가능 (SE-0392)

## Actor Hop

**Actor hop**은 실행 컨텍스트가 한 actor에서 다른 actor로 전환되는 것을 의미한다.

### 발생 시점

```swift
actor ActorA {
    func doWork() async {
        // ActorA의 executor에서 실행 중

        let b = ActorB()
        await b.process()  // Actor hop 발생! → ActorB의 executor로 전환

        // 다시 ActorA의 executor로 복귀
        print("Back to A")
    }
}

actor ActorB {
    func process() {
        // ActorB의 executor에서 실행
        print("Processing in B")
    }
}
```

### 특징

- `await` 키워드가 있는 곳에서 hop이 발생할 수 있음
- Hop은 **suspension point** (일시 중단 지점)
- Hop 전후로 actor의 상태가 변경되었을 수 있음 → **재진입(reentrancy)** 주의

### 성능 고려사항

- Actor hop에는 컨텍스트 스위칭 비용이 발생
- 동일 actor 내에서는 hop 없이 직접 호출 가능
- 빈번한 hop은 성능에 영향을 줄 수 있음
- 자세한 내용은 하단의 [Actor Hop 성능 문제와 해결책](#actor-hop-성능-문제와-해결책) 참조

## Actor 재진입 (Reentrancy)

Actor-isolated 함수는 **재진입 가능(reentrant)** 하다. 이전 작업이 완료되기 전에 새로운 작업이 시작될 수 있다는 의미다.

### 핵심 개념

- `await` 키워드는 **잠재적 일시 중단 지점(suspension point)**
- 일시 중단된 동안 actor는 **다른 작업을 시작**할 수 있음
- 재개 후 **상태가 변경되었을 수 있음**

### 예제: 재진입으로 인한 예상치 못한 결과

```swift
actor Player {
    var name = "Anonymous"
    var score = 0

    func addToScore() {
        Task {
            score += 1  // 1. 점수 증가
            try? await Task.sleep(for: .seconds(1))  // 2. 일시 중단 → 다른 작업 실행 가능
            print("Score is now \(score)")  // 3. 재개 시 score 값이 변경되어 있을 수 있음
        }
    }
}

let player = Player()
await player.addToScore()  // score = 1, 출력 시점에는 3
await player.addToScore()  // score = 2, 출력 시점에는 3
await player.addToScore()  // score = 3, 출력 시점에는 3

try? await Task.sleep(for: .seconds(1.1))
// 출력: "Score is now 3" 세 번 (모두 3을 출력)
```

### 실행 흐름 (Interleaving)

```
시간 →
Task 1: [score += 1] → [sleep...] → [print(3)]
Task 2:      [score += 1] → [sleep...] → [print(3)]
Task 3:           [score += 1] → [sleep...] → [print(3)]
```

1. Task 1이 `score += 1` 실행 → score = 1
2. Task 1이 sleep으로 일시 중단, actor가 Task 2 시작
3. Task 2가 `score += 1` 실행 → score = 2
4. Task 2가 sleep으로 일시 중단, actor가 Task 3 시작
5. Task 3가 `score += 1` 실행 → score = 3
6. 모든 Task가 깨어나서 print → 모두 "3" 출력

### 중요 규칙

- **두 작업이 병렬로 실행되지 않음**: 동시에 실행되는 건 아님
- 여러 작업이 진행 중일 수 있지만, **한 번에 하나만 실행**
- 동기 코드는 중단점 없이 끝까지 실행됨

### 왜 재진입을 허용하는가?

- **성능**: Actor가 대기 중인 작업을 진행할 수 있음
- **데드락 방지**: 두 작업이 서로를 기다리며 멈추는 상황 방지

### 주의사항

```swift
// ⚠️ 잘못된 접근: Actor 내부에서 수동 락 사용
actor BadExample {
    var lock = NSLock()  // ❌ Actor 설계 의도에 반함
}

// ✅ 올바른 접근: 재진입 방지가 필요하면 별도의 serial queue 사용
```

**핵심**: 재진입 방지가 필요하다면 actor 대신 **별도의 serial dispatch queue**를 고려하라.

## isolated 파라미터

`isolated` 키워드를 사용하면 **함수를 특정 actor 인스턴스의 격리 도메인에서 실행**시킬 수 있다. 이를 통해 actor 내부처럼 `await` 없이 프로퍼티에 직접 접근 가능하다.

### 격리의 방향 — 함수가 인자 쪽으로 끌려 들어간다

가장 헷갈리기 쉬운 부분이다. `isolated`는 **인자를 내 격리 안으로 데려오는 게 아니라, 함수가 그 인자(actor)의 격리 도메인 *안으로* 들어가는** 것이다.

> **함수** → **인자(actor)의 격리 도메인**에서 실행됨

그래서 호출하는 쪽에서는 그 인자의 도메인으로 hop이 일어나므로 `await`가 필요하고, 함수 본문 안에서는 그 인자가 이미 자기 도메인이므로 `await` 없이 직접 접근할 수 있다.

### 사용법

```swift
actor DataStore {
    var username = "Anonymous"
    var friends = [String]()
    var highScores = [Int]()
    var favorites = Set<Int>()

    init() {
        // 데이터 로드
    }

    func save() {
        // 데이터 저장
    }
}

// isolated 키워드로 함수를 actor에 격리
func debugLog(dataStore: isolated DataStore) {
    // await 없이 직접 접근 가능!
    print("Username: \(dataStore.username)")
    print("Friends: \(dataStore.friends)")
    print("High scores: \(dataStore.highScores)")
    print("Favorites: \(dataStore.favorites)")

    // 쓰기도 가능
    dataStore.username = "NewName"
}

let data = DataStore()
// 함수 자체가 actor에서 실행되므로 await 필요
await debugLog(dataStore: data)
```

### 특징

- 함수 전체가 해당 actor의 executor에서 실행됨
- Actor의 안전성은 그대로 유지됨 (한 번에 하나의 스레드만 접근)
- `async`로 선언하지 않아도 호출 시 `await` 필요
- 함수 전체가 하나의 suspension point가 됨 (개별 접근이 아닌)
- **두 개의 isolated 파라미터는 불가** → 어떤 actor에서 실행할지 모호해짐

### 일반 함수 vs isolated 함수

```swift
// 일반 함수: 각 접근마다 await 필요
func normalLog(dataStore: DataStore) async {
    print(await dataStore.username)  // await 필요
    print(await dataStore.friends)   // await 필요
}

// isolated 함수: await 없이 직접 접근
func isolatedLog(dataStore: isolated DataStore) {
    print(dataStore.username)  // await 불필요
    print(dataStore.friends)   // await 불필요
}
```

### actor 안에서 isolated 파라미터 받기

actor의 일반 인스턴스 메서드는 기본적으로 `self`에 격리된다. 그런데 **메서드에 `isolated` 파라미터를 선언하면, 격리 대상이 `self` → 그 파라미터로 바뀐다.** `nonisolated`를 붙일 필요가 없으며(붙이면 오히려 에러), 그 안에서 `self`는 **nonisolated로 취급**된다.

```swift
actor DataStore {
    var x = 0

    // ✅ 그냥 컴파일됨. 이 메서드는 self가 아니라 other에 격리됨
    func foo(other: isolated DataStore) {
        other.x += 1   // ✅ other 도메인 → await 없이 직접 접근
        // x += 1       // ❌ self는 nonisolated 취급 → 격리 상태 접근 불가
    }
}
```

주의할 점:

- **`nonisolated`를 붙이면 에러다.** `isolated` 파라미터가 이미 격리를 지정하므로 중복/모순이다.
  ```swift
  // ❌ error: instance method with 'isolated' parameter cannot be 'nonisolated'
  nonisolated func bar(other: isolated DataStore) {}
  ```
- **`isolated` 파라미터는 함수당 하나만** 가능하다. (explicit 파라미터를 선언하면 self의 암묵적 격리는 풀리므로, self와 충돌하는 게 아니라 explicit 파라미터가 2개일 때만 에러)
  ```swift
  // ❌ error: cannot have more than one 'isolated' parameter
  func baz(a: isolated DataStore, b: isolated DataStore) {}
  ```

| 선언 | 무엇에 격리되나 | 메서드 안 `self` |
|---|---|---|
| 일반 인스턴스 메서드 | `self` | 격리됨 |
| isolated 파라미터를 받는 메서드 | **그 파라미터** | nonisolated 취급 |
| `nonisolated` 메서드 (isolated 파라미터 없음) | 아무 데도 안 됨 | nonisolated |

> 즉 `isolated` 파라미터는 그 메서드의 **격리 대상을 self에서 파라미터로 옮기는** 스위치다. `static` 메서드나 actor 밖의 자유 함수(위 `debugLog(dataStore:)`)는 애초에 self 격리가 없어 동일하게 동작한다.

## nonisolated

`nonisolated` 키워드를 사용하면 actor의 메서드나 연산 프로퍼티를 **격리에서 제외**할 수 있다. 이를 통해 외부에서 `await` 없이 호출 가능하다.

### 사용법

```swift
import CryptoKit
import Foundation

actor User {
    // 상수 프로퍼티 - 기본적으로 외부 접근 허용
    let username: String
    let password: String

    // 가변 프로퍼티 - 격리됨
    var isOnline = false

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    // nonisolated 메서드 - 외부에서 await 없이 호출 가능
    nonisolated func passwordHash() -> String {
        // 상수 프로퍼티(password)만 접근 가능
        let passwordData = Data(password.utf8)
        let hash = SHA256.hash(data: passwordData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

let user = User(username: "twostraws", password: "s3kr1t")
// await 없이 직접 호출!
print(user.passwordHash())
```

### 규칙

- `nonisolated` 메서드/연산 프로퍼티는 **다른 nonisolated 멤버만 접근 가능**
- 상수(`let`) 프로퍼티는 기본적으로 nonisolated처럼 동작
- **저장 프로퍼티에는 nonisolated 사용 불가** (연산 프로퍼티만 가능)
- 격리된 상태에 접근하려면 `await` 사용 필요

### 연산 프로퍼티에 적용

```swift
actor User {
    let firstName: String
    let lastName: String

    // nonisolated 연산 프로퍼티
    nonisolated var fullName: String {
        // 상수 프로퍼티만 접근
        "\(firstName) \(lastName)"
    }
}

let user = User(firstName: "Paul", lastName: "Hudson")
print(user.fullName)  // await 불필요
```

### 주의사항

- `Codable`, `Equatable` 등 동기 프로토콜 준수 시에는 도움이 안 됨
- 격리된 상태가 필요한 프로토콜 메서드는 여전히 문제가 될 수 있음

## @MainActor

`@MainActor`는 **메인 스레드에서 실행되는 global actor**이다. UI 업데이트가 항상 메인 스레드에서 실행되도록 보장한다.

### 타입에 적용

```swift
// @Observable 클래스에 적용
@Observable @MainActor
class AccountViewModel {
    // 모든 프로퍼티와 메서드가 메인 스레드에서 실행됨
    var username = "Anonymous"
    var isAuthenticated = false
}

// ObservableObject에 적용
@MainActor
class LegacyViewModel: ObservableObject {
    @Published var username = "Anonymous"
    @Published var isAuthenticated = false
}
```

### SwiftUI와의 관계

- **Xcode 16+**: `View`를 준수하는 모든 struct가 자동으로 main actor에서 실행
- 그러나 observable 클래스에는 여전히 `@MainActor` 명시 권장
- 특정 메서드를 main actor에서 제외하려면 `nonisolated` 사용

> Observable 객체에는 일반 `actor`가 아닌 `@MainActor`를 사용해야 함. UI 업데이트는 반드시 main actor에서 실행되어야 하기 때문.

### MainActor.run()

어디서든 메인 스레드에서 코드를 실행할 수 있다.

```swift
func couldBeAnywhere() async {
    // 메인 스레드에서 실행
    await MainActor.run {
        print("This is on the main actor.")
    }
}

// 값 반환도 가능
func fetchAndUpdate() async {
    let result = await MainActor.run {
        // UI 업데이트 로직
        return 42
    }
    print(result)
}
```

### Task에서 @MainActor 사용

동기 컨텍스트에서 main actor로 작업을 보낼 때 유용하다.

```swift
func couldBeAnywhere() {
    // 방법 1: MainActor.run() 사용
    Task {
        await MainActor.run {
            print("This is on the main actor.")
        }
    }

    // 방법 2: Task 클로저에 @MainActor 적용
    Task { @MainActor in
        print("This is on the main actor.")
    }

    // 다른 작업 계속 실행
}
```

### 실행 순서 주의

```swift
@MainActor @Observable
class ViewModel {
    func runTest() async {
        print("1")

        await MainActor.run {
            print("2")

            // Task는 다음 run loop까지 대기
            Task { @MainActor in
                print("3")
            }

            print("4")
        }

        print("5")
    }
}

let model = ViewModel()
await model.runTest()
// 출력: 1, 2, 4, 5, 3
```

- `MainActor.run()`: 이미 main actor면 **즉시 실행**
- `Task { @MainActor in }`: 항상 **다음 run loop까지 대기**

### 주의사항

- `@MainActor` 클래스의 메서드라도 내부에서 백그라운드 작업이 실행될 수 있음
  - 어디까지나 `Swift Concurrency`내에서 보장, `DispatchQueue` 사용시 적용 안됨

- 예: Face ID의 `evaluatePolicy()` 완료 핸들러는 백그라운드 스레드에서 호출됨
- 완전한 보호가 아니므로 필요시 명시적으로 `MainActor.run()` 사용

## 코드가 실행되는 Actor 결정

async 함수가 어떤 actor에서 실행될지는 **호출하는 쪽이 아닌 함수 자체가 결정**한다.

### 흔한 오해

```swift
Task { @MainActor in
    // 이 클로저의 동기 코드는 main actor에서 실행됨
    await downloadData()  // 하지만 이 함수는 어디서 실행될까?
}
```

`downloadData()`가 main actor에서 실행될 것이라고 생각할 수 있지만, 실제로는 **함수 정의에 따라 달라진다**.

### 함수 정의에 따른 실행 위치

```swift
// 경우 1: actor 지정 없음 → Swift가 자유롭게 선택 (대부분 백그라운드)
func downloadData() async {
    // main actor에서 실행되지 않을 가능성 높음
}

// 경우 2: @MainActor 명시 → 항상 main actor에서 실행
@MainActor
func downloadData() async {
    // 반드시 main actor에서 실행
}

// 경우 3: @MainActor 타입의 메서드 → 항상 main actor에서 실행
@MainActor
class DataFetcher {
    func downloadData() async {
        // 반드시 main actor에서 실행
    }
}
```

### @MainActor in의 실제 의미

```swift
Task { @MainActor in
    print("1 - main actor")       // main actor에서 실행
    await downloadData()           // downloadData() 정의에 따라 다름
    print("2 - main actor")       // main actor에서 실행
}
```

`@MainActor in`은 **클로저 본문의 동기 코드**만 main actor에서 실행하도록 보장한다. `await`로 호출하는 async 함수는 해당 함수의 정의에 따라 실행 위치가 결정된다.

### 핵심 규칙

> **async 함수는 호출 방식과 무관하게 자신이 실행될 위치를 스스로 결정한다.**

- `await`는 potential suspension point (잠재적 일시 중단 지점)
- suspension point에서 Swift는 실행을 필요한 곳으로 자유롭게 이동시킴
- 함수가 특정 actor에서 실행되길 원하면 **함수 정의에 명시**해야 함

## Global Actor Inference

Global actor inference는 특정 규칙에 따라 `@MainActor`가 **자동으로 추론**되는 기능이다.

> 💡**Swift 6 언어 모드에서는 비활성화됨**. Swift 5.5 ~ 5.10에서만 적용.

### 5가지 추론 규칙

#### 1. 클래스 상속

`@MainActor` 클래스를 상속하면 서브클래스도 자동으로 `@MainActor`.

```swift
@MainActor
class Parent { }

// Child도 자동으로 @MainActor
class Child: Parent { }
```

#### 2. 메서드 오버라이드

`@MainActor` 메서드를 오버라이드하면 해당 메서드도 자동으로 `@MainActor`.

```swift
class Parent {
    @MainActor func update() { }
}

class Child: Parent {
    // 자동으로 @MainActor
    override func update() { }
}
```

#### 3. Property Wrapper

`@MainActor`를 wrapped value에 적용하는 property wrapper 사용 시 해당 타입 전체가 `@MainActor`.

```swift
// SwiftUI의 @StateObject, @ObservedObject가 이에 해당
struct ContentView: View {
    @StateObject var viewModel = ViewModel()  // View 전체가 @MainActor
}
```

#### 4. 프로토콜의 @MainActor 메서드

프로토콜의 `@MainActor` 메서드를 구현할 때, **준수와 구현을 동시에** 하면 자동 추론.

```swift
protocol DataStoring {
    @MainActor func save()
}

// 준수와 구현을 동시에 → 자동 @MainActor
extension DataStore1: DataStoring {
    func save() { }  // 자동으로 @MainActor
}

// 준수와 구현을 분리 → 명시 필요
struct DataStore2: DataStoring { }

extension DataStore2 {
    @MainActor func save() { }  // 명시적으로 @MainActor 필요
}
```

#### 5. @MainActor 프로토콜 준수

`@MainActor` 프로토콜을 **타입 선언과 동시에** 준수하면 타입 전체가 `@MainActor`.

```swift
@MainActor protocol DataStoring {
    func save()
}

// 타입 선언과 동시에 준수 → 타입 전체가 @MainActor
struct DataStore1: DataStoring {
    func save() { }  // 타입 전체가 @MainActor
}

// 별도 extension에서 준수 → 메서드만 @MainActor
struct DataStore2 { }  // 이 타입은 @MainActor 아님

extension DataStore2: DataStoring {
    func save() { }  // 이 메서드만 @MainActor
}
```

### 왜 이런 구분이 있는가?

외부 라이브러리(Apple 타입 등)에 `@MainActor` 프로토콜 준수를 추가할 때, 해당 타입 전체를 `@MainActor`로 만들면 기존 동작이 깨질 수 있다. 따라서 **extension으로 준수를 추가하면 메서드만** `@MainActor`가 된다.

---

# 문제 해결

## Actor Hop 성능 문제와 해결책

### Cooperative Thread Pool

Swift의 동시성 모델은 **cooperative thread pool**을 사용한다:
- 시스템은 CPU 코어 수만큼의 스레드를 유지
- 일반 actor들은 이 pool에서 실행
- **Main Actor는 별도의 main thread**에서 실행

### Main Actor와 Cooperative Pool 간 Hop

Main Actor와 일반 actor 간 전환은 **스레드 간 컨텍스트 스위칭**을 발생시킨다:

```swift
actor DataProcessor {
    // Cooperative thread pool에서 실행됨
    func process() async {
        for item in items {
            // 매번 main thread로 hop - 비용 발생!
            await updateUI(item)
        }
    }
}

@MainActor
func updateUI(_ item: Item) {
    // Main thread에서 실행됨
}
```

#### 문제가 되는 패턴

```swift
// ❌ 비효율적: 매 iteration마다 main thread hop
for item in items {
    await MainActor.run {
        label.text = item.description
    }
}
```

### 해결책: 배치 처리

```swift
// ✅ 효율적: 한 번의 hop으로 모든 UI 업데이트
let results = items.map { $0.description }
await MainActor.run {
    for (index, result) in results.enumerated() {
        labels[index].text = result
    }
}
```

**핵심**: 가능하면 actor 경계를 넘는 호출을 **배치 처리**하여 hop 횟수를 줄인다.

## SwiftUI 데이터 모델에 Actor 사용 금지

> ⚠️ **중요**: SwiftUI 데이터 모델에 actor를 사용하지 마라.

### 왜 Actor가 SwiftUI에 부적합한가?

SwiftUI는 **main actor에서 UI를 업데이트**한다. `@Observable` 또는 `ObservableObject`를 사용하면 모든 작업이 main actor에서 수행되어야 한다.

Custom actor를 사용하면:
1. **데이터 쓰기**: main actor가 아닌 custom actor에서 발생 → UI 업데이트 위치 불일치
2. **데이터 읽기**: `TextField` 바인딩 시 main actor와 custom actor를 동시에 사용해야 함 → 불가능

```swift
// ❌ SwiftUI 데이터 모델에 actor 사용
actor BadViewModel {
    var text: String = ""   // TextField 바인딩 불가능!
}

// SwiftUI View에서:
// TextField("입력", text: $viewModel.text)  // ❌ 컴파일 에러
```

### 올바른 패턴: @MainActor class + Sibling Actor

```swift
// ✅ UI 데이터 모델: @Observable class + @MainActor
@MainActor
@Observable
class ViewModel {
    var items: [Item] = []
    var isLoading = false

    private let dataService = DataService()

    func loadItems() async {
        isLoading = true
        items = await dataService.fetchItems()  // sibling actor 호출
        isLoading = false
    }
}

// ✅ 비동기 작업: 별도의 sibling actor (main actor 아님)
actor DataService {
    func fetchItems() async -> [Item] {
        // 백그라운드에서 안전하게 데이터 로드
    }
}
```

**핵심**: UI 데이터는 `@MainActor` class로, 백그라운드 작업은 별도의 **sibling actor**로 분리한다.

## 참조 문서

- [SE-0306: Actors](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0306-actors.md) - Actor 기본 제안서
- [SE-0327: Actor Initializers](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0327-actor-initializers.md) - Actor 초기화 관련
- [SE-0392: Custom Actor Executors](https://forums.swift.org/t/accepted-se-0392-custom-actor-executors/64817) - Custom Executor 제안서

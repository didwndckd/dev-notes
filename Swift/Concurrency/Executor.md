# Executor

## Executor란?

**Executor**는 Swift Concurrency에서 **job(작업)을 실제로 실행하는 주체**이다. actor와 task가 만들어낸 작업 조각을 받아서 **스레드 위에 스케줄링**하는 역할을 한다.

- `async/await`로 작성한 코드는 컴파일러에 의해 여러 개의 **job**(부분 작업)으로 쪼개진다.
- 각 job은 어딘가에서 실행되어야 하는데, 그 "어딘가"가 바로 **executor**이다.
- 즉 executor는 **"이 일을 어느 스레드에서 돌릴 것인가"** 를 결정한다.

```
async 함수 ──컴파일러──▶ job 조각들 ──enqueue──▶ Executor ──▶ Thread Pool
```

## Job (ExecutorJob)

**Job**은 executor가 실행하는 **작업의 최소 단위**이다.

- `ExecutorJob`: job을 표현하는 **move-only 구조체** (`~Copyable`)
- `priority`: job의 우선순위
- `runSynchronously(on:)`: 주어진 executor 위에서 job을 동기적으로 실행 (consuming)

```swift
// 모든 executor의 기반 프로토콜.
// AnyObject: executor는 참조 타입(클래스)이어야 함 → 식별(identity)이 필요하기 때문
// Sendable: executor 자체가 여러 스레드를 넘나들며 공유되므로 동시성 안전해야 함
public protocol Executor: AnyObject, Sendable {
    // 런타임이 "이 job을 실행해라"라고 호출하는 유일한 진입점.
    // consuming: job은 move-only라서, 받은 즉시 소유권을 가져와 한 번만 실행함
    func enqueue(_ job: consuming ExecutorJob)
}
```

> `enqueue(_:)`가 모든 executor의 핵심이다. "job을 받아서 적절한 시점/스레드에 실행시켜라"가 전부다.

## Executor 프로토콜 계층

| 프로토콜 | 역할 | 동시성 | 도입 |
|---|---|---|---|
| `Executor` | 모든 executor의 기반. `enqueue` 정의 | - | - |
| `SerialExecutor` | **상호 배제(mutual exclusion)** 보장. actor isolation 담당 | 한 번에 하나 | Swift 5.9 (SE-0392) |
| `TaskExecutor` | task를 실행할 **스레드 공급원** | 동시 실행 가능 | Swift 6.0 (SE-0417) |

- **SerialExecutor** = "직렬 접근을 보장한다" (actor의 안전성)
- **TaskExecutor** = "어느 스레드 풀에서 일을 꺼내올 것인가" (실행 위치)
- 한 타입이 두 프로토콜을 **동시에 구현**할 수도 있다.

## 기본 Executor: Cooperative Thread Pool

커스텀 executor를 지정하지 않으면, Swift 런타임이 제공하는 **기본 executor**가 사용된다. 이는 **Cooperative Thread Pool(협력적 스레드 풀)** 로 동작한다. (자세한 런타임 동작은 → [[Swift-Concurrency-Behind-the-Scenes]])

- **스레드 수를 CPU 코어 수만큼으로 제한** → GCD의 thread explosion(스레드 폭발) 방지
- 스레드는 항상 **forward progress(전진)** 한다는 런타임 계약을 지킨다
  - `await`에서 블로킹하지 않고 **suspend(일시 중단)** → 스레드는 다음 작업을 집어든다
  - 그래서 `semaphore`, `NSCondition` 같이 스레드를 막는 프리미티브를 task 경계에서 쓰면 안 된다
- **global concurrent executor**: `nonisolated async` 함수가 기본적으로 hop 해서 실행되는 곳 (단, 이 기본 동작은 Swift 6.1까지의 모델이다 → 아래 [TaskExecutor](#taskexecutor-se-0417) 섹션의 ⚠️ 참고)

| 구분 | GCD | Cooperative Thread Pool |
|---|---|---|
| 스레드 생성 | 필요 시 적극 생성 (폭발 위험) | 코어 수로 제한 |
| 블로킹 | 스레드를 막음 | suspend 후 스레드 재사용 |
| 컨텍스트 스위칭 | 잦음 | 최소화 |

> 커스텀 executor는 이 기본 동작을 바꾸고 싶을 때(특정 스레드 고정, 전용 풀 등) 쓰는 것이다. 대부분의 앱은 기본 executor로 충분하다.

## SerialExecutor

**SerialExecutor**는 job을 **한 번에 하나씩** 실행하여 상호 배제를 보장한다. 각 actor 인스턴스는 자신만의 serial executor를 가진다. (→ [[Actor]]의 Executor 섹션)

- 가장 친숙한 예가 **`MainActor`** 다. MainActor는 **메인 스레드에 묶인 serial executor**(`MainActor.shared.unownedExecutor`) 위에서 모든 작업을 직렬 실행한다 — UI 코드가 항상 메인 스레드에서 도는 근거다.
- 단, **global actor(MainActor 등)는 "인스턴스마다 하나"가 아니라 타입 전체가 단일 공유 executor**를 쓴다는 점이 일반 actor와 다르다.

### 핵심 API

```swift
// Executor를 상속받아 "한 번에 하나씩(직렬)" 실행을 보장하는 프로토콜.
// actor가 자신의 상태를 안전하게 지키는(상호 배제) 근거가 됨
public protocol SerialExecutor: Executor {
    // 런타임이 "현재 어느 executor 위에 있는지" 비교할 때 쓰는 경량 식별자를 반환.
    // 매번 ARC(retain/release) 비용을 치르지 않도록 unowned 래퍼로 감쌈
    func asUnownedSerialExecutor() -> UnownedSerialExecutor

    // 서로 다른 인스턴스라도 "사실상 같은 실행 컨텍스트"로 취급해야 할 때 구현(선택).
    // 예: 같은 DispatchQueue를 가리키는 두 executor를 동일하게 보고 싶을 때
    func isSameExclusiveExecutionContext(other: Self) -> Bool
}
```

- `UnownedSerialExecutor`: 참조 카운팅 없이 executor를 식별하기 위한 경량 래퍼
  - `init(ordinary:)`: 단순 포인터 식별
  - `init(complexEquality:)`: 커스텀 동등성이 필요할 때

### 커스텀 SerialExecutor 구현

`DispatchSerialQueue`를 백킹으로 하는 가장 단순한 형태:

```swift
final class DispatchQueueExecutor: SerialExecutor {
    // 실제 직렬성을 보장해주는 백킹 큐. 이 큐가 "한 번에 하나씩"을 책임짐
    let queue: DispatchSerialQueue

    init(queue: DispatchSerialQueue) {
        self.queue = queue
    }

    func enqueue(_ job: consuming ExecutorJob) {
        // ExecutorJob은 move-only(~Copyable)라 클로저에 그대로 캡처할 수 없음.
        // UnownedJob으로 감싸 "복사 가능한 핸들"로 바꿔야 큐 클로저에 넘길 수 있음
        let unownedJob = UnownedJob(job)
        // 직렬 큐에 비동기로 올림 → 실제 실행 스레드/시점은 큐가 결정
        queue.async {
            // 이 executor 위에서 job 본문을 동기 실행. 끝나면 다음 job 차례로 넘어감
            unownedJob.runSynchronously(on: self.asUnownedSerialExecutor())
        }
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        // ordinary: 단순 포인터 동일성으로 executor를 식별(가장 일반적인 경우)
        UnownedSerialExecutor(ordinary: self)
    }

    // SE-0424: assumeIsolated/assertIsolated의 "지금 이 executor 위인가" 판별에서
    // 런타임이 executor identity 비교(isCurrentExecutor)로 증명하지 못했을 때만
    // 호출되는 last-resort 훅. 기본 구현은 fatalError라, identity 비교가 실패하는
    // 경로(예: 큐에 직접 올린 동기 콜백)에서 assumeIsolated를 쓰려면 구현이 필요.
    func checkIsolated() {
        // 백킹 큐 위에서 실행 중인지 확인 → 아니면 즉시 크래시
        dispatchPrecondition(condition: .onQueue(queue))
    }
}
```

> `DispatchSerialQueue` 자체가 이미 `SerialExecutor`를 채택(SE-0392)하므로, 위처럼 직접 만들지 않고 큐를 바로 executor로 쓸 수도 있다. 단 이 채택은 **Swift 5.9 / iOS 17 · macOS 14 이상**에서만 제공되므로, 그 이하를 지원해야 하면 가용성 가드(`@available` / `if #available`)가 필요하다.

> ⚠️ 위 예제에서 쓴 `UnownedJob`은 **정확히 한 번만** `runSynchronously`로 실행해야 하는 unsafe 핸들이다. 두 번 실행하거나 실행하지 않으면 미정의 동작(UB)이 된다 — 큐 클로저가 반드시 1회 실행됨을 보장해야 한다.

## Actor에 커스텀 Executor 연결

actor의 `unownedExecutor` 프로퍼티를 오버라이드하면 해당 actor의 모든 작업이 지정한 executor에서 실행된다.

```swift
actor DataProcessor {
    // 이 actor 전용 executor. actor가 살아있는 동안 함께 유지됨
    private let executor: DispatchQueueExecutor

    init() {
        // 이 actor의 작업이 항상 돌아갈 직렬 큐를 생성
        let queue = DispatchSerialQueue(label: "com.app.dataprocessor")
        self.executor = DispatchQueueExecutor(queue: queue)
    }

    // 핵심: 이 프로퍼티를 오버라이드하면 런타임 기본 executor 대신 내 executor가 쓰임.
    // nonisolated여야 하는 이유 → actor에 진입(hop)할 "목적지 executor"를 정하는 정보라
    //                            actor 격리 바깥에서 접근 가능해야 함
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        executor.asUnownedSerialExecutor()
    }

    func process() {
        // 이 메서드를 누가 호출하든, 본문은 항상 com.app.dataprocessor 큐에서 실행됨
    }
}
```

### 언제 필요한가

- **스레드 친화성(thread affinity)** 이 필요한 경우: 스레드 안전하지 않은 DB 드라이버, Core Text 등
- 레거시 **C/C++/Objective-C** 코드와 통합 시 특정 스레드 고정이 필요할 때
- 기존 `DispatchQueue` 기반 코드를 actor 모델로 점진적으로 마이그레이션할 때

### 실전 예제: 전용 스레드에 고정하는 ThreadExecutor

위 `DispatchSerialQueue` 예제는 최소 형태이고, **특정 스레드 하나에 영구히 고정**해야 할 때(스레드 친화성)는 전용 스레드 + run loop를 직접 돌리는 형태가 필요하다.

```swift
// @unchecked Sendable: thread/runLoop를 가변 저장하지만 내부적으로 안전하게 다루므로
//                      컴파일러 동시성 검사를 수동으로 보증하겠다는 의미
public final class ThreadExecutor: SerialExecutor, @unchecked Sendable {
    // 이 executor가 소유한 단 하나의 전용 스레드
    private var thread: Thread!
    // 그 스레드 위에서 도는 run loop. 여기에 job을 실어 보냄
    private var runLoop: CFRunLoop!

    public init(name: String = "ThreadExecutor") {
        // 스레드가 run loop를 준비할 때까지 init이 기다리게 하는 동기화 신호
        let ready = DispatchSemaphore(value: 0)
        let thread = Thread { [weak self] in
            // 새 스레드 진입 직후, 그 스레드의 run loop를 캡처해 저장
            self?.runLoop = CFRunLoopGetCurrent()
            // run loop 준비 완료 → init 쪽 대기를 풀어줌
            ready.signal()
            // 이 스레드는 여기서 run loop를 돌며 영원히 살아있음(job을 계속 받기 위해)
            CFRunLoopRun()
        }
        thread.name = name
        self.thread = thread
        thread.start()
        // runLoop가 세팅되기 전에 enqueue가 호출되면 크래시 → 준비될 때까지 블록
        ready.wait()
    }

    public func enqueue(_ job: consuming ExecutorJob) {
        // move-only job을 클로저 캡처용 핸들로 변환 (DispatchQueue 예제와 동일한 이유)
        let unowned = UnownedJob(job)
        // 식별자를 미리 떠놓음(클로저 안에서 self 캡처를 줄이기 위함)
        let exec = asUnownedSerialExecutor()
        // 어느 스레드에서 호출되든, 실제 실행은 전용 스레드의 run loop로 넘김
        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue) {
            // 전용 스레드 위에서 job 본문 실행 → 스레드 affinity 달성
            unowned.runSynchronously(on: exec)
        }
        // run loop가 idle 상태로 잠들어 있을 수 있으니 깨워서 블록을 즉시 처리하게 함
        CFRunLoopWakeUp(runLoop)
    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    // SE-0424: 현재 호출이 정말 이 전용 스레드 위에서 일어나는지 검증.
    // assumeIsolated/assertIsolated가 이 훅을 통해 isolation을 판별한다.
    public func checkIsolated() {
        precondition(Thread.current === thread, "ThreadExecutor가 아닌 스레드에서 접근")
    }
}

actor ArchiveIndex {
    // nonisolated let: unownedExecutor에서 격리 없이 접근해야 하므로 nonisolated.
    //                  actor 생성과 동시에 전용 스레드도 함께 떠 있게 됨
    private nonisolated let exec = ThreadExecutor(name: "Archive-Index")

    // 이 actor의 모든 작업을 위 전용 스레드로 보내도록 연결
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        exec.asUnownedSerialExecutor()
    }

    func record(path: String, size: Int) {
        // 호출자가 메인 스레드든 백그라운드든, 본문은 늘 "Archive-Index" 스레드에서 실행.
        // → 스레드에 묶인(thread-unsafe) C 라이브러리 호출도 안전
    }
}
```

> 핵심은 `enqueue`가 job을 **항상 같은 스레드의 run loop**로 보낸다는 점이다. 덕분에 스레드 안전하지 않은 C 라이브러리도 안전하게 다룰 수 있다.

## Isolation 검증 / 가정 API

동기 코드에서 "지금 이 executor 위에 있다"는 것을 검증하거나 가정할 때 사용한다.

```swift
extension MyActor {
    // nonisolated: await 없이 동기적으로 호출되는 콜백(예: 델리게이트, C 콜백)
    nonisolated func callback() {
        // "이 콜백은 실제로 MyActor의 executor 위에서 호출된다"는 걸 개발자는 알지만
        // 컴파일러는 모름 → assumeIsolated로 그 사실을 런타임에 단언.
        // 단언이 틀리면(다른 executor였다면) 즉시 크래시 = 데이터 레이스보다 안전
        self.assumeIsolated { isolatedSelf in
            // 이 클로저 안에서는 actor 격리가 보장되므로 await 없이 isolated 멤버 접근 가능
            isolatedSelf.mutableState += 1
        }
    }
}
```

| API | 동작 |
|---|---|
| `assertIsolated()` | 예상 executor가 아니면 디버그 빌드에서 크래시 |
| `preconditionIsolated()` | 예상 executor가 아니면 릴리스 빌드에서도 크래시 |
| `assumeIsolated(_:)` | 해당 컨텍스트라고 가정하고 isolated 멤버 접근, 아니면 크래시 |

> 델리게이트/콜백이 "실제로는 해당 큐에서 호출되지만 컴파일러는 모르는" 상황을 안전하게 연결할 때 유용하다.

### 커스텀 executor에서는 `checkIsolated()`가 필요 (SE-0424)

위 API들은 런타임에 "지금 이 executor 위인가"를 판별해야 한다. 기본 executor는 런타임이 알아서 판별하지만, **커스텀 `SerialExecutor`** 의 경우 SE-0424(Swift 6.0)로 추가된 `func checkIsolated()`를 직접 구현할 수 있다.

**`checkIsolated()`는 "무조건" 불리는 게 아니라 last-resort다.** 런타임의 판별 순서는 대략 다음과 같다:

```
guard let current else { expected.checkIsolated() }    // ① 현재 executor를 아예 모를 때
if isSameSerialExecutor(current, expected) { return }  // ② identity 비교 통과 → 여기서 끝(호출 안 됨)
else { expected.checkIsolated() }                      // ③ 비교 실패 시에만 last-resort로 호출
```

- **actor의 task 안에서** `assumeIsolated`를 부르면 실제로 그 executor 위에서 job이 도는 중이라 ②에서 통과한다 → `checkIsolated()`가 **아예 호출되지 않으므로, 미구현이어도 크래시하지 않는다.** ("구현 안 하면 무조건 크래시"는 오해다.)
- `checkIsolated()`가 실제로 필요한 건 **identity 비교가 실패하는(①/③) 경로**다. 런타임이 현재 executor를 모르거나 다른 것으로 인식하지만 실제로는 올바른 컨텍스트인 경우 — 대표적으로 백킹 `DispatchQueue`에 `async`로 직접 올린 **동기 델리게이트/C 콜백**에서 `assumeIsolated`를 호출할 때다. 이때 미구현이면 기본 구현(`fatalError`)이 그대로 크래시한다.
- 그래서 백킹이 `DispatchQueue`면 `dispatchPrecondition(condition: .onQueue(queue))`, 전용 스레드면 `Thread.current === thread` 같은 식으로 현재 실행 컨텍스트를 검증하도록 구현한다. (앞의 `DispatchQueueExecutor` / `ThreadExecutor` 예제 참고)

## TaskExecutor (SE-0417)

**TaskExecutor**는 actor에 묶이지 않은 **자유 task의 실행 위치**를 제어한다.

### 해결하는 문제

`nonisolated async` 함수는 기본적으로 항상 **global concurrent executor**로 hop 한다. 이벤트 루프 기반 서버처럼 성능에 민감한 환경에서는 이 불필요한 컨텍스트 스위칭이 비용이 된다. TaskExecutor는 "이 task 트리는 내 스레드 풀에서 돌려라"라고 **선호(preference)** 를 지정하게 해준다.

> ⚠️ **버전 주의**: "`nonisolated async`는 항상 global executor로 hop"은 **SE-0338(Swift 5.7) ~ 6.1** 기준의 기본 동작이다. **Swift 6.2의 SE-0461(`nonisolated(nonsending)`)** 부터는 `nonisolated async` 함수가 기본적으로 **호출자의 isolation을 따라 실행**되도록 바뀐다(별도 hop 없음). 따라서 6.2 이후에는 위 전제가 달라지며, TaskExecutor preference의 효과 범위도 함께 해석해야 한다.

```swift
// SerialExecutor와 달리 "직렬성"을 요구하지 않음 → 동시 실행 허용.
// 역할은 actor 보호가 아니라 "task를 돌릴 스레드를 공급"하는 것
public protocol TaskExecutor: Executor {
    // Executor와 동일한 진입점. 여러 job을 동시에 처리해도 무방
    func enqueue(_ job: consuming ExecutorJob)
    // SerialExecutor의 asUnownedSerialExecutor에 대응하는 task용 식별자
    func asUnownedTaskExecutor() -> UnownedTaskExecutor
}
```

### Executor preference 지정 방법

```swift
// 1. 스코프 단위 — 이 블록과 블록이 만든 자식 task들이 myExecutor를 선호
await withTaskExecutorPreference(myExecutor) {
    // nonisolated async 함수가 기본 global executor가 아닌 myExecutor에서 실행됨
    await someNonisolatedWork()
}

// 2. 비구조적 task — 이 Task 트리 전체에 preference 지정
Task(executorPreference: myExecutor) {
    await someNonisolatedWork()
}

// 3. 구조적 동시성 — TaskGroup의 개별 자식 task에 지정
group.addTask(executorPreference: myExecutor) {
    await someNonisolatedWork()
}
```

### 상속(inheritance) 동작

- preference는 **sticky**: `async let`, `TaskGroup`, actor-isolated 메서드(커스텀 executor가 없는 경우)를 통해 만들어진 **자식 task에 상속**된다.
- 단, `Task {}`, `Task.detached {}` 같은 **비구조적 task는 상속하지 않는다.**
- 덕분에 매 단계마다 파라미터를 넘기지 않아도 task 트리 전체가 지정한 executor에서 실행된다.

### 실전 예제: 동시 실행 수를 제한하는 QueueTaskExecutor

`OperationQueue`로 **최대 동시 실행 수를 제한**한 커스텀 task 풀. blocking I/O 작업이 시스템 스레드를 고갈시키지 않도록 throttling 한다.

```swift
final class QueueTaskExecutor: TaskExecutor, @unchecked Sendable {
    // 동시 실행 개수를 조절할 수 있는 백킹 큐. throttling의 실체
    private let q: OperationQueue

    init(label: String = "TaskExec",
         maxConcurrent: Int = OperationQueue.defaultMaxConcurrentOperationCount,
         qos: QualityOfService = .default) {
        self.q = OperationQueue()
        q.name = label
        // 핵심: 한 번에 최대 몇 개 job까지 동시에 돌릴지 제한 (스레드 고갈 방지)
        q.maxConcurrentOperationCount = maxConcurrent
        // 이 풀에서 도는 작업의 우선순위(QoS) 지정
        q.qualityOfService = qos
    }

    func enqueue(_ job: consuming ExecutorJob) {
        // task용 식별자 (SerialExecutor의 asUnownedSerialExecutor 대응)
        let exec = asUnownedTaskExecutor()
        // move-only job → 클로저 캡처용 핸들로 변환
        let unowned = UnownedJob(job)
        // 큐에 올리면 maxConcurrent 한도 내에서 여러 job이 병렬로 실행됨
        q.addOperation {
            unowned.runSynchronously(on: exec)
        }
    }

    func asUnownedTaskExecutor() -> UnownedTaskExecutor {
        UnownedTaskExecutor(ordinary: self)
    }
}

// 파일 I/O를 최대 4개까지만 동시에 돌리는 전용 풀 생성
let ioPool = QueueTaskExecutor(label: "File-IO", maxConcurrent: 4, qos: .utility)

func loadFiles(urls: [URL]) async throws -> [Data] {
    // 이 스코프 안의 task들이 ioPool을 선호하도록 지정
    try await withTaskExecutorPreference(ioPool) {
        try await withThrowingTaskGroup(of: Data.self) { group in
            for url in urls {
                // preference가 자식 task에 상속됨 → 각 다운로드가 ioPool에서 실행.
                // url이 100개여도 동시에 도는 건 최대 4개로 제한됨
                group.addTask { try Data(contentsOf: url) }
            }
            // ⚠️ TaskGroup 결과는 입력(urls) 순서가 아니라 "완료 순서"로 도착한다.
            //    입력 순서를 보존하려면 (index, Data)를 함께 반환해 인덱스로 정렬해야 함.
            return try await group.reduce(into: []) { $0.append($1) }
        }
    }
}
```

> `SerialExecutor`와 비교: 여기선 `maxConcurrentOperationCount`만큼 **여러 job이 동시에** 실행된다. 상호 배제가 아니라 "스레드 공급원" 역할이기 때문이다.

## SerialExecutor vs TaskExecutor

| 구분 | SerialExecutor | TaskExecutor |
|---|---|---|
| 목적 | actor isolation (상호 배제) | task 실행 스레드 공급 |
| 동시성 | 한 번에 하나 (직렬) | 동시 실행 허용 |
| 연결 대상 | actor (`unownedExecutor`) | task (`executorPreference`) |
| 식별 기준 | isolation identity | task의 executor preference |
| 대표 용도 | 스레드 고정, 직렬 보장 | 커스텀 task 풀, blocking/CPU 작업, throttling |

## 정리

- **Executor = job을 스레드에 스케줄링하는 주체**, 핵심은 `enqueue(_:)`.
- **SerialExecutor**는 actor의 안전성(직렬 실행)을, **TaskExecutor**는 task의 실행 위치를 담당한다.
- 커스텀 SerialExecutor + `unownedExecutor`로 actor를 특정 큐/스레드에 고정할 수 있다.
- 커스텀 TaskExecutor + `executorPreference`로 task 트리의 실행 스레드 풀을 지정할 수 있다.
- 대부분의 앱은 런타임 기본 executor로 충분하며, 스레드 친화성·성능 최적화·레거시 통합이 필요할 때 커스텀을 고려한다.

## 참조 문서

### WWDC 세션

> Executor를 **단독 주제**로 다룬 세션은 없다. SerialExecutor/TaskExecutor는 Swift Evolution(SE-0392/0417)으로 도입된 기능이라 공식 영상이 따로 없다. 대신 아래 세션들이 executor의 **런타임 동작**을 다룬다.

- [Swift concurrency: Behind the Scenes (WWDC21, 10254)](https://developer.apple.com/videos/play/wwdc2021/10254/) - ⭐ **executor / cooperative thread pool / actor hopping의 핵심**. (저장소 노트: [[Swift-Concurrency-Behind-the-Scenes]])
- [Protect mutable state with Swift actors (WWDC21, 10133)](https://developer.apple.com/videos/play/wwdc2021/10133/) - actor와 serial executor의 관계
- [Visualize and optimize Swift concurrency (WWDC22, 110350)](https://developer.apple.com/videos/play/wwdc2022/110350/) - Instruments로 executor/스레드 동작 시각화
- [Beyond the basics of structured concurrency (WWDC23, 10170)](https://developer.apple.com/videos/play/wwdc2023/10170/) - task 트리와 실행 컨텍스트 심화

### Swift Evolution & 공식 소스

- [SE-0392: Custom Actor Executors](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0392-custom-actor-executors.md) - SerialExecutor, unownedExecutor 제안서
- [SE-0417: Task Executor Preference](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0417-task-executor-preference.md) - TaskExecutor 제안서
- [stdlib Executor.swift](https://github.com/swiftlang/swift/blob/main/stdlib/public/Concurrency/Executor.swift) - 실제 프로토콜 정의 소스
- [swift-platform-executors](https://github.com/swiftlang/swift-platform-executors) - 플랫폼 네이티브 executor 패키지

### 아티클

- [Crafting Thread-Pinned and Pool-Bound Executors](https://medium.com/@mateusz.kosikowski/swift-concurrency-under-your-control-crafting-thread-pinned-and-pool-bound-executors-baecafcfa2e5) - ThreadExecutor 직접 구현 예제
- [Controlling Actors With Custom Executors (Jack Morris)](https://jackmorris.xyz/posts/2023/11/21/controlling-actors-with-custom-executors/) - 커스텀 actor executor 실전
- [SE-0417 해설 (Massicotte)](https://www.massicotte.org/concurrency-swift-6-se-0417/) - TaskExecutor 쉬운 설명

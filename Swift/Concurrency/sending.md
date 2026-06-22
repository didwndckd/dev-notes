# sending

> non-Sendable 값을 동시성 경계 너머로 **이동(transfer)** 시키는 키워드. 값의 소유권을 한쪽으로 넘겨 원래 쪽에서는 더 쓰지 못하게 함으로써, `Sendable`이 아니어도 안전하게 경계를 넘길 수 있게 한다.

## References

- [SE-0430: sending parameter and result values](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0430-transferring-parameters-and-results.md)
- [SE-0414: Region based isolation](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0414-region-based-isolation.md)

## 기본 개념

`sending`은 값의 **소유권을 한 도메인으로 넘기는(transfer)** 개념이다. 여러 곳에서 동시에 공유(share)할 수 있어야 하는 `Sendable`과 달리, "넘긴 뒤 원래 자리에서는 더 안 쓴다"는 것만 보장되면 **non-Sendable 값도 경계를 넘길 수 있다.**

| | 보장 | 전제 |
|---|---|---|
| `Sendable` | 타입이 **동시 공유**해도 안전 | 여러 도메인이 함께 가질 수 있음 |
| `sending` | 값이 **disconnected**(어디에도 안 묶임) | 넘긴 뒤 원래 쪽에서 재사용 안 함 |

`sending`은 **파라미터**와 **반환 타입** 양쪽에 붙일 수 있고, 위치에 따라 "누가 disconnected를 보장하느냐"가 달라진다.

| 위치 | 문법 | 누가 disconnected 보장 | 효과 |
|---|---|---|---|
| 파라미터 | `func f(_ x: sending T)` | **호출자**가 disconnected 값을 넘김 | 함수가 그 값을 자기 region으로 가져감 → 호출자는 이후 사용 불가 |
| 반환 | `func f() -> sending T` | **구현부**가 disconnected 값을 반환 | 호출자가 받은 값을 disconnected로 간주 → 자유롭게 사용·전달 가능 |

### 파라미터에 sending

호출자가 값의 소유권을 넘긴다. 넘긴 뒤에는 호출자가 그 값을 다시 쓸 수 없다.

``` swift
final class NonSendable {}

func process(_ value: sending NonSendable) {
    Task { use(value) }   // value를 Task로 안전하게 이동
}

let x = NonSendable()
process(x)
// print(x)   // ❌ Error: 이미 sending으로 넘긴 값
```

### 반환값에 sending

**반환에 `sending`이 없으면 actor가 만든 non-Sendable 값을 외부에서 못 쓴다.** 시그니처만 보고 판단하는 호출자는 "반환값이 actor 상태와 엮여 있을 수도 있다"고 보수적으로 가정하기 때문이다.

``` swift
actor Store {
    var item = NonSendable()

    func get() -> NonSendable { item }                    // sending 없음
    func make() -> sending NonSendable { NonSendable() }  // sending O
}

func handle(_ store: Store) async {
    let a = await store.get()    // ❌ Error: store region의 값을 외부에서 사용
    let b = await store.make()   // ✅ OK: 호출자는 b를 disconnected로 간주
    print(b)
}
```

단, **반환에 `sending`을 붙였으면 구현부도 disconnected 값을 반환해야 한다.** actor의 isolated 상태를 그대로 반환하는 건 `sending`을 붙여도 에러다.

``` swift
actor Store {
    var item = NonSendable()
    func get() -> sending NonSendable {
        return item   // ❌ Error: isolated 상태(item)는 disconnected가 아님
    }
}
```

| 반환 시그니처 | 외부 사용 | 비고 |
|---|---|---|
| `-> NonSendable` | ❌ 불가 | actor region으로 취급 |
| `-> sending NonSendable` + 새 값 반환 | ✅ 가능 | 호출자가 disconnected로 간주 |
| `-> sending NonSendable` + isolated 상태 반환 | ❌ 컴파일 에러 | 구현부가 disconnected 아님 |

## 예시: Task

`Task.init` / `Task.detached`의 `operation` 클로저가 Swift 6에서 `@Sendable` → `sending`으로 바뀐 것이 대표적인 적용 사례다.

``` swift
// 현재 시그니처 (단순화)
static func detached(
    priority: TaskPriority? = nil,
    operation: sending @escaping () async -> Success
) -> Task<Success, Failure>
```

- `@Sendable`이었을 때: 클로저가 캡처하는 값이 **항상 Sendable**이어야 했다(여러 곳에서 공유될 수 있다는 전제).
- `sending`으로 바뀐 뒤: "넘긴 뒤 원래 자리에서 안 쓴다"가 증명되면 **non-Sendable 값을 캡처한 작업도** Task로 전달할 수 있다.

> `sending`은 SE-0430 초안에서 `transferring`이라는 이름이었으나 리뷰 과정에서 `sending`으로 변경됐다. SE-0414가 future direction에서 언급한 "transferring modifier"가 그 흔적이다.

## 더 알아보기

### Region-Based Isolation — 키워드 없이도 경계를 넘는 이유

`sending`을 명시하지 않아도 non-Sendable 값이 actor 경계를 넘어가는 경우가 있다. 이는 [SE-0414 Region-Based Isolation](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0414-region-based-isolation.md) 때문이다.

핵심 규칙(SE-0414 원문):

> "we are defining the **default convention** for passing non-`Sendable` values **across isolation boundaries as being a transfer operation**. This does not apply when calling async functions from within the same isolation domain."

즉 **isolation 경계를 넘기는 행위 자체가 기본적으로 transfer**다. 키워드는 오히려 *같은* isolation 도메인 안에서 호출할 때 필요하다.

**disconnected region**: 어떤 isolation 도메인에도 속하지 않은(예: 함수 안에서 갓 생성한) non-Sendable 값. 이 값은 경계를 넘겨 transfer할 수 있고, 단 **넘긴 뒤 원래 자리에서 다시 쓰면 에러**다.

``` swift
final class NonSendable {}

actor Store {
    func append(_ value: NonSendable) { ... }   // 파라미터에 sending 없음
}

func handle(_ store: Store) async {
    let x = NonSendable()                // disconnected region
    await store.append(x)                // actor 경계를 넘김 → x가 store region으로 transfer
    print(x)                             // ❌ Error: 이미 넘어간 x를 다시 사용
}
```

> 위 코드에서 `append`의 파라미터 `value`에 `sending`이 없는데도 `print(x)`가 에러다.
> 즉 **재사용 금지(use-after-transfer)** 진단은 `sending` 키워드가 아니라 **region isolation 엔진**이 actor 경계에서 자동으로 적용한다.

### 확인 시 주의

- **Playground는 Build Settings(Strict Concurrency Checking)를 따르지 않으므로** 이 진단이 안 보인다. 실제 앱/패키지 타겟에서 확인해야 한다.
- Swift 5 모드 기본값(`minimal`)은 검사를 거의 안 한다. **Strict Concurrency Checking = Complete** 또는 Swift 6 모드여야 진단이 동작한다.
- 단, `store.append(x)` 호출 **단독**은 Complete에서도 통과한다(transfer는 허용). 진단을 보려면 그 뒤에 `x` **재사용 코드**가 있어야 한다.

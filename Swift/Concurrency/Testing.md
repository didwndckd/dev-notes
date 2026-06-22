# Testing

## 요약

### Swift Concurrency 테스트 기본

Swift의 동시성 기능은 **XCTest**와 **Swift Testing** 두 프레임워크에서 모두 테스트 가능하다.

### 공통점

- 비동기 함수 테스트 시 `async` 마킹 필요
- 특정 횟수의 assertion 완료 처리 가능
- 특정 actor에서 테스트 실행 강제 가능
- completion 기반 비동기 코드 주의 필요
- 테스트에서 직접 에러 throw 또는 내부 catch 가능
- 병렬 테스트 실행 지원

### 차이점

| 항목 | XCTest | Swift Testing |
|------|--------|---------------|
| 동기 테스트 실행 위치 | Main Actor (기본) | 임의 위치 |
| 직렬 실행 | - | 선택적 직렬 실행 가능 |
| 시간 제한 | 수동 구현 필요 | 간편한 설정 |
| Actor 기반 Suite | - | 지원 |



## 기본 비동기 테스트 작성법

**Swift Testing**과 **XCTest** 모두 `async` 키워드로 비동기 테스트 지원한다.

**중요**: 테스트 코드에서 `@testable import YourAppTarget`을 사용해 internal 타입에 접근한다.

**Swift Testing 예시:**
```swift
struct DataHandling {
    @Test("Loading view model names")  // 테스트 설명 지정
    func loadNames() async throws {  // async throws로 비동기 + 에러 처리
        let viewModel = ViewModel()
        try await viewModel.loadNames()  // 비동기 메서드 호출
        #expect(viewModel.names.isEmpty == false, "Names should be full of values.")  // 조건 검증
    }
}
```

**XCTest 예시:**
```swift
final class DataHandlingTests: XCTestCase {
    func test_loadNames() async throws {  // async throws로 비동기 + 에러 처리
        let viewModel = ViewModel()
        try await viewModel.loadNames()  // 비동기 메서드 호출
        XCTAssertFalse(viewModel.names.isEmpty, "Names should be full of values.")  // 조건 검증
    }
}
```

**필수 조건 검사 (테스트 실패 시 즉시 종료):**

- Swift Testing: `#require` 사용 → 실패 시 에러 throw
  ```swift
  try #require(viewModel.names.isEmpty == false)  // 실패 시 테스트 즉시 종료
  ```
- XCTest: `continueAfterFailure` 프로퍼티 (매번 토글 필요)



## 테스트에서 동시성 에러 처리

테스트에서 에러를 처리하는 3가지 방법: **즉시 실패**, **내부 처리**, **예상된 에러**

### 1. 에러를 테스트 실패로 처리 (가장 단순)

`throws` 마킹 후 에러를 처리하지 않으면 자동으로 테스트 실패 처리된다.

```swift
// Swift Testing
@Test func loadNames() async throws {
    try await viewModel.loadNames()  // 에러 발생 시 테스트 실패
}

// XCTest
func test_loadNames() async throws {
    try await viewModel.loadNames()  // 동일하게 동작
}
```

**Swift Testing 전용**: `CustomTestStringConvertible`로 에러 메시지 커스터마이징 (테스트 타겟에만 추가)
```swift
extension LoadError: @retroactive CustomTestStringConvertible {
    public var testDescription: String {  // 테스트 실패 시 표시될 메시지
        switch self {
        case .notEnoughData: "At least three names should be loaded."  // 데이터 부족 에러 메시지
        case .tooMuchData: "No more than 1000 names are supported."    // 데이터 초과 에러 메시지
        }
    }
}
```

### 2. 에러를 내부에서 처리하고 직접 메시지 발행

```swift
// Swift Testing - Issue.record() 사용
@Test func loadNames() async {  // throws 없음 - 에러를 직접 처리
    do {
        try await viewModel.loadNames()
    } catch {
        Issue.record(error, "Between 3 and 1000 names are supported.")  // 에러와 메시지 기록
    }
}

// XCTest - XCTFail() 사용
func test_loadNames() async {  // throws 없음 - 에러를 직접 처리
    do {
        try await viewModel.loadNames()
    } catch {
        XCTFail("Between 3 and 1000 names are supported.")  // 테스트 실패 처리
    }
}
```

**Issue.record() 상세**: Swift Testing에서 테스트 이슈를 기록하는 다양한 방법을 제공한다.

```swift
// 기본 사용 - 코멘트만
Issue.record("Something went wrong")  // 단순 메시지 기록

// 에러와 함께 기록 - 에러 정보 + 코멘트
Issue.record(error, "Failed to load data")  // 에러 객체와 설명 함께 기록

// 소스 위치 명시 - 다른 위치에서 발생한 이슈 기록 시 유용
Issue.record(
    "Validation failed",
    sourceLocation: SourceLocation()  // 현재 위치 또는 커스텀 위치
)
```

| 메서드 | 용도 |
|--------|------|
| `Issue.record(_:)` | 단순 코멘트로 이슈 기록 |
| `Issue.record(_:_:)` | 에러 객체 + 코멘트 함께 기록 |
| `Issue.record(_:sourceLocation:)` | 소스 위치 명시하여 기록 |

### 3. 특정 에러가 throw되길 기대하는 경우

```swift
// Swift Testing - #expect(throws:) 사용
@Test func loadNames() async {
    // LoadError 타입의 에러가 throw되길 기대
    await #expect(throws: LoadError.self, performing: viewModel.loadNames)
    // 특정 케이스 지정도 가능 (더 엄격한 검증)
    await #expect(throws: LoadError.notEnoughData, performing: viewModel.loadNames)
}

// XCTest - XCTAssertThrowsError()는 async 미지원, do/catch 사용
func test_loadNames() async throws {
    do {
        try await viewModel.loadNames()
        XCTFail("This should fail to load.")  // 에러가 안 나면 실패
    } catch {
        // 에러 발생 = 테스트 성공 (아무것도 안 함)
    }
}
```

### 4. Swift Testing 전용: withKnownIssue()

에러가 예상되는 경우 사용. 에러가 발생하지 않으면 오히려 테스트 실패.

```swift
@Test func loadNames() async {
    // 에러가 발생할 것으로 알려진 코드 블럭
    await withKnownIssue("Names can sometimes come back with too few values") {
        try await viewModel.loadNames()  // 에러 발생 시 "예상된 실패"로 처리
    }
}
```

**isIntermittent 옵션**: 간헐적으로 발생하는 에러를 처리할 때 유용하다. 네트워크 코드 디버깅 시 특히 효과적.

| isIntermittent | 에러 발생 | 에러 미발생 |
|----------------|----------|------------|
| `false` (기본값) | 예상된 실패 ✓ | 테스트 실패 ✗ |
| `true` | 예상된 실패 ✓ | 테스트 통과 ✓ |

```swift
// 간헐적 에러 처리 - 문제 해결 중에도 테스트 스위트가 계속 통과할 수 있음
await withKnownIssue("Network timeout sometimes occurs", isIntermittent: true) {
    try await viewModel.loadNames()  // 에러 발생해도 OK, 안 발생해도 OK
}
```



## Completion Handler 테스트

async/await이 아닌 콜백 기반 비동기 코드를 테스트할 때, completion handler가 호출될 때까지 테스트가 대기해야 한다.

**테스트 대상 예시:**
```swift
class ViewModel {
    func loadReadings(completion: @escaping ([Double]) -> Void) {
        let url = URL(string: "https://hws.dev/readings.json")!

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data,
               let numbers = try? JSONDecoder().decode([Double].self, from: data) {
                completion(numbers)  // 성공 시 데이터 전달
                return
            }
            completion([])  // 실패 시 빈 배열 전달
        }.resume()
    }
}
```

### Swift Testing: withCheckedContinuation 사용

```swift
@Test("Loading view model readings")
func loadReadings() async {
    let viewModel = ViewModel()

    // continuation으로 completion handler를 async/await으로 변환
    await withCheckedContinuation { continuation in
        viewModel.loadReadings { readings in
            #expect(readings.count >= 10, "At least 10 readings must be returned.")  // 검증
            continuation.resume()  // 테스트 계속 진행
        }
    }
}
```

### XCTest: XCTestExpectation 사용

```swift
final class DataHandlingTests: XCTestCase {
    func test_loadViewModelReadings() async {
        let viewModel = ViewModel()
        let expectation = XCTestExpectation(description: "Check view model readings")  // expectation 생성

        viewModel.loadReadings { readings in
            if readings.count >= 10 {
                expectation.fulfill()  // 조건 충족 시 expectation 완료
            }
        }

        await fulfillment(of: [expectation], timeout: 10)  // 최대 10초 대기
    }
}
```

### 핵심 포인트

| 항목 | Swift Testing | XCTest |
|------|---------------|--------|
| 대기 방식 | `withCheckedContinuation` | `XCTestExpectation` |
| 완료 신호 | `continuation.resume()` | `expectation.fulfill()` |
| 타임아웃 | 기본 제공 | `fulfillment(of:timeout:)` |

**중요**: 두 방식 모두 assertion은 completion closure 내부에서 수행하고, 테스트가 해당 assertion까지 대기하도록 해야 한다.



## AsyncSequence / AsyncStream 테스트

시간에 따라 값을 스트리밍하는 코드를 테스트할 때, 특정 횟수의 값이 전달되는지 확인해야 한다.

**테스트 대상 예시:**
```swift
struct DoubleGenerator: AsyncSequence, AsyncIteratorProtocol {
    var current = 1

    mutating func next() async -> Int? {
        defer { current &*= 2 }  // &*=: 오버플로우 허용 곱셈

        if current < 0 {
            return nil  // 오버플로우로 음수가 되면 종료
        } else {
            return current
        }
    }

    func makeAsyncIterator() -> DoubleGenerator {
        self
    }
}
```

### Swift Testing: confirmation(expectedCount:) 사용

```swift
@Test("DoubleGenerator should create 63 doubles")
func testDoubling() async {
    let generator = DoubleGenerator()

    // 정확히 63번 confirm()이 호출되어야 테스트 통과
    await confirmation(expectedCount: 63) { confirm in
        for await _ in generator {
            confirm()  // 값을 받을 때마다 확인
        }
    }
}
```

**confirmation() 주의사항:**
- `expectedCount`와 정확히 일치해야 함 (62, 64 등은 실패)
- closure가 끝나기 전에 모든 작업이 완료되어야 함
- 기본값은 1, 0으로 설정하면 "절대 호출되면 안 됨" 의미

### XCTest: XCTestExpectation + expectedFulfillmentCount 사용

```swift
final class AsyncSequenceTests: XCTestCase {
    func test_doubleGeneratorContainsCorrectValues() async {
        let generator = DoubleGenerator()
        let expectation = XCTestExpectation(description: "DoubleGenerator should create 63 doubles")
        expectation.expectedFulfillmentCount = 63  // 정확히 63번 fulfill 필요
        expectation.assertForOverFulfill = true     // 64번 이상이면 실패

        for await _ in generator {
            expectation.fulfill()  // 값을 받을 때마다 fulfill
        }

        await fulfillment(of: [expectation], timeout: 1)  // 짧은 타임아웃 권장
    }
}
```

### 핵심 비교

| 항목 | Swift Testing | XCTest |
|------|---------------|--------|
| 횟수 검증 | `confirmation(expectedCount:)` | `expectedFulfillmentCount` |
| 완료 신호 | `confirm()` | `expectation.fulfill()` |
| 초과 검증 | 기본 적용 | `assertForOverFulfill = true` |
| 타임아웃 | 자동 | 수동 설정 필요 (`timeout:`) |



## 동시성 테스트 시간 제한

동시성 테스트에서 시간 제한은 매우 중요하다. 제한이 없으면 시스템이 무한정 대기할 수 있다.

### Swift Testing: .timeLimit() trait 사용

```swift
@Test("Loading view model names", .timeLimit(.minutes(1)))  // 1분 제한
func loadNames() async {
    let viewModel = ViewModel()
    await viewModel.loadNames()
    #expect(viewModel.names.isEmpty == false, "Names should be full of values.")
}
```

**특징:**
- 시간 단위: **분(minutes)** 으로 지정
- Suite에 적용하면 모든 테스트에 개별 적용
- 개별 테스트에 다른 제한 설정 시, 더 짧은 값이 사용됨

### XCTest: Task + fulfillment(of:timeout:) 사용

```swift
final class DataHandlingTests: XCTestCase {
    func test_loadNames() async {
        let viewModel = ViewModel()
        let expectation = XCTestExpectation(description: "Names should be full of values.")

        // Task로 감싸서 비동기 실행
        // await 직접 사용 시 작업 완료까지 테스트가 블로킹되어 타임아웃 체크 불가
        Task {
            await viewModel.loadNames()

            if viewModel.names.isEmpty == false {
                expectation.fulfill()  // 조건 충족 시 완료
            }
        }

        await fulfillment(of: [expectation], timeout: 60)  // 60초 제한
    }
}
```

**특징:**
- 시간 단위: **초(seconds)** 로 지정
- `await` 직접 사용 시 테스트가 작업 완료까지 블로킹됨 → 타임아웃 체크 불가
- `Task`로 감싸면 테스트가 `fulfillment(of:timeout:)`까지 진행하여 타임아웃 체크 가능

### 핵심 비교

| 항목 | Swift Testing | XCTest |
|------|---------------|--------|
| 설정 방법 | `.timeLimit(.minutes(n))` | `fulfillment(of:timeout:)` |
| 시간 단위 | 분 | 초 |
| 비동기 래핑 | 불필요 | `Task { }` 필요 |

**권장사항:** 유닛 테스트는 빠르게 실행되어야 한다 (초당 수천 개 수준). 실제 네트워킹 테스트는 별도 테스트 타겟으로 분리하거나, mock 데이터를 사용해 즉시 응답하도록 구성하는 것이 좋다.



## 특정 Actor에서 테스트 실행 강제

두 프레임워크의 기본 동작이 다르다:
- **Swift Testing**: 동기/비동기 테스트 모두 임의의 task에서 실행
- **XCTest**: 동기 테스트는 Main Actor, 비동기 테스트는 백그라운드 task에서 실행

### Swift Testing

**1. 개별 테스트에 적용:**
```swift
@MainActor  // Main Actor에서 실행 강제
@Test("Loading view model names")
func loadNames() async {
    // 테스트 코드
}
```

**2. 전체 Suite에 적용:**
```swift
@MainActor  // Suite 내 모든 테스트가 Main Actor에서 실행
struct DataHandlingTests {
    @Test("Loading view model names")
    func loadNames() async {
        // 테스트 코드
    }
}
```

**3. 특정 closure에만 적용 (confirmation, withKnownIssue):**
```swift
@Test("Loading view model names")
func loadNames() async {
    // 이 closure만 Main Actor에서 실행, 나머지는 다른 곳에서 실행 가능
    await withKnownIssue("Names can sometimes come back with too few values") { @MainActor in
        // Main Actor에서 실행되는 테스트 코드
    }
}
```

**커스텀 Actor 사용:**
```swift
// withKnownIssue(), confirmation() 모두 isolation 파라미터 지원
await confirmation(isolation: myCustomActor) { confirm in
    // 커스텀 actor에서 실행
}
```

### XCTest

**1. 전체 TestCase에 적용:**
```swift
@MainActor  // 모든 테스트가 Main Actor에서 실행
final class DataHandlingTests: XCTestCase {
    func test_loadNames() async {
        // 테스트 코드
    }
}
```

**2. 개별 테스트에 적용:**
```swift
final class DataHandlingTests: XCTestCase {
    @MainActor  // 이 테스트만 Main Actor에서 실행
    func test_loadNames() async {
        // 테스트 코드
    }
}
```

**3. 특정 closure에만 적용 (Task 사용):**
```swift
final class DataHandlingTests: XCTestCase {
    func test_loadNames() async throws {
        let viewModel = ViewModel()
        let expectation = XCTestExpectation(description: "Names should be full of values.")

        // Task 내부만 Main Actor에서 실행
        Task { @MainActor in
            await viewModel.loadNames()

            if viewModel.names.isEmpty == false {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 60)
    }
}
```

### 핵심 비교

| 적용 범위 | Swift Testing | XCTest |
|----------|---------------|--------|
| 개별 테스트 | `@MainActor @Test` | `@MainActor func test_` |
| 전체 Suite/Case | Suite에 `@MainActor` | TestCase에 `@MainActor` |
| 특정 closure | `{ @MainActor in }` | `Task { @MainActor in }` |
| 커스텀 Actor | `isolation:` 파라미터 | Task isolation |



## 파라미터화된 테스트 직렬 실행 (Swift Testing 전용)

Swift Testing의 파라미터화된 테스트는 기본적으로 **병렬 실행**된다. 직렬 실행이 필요한 경우 `.serialized` trait을 사용한다.

**주의**: `.serialized`는 파라미터화된 테스트에만 적용되며, 일반 테스트에는 영향 없음.

**사용 사례:**
- 서버 연결 수 제한이 있는 경우
- 공유 리소스에 대한 동시 접근 문제
- 순서가 중요한 테스트

```swift
@Test(
    "Scores should always be in the range 0...100",
    .serialized,  // 직렬 실행 강제
    arguments: [0, 50, 100, 200, -1]  // 5개의 테스트 케이스
)
func addingPoints(score: Int) async {
    var player = Player()
    await player.add(points: score)  // 각 점수로 테스트
    #expect(player.score >= 0 && player.score <= 100)  // 범위 검증
}
```

**동작 방식:**
- `.serialized` 없음: 5개 테스트가 동시에 실행 (기본값)
- `.serialized` 있음: 5개 테스트가 순차적으로 실행

**XCTest 대안:**
XCTest에서는 직접적인 동등 기능이 없다. 별도 테스트 타겟을 생성하고 각 타겟별로 병렬 테스트 활성화/비활성화를 수동으로 설정해야 한다.


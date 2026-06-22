# TaskGroup

## Task Group 생성과 태스크 추가 방법

### 1. Task Group 개념

- **Task Group**은 여러 개의 `Task`가 **함께 하나의 결과를 만들어내는 컨테이너**이다.
- 그룹 안의 각 `Task`는 **동일한 타입의 값을 반환**해야 한다.
  - 필요하다면 `enum` + 연관값(associated value)로 서로 다른 데이터를 감싸서 한 타입으로 만들 수 있다. (조금 번거롭지만 가능)
- TaskGroup 인스턴스를 직접 생성하지 않고,
  - **`withTaskGroup(of:_:)`**
  - 또는 에러를 바깥으로 전달하고 싶다면 **`withThrowingTaskGroup(of:_:)`**를 사용한다.

---

### 2. 기본 예제: 문자열 5개를 모아서 한 문장 만들기

```swift
func printMessage() async {
    // TaskGroup이 반환할 타입을 String으로 명시
    let string = await withTaskGroup(of: String.self) { group in
        // group 파라미터로 TaskGroup 인스턴스를 전달받음
        // 각 addTask는 String을 반환하는 child Task를 하나씩 추가
        group.addTask { "Hello" }
        group.addTask { "From" }
        group.addTask { "A" }
        group.addTask { "Task" }
        group.addTask { "Group" }

        var collected = [String]()

        // TaskGroup은 AsyncSequence를 준수하므로
        // for await를 사용해 child Task들의 결과를 순서대로(완료 순서 기준) 읽을 수 있음
        for await value in group {
            collected.append(value)
        }

        // 수집된 문자열들을 공백으로 이어 붙여 하나의 문장으로 반환
        return collected.joined(separator: " ")
    }

    // 예: "Hello From A Task Group" 또는 순서가 섞인 문자열이 출력될 수 있음
    print(string)
}

// INSIDE MAIN
await printMessage()
```

---

### 3. Swift 6.1 이후 변화 & Throwing TaskGroup

#### 3.1 Swift 6.1 부터의 타입 추론

- Swift 6.1 이후:
  - `withTaskGroup()` 호출 시 `of:` 파라미터를 생략할 수 있다.
  - **그룹에 처음 추가되는 child task의 반환 타입**을 기준으로 Swift가 타입을 추론한다.

예:

```swift
await withTaskGroup { group in
    // 첫 번째 child Task가 String을 반환하므로
    // 그룹 전체의 타입이 String으로 추론됨
    group.addTask { "Hello" }
    // ...
}
```

#### 3.2 에러를 던지는 Task가 필요할 때

- `withTaskGroup(of:_:)` 를 사용할 때 생성된 Task는 **그룹 바깥으로 에러를 던질 수 없다.**
- Task 내부에서 발생한 에러를 **외부에서 처리할 수 있도록 전달**하려면 → **`withThrowingTaskGroup(of:_:)`** 를 사용해야 한다.

---

### 4. 실전 예제: 여러 뉴스 피드를 병렬로 가져와 합치기

```swift
// 개별 뉴스 기사를 표현하는 모델
struct NewsStory: Decodable, Identifiable {
    let id: Int
    let title: String
    let strap: String
    let url: URL
}

// 뉴스 목록을 보여주는 SwiftUI 뷰
struct ContentView: View {
    @State private var stories = [NewsStory]()

    var body: some View {
        NavigationStack {
            List(stories) { story in
                VStack(alignment: .leading) {
                    Text(story.title)
                        .font(.headline)

                    Text(story.strap)
                }
            }
            .navigationTitle("Latest News")
        }
        // View가 나타날 때 비동기로 뉴스 로딩
        .task {
            await loadStories()
        }
    }

    // 여러 JSON 피드를 병렬로 가져와 하나의 배열로 합치는 함수
    func loadStories() async {
        do {
            // 에러를 외부로 전파해야 하므로 withThrowingTaskGroup 사용
            stories = try await withThrowingTaskGroup(of: [NewsStory].self) { group in
                // 1 ~ 5번까지 뉴스 JSON을 병렬로 가져올 Task를 반복문에서 추가
                for i in 1...5 {
                    group.addTask {
                        let url = URL(string: "https://hws.dev/news-\(i).json")!
                        // 네트워크 요청은 에러를 던질 수 있으므로 try/await 사용
                        let (data, _) = try await URLSession.shared.data(from: url)
                        // 각 Task는 [NewsStory]를 디코딩해서 반환
                        return try JSONDecoder().decode([NewsStory].self, from: data)
                    }
                }

                var allStories = [NewsStory]()

                // 그룹 안의 Task는 어떤 순서로든 완료될 수 있으므로
                // for try await 로 완료되는 순서대로 결과를 읽어와 하나의 배열로 합침
                for try await stories in group {
                    allStories.append(contentsOf: stories)
                }

                // id 기준 내림차순으로 정렬해
                // 항상 일관된 순서로 화면에 표시되도록 정제된 배열을 반환
                return allStories.sorted { $0.id > $1.id }
            }
        } catch {
            // 전체 TaskGroup 중 하나라도 실패하면 여기로 에러가 전파됨
            print("Failed to load stories")
        }
    }
}
```

---

### 5. TaskGroup의 완료 규칙과 “기다리는 방법” 3가지

- 공통 규칙:
  - Throwing/Non-Throwing에 상관없이 **그룹 안의 모든 child task가 완료되어야** `withTaskGroup` / `withThrowingTaskGroup` 이 반환된다.

#### 6.1 모든 Task를 개별적으로 await 하기

- 예: `for await value in group { ... }`, 또는 `for try await value in group { ... }`
- 장점:
  - **가장 명시적**이고 읽기 쉽다.
  - “Task를 만들어놓고 결과를 안 쓰는 건가?” 같은 의문을 줄여준다.

#### 6.2 `waitForAll()` 사용

- `group.waitForAll()` 을 호출하면,
  - 우리가 명시적으로 `await`하지 않은 Task들까지 **모두 완료될 때까지 기다려 준다.**
  - 이때 그 Task들의 **반환값은 버려진다.**

#### 6.3 아무 child task도 명시적으로 await 하지 않기 (암묵적 await)

- 우리가 개별 Task를 전혀 `await` 하지 않아도,
  - Swift는 **그룹이 끝나기 전에 모든 child task가 끝날 때까지 자동으로 기다린다.**
- 즉, 결과를 사용하지 않더라도 Task들은 끝까지 실행된다.

#### 6.4 실무에서 자주 쓰는 방식

- 세 가지 방법 중 **“각 Task를 명시적으로 await 하는 방식(6.1)”**을 가장 자주 사용하게 된다.
- 이유:
  - 코드 읽는 사람이 “이 Task는 왜 만들고 방치하지?” 같은 의문을 갖지 않게 해주고,
  - 흐름이 가장 분명하다.

---

### 7. 한 줄 정리

- `withTaskGroup` / `withThrowingTaskGroup` =
  - 여러 비동기 작업을 **한 번에 던져두고**, **완료되는 순서대로 결과를 모아서 하나의 결과로 만드는 도구**
- 실제 네트워크/파일 I/O, 여러 API 병렬 호출 같은 곳에서 **간단한 루프로 Task를 생성하고 합치는 패턴**을 만들 수 있다.



## Task Group 취소하는 방법 (How to Cancel a Task Group)

### 1. Task Group이 취소되는 3가지 경우

1. **부모 Task가 취소될 때**
   - TaskGroup의 부모 Task가 취소되면 그룹 전체가 취소됨

2. **`cancelAll()` 명시적 호출**
   - 그룹에서 `group.cancelAll()`을 직접 호출

3. **child Task 중 하나가 에러를 던질 때**
   - throwing task group에서 한 task가 에러를 던지면 나머지 모든 task가 암묵적으로 취소됨

---

### 2. cancelAll()의 동작 방식

#### ✔️ 핵심 특징

- Task Group 취소도 **협력적 취소(cooperative cancellation)**
- `cancelAll()`을 호출해도 child task들이 취소를 확인하지 않으면 계속 실행됨
- Task는 `Task.isCancelled` 또는 `Task.checkCancellation()`으로 취소 여부를 확인해야 함
- **이미 완료된 작업은 취소할 수 없음** — 취소는 "남은 작업"에만 적용됨

---

### 3. 예시: cancelAll()만 호출하는 경우

```swift
func printMessage() async {
    let result = await withThrowingTaskGroup(of: String.self) { group in
        group.addTask { "Testing" }
        group.addTask { "Group" }
        group.addTask { "Cancellation" }

        // 모든 Task를 생성한 직후 즉시 취소 요청
        group.cancelAll()

        var collected = [String]()

        do {
            for try await value in group {
                collected.append(value)
            }
        } catch {
            print(error.localizedDescription)
        }

        return collected.joined(separator: " ")
    }

    print(result)
}

// INSIDE MAIN
await printMessage()
```

**결과:**

- 세 개의 문자열이 모두 출력됨
- **이유:** Task들이 취소를 확인하지 않기 때문에 `cancelAll()`이 영향을 주지 못함

---

### 4. 예시: 취소를 실제로 확인하는 경우

```swift
func printMessage() async {
    let result = await withThrowingTaskGroup(of: String.self) { group in
        // 첫 번째 Task는 취소를 명시적으로 확인
        group.addTask {
            try Task.checkCancellation()  // 취소되었다면 여기서 CancellationError throw
            return "Testing"
        }

        group.addTask { "Group" }
        group.addTask { "Cancellation" }

        group.cancelAll()

        var collected = [String]()

        do {
            for try await value in group {
                collected.append(value)
            }
        } catch {
            print(error.localizedDescription)
        }

        return collected.joined(separator: " ")
    }

    print(result)
}

// INSIDE MAIN
await printMessage()
```

**가능한 결과:**

- "Cancellation" 단독
- "Group" 단독
- "Cancellation Group"
- "Group Cancellation"
- 빈 문자열

**이유:**

- 세 Task가 모두 즉시 시작됨 (병렬 실행 가능)
- `cancelAll()` 호출 시점에 이미 일부 Task가 실행 중일 수 있음
- 첫 번째로 완료되는 Task가 `checkCancellation()`을 호출하면 즉시 에러를 던지고 종료
- 다른 Task들이 먼저 완료되면 그 결과가 포함될 수 있음

---

### 5. 중요한 포인트 정리

1. **cancelAll()은 "남은 작업"만 취소**
   - 이미 완료된 작업은 되돌릴 수 없음

2. **취소는 협력적(cooperative)**
   - Task가 스스로 취소 상태를 확인해야 함
   - `Task.isCancelled` 또는 `Task.checkCancellation()` 사용 필요

3. **병렬 실행의 불확실성**
   - Task들이 언제 시작되고 완료되는지는 시스템이 결정
   - 취소 시점과 Task 완료 시점의 경쟁 조건(race condition) 발생 가능

4. **에러 발생 시 자동 취소**
   - `withThrowingTaskGroup`에서 한 Task가 에러를 던지면
   - 나머지 모든 Task가 자동으로 취소됨 (협력적 취소)

---

### 6. 실전 예제: 뉴스 피드 가져오기 중 중단하기

```swift
struct NewsStory: Identifiable, Decodable {
    let id: Int
    let title: String
    let strap: String
    let url: URL
}

struct ContentView: View {
    @State private var stories = [NewsStory]()

    var body: some View {
        NavigationStack {
            List(stories) { story in
                VStack(alignment: .leading) {
                    Text(story.title)
                        .font(.headline)

                    Text(story.strap)
                }
            }
            .navigationTitle("Latest News")
        }
        .task {
            await loadStories()
        }
    }

    func loadStories() async {
        do {
            try await withThrowingTaskGroup(of: [NewsStory].self) { group in
                // 5개의 뉴스 피드를 병렬로 가져오기
                for i in 1...5 {
                    group.addTask {
                        let url = URL(string: "https://hws.dev/news-\(i).json")!
                        let (data, _) = try await URLSession.shared.data(from: url)

                        // 명시적 취소 확인
                        try Task.checkCancellation()

                        return try JSONDecoder().decode([NewsStory].self, from: data)
                    }
                }

                // 완료된 결과를 순서대로 처리
                for try await result in group {
                    if result.isEmpty {
                        // 빈 배열 = 데이터 할당량 소진
                        // 나머지 피드 가져오기를 모두 취소
                        group.cancelAll()
                    } else {
                        stories.append(contentsOf: result)
                    }
                }

                stories.sort { $0.id < $1.id }
            }
        } catch {
            print("Failed to load stories: \(error.localizedDescription)")
        }
    }
}
```

**핵심 포인트:**

- 빈 배열을 받으면 즉시 `cancelAll()` 호출하여 불필요한 네트워크 요청 중단
- `Task.checkCancellation()`으로 명시적 취소 확인
- `URLSession.shared.data(from:)`도 내부적으로 취소를 확인하여 불필요한 작업 방지

---

### 7. 에러 발생 시 자동 취소 예제

```swift
enum ExampleError: Error {
    case badURL
}

func testCancellation() async {
    do {
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Task 1: 1초 후 에러 발생
            group.addTask {
                try await Task.sleep(for: .seconds(1))
                throw ExampleError.badURL
            }

            // Task 2: 2초 후 취소 여부 확인
            group.addTask {
                try await Task.sleep(for: .seconds(2))
                print("Task is cancelled: \(Task.isCancelled)")
            }

            // next()로 첫 번째 완료된 Task의 결과를 기다림
            // 에러가 발생하면 여기서 throw되고 나머지 Task들이 취소됨
            try await group.next()
        }
    } catch {
        print("Error thrown: \(error.localizedDescription)")
    }
}

// INSIDE MAIN
await testCancellation()

/*
출력:
Task is cancelled: true
Error thrown: The operation couldn't be completed. (...)
*/
```

**동작 과정:**

1. 두 Task 모두 동시에 시작
2. 1초 후 첫 번째 Task가 에러를 throw
3. `group.next()`가 에러를 받아서 다시 throw
4. 그룹의 나머지 Task(두 번째)가 자동으로 취소됨
5. 두 번째 Task는 2초 후 깨어나면서 `Task.isCancelled`가 `true`임을 확인

---

### 8. 에러 발생 시 취소의 중요한 규칙

⚠️ **Task 내부에서 에러를 던지는 것만으로는 다른 Task가 취소되지 않음**

취소가 발생하려면:

- `next()`로 명시적으로 Task 결과를 기다리거나
- `for try await` 루프로 Task 결과를 순회해야 함

즉, **에러를 던진 Task의 결과에 접근할 때** 비로소 에러가 전파되고 그룹의 다른 Task들이 취소됨.

---

### 9. addTaskUnlessCancelled() — 취소된 그룹에 Task 추가 방지

#### 문제 상황

- `group.addTask()`는 **그룹이 이미 취소되었어도 무조건 Task를 추가**함
- 이미 취소된 그룹에 불필요한 작업을 추가하게 될 수 있음

#### 해결 방법

```swift
// 그룹이 취소되지 않았을 때만 Task 추가
let wasAdded = group.addTaskUnlessCancelled {
    // 작업 내용
    return someValue
}

if wasAdded {
    print("Task가 성공적으로 추가됨")
} else {
    print("그룹이 이미 취소되어 Task가 추가되지 않음")
}
```

#### 특징

- 반환값: `Bool`
  - `true` — Task가 성공적으로 추가됨
  - `false` — 그룹이 이미 취소되어 Task가 추가되지 않음
- 사용 시기:
  - 동적으로 Task를 추가하는 상황에서
  - 그룹이 취소된 후 불필요한 작업을 방지하고 싶을 때

---

### 10. Task Group 취소 요약

| 상황                  | 취소 방법   | 비고                                         |
| --------------------- | ----------- | -------------------------------------------- |
| 부모 Task 취소        | 자동 취소   | 부모가 취소되면 그룹 전체 취소               |
| `cancelAll()` 호출    | 명시적 취소 | 남은 Task만 취소, 협력적                     |
| 에러 발생             | 자동 취소   | `next()` 또는 `for try await`로 에러 접근 시 |
| View 사라짐 (SwiftUI) | 자동 취소   | `.task` modifier 사용 시                     |

**핵심 원칙:**

- 모든 취소는 **협력적**
- Task는 `Task.isCancelled` 또는 `Task.checkCancellation()`으로 스스로 확인해야 함
- Foundation API (URLSession 등)는 내부적으로 취소를 확인함



## Task Group에서 서로 다른 결과 타입 처리하기

### 1. 문제 상황

- Task Group의 모든 child task는 **동일한 타입**을 반환해야 함
- 예: `withTaskGroup(of: String.self)` → 모든 Task가 `String` 반환
- 하지만 실무에서는 여러 다른 타입의 데이터를 동시에 가져와야 하는 경우가 많음

---

### 2. 해결 방법 두 가지

#### 방법 1: async let 사용 (권장)

```swift
async let username = fetchUsername()
async let favorites = fetchFavorites()  // Set<Int>
async let messages = fetchMessages()    // [Message]

// 각자 다른 타입을 반환 가능
let user = await User(
    username: username,
    favorites: favorites,
    messages: messages
)
```

**장점:**

- 각 작업이 고유한 타입을 반환할 수 있음
- 간결하고 타입 안전

**단점:**

- 작업 개수가 컴파일 타임에 고정되어야 함
- 루프로 동적 생성 불가

---

#### 방법 2: Enum + Associated Values 사용

- Task를 루프로 동적 생성해야 할 때
- Task Group을 반드시 써야 할 때

**핵심 아이디어:**

1. 반환할 각 타입을 감싸는 **enum**을 만듦
2. 각 case는 **associated value**로 실제 데이터를 포함
3. 모든 Task는 이 enum 타입을 반환 (형식적으로는 같은 타입)
4. 결과를 받을 때 **switch**로 case를 구분하고 데이터를 추출

---

### 3. 실전 예제: 사용자 정보 가져오기 (3가지 다른 타입)

```swift
// 디코딩할 메시지 구조체
struct Message: Decodable {
    let id: Int
    let from: String
    let message: String
}

// 최종적으로 만들 사용자 구조체
struct User {
    let username: String
    let favorites: Set<Int>
    let messages: [Message]
}

// 서로 다른 타입들을 감싸는 enum
enum FetchResult {
    case username(String)       // String 타입
    case favorites(Set<Int>)    // Set<Int> 타입
    case messages([Message])    // [Message] 타입
}

func loadUser() async {
    // TaskGroup은 FetchResult라는 하나의 타입만 반환
    let user = await withThrowingTaskGroup(of: FetchResult.self) { group in

        // Task 1: username (String) 가져오기
        group.addTask {
            let url = URL(string: "https://hws.dev/username.json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = String(decoding: data, as: UTF8.self)

            // FetchResult.username case로 감싸서 반환
            return .username(result)
        }

        // Task 2: favorites (Set<Int>) 가져오기
        group.addTask {
            let url = URL(string: "https://hws.dev/user-favorites.json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(Set<Int>.self, from: data)

            // FetchResult.favorites case로 감싸서 반환
            return .favorites(result)
        }

        // Task 3: messages ([Message]) 가져오기
        group.addTask {
            let url = URL(string: "https://hws.dev/user-messages.json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode([Message].self, from: data)

            // FetchResult.messages case로 감싸서 반환
            return .messages(result)
        }

        // 기본값 설정
        var username = "Anonymous"
        var favorites = Set<Int>()
        var messages = [Message]()

        // 완료된 Task들의 결과를 순회하며 처리
        do {
            for try await value in group {
                // switch로 각 case를 구분하고 associated value 추출
                switch value {
                case .username(let value):
                    username = value
                case .favorites(let value):
                    favorites = value
                case .messages(let value):
                    messages = value
                }
            }
        } catch {
            // 일부 fetch가 실패해도 받아온 데이터는 사용
            print("Fetch at least partially failed; sending back what we have so far. \(error.localizedDescription)")
        }

        // User 인스턴스 생성 및 반환
        return User(username: username, favorites: favorites, messages: messages)
    }

    // 완성된 사용자 데이터 사용
    print("User \(user.username) has \(user.messages.count) messages and \(user.favorites.count) favorites.")
}

// INSIDE MAIN
await loadUser()
```

---

### 4. 핵심 단계 정리

#### Step 1: Enum 정의

```swift
enum FetchResult {
    case username(String)
    case favorites(Set<Int>)
    case messages([Message])
}
```

- 각 case = 하나의 데이터 타입
- associated value로 실제 데이터를 감쌈

#### Step 2: Task에서 enum case로 감싸서 반환

```swift
group.addTask {
    let data = try await fetchSomeData()
    return .username(data)  // enum case로 반환
}
```

#### Step 3: 결과 처리 시 switch로 분기

```swift
for try await value in group {
    switch value {
    case .username(let str):
        // String 데이터 사용
    case .favorites(let set):
        // Set<Int> 데이터 사용
    case .messages(let arr):
        // [Message] 데이터 사용
    }
}
```

---

### 5. 장단점 비교

| 방법                 | 장점                                                         | 단점                                                         | 사용 시기                                 |
| -------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ----------------------------------------- |
| **async let**        | • 간결함<br>• 타입 안전<br>• 코드가 명확                     | • 작업 개수 고정<br>• 동적 생성 불가                         | 작업 개수가 고정일 때                     |
| **enum + TaskGroup** | • 동적 Task 생성 가능<br>• 루프로 Task 추가 가능<br>• 유연함 | • 보일러플레이트 코드 증가<br>• enum 정의 필요<br>• switch 처리 필요 | 작업 개수가 동적일 때<br>루프가 필요할 때 |

---

### 6. 실무 팁

1. **대부분의 경우 async let을 먼저 고려**
   - 코드가 더 명확하고 간결
   - 타입 안전성이 높음

2. **다음 경우에만 enum + TaskGroup 사용**
   - 루프로 Task를 생성해야 할 때
   - 런타임에 Task 개수가 결정될 때
   - Task Group의 다른 기능(취소, 우선순위 등)이 필요할 때

3. **부분 실패 처리**
   - 위 예제처럼 기본값을 설정하고
   - catch에서도 지금까지 받은 데이터를 사용할 수 있음
   - 일부 데이터라도 사용자에게 보여주는 것이 더 나은 UX

---

### 7. 요약

**문제:** Task Group의 모든 Task는 같은 타입을 반환해야 함

**해결:**

- 작업 개수 고정 → `async let` 사용 (권장)
- 작업 개수 동적 → `enum` + `associated values` + `TaskGroup`

**핵심:**

- Enum으로 여러 타입을 하나의 타입으로 "포장"
- Switch로 결과를 "언박싱"하여 사용



## Task Group에서 결과 폐기하기 (Discarding Task Group)

### 1. 문제 상황: 일반 Task Group의 메모리 누수

#### 서버나 장시간 실행되는 Task의 문제

- 서버가 연결을 계속 받는 경우
- 파일 시스템 감시자가 계속 변경사항을 스캔하는 경우
- 무한히 데이터를 생성하는 경우

→ Task가 완료되어도 우리가 `next()` 또는 `for await`로 결과를 기다리지 않으면 **Task가 메모리에 계속 쌓임**

---

### 2. 메모리 누수 예제

#### 계속해서 랜덤 숫자를 생성하는 AsyncSequence

```swift
struct RandomGenerator: AsyncSequence, AsyncIteratorProtocol {
    mutating func next() async -> Int? {
        try? await Task.sleep(for: .seconds(0.001))
        return Int.random(in: 1...Int.max)
    }

    func makeAsyncIterator() -> Self {
        self
    }
}
```

#### 메모리 누수가 발생하는 코드

```swift
// INSIDE MAIN
let generator = RandomGenerator()

await withTaskGroup(of: Void.self) { group in
    for await newNumber in generator {
        group.addTask {
            print(newNumber)
        }
    }
}
```

**문제점:**

- Task는 `Void`를 반환 (반환값 없음)
- 하지만 **완료된 Task를 명시적으로 await 하지 않음**
- 완료된 Task들이 메모리에 계속 쌓여서 **초당 약 0.5MB씩 메모리 누수 발생**

---

### 3. 일반적인 해결 시도와 새로운 문제

#### 해결 시도: Task 결과를 await 하기

```swift
await withTaskGroup(of: Void.self) { group in
    for await newNumber in generator {
        group.addTask {
            print(newNumber)
        }

        // Task 완료를 기다림 → 메모리 누수 해결
        await group.next()
    }
}
```

#### 새로운 문제 발생

- 현재 Task가 완료될 때까지 기다려야 함
- **그동안 새로운 연결(또는 데이터)을 받을 수 없음**
- 서버의 경우: 한 번에 하나의 연결만 처리 가능 → 병렬 처리 불가능
- 성능 저하 발생

---

### 4. 해결책: Discarding Task Group

#### 핵심 개념

- **Discarding Task Group**은 완료된 Task를 자동으로 폐기하고 파괴함
- `next()` 같은 명시적 대기가 **필요 없음**
- 실제로 결과를 기다릴 수도 **없음** (설계상 불가능)
- 완료되는 즉시 자동으로 정리됨

#### 사용 방법

```swift
// 기존 코드
await withTaskGroup(of: Void.self) { group in

// 변경 후
await withDiscardingTaskGroup { group in
```

---

### 5. 완전한 예제: Discarding Task Group 사용

```swift
// INSIDE MAIN
let generator = RandomGenerator()

await withDiscardingTaskGroup { group in
    for await newNumber in generator {
        group.addTask {
            print(newNumber)
        }
    }
}
```

**효과:**

- ✅ 메모리 누수 없음 (완료된 Task 자동 파괴)
- ✅ 병렬 처리 가능 (새 Task를 계속 추가 가능)
- ✅ 명시적 대기 불필요

---

### 6. 실전 사용 사례

#### 서버 연결 처리

```swift
// 서버가 계속해서 연결을 받는 상황
await withDiscardingTaskGroup { group in
    for await connection in server.incomingConnections {
        group.addTask {
            // 각 연결을 독립적으로 처리
            await handleConnection(connection)
            // 완료되면 자동으로 Task가 파괴됨
        }
    }
}
```

#### 파일 시스템 감시

```swift
await withDiscardingTaskGroup { group in
    for await fileChange in fileWatcher.changes {
        group.addTask {
            // 파일 변경사항 처리
            await processFileChange(fileChange)
            // 완료 후 자동 정리
        }
    }
}
```

---

### 7. Throwing Discarding Task Group

#### withThrowingDiscardingTaskGroup

- 에러를 던질 수 있는 Discarding Task Group
- 기본적인 동작은 동일하지만 Task 내부에서 에러를 던질 수 있음

```swift
await withThrowingDiscardingTaskGroup { group in
    for await connection in server.incomingConnections {
        group.addTask {
            // 에러가 발생할 수 있는 작업
            try await handleConnection(connection)
        }
    }
}
```

---

### 8. 일반 Task Group vs Discarding Task Group 비교

| 특징            | 일반 Task Group              | Discarding Task Group            |
| --------------- | ---------------------------- | -------------------------------- |
| **결과 대기**   | 필수 (`next()`, `for await`) | 자동 (불가능)                    |
| **메모리 관리** | 수동 (명시적 대기 필요)      | 자동 (완료 즉시 파괴)            |
| **반환값 사용** | 가능                         | 불가능 (자동 폐기)               |
| **사용 사례**   | 결과가 필요한 경우           | 결과가 필요 없는 fire-and-forget |
| **장시간 실행** | 메모리 누수 위험             | 안전                             |
| **병렬 처리**   | 대기 시 차단 가능            | 항상 비차단                      |

---

### 9. 언제 Discarding Task Group을 사용해야 할까?

#### ✅ 사용해야 할 때

1. **장시간 또는 무한히 실행되는 작업**
   - 서버 연결 처리
   - 파일 시스템 감시
   - 이벤트 리스너

2. **Task의 반환값이 필요 없는 경우**
   - Fire-and-forget 패턴
   - 로깅, 알림 전송 등

3. **많은 수의 Task를 계속 생성하는 경우**
   - 수천~수만 개의 독립적인 작업 처리

#### ❌ 사용하지 말아야 할 때

1. **Task의 결과를 수집해야 하는 경우**
   - 여러 API 호출 결과를 모아서 사용
   - 일반 Task Group 사용

2. **모든 Task의 완료를 명시적으로 기다려야 하는 경우**
   - 일반 Task Group의 `waitForAll()` 사용

3. **Task 개수가 적고 제한적인 경우**
   - 일반 Task Group으로 충분

---

### 10. 핵심 정리

**문제:**

- 일반 Task Group에서 결과를 기다리지 않으면 메모리 누수 발생
- 결과를 기다리면 병렬 처리가 제한됨

**해결:**

- `withDiscardingTaskGroup` 사용
- 완료된 Task를 자동으로 폐기하여 메모리 관리
- 병렬 처리를 막지 않음

**사용법:**

```swift
// Non-throwing
await withDiscardingTaskGroup { group in
    // Task 추가
}

// Throwing
await withThrowingDiscardingTaskGroup { group in
    // 에러를 던질 수 있는 Task 추가
}
```

**주의사항:**

- Task의 반환값을 사용할 수 없음 (자동 폐기되므로)
- 오직 side effect만을 위한 작업에 사용



## async let vs Task vs Task Group 비교 및 선택 가이드

### 1. 공통점

세 가지 모두 **동시성(concurrency)을 생성**하여 시스템이 효율적으로 실행할 수 있도록 함

---

### 2. 핵심 차이점 5가지

#### 차이점 1: 작업 개수의 동적/정적 처리

**async let & Task**

- **개별 작업** 생성에 적합
- 작업 개수가 **컴파일 타임에 고정**되어야 함
- 동적으로 작업을 생성할 수 없음

```swift
// ❌ 배열의 URL 개수만큼 동적으로 작업 생성 불가
async let data1 = fetch(url1)
async let data2 = fetch(url2)
// ... 개수가 정해져 있어야 함
```

**Task Group**

- **여러 작업을 동시에 실행**하고 결과를 수집
- 작업 개수를 **런타임에 동적으로 결정** 가능
- 배열을 루프로 돌면서 작업 추가 가능

```swift
// ✅ 배열의 URL 개수만큼 동적으로 작업 생성 가능
await withTaskGroup(of: Data.self) { group in
    for url in urls {  // urls.count는 런타임에 결정
        group.addTask {
            await fetch(url)
        }
    }
}
```

**예시: URL 배열에서 날씨 데이터 가져오기**

- Task Group: 배열을 루프로 돌면서 각 URL을 병렬로 fetch
- async let/Task: URL 개수를 미리 알아야 하므로 하드코딩 필요

**✅ Task를 동적으로 생성하면 요청 순서를 유지할 수 있다**

Task 자체는 배열을 순회하며 동적으로 생성할 수 있습니다. 이 방식의 **장점**은 **요청 순서를 보장**할 수 있다는 점입니다:

```swift
let data = [1, 2, 3, 4, 5]

func createTask(for index: Int) -> Task<Int, any Error> {
    return Task {
        let delay = data.randomElement()!
        print("Task(\(index)) 시작 -> 딜레이: \(delay)")
        // 랜덤하게 sleep, 병렬 처리 시 언제 끝날지 모르는 상황을 재현
        try await Task.sleep(for: .seconds(delay))
        return index
    }
}

Task {
    let start = Date()

    let tasks = data.map { createTask(for: $0) }
    var result: [Int] = []

    // 모든 테스크는 반드시 await을 하여 끝내야 한다. 그러지 않으면 고아 테스크가 생겨 성능 이슈로 이어짐.
    for task in tasks {
        result.append(try await task.value)
    }

    print("총 걸린 시간: \(Date().timeIntervalSince(start))")
    print("결과: \(result)")
}

/*
출력:
Task(1) 시작 -> 딜레이: 3
Task(2) 시작 -> 딜레이: 5
Task(4) 시작 -> 딜레이: 3
Task(3) 시작 -> 딜레이: 4
Task(5) 시작 -> 딜레이: 1
총 걸린 시간: 5.297232031822205
결과: [1, 2, 3, 4, 5]
*/
```

**핵심 특징:**

1. **병렬 실행**: 모든 Task가 동시에 시작됨 (Task(1)~(5) 모두 즉시 실행)
2. **요청 순서 보장**: 결과는 항상 `[1, 2, 3, 4, 5]` 순서로 수집됨
3. **총 실행 시간**: 가장 긴 작업 시간만큼 소요 (위 예시: 5초)
4. **고아 Task 방지**: 배열의 순서대로 모든 Task를 명시적으로 await

**Task Group과의 비교:**

```swift
// Task Group: 완료 순서대로 결과 처리 (순서 보장 안 됨)
await withTaskGroup(of: Int.self) { group in
    for index in data {
        group.addTask {
            try await Task.sleep(for: .seconds(data.randomElement()!))
            return index
        }
    }

    var result: [Int] = []
    for await value in group {
        result.append(value)
    }
    print(result)  // 예: [5, 1, 4, 3, 2] - 완료 순서대로

    // 순서를 맞추려면 정렬 필요 → O(n log n) 시간복잡도
    result.sort()
    print(result)  // [1, 2, 3, 4, 5]
}
```

**💡 Task Group에서도 순서를 O(n)으로 보장하는 방법**

정렬 대신, **인덱스와 함께 반환**하여 미리 할당된 배열의 올바른 위치에 저장하면 시간복잡도를 **O(n)**으로 유지할 수 있습니다:

```swift
// Task Group: 인덱스를 함께 반환하여 순서 보장 (O(n))
await withTaskGroup(of: (index: Int, value: Int).self) { group in
    for (index, _) in data.enumerated() {
        group.addTask {
            let delay = data.randomElement()!
            try await Task.sleep(for: .seconds(delay))
            return (index: index, value: index + 1)  // 인덱스와 값을 함께 반환
        }
    }

    // 미리 결과 배열을 요청 개수만큼 할당
    var result = Array(repeating: 0, count: data.count)

    for await (index, value) in group {
        result[index] = value  // O(1) - 올바른 위치에 직접 저장
    }

    print(result)  // [1, 2, 3, 4, 5] - 정렬 없이 순서 보장
}
```

**시간복잡도 비교:**

| 방식                              | 시간복잡도  | 설명                                      |
| --------------------------------- | ----------- | ----------------------------------------- |
| Task 배열 (순서대로 await)        | **O(n)**    | 배열 순서대로 await하므로 자동 정렬       |
| TaskGroup + 정렬                  | **O(n log n)** | 완료 순서로 받은 후 정렬 필요             |
| TaskGroup + 인덱스 기반 배열 저장 | **O(n)**    | 미리 할당된 배열에 인덱스로 직접 저장     |

**언제 어떤 방식을 선택할까?**

| 상황                              | 선택                       | 이유                                               |
| --------------------------------- | -------------------------- | -------------------------------------------------- |
| 순서 보장 + 간단한 구현           | Task 배열                  | 요청 순서대로 자동 정렬, 코드 간결                 |
| 순서 보장 + 취소 기능 필요        | TaskGroup + 인덱스         | O(n) 시간복잡도 + `cancelAll()` 사용 가능          |
| 순서 보장 + 대용량 데이터         | TaskGroup + 인덱스         | 정렬 비용(O(n log n)) 없이 O(n)으로 처리           |
| 가장 빠른 결과만 필요             | Task Group                 | `group.next()` 로 첫 번째 완료된 것만 사용         |
| 완료되는 대로 즉시 UI 업데이트    | Task Group                 | 완료 순서대로 즉시 표시 (응답성 향상)              |
| 결과 순서가 중요하지 않은 경우    | Task Group                 | 완료 순서대로 처리                                 |
| 작업 그룹 전체 취소가 필요한 경우 | Task Group                 | `cancelAll()` 로 그룹 전체 취소 가능               |

→ **결론**:
- **Task 배열**: 간단한 순서 보장이 필요할 때, 코드 가독성이 중요할 때
- **TaskGroup + 인덱스**: 순서 보장 + 취소 기능 + O(n) 성능이 모두 필요할 때 (대용량 데이터에 유리)
- **TaskGroup (일반)**: 완료 순서대로 처리하여 빠른 응답성이 필요할 때

---

#### 차이점 2: 결과 처리 순서

**async let & Task**

- **명시한 순서대로** 결과를 받아야 함
- 먼저 완료된 작업이 있어도 await 순서대로만 읽을 수 있음

```swift
async let data1 = slowTask()   // 10초 걸림
async let data2 = fastTask()   // 1초 걸림

// data2가 먼저 완료되어도 data1을 먼저 기다려야 함
let result1 = await data1  // 10초 대기
let result2 = await data2  // 이미 완료됨
```

**Task Group**

- **완료되는 순서대로** 결과를 처리 가능
- `group.next()` 또는 `for await`로 가장 먼저 완료된 작업의 결과를 읽음

```swift
await withTaskGroup(of: Data.self) { group in
    group.addTask { await slowTask() }   // 10초
    group.addTask { await fastTask() }   // 1초

    // fastTask 결과를 먼저 받음 (1초 후)
    if let firstResult = await group.next() {
        print("First result: \(firstResult)")
    }
}
```

**실전 예시: 여러 서버 중 가장 빠른 서버 사용**

```swift
await withTaskGroup(of: Data.self) { group in
    group.addTask { await fetchFrom(server1) }
    group.addTask { await fetchFrom(server2) }
    group.addTask { await fetchFrom(server3) }

    // 가장 빠른 서버의 응답만 사용
    if let fastestResponse = await group.next() {
        return fastestResponse
    }
}
```

---

#### 차이점 3: 직접 취소 기능

**async let**

- ❌ 직접 취소 불가능
- 부모 Task가 취소되면 자동으로 취소됨

**Task**

- ✅ `task.cancel()` 로 직접 취소 가능

```swift
let task = Task {
    await someWork()
}

task.cancel()  // 직접 취소
```

**Task Group**

- ✅ `group.cancelAll()` 로 모든 child task 취소 가능

```swift
await withTaskGroup(of: Int.self) { group in
    group.addTask { await work1() }
    group.addTask { await work2() }

    group.cancelAll()  // 모든 작업 취소
}
```

---

#### 차이점 4: Task 참조 전달 가능 여부

**async let**

- ❌ 내부 Task에 대한 참조(handle)를 얻을 수 없음
- 다른 함수로 Task를 전달할 수 없음
- async let을 시작한 곳에서 반드시 await 해야 함

```swift
func startWork() {
    async let result = fetchData()
    // result를 다른 함수로 전달 불가능
    await processResult(result)  // 여기서만 사용 가능
}
```

**Task**

- ✅ Task 객체를 변수에 저장하고 전달 가능
- `Task<String, Never>` 같은 타입으로 참조 가능

```swift
func startWork() -> Task<String, Never> {
    // Task를 반환하여 다른 곳에서 사용 가능
    return Task {
        return await fetchData()
    }
}

func processWork() async {
    let task = startWork()
    // 다른 작업...
    let result = try await task.value
}
```

---

#### 차이점 5: 서로 다른 타입 처리

**async let & Task**

- ✅ 각 작업이 서로 다른 타입을 반환 가능
- 추가 작업 없이 자연스럽게 처리

```swift
async let name: String = fetchName()
async let age: Int = fetchAge()
async let scores: [Double] = fetchScores()

// 각기 다른 타입을 쉽게 사용
let user = User(
    name: await name,
    age: await age,
    scores: await scores
)
```

**Task Group**

- ⚠️ 모든 child task가 같은 타입을 반환해야 함
- 다른 타입을 사용하려면 **enum + associated values**로 감싸야 함 (번거로움)

```swift
// 각기 다른 타입을 위해 enum 필요
enum Result {
    case name(String)
    case age(Int)
    case scores([Double])
}

await withTaskGroup(of: Result.self) { group in
    group.addTask { .name(await fetchName()) }
    group.addTask { .age(await fetchAge()) }
    group.addTask { .scores(await fetchScores()) }
    // switch로 unwrapping 필요...
}
```

---

### 3. 비교표

| 특징            | async let          | Task               | Task Group      |
| --------------- | ------------------ | ------------------ | --------------- |
| **작업 개수**   | 고정 (컴파일 타임) | 고정 (컴파일 타임) | 동적 (런타임)   |
| **결과 순서**   | 명시한 순서대로    | 명시한 순서대로    | 완료 순서대로   |
| **직접 취소**   | ❌ 불가능           | ✅ `cancel()`       | ✅ `cancelAll()` |
| **Task 전달**   | ❌ 불가능           | ✅ 가능             | N/A             |
| **다른 타입**   | ✅ 쉬움             | ✅ 쉬움             | ⚠️ enum 필요     |
| **사용 난이도** | 가장 쉬움          | 쉬움               | 복잡함          |
| **코드 간결성** | 매우 간결          | 간결               | 상대적으로 장황 |

---

### 4. 실무 사용 가이드

#### 📊 사용 빈도 (높음 → 낮음)

1. **async let** (가장 많이 사용)
2. **Task** (중간)
3. **Task Group** (가장 적게 사용)

---

### 5. 언제 무엇을 사용할까?

#### ✅ async let을 사용해야 할 때 (1순위)

**특징:**

- 가장 간결하고 읽기 쉬운 코드
- 타입 안전성이 높음
- 대부분의 상황에서 충분함

**사용 사례:**

- 고정된 개수의 작업을 병렬로 실행
- 각 작업이 서로 다른 타입을 반환
- 모든 결과가 필요함

```swift
// 사용자 프로필 페이지 로딩
async let profile = fetchProfile()
async let posts = fetchPosts()
async let followers = fetchFollowers()

return ProfileView(
    profile: await profile,
    posts: await posts,
    followers: await followers
)
```

---

#### ✅ Task를 사용해야 할 때 (2순위)

**특징:**

- async let보다 유연함
- 취소 기능 필요
- Task 참조를 전달해야 함

**사용 사례:**

- Task를 취소해야 하는 경우
- Task를 다른 함수로 전달해야 하는 경우
- async let으로는 표현할 수 없는 로직

```swift
// 검색 기능: 이전 검색 취소
class SearchViewModel {
    var currentSearchTask: Task<[Result], Never>?

    func search(query: String) {
        // 이전 검색 취소
        currentSearchTask?.cancel()

        // 새 검색 시작
        currentSearchTask = Task {
            await performSearch(query)
        }
    }
}
```

---

#### ✅ Task Group을 사용해야 할 때 (3순위)

**특징:**

- 동적 개수의 작업 처리
- 완료 순서대로 결과 처리
- 가장 복잡하지만 강력함

**사용 사례:**

- 작업 개수가 런타임에 결정 (배열, 딕셔너리 등)
- 완료 순서가 중요한 경우
- 가장 빠른 결과만 필요한 경우

```swift
// 동적 개수의 이미지 다운로드
func downloadImages(urls: [URL]) async -> [UIImage] {
    await withTaskGroup(of: UIImage?.self) { group in
        for url in urls {
            group.addTask {
                await downloadImage(from: url)
            }
        }

        var images: [UIImage] = []
        for await image in group {
            if let image = image {
                images.append(image)
            }
        }
        return images
    }
}
```

---

### 6. 실무 선택 원칙

#### 1단계: async let으로 시작

```swift
async let data1 = fetch1()
async let data2 = fetch2()
let result = await (data1, data2)
```

**이유:**

- 대부분의 경우 async let으로 충분
- 가장 간결하고 읽기 쉬움
- 다른 타입 처리가 간편

---

#### 2단계: 필요시 Task로 이동

**다음 경우에만 Task 사용:**

- ✅ 취소 기능이 필요할 때
- ✅ Task를 전달해야 할 때
- ✅ fire-and-forget 패턴이 필요할 때

```swift
let task = Task {
    await longRunningWork()
}

// 나중에 취소 가능
task.cancel()
```

---

#### 3단계: 특수한 경우에만 Task Group 사용

**다음 경우에만 Task Group 사용:**

- ✅ 작업 개수가 동적일 때 (배열, 루프)
- ✅ 완료 순서대로 처리해야 할 때
- ✅ 가장 빠른 결과만 필요할 때

```swift
// 가장 빠른 서버 응답 사용
await withTaskGroup(of: Data.self) { group in
    for server in servers {
        group.addTask { await fetch(from: server) }
    }
    return await group.next()  // 가장 빠른 것만
}
```

---

### 7. 왜 이 순서로 선택해야 할까?

#### 실무에서 발견한 패턴

1. **대부분은 모든 결과가 필요함**
   - 일부만 사용하거나 완료 순서가 중요한 경우는 드묾
   - async let이면 충분

2. **서로 다른 타입을 다루는 경우가 많음**
   - Task Group의 enum wrapping은 번거로움
   - async let/Task는 자연스러움

3. **취소가 필요하면 Task로 쉽게 전환 가능**
   - async let → Task로 전환은 간단
   - Task Group으로 바로 가는 것보다 점진적

---

### 8. 의사결정 플로우차트

```
작업이 고정된 개수인가?
├─ Yes → 다른 타입을 반환하는가?
│         ├─ Yes → async let 사용
│         └─ No → 취소 기능이 필요한가?
│                   ├─ Yes → Task 사용
│                   └─ No → async let 사용
│
└─ No (동적 개수) → Task Group 사용

특수 케이스:
- 가장 빠른 결과만 필요? → Task Group
- 완료 순서대로 처리? → Task Group
- Task를 전달해야 함? → Task
```

---

### 9. 핵심 요약

| 우선순위 | 도구           | 사용 빈도 | 주요 사용 사례                 |
| -------- | -------------- | --------- | ------------------------------ |
| 🥇 1순위  | **async let**  | 가장 높음 | 고정된 작업, 다른 타입, 간결함 |
| 🥈 2순위  | **Task**       | 중간      | 취소 필요, Task 전달 필요      |
| 🥉 3순위  | **Task Group** | 가장 낮음 | 동적 작업, 완료 순서 중요      |

**기본 원칙:**

1. async let으로 시작
2. 안 되면 Task 고려
3. 정말 필요할 때만 Task Group 사용

**실무 팁:**

- Task Group을 직접 사용하는 빈도는 낮음
- 하지만 Task Group 위에 다른 추상화를 만들어 사용하는 경우는 많음
- 예: 커스텀 병렬 처리 유틸리티, 배치 작업 처리기 등



## 커맨드라인 도구에서 async 사용하기

### 1. 개요

Swift로 커맨드라인 도구를 작성할 때 async 코드를 사용하는 방법은 두 가지입니다:

1. **main.swift 사용**: 즉시 async 함수를 만들고 사용 가능
2. **@main 속성 사용**: 앱을 즉시 async 컨텍스트로 실행

⚠️ **중요**: 프로그램이 종료되기 전에 작업이 완료될 때까지 기다려야 합니다. 그렇지 않으면 작업이 완료되지 않을 수 있습니다.

---

### 2. 방법 1: main.swift 사용

main.swift 파일을 사용하는 경우, await와 같은 비동기 코드를 바로 사용할 수 있습니다:

```swift
let url = URL(string: "https://hws.dev/users.csv")!

for try await line in url.lines {
    print("Received user: \(line)")
}
```

**특징:**

- 별도의 설정 없이 바로 async/await 사용 가능
- 파일명이 반드시 `main.swift`여야 함
- 가장 간단한 방법

---

### 3. 방법 2: @main 속성 사용

main.swift를 사용하지 않고 `@main` 속성을 선호하는 경우:

1. 일반적으로 사용하는 static `main()` 메서드를 만듦
2. `async`를 추가
3. 선택적으로 `throws`도 추가 (에러를 직접 처리하지 않을 경우)

```swift
@main
struct UserFetcher {
    static func main() async throws {
        let url = URL(string: "https://hws.dev/users.csv")!

        for try await line in url.lines {
            print("Received user: \(line)")
        }
    }
}
```

**동작 방식:**

- Swift가 자동으로 새 Task를 생성하여 `main()` 메서드를 실행
- Task가 완료되면 프로그램이 종료됨

**주의사항:**

- `@main` 속성을 사용할 때는 프로젝트에 `main.swift` 파일을 포함하지 않아야 함
- 동기 `main()` 메서드를 사용하는 것과 동일한 규칙 적용

---

### 4. 방법 비교

| 특징                | main.swift      | @main + async main() |
| ------------------- | --------------- | -------------------- |
| **파일명**          | main.swift 필수 | 자유롭게 지정 가능   |
| **구조**            | 스크립트 스타일 | 구조화된 타입        |
| **async 사용**      | 직접 사용       | static 메서드 내부   |
| **에러 처리**       | do-catch 필요   | throws 선언 가능     |
| **코드 구조화**     | 어려움          | 타입으로 구조화 가능 |
| **추가 속성/메서드** | 불가능          | 가능                 |

---

### 5. 실전 예제: 여러 URL에서 데이터 가져오기

#### main.swift 방식

```swift
// main.swift
let urls = [
    URL(string: "https://hws.dev/users.csv")!,
    URL(string: "https://hws.dev/posts.csv")!,
    URL(string: "https://hws.dev/comments.csv")!
]

await withTaskGroup(of: Void.self) { group in
    for url in urls {
        group.addTask {
            for try await line in url.lines {
                print("[\(url.lastPathComponent)] \(line)")
            }
        }
    }
}

print("All downloads completed!")
```

#### @main 방식

```swift
// DataFetcher.swift
@main
struct DataFetcher {
    static let urls = [
        URL(string: "https://hws.dev/users.csv")!,
        URL(string: "https://hws.dev/posts.csv")!,
        URL(string: "https://hws.dev/comments.csv")!
    ]

    static func main() async throws {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask {
                    try? await fetchData(from: url)
                }
            }
        }

        print("All downloads completed!")
    }

    static func fetchData(from url: URL) async throws {
        for try await line in url.lines {
            print("[\(url.lastPathComponent)] \(line)")
        }
    }
}
```

---

### 6. 선택 가이드

#### ✅ main.swift를 사용해야 할 때

- 간단한 스크립트 작성
- 빠른 프로토타이핑
- 최소한의 구조로 충분한 경우
- 단일 파일 프로젝트

#### ✅ @main을 사용해야 할 때

- 구조화된 커맨드라인 도구
- 여러 메서드와 속성이 필요한 경우
- 테스트 가능한 코드 작성
- 프로젝트가 커질 가능성이 있는 경우
- 다른 Swift 파일과 함께 사용하는 경우

---

### 7. 핵심 정리

**공통 규칙:**

- async 컨텍스트에서 모든 작업이 완료될 때까지 기다려야 함
- 프로그램이 일찍 종료되면 async 작업이 중단될 수 있음

**main.swift:**

- 파일명 고정
- 스크립트처럼 바로 코드 실행
- 간단한 도구에 적합

**@main:**

- 파일명 자유
- 타입 기반 구조화
- 복잡한 도구에 적합
- `main.swift` 파일이 있으면 안 됨



## Task-Local Values 생성과 사용

### 1. Task-Local Values란?

Swift는 **task-local values**를 사용하여 Task에 메타데이터를 첨부할 수 있습니다. 이는 Task 내부의 모든 코드가 읽을 수 있는 작은 정보 조각입니다.

예를 들어, `Task.isCancelled`를 읽어 현재 Task가 취소되었는지 확인할 수 있지만, 이것은 진짜 static 속성이 아닙니다 – 모든 Task 간에 공유되는 것이 아니라 **현재 Task에만 범위가 지정**됩니다. 이것이 task-local values의 힘입니다: Task 내부에 static과 같은 속성을 만들 수 있는 능력.

**⚠️ 중요**: 대부분의 사람들은 task-local values를 사용할 필요가 없습니다. 이 기능은 매우 특정한 소수의 상황에서만 유용하며, 복잡하다고 느껴진다면 크게 걱정하지 않아도 됩니다.

**개념:**

- Task-local values는 구식 멀티스레딩 환경의 **thread-local values**와 유사
- Task에 메타데이터를 첨부하고, Task 내부에서 실행되는 모든 코드가 필요에 따라 해당 데이터를 읽을 수 있음
- Swift의 구현은 데이터를 Task에 직접 주입하는 대신 **데이터를 사용할 수 있는 컨텍스트를 생성**하도록 신중하게 범위가 지정됨

---

### 2. Task-Local Values 사용 3단계

#### Step 1: Task-local values로 만들 속성을 가진 타입 생성

```swift
enum User {
    @TaskLocal static var id = "Anonymous"
}
```

- enum, struct, class, actor 모두 가능
- 하지만 **enum 권장** (인스턴스를 만들 의도가 없음을 명확히 함)

#### Step 2: `@TaskLocal` 매크로로 각 task-local value 표시

- 속성은 **모든 타입** 가능 (옵셔널 포함)
- 반드시 **static**으로 표시해야 함

#### Step 3: `withValue()`로 새 task-local scope 시작

```swift
YourType.$yourProperty.withValue(someValue) {
    // 이 scope 내에서 YourType.yourProperty는 someValue를 반환
}
```

**핵심 특징:**

- Task-local scope 내에서 `YourType.yourProperty`를 읽으면 **task-local value**를 받음
- 모든 프로그램에서 공유되는 단일 값을 가진 일반 static 속성이 아님
- **어떤 Task가 읽는지에 따라 다른 값을 반환**할 수 있음

---

### 3. 간단한 예제: Task마다 다른 사용자 ID

```swift
enum User {
    @TaskLocal static var id = "Anonymous"
}

@main
struct App {
    static func main() async throws {
        let first = Task {
            try await User.$id.withValue("Piper") {
                print("Start of task: \(User.id)")
                try await Task.sleep(for: .seconds(1))
                print("End of task: \(User.id)")
            }
        }

        let second = Task {
            try await User.$id.withValue("Alex") {
                print("Start of task: \(User.id)")
                try await Task.sleep(for: .seconds(1))
                print("End of task: \(User.id)")
            }
        }

        print("Outside of tasks: \(User.id)")
        try await first.value
        try await second.value
    }
}
```

**출력:**

```
Outside of tasks: Anonymous
Start of task: Piper
Start of task: Alex
End of task: Piper
End of task: Alex
```

**핵심 포인트:**

- 두 Task는 독립적으로 실행되므로 Piper와 Alex의 순서가 바뀔 수 있음
- 각 Task는 겹치는 시간에도 자신만의 `User.id` 값을 가짐
- Task 외부의 코드는 계속 원래 값(Anonymous)을 사용

---

### 4. Scoping과 Nesting

Swift는 설정한 task-local value를 잊어버리는 것을 불가능하게 만듭니다. **`withValue()` 내부의 작업에만 존재**하기 때문입니다.

**Scoping의 장점:**

1. **중첩(Nesting) 가능**: 필요에 따라 여러 task-local을 중첩할 수 있음
2. **Shadowing 가능**: 하나의 scope를 시작하고, 작업을 수행한 후, 같은 속성에 대해 중첩된 다른 scope를 시작하여 일시적으로 다른 값을 가질 수 있음

```swift
try await User.$id.withValue("Piper") {
    print(User.id)  // "Piper"

    try await User.$id.withValue("Alex") {
        print(User.id)  // "Alex" - 일시적으로 shadowing
    }

    print(User.id)  // "Piper" - 다시 원래 값으로
}
```

---

### 5. 실전 예제: Task별 로깅 레벨

Task-local values는 **Task 내에서 값을 반복적으로 전달해야 하는 경우**에 유용합니다 – Task 내에서 공유되어야 하지만 싱글톤처럼 전체 프로그램에서 공유되지 않아야 하는 값들입니다.

**실제 사용 사례:**

- 트레이싱(Tracing)
- 모킹(Mocking)
- 진행 상황 모니터링(Progress monitoring)

#### 로깅 시스템 구현

5가지 로그 레벨을 가진 Logger를 만들어봅시다: debug (가장 낮음) → info → warn → error → fatal (가장 높음)

**필요한 구성 요소:**

1. 5가지 로깅 레벨을 설명하는 enum
2. 싱글톤인 Logger struct
3. Logger 내부의 현재 로그 레벨을 저장하는 task-local 속성

```swift
// 5가지 로그 레벨, Comparable로 표시하여 < 및 > 사용 가능
enum LogLevel: Comparable {
    case debug, info, warn, error, fatal
}

struct Logger {
    // 개별 Task의 로그 레벨
    @TaskLocal static var logLevel = LogLevel.info

    // 싱글톤으로 만들기
    private init() { }
    static let shared = Logger()

    // 로그 레벨을 충족하거나 초과하는 경우에만 메시지 출력
    func write(_ message: String, level: LogLevel) {
        if level >= Logger.logLevel {
            print(message)
        }
    }
}

@main
struct App {
    // URL에서 데이터를 반환하고 로그 메시지 작성
    static func fetch(url urlString: String) async throws -> String? {
        Logger.shared.write("Preparing request: \(urlString)", level: .debug)

        if let url = URL(string: urlString) {
            let (data, _) = try await URLSession.shared.data(from: url)
            Logger.shared.write("Received \(data.count) bytes", level: .info)
            return String(decoding: data, as: UTF8.self)
        } else {
            Logger.shared.write("URL \(urlString) is invalid", level: .error)
            return nil
        }
    }

    // 다른 로그 레벨로 fire-and-forget task 시작
    static func main() async throws {
        let first = Task {
            try await Logger.$logLevel.withValue(.debug) {
                try await fetch(url: "https://hws.dev/news-1.json")
            }
        }

        let second = Task {
            try await Logger.$logLevel.withValue(.error) {
                try await fetch(url: "")
            }
        }

        _ = try await first.value
        _ = try await second.value
    }
}
```

**출력:**

```
Preparing request: https://hws.dev/news-1.json
URL  is invalid
Received 8075 bytes
```

**핵심 포인트:**

- `fetch()` 메서드는 task-local value가 사용되는지조차 알 필요가 없음
- 단순히 Logger 싱글톤을 호출하고, Logger가 task-local value를 참조
- 각 Task는 자신만의 로그 레벨을 가짐

---

### 6. Task-Local Values 사용 시 주의사항

#### ✅ 중요한 팁

1. **withValue() scope 외부에서 접근 가능**
   - withValue() scope 외부에서 task-local value에 접근해도 괜찮음
   - 단순히 지정한 기본값을 받게 됨

2. **상속 규칙**
   - 일반 Task는 부모 Task의 task-local values를 **상속**함
   - Detached Task는 부모가 없으므로 **상속하지 않음**

3. **읽기 전용**
   - Task-local values는 **읽기 전용**
   - 위에 표시된 대로 `withValue()`를 호출해야만 수정 가능

4. **과도한 사용 주의 ⚠️**
   - Swift Evolution 제안서 인용:
     > "please be careful with the use of task-locals and don't use them in places where plain-old parameter passing would have done the job."

   - **더 간단히 말하면**: task-local이 답이라면, 잘못된 질문을 하고 있을 가능성이 높습니다
   - **일반 매개변수 전달로 충분하다면 그것을 사용하세요**

---

### 7. 언제 Task-Local Values를 사용해야 할까?

#### ✅ 적합한 경우

1. **트레이싱/로깅**
   - 각 Task마다 다른 로그 레벨
   - 분산 트레이싱 ID

2. **테스트 환경**
   - 모킹 데이터
   - 테스트별 설정

3. **진행 상황 모니터링**
   - Task별 진행률 추적

4. **컨텍스트 정보**
   - 사용자 ID
   - 요청 ID
   - 세션 정보

#### ❌ 부적합한 경우 (대안 사용)

| 상황                         | Task-Local 대신 사용할 것 |
| ---------------------------- | ------------------------- |
| 함수 간 값 전달              | 일반 매개변수             |
| 전역 설정                    | 싱글톤 또는 전역 변수     |
| Task 간 공유 상태            | Actor 또는 @Sendable      |
| 단순한 값 전달               | 구조체 속성               |

---

### 8. Task-Local Values vs 다른 패턴 비교

| 특징          | Task-Local Values        | 매개변수 전달          | 싱글톤               | Thread-Local (구식) |
| ------------- | ------------------------ | ---------------------- | -------------------- | ------------------- |
| **범위**      | 현재 Task와 자식 Task    | 명시적 전달            | 전역                 | 현재 스레드         |
| **상속**      | 자식 Task에 자동 상속    | 수동 전달              | 모든 곳에서 동일     | 스레드별로 다름     |
| **수정**      | withValue()로만 가능     | 언제든지 가능          | 언제든지 가능        | 언제든지 가능       |
| **명시성**    | 암묵적 (scope 내)        | 명시적 (파라미터)      | 전역적으로 명시적    | 암묵적              |
| **타입 안정** | ✅ 컴파일 타임 체크       | ✅ 컴파일 타임 체크     | ✅ 컴파일 타임 체크   | ⚠️ 런타임 체크       |
| **사용 난이도** | 복잡                     | 간단                   | 간단                 | 복잡                |

---

### 9. 핵심 정리

**Task-Local Values란:**

- Task에 메타데이터를 첨부하는 방법
- Task 내부의 모든 코드가 읽을 수 있음
- 각 Task는 자신만의 값을 가질 수 있음

**사용 방법:**

1. `@TaskLocal` 매크로로 static 속성 선언
2. `withValue()` 로 scope 생성
3. Scope 내에서 속성 읽기

**주의사항:**

- 대부분의 경우 **일반 매개변수 전달**이 더 나음
- 매우 특정한 상황(트레이싱, 로깅, 모킹)에서만 유용
- 과도하게 사용하지 말 것

**기억할 것:**

- Detached Task는 task-local values를 상속하지 않음
- 읽기 전용 (withValue()로만 수정 가능)
- Task-local이 답이라면, 아마도 잘못된 질문을 하고 있을 것



## SwiftUI의 task() modifier로 Task 실행하기

### 1. task() modifier란?

SwiftUI는 **`task()` modifier**를 제공하여 뷰가 나타나는 즉시 새 Task를 시작하고, 뷰가 사라질 때 자동으로 Task를 취소합니다.

**동작 원리:**

- `onAppear()`에서 Task를 시작하고 `onDisappear()`에서 취소하는 것과 유사
- **추가 기능**: 식별자를 추적하여 식별자가 변경되면 Task를 자동으로 재시작

**⚠️ 중요**: 모든 SwiftUI 뷰는 자동으로 main actor에서 실행되므로, 뷰가 시작하는 Task도 다른 곳으로 이동할 때까지 자동으로 main actor에서 실행됩니다.

---

### 2. 기본 사용법: 뷰의 초기 데이터 로딩

가장 간단한 시나리오이자 가장 많이 사용할 방법은 `task()`를 사용하여 **뷰의 초기 데이터를 로드**하는 것입니다. 이 데이터는 로컬 스토리지에서 로드하거나 원격 URL에서 가져와 디코딩할 수 있습니다.

```swift
struct Message: Decodable, Identifiable {
    let id: Int
    let user: String
    let text: String
}

struct ContentView: View {
    @State private var messages = [Message]()

    var body: some View {
        NavigationStack {
            List(messages) { message in
                VStack(alignment: .leading) {
                    Text(message.user)
                        .font(.headline)

                    Text(message.text)
                }
            }
            .navigationTitle("Inbox")
            .task {
                await fetchData()
            }
        }
    }

    func fetchData() async {
        do {
            let url = URL(string: "https://hws.dev/inbox.json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            messages = try JSONDecoder().decode([Message].self, from: data)
        } catch {
            messages = [
                Message(id: 0, user: "Failed to load inbox.", text: "Please try again later.")
            ]
        }
    }
}
```

**핵심 포인트:**

- 뷰가 나타나면 `fetchData()` 자동 실행
- 뷰가 사라지면 Task 자동 취소
- SwiftUI 뷰의 데이터를 로드하기에 완벽한 위치

**⚠️ 중요**: `task()` modifier는 SwiftUI 뷰의 데이터를 로드하기에 좋은 장소입니다. SwiftUI 뷰는 앱 수명 동안 여러 번 재생성될 수 있으므로, 가능하면 이러한 작업을 이니셜라이저에 넣지 않아야 합니다.

---

### 3. 고급 사용법: 식별자로 Task 재시작

`task()`의 더 고급 사용법은 **Equatable 식별 값**을 첨부하는 것입니다. 이 값이 변경되면 SwiftUI는 자동으로 이전 Task를 취소하고 새 값으로 새 Task를 생성합니다.

**Task가 실행되는 시점:**

1. **뷰가 처음 나타날 때** - 초기 데이터 로딩
2. **식별자가 변경될 때** - 자동으로 이전 Task 취소 후 새 Task 시작
3. **뷰가 사라졌다가 다시 나타날 때** - Task가 다시 실행됨 (예: NavigationStack에서 뒤로 갔다가 다시 돌아오는 경우)

**사용 사례:**

- 공유 앱 상태 (예: 사용자 로그인 여부)
- 로컬 상태 (예: 데이터에 적용할 필터 종류)

#### 예제: Inbox와 Sent Box 전환

```swift
struct Message: Decodable, Identifiable {
    let id: Int
    let user: String
    let text: String
}

// 두 가지 메시지 박스를 처리할 수 있는 뷰
struct ContentView: View {
    @State private var messages = [Message]()
    @State private var selectedBox = "Inbox"
    let messageBoxes = ["Inbox", "Sent"]

    var body: some View {
        NavigationStack {
            List(messages) { message in
                VStack(alignment: .leading) {
                    Text(message.user)
                        .font(.headline)

                    Text(message.text)
                }
            }
            .navigationTitle(selectedBox)

            // selectedBox가 변경될 때마다 fetchData() task를 재생성
            .task(id: selectedBox) {
                await fetchData()
            }
            .toolbar {
                // 두 메시지 박스 간 전환
                Picker("Select a message box", selection: $selectedBox) {
                    ForEach(messageBoxes, id: \.self, content: Text.init)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // 이전과 거의 동일하지만 이제 항상 inbox를 로드하는 대신 selectedBox JSON 파일을 로드
    func fetchData() async {
        do {
            let url = URL(string: "https://hws.dev/\(selectedBox.lowercased()).json")!
            let (data, _) = try await URLSession.shared.data(from: url)
            messages = try JSONDecoder().decode([Message].self, from: data)
        } catch {
            messages = [
                Message(id: 0, user: "Failed to load message box.", text: "Please try again later.")
            ]
        }
    }
}
```

**동작 방식:**

1. `selectedBox`가 "Inbox"에서 "Sent"로 변경
2. SwiftUI가 현재 실행 중인 Task를 자동으로 취소
3. 새로운 `selectedBox` 값으로 새 Task 시작
4. 새 데이터를 자동으로 가져옴

**💡 팁**: 이 예제는 공유 URLSession을 사용하므로 응답을 캐시하고 두 inbox를 한 번만 로드합니다. 항상 파일을 가져오려면 자체 세션 구성을 만들고 캐싱을 비활성화하세요.

---

### 4. AsyncSequence와 함께 사용: 연속적인 값 스트리밍

`task()`의 특히 흥미로운 사용 사례는 **연속적으로 값을 생성하는 AsyncSequence 컬렉션**과 함께 사용하는 것입니다.

**사용 사례:**

- 새로운 콘텐츠를 보내는 동안 열린 연결을 유지하는 서버
- 파일 감시자(URLWatcher)
- 로컬 값 생성기

#### 예제: 랜덤 숫자 생성기 스트리밍

```swift
// 간단한 랜덤 숫자 생성기 시퀀스
struct NumberGenerator: AsyncSequence, AsyncIteratorProtocol {
    let range: ClosedRange<Int>
    let delay: Double = 1

    mutating func next() async -> Int? {
        // Task가 취소되면 숫자 생성 중지
        while Task.isCancelled == false {
            try? await Task.sleep(for: .seconds(delay))
            print("Generating number")
            return Int.random(in: range)
        }

        return nil
    }

    func makeAsyncIterator() -> NumberGenerator {
        self
    }
}

// DetailView를 요청할 때만 표시하기 위해 존재
struct ContentView: View {
    var body: some View {
        NavigationStack {
            NavigationLink("Start Generating Numbers") {
                DetailView()
            }
        }
    }
}

// 생성된 모든 랜덤 숫자를 생성하고 표시
struct DetailView: View {
    @State private var numbers = [String]()
    let generator = NumberGenerator(range: 1...1000)

    var body: some View {
        List(numbers, id: \.self, rowContent: Text.init)
            .task {
                await generateNumbers()
            }
    }

    func generateNumbers() async {
        for await number in generator {
            numbers.insert("\(numbers.count + 1). \(number)", at: 0)
        }
    }
}
```

**핵심 포인트:**

- `generateNumbers()` 메서드는 실제로 종료하는 방법이 없음
- `generator`가 값 반환을 중지하면 자동으로 종료됨
- Task가 취소되면 generator가 값 반환을 중지
- DetailView가 dismiss되면 Task가 취소됨
- **우리가 특별히 할 일이 없음** – 모두 자동!

**동작 흐름:**

1. DetailView가 나타남 → task 시작
2. 1초마다 랜덤 숫자 생성 및 표시
3. DetailView가 사라짐 → task 자동 취소
4. generator가 값 반환 중지
5. `generateNumbers()` 자동 종료

---

### 5. Task 우선순위 지정

`task()` modifier는 Task의 우선순위를 세밀하게 제어하고 싶을 때 **priority 파라미터**를 받습니다.

```swift
.task(priority: .low) {
    await loadBackgroundData()
}

.task(priority: .high) {
    await loadCriticalData()
}

.task(priority: .userInitiated) {
    await loadUserRequestedData()
}
```

**사용 가능한 우선순위:**

| 우선순위              | 사용 사례                                    |
| --------------------- | -------------------------------------------- |
| `.low`                | 백그라운드 데이터 로딩, 프리페칭             |
| `.medium` (기본값)    | 일반적인 데이터 로딩                         |
| `.high`               | 중요한 데이터, 사용자가 기다리는 작업        |
| `.userInitiated`      | 사용자가 명시적으로 요청한 작업              |
| `.utility`            | 진행률이 표시되는 장기 실행 작업             |
| `.background`         | 사용자가 인식하지 못하는 백그라운드 작업     |

---

### 6. task() vs onAppear/onDisappear 비교

| 특징                    | task()                            | onAppear + onDisappear      |
| ----------------------- | --------------------------------- | --------------------------- |
| **Task 시작**           | 자동                              | 수동 (Task { } 필요)        |
| **Task 취소**           | 자동                              | 수동 (cancel() 호출 필요)   |
| **식별자 기반 재시작**  | ✅ `task(id:)` 지원                | ❌ 수동 구현 필요            |
| **코드 간결성**         | 매우 간결                         | 상대적으로 장황             |
| **취소 처리**           | 자동 처리                         | 명시적 처리 필요            |
| **사용 난이도**         | 쉬움                              | 중간                        |

#### onAppear/onDisappear 방식 (권장하지 않음)

```swift
struct ContentView: View {
    @State private var task: Task<Void, Never>?

    var body: some View {
        Text("Hello")
            .onAppear {
                task = Task {
                    await loadData()
                }
            }
            .onDisappear {
                task?.cancel()
            }
    }
}
```

#### task() 방식 (권장)

```swift
struct ContentView: View {
    var body: some View {
        Text("Hello")
            .task {
                await loadData()
            }
    }
}
```

---

### 7. 실전 사용 패턴

#### 패턴 1: 초기 데이터 로딩

```swift
.task {
    await viewModel.loadInitialData()
}
```

#### 패턴 2: 식별자 기반 데이터 갱신

```swift
.task(id: userId) {
    await viewModel.loadUserData(id: userId)
}
```

#### 패턴 3: 실시간 데이터 스트리밍

```swift
.task {
    for await update in liveDataStream {
        handleUpdate(update)
    }
}
```

#### 패턴 4: 우선순위가 있는 데이터 로딩

```swift
.task(priority: .high) {
    await loadCriticalData()
}
.task(priority: .low) {
    await prefetchData()
}
```

#### 패턴 5: 여러 Task 조합

```swift
.task {
    async let profile = fetchProfile()
    async let posts = fetchPosts()
    async let followers = fetchFollowers()

    await (profile, posts, followers)
}
```

---

### 8. 주의사항 및 모범 사례

#### ✅ 모범 사례

1. **뷰의 이니셜라이저가 아닌 task()에서 데이터 로드**
   - SwiftUI 뷰는 여러 번 재생성될 수 있음
   - task()는 뷰가 실제로 나타날 때만 실행됨

2. **식별자 사용으로 자동 갱신**
   - 수동으로 Task를 취소하고 재시작하는 대신 `task(id:)` 사용

3. **AsyncSequence와 함께 사용**
   - 자동 취소로 리소스 누수 방지

4. **적절한 우선순위 설정**
   - 사용자 경험을 개선하기 위해 중요한 작업에는 높은 우선순위 설정

#### ⚠️ 주의사항

1. **Main Actor에서 실행됨**
   - 모든 SwiftUI 뷰는 자동으로 main actor에서 실행됨
   - 뷰가 시작하는 Task도 다른 곳으로 이동할 때까지 자동으로 main actor에서 실행됨

2. **뷰 재생성 시 Task 재시작**
   - 뷰가 재생성되면 task()도 다시 실행될 수 있음
   - 필요한 경우 식별자를 사용하여 불필요한 재시작 방지

3. **여러 task() 사용 시 순서 보장 없음**
   - 여러 개의 task() modifier는 독립적으로 실행됨

---

### 9. 핵심 정리

**task() modifier란:**

- SwiftUI 뷰에서 async 작업을 실행하는 가장 좋은 방법
- 자동 시작/취소로 리소스 관리 간소화
- 식별자 기반 재시작으로 반응형 UI 구현

**기본 사용법:**

```swift
.task {
    await loadData()
}
```

**식별자와 함께:**

```swift
.task(id: selectedFilter) {
    await loadFilteredData()
}
```

**우선순위와 함께:**

```swift
.task(priority: .high) {
    await loadCriticalData()
}
```

**언제 사용할까:**

- 뷰의 초기 데이터 로딩 (가장 일반적)
- 식별자가 변경될 때 데이터 갱신
- AsyncSequence에서 값 스트리밍
- 우선순위가 필요한 비동기 작업

**왜 task()를 사용해야 할까:**

- ✅ 자동 취소로 메모리 누수 방지
- ✅ 코드 간결성
- ✅ SwiftUI 생명주기와 완벽한 통합
- ✅ 식별자 기반 자동 갱신



## 많은 Task를 생성하는 것이 효율적인가?

### 1. Thread Explosion vs Task

이전에 **thread explosion(스레드 폭발)** 개념에 대해 이야기했습니다. 이는 CPU 코어보다 훨씬 많은 스레드를 생성할 때 시스템이 이를 효과적으로 관리하는 데 어려움을 겪는 현상입니다.

**하지만 Swift의 Task는 스레드와 매우 다르게 구현됩니다:**

- Task는 스레드보다 훨씬 가벼움
- 많은 수로 사용해도 성능 문제를 일으킬 가능성이 현저히 낮음
- Swift 팀 개발자에 따르면: **10,000개 이상의 Task를 생성하지 않는 한 영향을 걱정할 필요가 없음**

---

### 2. Task Group에서의 Task 생성

많은 Task를 생성하는 것이 반드시 최선의 아이디어는 아닐 수 있지만, 어렵지 않게 많은 Task를 생성할 수 있습니다.

**예시:**

```swift
await withTaskGroup(of: Int.self) { group in
    // 배열의 크기에 따라 수백~수천 개의 Task가 생성될 수 있음
    for item in hugeArray {  // 배열에 5000개 요소가 있다면?
        group.addTask {
            await process(item)
        }
    }
}
```

- Task Group에서 루프 내부에 `addTask()`를 호출하면 수백 또는 수천 개의 Task가 생성될 수 있음
- **이것도 괜찮습니다!**

---

### 3. 10,000개 이상의 Task도 괜찮다

10,000개 이상의 Task를 생성해도 다음 조건이 충족되면 문제가 될 가능성이 낮습니다:

1. **의도적으로 그렇게 하고 있다는 것을 알고 있을 때**
2. **대안을 평가한 후 내린 아키텍처 결정일 때**

**핵심 포인트:**

- 무작정 많은 Task를 생성하는 것을 두려워할 필요 없음
- Swift의 Task 시스템은 이를 효율적으로 처리하도록 설계됨

---

### 4. 성능 체크가 필요한 경우

**⚠️ 다음 경우에는 성능을 확인해야 합니다:**

- **거대한 배열의 요소를 변환하기 위해 Task를 생성할 때**
- 예: 100,000개 요소가 있는 배열을 처리

```swift
// 성능 체크가 필요한 예시
let results = await withTaskGroup(of: ProcessedData.self) { group in
    for item in massiveArray {  // 100,000개 요소
        group.addTask {
            return processItem(item)
        }
    }

    var collected = [ProcessedData]()
    for await result in group {
        collected.append(result)
    }
    return collected
}
```

**권장사항:**

- **Instruments를 사용하여 성능 측정**
- CPU 사용률, 메모리 사용량, 실행 시간 확인
- 필요시 배치 처리(batching) 고려

---

### 5. 대안: 배치 처리(Batching)

거대한 배열을 처리할 때 모든 요소에 대해 개별 Task를 생성하는 대신, **배치로 묶어서 처리**할 수 있습니다.

#### 개별 Task 생성 (10,000개 Task)

```swift
await withTaskGroup(of: Int.self) { group in
    for item in hugeArray {  // 10,000개
        group.addTask {
            await process(item)
        }
    }
}
```

#### 배치 처리 (100개 Task)

```swift
await withTaskGroup(of: [Int].self) { group in
    let batchSize = 100
    let batches = stride(from: 0, to: hugeArray.count, by: batchSize).map {
        Array(hugeArray[$0..<min($0 + batchSize, hugeArray.count)])
    }

    for batch in batches {  // 100개 배치 = 100개 Task
        group.addTask {
            var results = [Int]()
            for item in batch {
                results.append(await process(item))
            }
            return results
        }
    }

    var allResults = [Int]()
    for await batchResults in group {
        allResults.append(contentsOf: batchResults)
    }
    return allResults
}
```

**배치 처리의 장점:**

- Task 생성 오버헤드 감소
- 메모리 사용량 예측 가능
- 더 나은 성능 특성 (특정 상황에서)

---

### 6. 성능 최적화 가이드

| 배열 크기           | 권장 접근 방식                     | 이유                                    |
| ------------------- | ---------------------------------- | --------------------------------------- |
| < 100개             | 개별 Task 생성                     | 오버헤드 무시 가능                      |
| 100 ~ 1,000개       | 개별 Task 생성 (일반적으로 괜찮음) | Swift Task 시스템이 효율적으로 처리     |
| 1,000 ~ 10,000개    | 개별 Task 또는 배치 처리           | 상황에 따라 선택, 필요시 성능 측정      |
| 10,000개 이상       | 배치 처리 고려                     | Instruments로 성능 측정 후 결정         |

---

### 7. Instruments로 성능 측정하기

**측정해야 할 지표:**

1. **CPU 사용률**
   - Task가 CPU를 효율적으로 사용하는지 확인

2. **메모리 사용량**
   - Task 생성으로 인한 메모리 증가 확인

3. **실행 시간**
   - 개별 Task vs 배치 처리의 실제 성능 차이

4. **Task 생성/파괴 오버헤드**
   - Task Lifecycle 추적

**Instruments 사용 팁:**

```bash
# Time Profiler로 CPU 사용 분석
# Allocations로 메모리 사용 분석
# System Trace로 Task 스케줄링 확인
```

---

### 8. 실전 예제: 이미지 배치 처리

#### 문제 상황: 10,000개의 이미지 리사이징

```swift
// ❌ 비효율적일 수 있음: 10,000개의 Task 생성
await withTaskGroup(of: UIImage.self) { group in
    for url in imageURLs {  // 10,000개
        group.addTask {
            return await resizeImage(from: url)
        }
    }
}
```

#### 해결: 배치 처리

```swift
// ✅ 효율적: 100개의 Task로 배치 처리
await withTaskGroup(of: [UIImage].self) { group in
    let batchSize = 100

    for batch in imageURLs.chunked(into: batchSize) {
        group.addTask {
            var images = [UIImage]()
            for url in batch {
                images.append(await resizeImage(from: url))
            }
            return images
        }
    }

    var allImages = [UIImage]()
    for await batchImages in group {
        allImages.append(contentsOf: batchImages)
    }
    return allImages
}

// 배열을 청크로 나누는 헬퍼 extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
```

---

### 9. 핵심 정리

**Task 생성에 대한 염려:**

- ❌ 스레드처럼 걱정할 필요 없음
- ✅ Swift의 Task는 가볍고 효율적
- ✅ 10,000개 이하는 일반적으로 문제없음

**언제 성능을 체크해야 할까:**

- 거대한 배열(10,000개 이상)을 처리할 때
- 각 Task가 매우 가벼운 작업을 수행할 때
- 메모리나 성능 이슈가 의심될 때

**모범 사례:**

1. **기본적으로 자유롭게 Task 생성**
   - 대부분의 경우 문제없음

2. **필요시 Instruments로 측정**
   - 실제 데이터로 성능 확인

3. **배치 처리 고려**
   - 매우 큰 데이터셋의 경우

4. **의도적인 아키텍처 결정**
   - 왜 많은 Task를 생성하는지 이해하고 있어야 함

**기억할 것:**

> "Unless you're creating over 10,000 tasks, it's not worth worrying about the impact of so many tasks."
>
> – Swift 팀 개발자

→ 10,000개 이상의 Task를 생성하지 않는 한, 많은 Task의 영향을 걱정할 가치가 없습니다.
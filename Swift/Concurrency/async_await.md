# async/await

## async

1. 비동기 함수가 await 되면 해당 함수를 호출한 모든 함수도 await 된다. 따라서 동기 함수는 비동기 함수를 직접적으로 호출할 수 없다
2. 함수는 필요한 만큼 여러번 일시 중단 될 수 있지만, 사용자가 직접 작성하지 않으면 일시 중단되지 않는다. await 함수는 예상치 못한 상황에서 스스로 일시 중단되지 않는다.(???)
3. await 함수는 실행중인 스레드를 차단하지않고, 해당 스레드를 포기하여 Swift가 다른 작업을 수행할 수 있도록 한다
4. 함수가 재개될 때 이전과 같은 스레드에서 실행될 수도 있지만, 아닐 수도있다.

``` swift
func fetchNews() async -> Data? {
    do {
        let url = URL(string: "https://hws.dev/news-1.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    } catch {
        print("Failed to fetch data")
        return nil
    }
}

// <!-- INSIDE MAIN -->
if let data = await fetchNews() {
    print("Downloaded \(data.count) bytes")
} else {
    print("Download failed.")
}
```

``` swift
func fetchWeatherHistory() async -> [Double] {
    (1...100_000).map { _ in Double.random(in: -10...30) }
}

func calculateAverageTemperature(for records: [Double]) async -> Double {
    let total = records.reduce(0, +)
    let average = total / Double(records.count)
    return average
}

func upload(result: Double) async -> String {
    "OK"
}

func processWeather() async {
    let records = await fetchWeatherHistory()
    let average = await calculateAverageTemperature(for: records)
    let response = await upload(result: average)
    print("Server response: \(response)")
}

// <!-- INSIDE MAIN -->
await processWeather()
```

``` swift
func processWeather() async {
    let records = await fetchWeatherHistory()
    // anything could happen here
    let average = await calculateAverageTemperature(for: records)
    // or here
    let response = await upload(result: average)
    // or here
    print("Server response: \(response)")
}
```

## async throws

``` swift
func fetchFavorites() async throws -> [Int] {
    let url = URL(string: "https://hws.dev/user-favorites.json")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([Int].self, from: data)
}

// <!-- INSIDE MAIN -->
if let favorites = try? await fetchFavorites() {
    print("Fetched \(favorites.count) favorites.")
} else {
    print("Failed to fetch favorites.")
}
```

``` swift
func processWeather() async {
    // Do async work here
}

@main
struct MainApp {
    static func main() async {
        await processWeather()
    }
}
```



SwiftUI의 `@State` 프로퍼티 래퍼는 모든 스레드에서 값을 수정할 수 있다.

``` swift
struct ContentView: View {
    @State private var sourceCode = ""

    var body: some View {
        ScrollView {
            Text(sourceCode)
        }
        .task {
            await fetchSource()
        }
    }

    func fetchSource() async {
        do {
            let url = URL(string: "https://apple.com")!

            let (data, _) = try await URLSession.shared.data(from: url)
            sourceCode = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            sourceCode = "Failed to fetch apple.com"
        }
    }
}
```

``` swift
struct ContentView: View {
    @State private var site = "https://"
    @State private var sourceCode = ""

    var body: some View {
        VStack {
            HStack {
                TextField("Website address", text: $site)
                    .textFieldStyle(.roundedBorder)
                Button("Go") {
                    Task {
                        await fetchSource()
                    }
                }
            }
            .padding()

            ScrollView {
                Text(sourceCode)
            }
        }
    }

    func fetchSource() async {
        do {
            let url = URL(string: site)!
            let (data, _) = try await URLSession.shared.data(from: url)
            sourceCode = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            sourceCode = "Failed to fetch \(site)"
        }
    }
}
```

## 비동기 함수가 성능에 미치는 영향

- 비동기 함수를 호출 할 때마다 await 코드에서 잠재적 중단 지점을 표시
- 작업이 완료되는 동안 모든 호출자와 함께 함수가 중단될 가능성을 표시
- 아래 코드를 사용하면 서스펜션 체인이 작동하는 모습을 볼 수 있다.
  - ✅ 서스펜션 체인: 어느 작업이 멈췄는지, 무엇을 기다리는지, 어느 작업이 그 작업을 다시 깨우는지에 대한 관계
- Swift가 컴파일 시점에 await호출이 함수가 중단될지 알 수 없다. 런타임에 실제 무슨일이 발생하든 상관없이 동일한 (약간) 더 비싼 호출 규칙이 사용된다.
  - 일시 중단이 발생하면 Swift는 해당 함수와 그 호출자를 일시 중지 하는데, 이로 인해 약간의 성능 저하가 발생한다.
  - 중단이 발생하지 않으면 일시 중지가 발생하지 않고 함수는 동기 함수와 동일한 효율성과 타이밍으로 계속 실행 된다.

``` swift
// 실제로는 중단이 발생하지 않기 때문에 한번의 런루프가 지나갈 때까지 기다리지 않고 실행
func countFavorites() async throws {
    let favorites = try await decodeFavorites()
    print("Downloaded \(favorites.count) favorites.")
}

func decodeFavorites() async throws -> [Int] {
    let data = try await loadFavorites()
    return try JSONDecoder().decode([Int].self, from: data)
}

func loadFavorites() async throws -> Data {
    let url = URL(string: "https://hws.dev/user-favorites.json")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}
```

## 비동기 Get

``` swift
// 비동기, 에러 throw -> get에만 사용 가능
public var value: Success { get async throws }
```

``` swift
// First, a URLSession instance that never uses caches
extension URLSession {
    static let noCacheSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: config)
    }()
}

// Now our struct that will fetch and decode a URL every
// time we read its `contents` property
struct RemoteFile<T: Decodable> {
    let url: URL
    let type: T.Type

    var contents: T {
        get async throws {
            let (data, _) = try await URLSession.noCacheSession.data(from: url)
            return try JSONDecoder().decode(T.self, from: data)
        }
    }
}
```

``` swift
struct Message: Decodable, Identifiable {
    let id: Int
    var user: String
    var text: String
}

struct ContentView: View {
    let source = RemoteFile(url: URL(string: "https://hws.dev/inbox.json")!, type: [Message].self)
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
            .toolbar {
                Button("Refresh", systemImage: "arrow.clockwise", action: refresh)
            }
            .onAppear(perform: refresh)
        }
    }

    func refresh() {
        Task {
            do {
                // Access the property asynchronously
                messages = try await source.contents
            } catch {
                print("Message update failed.")
            }
        }
    }
}
```

## async let 을 사용하여 비동기 함수 호출

``` swift
struct User: Decodable, Identifiable {
    let id: UUID
    let name: String
    let age: Int
}

struct Message: Decodable, Identifiable {
    let id: Int
    let from: String
    let message: String
}

func loadData() async {
    async let (userData, _) = URLSession.shared.data(from: URL(string: "https://hws.dev/user-24601.json")!)

    async let (messageData, _) = URLSession.shared.data(from: URL(string: "https://hws.dev/user-messages.json")!)

    do {
        let decoder = JSONDecoder()
        let user = try await decoder.decode(User.self, from: userData)
        let messages = try await decoder.decode([Message].self, from: messageData)
        print("User \(user.name) has \(messages.count) message(s).")
    } catch {
        print("Sorry, there was a network problem.")
    }
}

// <!-- INSIDE MAIN -->
await loadData()
```

## await과 async let의 차이점

- 둘 다 비동기 코드를 실행하지만 실행 방식이 완전히 같지는 않음
- await: 작업이 완료 되어야 결과를 읽을 수 있을 때까지 기다림
- async let: 수행하려는 작업에 따라 달라짐

### await을 사용하는 경우

연관된 작업에서 await을 사용하는것이 좋다

``` swift
func fetchData() async -> Data? {
    // do work here
    nil
}

func process(_ data: Data?) async -> Bool {
    true
}

let download = await fetchData()
// download 실행 결과를 process에 사용
let result = await process(download)
```

### async let

연관되지 않은 여러 요청

``` swift
func getNews() async -> [String] { [] }
func getWeather() async -> [String] { [] }
func getUpdateAvailable() async -> Bool { true }

// 서로 상관없이 작업 후 최종 결과만 같이 나오면 된다.
func getAppData() async -> ([String], [String], Bool) {
    async let news = getNews()
    async let weather = getWeather()
    async let hasUpdate = getUpdateAvailable()
    return await (news, weather, hasUpdate)
}
```

## Continuation

### withCheckedContinuation

- resume은 반드시 한번만 호출 되어야 함.
  - 여러번 호출하면 크래시
- 오류 발생 불가

``` swift
struct Message: Decodable, Identifiable {
    let id: Int
    let from: String
    let message: String
}

// 기존 클로져 사용
func fetchMessages(completion: @Sendable @escaping ([Message]) -> Void) {
    let url = URL(string: "https://hws.dev/user-messages.json")!

    URLSession.shared.dataTask(with: url) { data, response, error in
        if let data {
            if let messages = try? JSONDecoder().decode([Message].self, from: data) {
                completion(messages)
                return
            }
        }

        completion([])
    }.resume()
}

// Continuation으로 리팩터링
func fetchMessages() async -> [Message] {
    await withCheckedContinuation { continuation in
        fetchMessages { messages in
            continuation.resume(returning: messages)
        }
    }
}

// <!-- INSIDE MAIN -->
let messages = await fetchMessages()
print("Downloaded \(messages.count) messages.")
```

### withCheckedThrowingContinuation

- resume은 반드시 한번만 호출 되어야 함.
  - 여러번 호출하면 크래시
- 오류 발생 가능

``` swift
struct Message: Decodable, Identifiable {
    let id: Int
    let from: String
    let message: String
}

// 기존 클로져를 사용한 함수
func fetchMessages(completion: @Sendable @escaping ([Message]) -> Void) {
    let url = URL(string: "https://hws.dev/user-messages.json")!

    URLSession.shared.dataTask(with: url) { data, response, error in
        if let data = data {
            if let messages = try? JSONDecoder().decode([Message].self, from: data) {
                completion(messages)
                return
            }
        }

        completion([])
    }.resume()
}

// An example error we can throw
enum FetchError: Error {
    case noMessages
}

// withCheckedThrowingContinuation 내부에서 오류 발생, catch해서 처리
func fetchMessages() async -> [Message] {
    do {
        return try await withCheckedThrowingContinuation { continuation in
            fetchMessages { messages in
                if messages.isEmpty {
                    continuation.resume(throwing: FetchError.noMessages)
                } else {
                    continuation.resume(returning: messages)
                }
            }
        }
    } catch {
        return [
            Message(id: 1, from: "Tom", message: "Welcome to MySpace! I'm your new friend.")
        ]
    }
}

// <!-- INSIDE MAIN -->
let messages = await fetchMessages()
print("Downloaded \(messages.count) messages.")
```

## 나중에 다시 시작할 Continuation 작업 저장

``` swift
@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
   // 추후 사용될 Continuation
    var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, any Error>?
    let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
    }

    @MainActor
    func requestLocation() async throws -> CLLocationCoordinate2D? {
        try await withCheckedThrowingContinuation { continuation in
						// Continuation 저장
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
      	// Continuation 실행
        locationContinuation?.resume(returning: locations.first?.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
      	// Continuation 실행
        locationContinuation?.resume(throwing: error)
    }
}

struct ContentView: View {
    @State private var locationManager = LocationManager()

    var body: some View {
        LocationButton {
            Task {
                if let location = try? await locationManager.requestLocation() {
                    print("Location: \(location)")
                } else {
                    print("Location unknown.")
                }
            }
        }
        .frame(height: 44)
        .foregroundStyle(.white)
        .clipShape(.capsule)
        .padding()
    }
}
```


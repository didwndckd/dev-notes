# Publisher

`Publisher`는 하나 이상의 `Subscriber` 인스턴스에 값을 전달 할 수 있는 프로토콜이다.

``` swift
public protocol Publisher<Output, Failure> {
    associatedtype Output
    associatedtype Failure : Error

    func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input
}
```

- `Output` : `Subscriber`에게 전달될 데이터 타입
- `Failure` : `Subscriber`에게 전달될 실패 타입, `Error`를 채택하고 있어야 함
- `receive(subscriber:)` : `Subscriber`를 전달받아 구독을 수락하는 함수
  - `Publisher` 를 구독하게되면 `receive(subscriber:)` 함수가 호출되고 내부에서 `Subscriber`와의 연결이 시작됨



## Publisher를 채택하는 타입

> `Publisher` 프로토콜을 채택하는 만들어져있는 타입

### Just

- `Just`는 구독이 시작되면 저장된 값을 방출하는 단순한 퍼블리셔이다
- 에러 타입은 항상  `Never`타입이다

``` swift
Just(1)
    .sink(
        receiveCompletion: { completion in
        print("completion: \(completion)")
    }, receiveValue: { value in
        print("value: \(value)")
    })
    .store(in: &cancelStore)

// 1
// completion: finished
```



### Future

- `Future`는 어떠한 작업을 수행한 다음 값을 비동기적으로 방출할 때 사용
- 생성자에서 `(Future.Promise) -> Void` 클로져 타입을 받음
  - `Future.Promise`: `(Result<Output, Failure>) -> Void`
- 전달한 클로져 내부에서 `Future.Promise` 클로져를 호출하면 값을 방출함

``` swift
Future<Int, Never>() { promiss in
    promiss(.success(1))
}
.sink(
    receiveCompletion: { completion in
        print("completion: \(completion)")
    }, receiveValue: { value in
        print("value: \(value)")
    })
.store(in: &cancelStore)

// value: 1
// completion: finished
```



## 커스텀 Publisher 구현 - CollectionJust

- 배열을 받아 1초 간격으로 값을 하나씩 방출하는 커스텀 `Publisher`
- `receive(subscriber:)`에서 `Subscription`을 생성해 `Subscriber`에게 전달하고, `Subscription`이 `Subscriber`의 `demand`에 맞춰 값을 방출함

``` swift
import Foundation
import Combine

struct CollectionJust<Output, Failure: Error>: Publisher {
    
    private let datas: [Output]
    
    init(datas: [Output]) {
        self.datas = datas
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        Swift.print(type(of: self), #function, "subscriber:", type(of: subscriber))
        let subscription = InnerSubscription(subscriber: subscriber, datas: self.datas)
        subscriber.receive(subscription: subscription)
    }
}

extension CollectionJust {
    final class InnerSubscription<S: Subscriber>: Combine.Subscription where Output == S.Input, Failure == S.Failure {
        private let subscriber: S
        private var datas: [Output]
        private var demand: Subscribers.Demand = .unlimited
        
        init(subscriber: S, datas: [Output]) {
            self.subscriber = subscriber
            self.datas = datas
        }
        
        deinit {
            Swift.print("deinit -> \(type(of: self))")
        }
        
        func request(_ demand: Subscribers.Demand) {
            Swift.print(type(of: self), #function, "demand:", demand)
            
            self.demand = demand
            
            self.excuteData()
        }
        
        func cancel() {
            Swift.print(type(of: self), #function)
            self.datas = []
        }
        
        private func excuteData() {
            Swift.print(type(of: self), #function, "datas: \(self.datas)")
            
            guard !self.datas.isEmpty, self.demand > .none else {
                self.subscriber.receive(completion: .finished)
                return
            }
            
            let data = self.datas.removeFirst()
            self.demand += self.subscriber.receive(data)
            self.demand -= 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                self.excuteData()
            })
        }
    }
}
```

- 사용 예시

``` swift
let publisher = CollectionJust<String, Never>(datas: ["A", "B", "C"])
    .eraseToAnyPublisher()

let cancellable = publisher
    .sink(
        receiveCompletion: { completion in
            print("receiveCompletion: \(completion)")
        },
        receiveValue: { value in
            print("receiveValue: \(value)")
        })

// receiveValue: A   (1초 간격)
// receiveValue: B
// receiveValue: C
// receiveCompletion: finished
```



## 커스텀 Subscriber 구현 - CustomSubscriber

- 구독, 값 수신, 완료 시점의 동작을 클로저로 주입받아 처리하는 커스텀 `Subscriber`
- `receive(subscription:)`에서 구독을 받고, `receive(_:)`에서 값을 받아 다음 `Demand`를 반환하며, `receive(completion:)`에서 종료를 처리함

``` swift
import Foundation
import Combine

final class CustomSubscriber<Input, Failure: Error>: Subscriber {
    
    private var receiveSubscription: ((Subscription) -> Void)?
    private var receiveInput: ((Input) -> Subscribers.Demand)?
    private var receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)?
    
    init(receiveSubscription: ((Subscription) -> Void)?,
         receiveInput: ((Input) -> Subscribers.Demand)?,
         receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)?) {
        self.receiveSubscription = receiveSubscription
        self.receiveInput = receiveInput
        self.receiveCompletion = receiveCompletion
    }
    
    deinit {
        print("deinit -> \(type(of: self))")
    }
    
    func receive(subscription: Subscription) {
        print(self, #function, "subscription: \(subscription)")
        self.receiveSubscription?(subscription)
    }
    
    func receive(_ input: Input) -> Subscribers.Demand {
        print(self, #function, "input: \(input)")
        return self.receiveInput?(input) ?? .none
    }
    
    func receive(completion: Subscribers.Completion<Failure>) {
        print(self, #function, "completion: \(completion)")
        self.receiveCompletion?(completion)
    }
}
```

- 사용 예시
  - `receiveSubscription`에서 원하는 `Demand`를 `request`로 요청해 backpressure를 직접 제어할 수 있음 (`.unlimited` 또는 `.max(n)`)

``` swift
let subscriber = CustomSubscriber<String, Never>(
    receiveSubscription: { subscription in
        // .max(n)으로 받을 개수를 제한하거나 .unlimited로 전부 받음
        subscription.request(.unlimited)
    },
    receiveInput: { input in
        print("receiveInput: \(input)")
        return .none
    },
    receiveCompletion: { completion in
        print("receiveCompletion: \(completion)")
    })

let publisher = CollectionJust<String, Never>(datas: ["A", "B", "C"])
publisher.subscribe(subscriber)
```


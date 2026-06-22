# AsyncStream

- `AsyncSequence`를 채택함

## 기본 사용

``` swift
let stream = AsyncStream { continuation in
    for i in 1...9 {
        continuation.yield(i)
    }

    continuation.finish()
}

// <!-- INSIDE MAIN -->
for await item in stream {
    print(item)
}
```

## init

``` swift
init(
    _ elementType: Element.Type = Element.self, // 방출할 타입
    bufferingPolicy limit: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded,
    _ build: (AsyncStream<Element>.Continuation) -> Void // 
)
```

- **build: `(AsyncStream<Element>.Continuation) -> Void`**: 값 생성 클로져

  - **[AsyncStream.Condinuation](https://developer.apple.com/documentation/swift/asyncstream/continuation)**

    - yeild(값을 방출): 주어진 요소를 가지고 중단 지점에서 정상적으로 복귀하여 다음 반복 지점을 기다리는 작업을 재개합니다.
      - 한번 꺼내쓰고 나면 새로운 값을 방출 해야 외부에서 값을 받을 수 있음
    - finish: 스트림 종료
      - 스트림 종료 이후 해당 AsyncStream을 사용해도 값을 받을 수 없음

  - 생성 즉시 호출된다

  - ``` swift
    let stream = AsyncStream { continuation in
        print("Start in continuation")
        for i in 1...9 {
            print("yeild: \(i)")
            continuation.yield(i)
        }
    
        continuation.finish()
    }
    
    print("Start")
    
    /*
    Start in continuation
    yeild: 1
    yeild: 2
    yeild: 3
    yeild: 4
    yeild: 5
    yeild: 6
    yeild: 7
    yeild: 8
    yeild: 9
    Start
    */
    ```

- **bufferingPolicy limit: `AsyncStream<Element>.Continuation.BufferingPolicy`**: 버퍼링 동작 설정

  - [`case unbounded`](https://developer.apple.com/documentation/swift/asyncstream/continuation/bufferingpolicy/unbounded)

    - 버퍼 제한 없음

  - [`case bufferingOldest(Int)`](https://developer.apple.com/documentation/swift/asyncstream/continuation/bufferingpolicy/bufferingoldest(_:))

    - 버퍼가 가득 차면 새로운 요소를 버린다. 오래된 값만 남겨둠

      ``` swift
      let stream = AsyncStream(bufferingPolicy: .bufferingOldest(5)) { continuation in
          for i in 1...9 {
              continuation.yield(i)
          }
      
          continuation.finish()
      }
      
      for await item in stream {
          print(item)
      }
      
      /*
      1
      2
      3
      4
      5
      */
      ```

      

  - [`case bufferingNewest(Int)`](https://developer.apple.com/documentation/swift/asyncstream/continuation/bufferingpolicy/bufferingnewest(_:))

    - 버퍼가 가득 차면 가장 오래된 요소를 버린다.

      ``` swift
      let stream = AsyncStream(bufferingPolicy: .bufferingNewest(5)) { continuation in
          for i in 1...9 {
              continuation.yield(i)
          }
      
          continuation.finish()
      }
      
      for await item in stream {
          print(item)
      }
      
      /*
      5
      6
      7
      8
      9
      */
      ```

  - 버퍼가 0인 경우

    - 값을 바로 읽지 않는다면 사라져서 외부에서 값을 읽을 수 없음

      ``` swift
      let stream = AsyncStream(bufferingPolicy: .bufferingOldest(0)) { continuation in
          continuation.yield("Hello, AsyncStream!")
          continuation.finish()
      }
      
      print("start")
      for await item in stream {
          print(item)
      }
      print("finished")
      
      
      /* 값을 받지 못함
      start
      finished
      */
      
      let delayStream = AsyncStream(bufferingPolicy: .bufferingOldest(0)) { continuation in
          Task { // 0.1초의 딜레이
              try await Task.sleep(for: .seconds(0.1))
              continuation.yield("Hello, AsyncStream!")
              continuation.finish()
          }
      }
      
      print("start with delay")
      for await item in delayStream {
          print(item)
      }
      
      print("finished with delay")
      
      /* 값을 읽을 수 있음
      start with delay
      Hello, AsyncStream!
      finished with delay
      */
      ```

## AsyncThrowingStream

- 에러 throw 가능한 스트림

``` swift
enum MultipleError: Error {
    case no3
}

let stream = AsyncThrowingStream { continuation in
    for i in 1...40 {
        continuation.yield(i)

        if i.isMultiple(of: 3) {
            // 3의 배수: 에러와 함께 스트림 종료
            continuation.finish(throwing: MultipleError.no3)
        }
    }

    continuation.finish()
}

do {
    for try await values in stream {
        print(values)
    }
} catch {
    print("Error received: \(error)")
}

/*
continuation start: 1
continuation start: 2
continuation start: 3
❌ continuation error: 3
continuation start: 4
continuation start: 5
continuation start: 6
❌ continuation error: 6
continuation start: 7
continuation start: 8..... 40까지

continuation finish

Value received: 1
Value received: 2
Value received: 3

Error received: no3
*/
```



### 동시 접근

``` swift
let stream = AsyncStream { continuation in
    for i in 1...9 {
        continuation.yield(i)
    }

    continuation.finish()
}

Task {
    print("Start1")
    for await item in stream {
        print("1.:", item)
    }

    print("finished")
}

Task {
    print("Start2")
    for await item in stream {
        print("2.:", item)
    }

    print("finished2")
}

/*
서로 다른 Task에서 접근하기 때문에 순서는 보장하지 않음
Start1
Start2
1: 1
2: 2
1: 3
2: 4
1: 5
2: 6
1: 7
2: 8
1: 9
finished2
finished
*/
```




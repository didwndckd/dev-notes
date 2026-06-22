# AsyncSequence

> https://developer.apple.com/documentation/swift/asyncsequence

## 직업 정의 해보기

### Sequence

``` swift
struct NumberGenerator: Sequence {
    typealias Element = Int
    let max: Int

    struct Iterator: IteratorProtocol {
        let max: Int
        var current = 0
        
      	// IteratorProtocol 구현 사항
        mutating func next() -> Int? {
            guard current < max else { return nil }
            current += 1
            print("Sequence Iterator next: \(current)")
            return current
        }
    }

  	// Sequence 구현 사항
    func makeIterator() -> Iterator {
        Iterator(max: max)
    }
}

for i in NumberGenerator(max: 3) {
    print(i)
}

/*
Sequence Iterator next: 1
1
Sequence Iterator next: 2
2
Sequence Iterator next: 3
3
*/
```

### AsyncSequence

``` swift
struct AsyncNumberGenerator: AsyncSequence {
    typealias Element = Int
    let max: Int
    
    struct AsyncIterator: AsyncIteratorProtocol {
        let max: Int
        var current = 0
        
        // AsyncIteratorProtocol 구현 사항, throws 가능
        mutating func next() async -> Int? {
            guard current < max else { return nil }
            print("AsyncSequence -> AsyncIterator next: \(current)")
            try? await Task.sleep(for: .seconds(0.1))
            
            current += 1
            
            return current
        }
    }
    
  	// AsyncSequence 구현 사항
    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(max: max)
    }
}

for await i in AsyncNumberGenerator(max: 3) {
    print(i)
}

/*
AsyncSequence -> AsyncIterator next: 0
1
AsyncSequence -> AsyncIterator next: 1
2
AsyncSequence -> AsyncIterator next: 2
3
*/
```

### 사용

- 기본 사용

  ``` swift
  // for 구문 사용
  for await i in AsyncNumberGenerator(max: 3) {
      print(i)
  }

- 다양한 **Operator**가 있음(map(), filter() ...)

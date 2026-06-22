# OOP 4대 특징

## 캡슐화 (Encapsulation)

- 객체의 데이터(속성)와 그 데이터를 조작하는 메서드를 하나로 묶고, 외부에서 내부 구현 세부사항에 직접 접근하지 못하도록 은닉하는 것
- 외부에는 필요한 인터페이스만 공개하고, 내부 상태는 객체 스스로 관리한다
- 접근 제어자(private, protected, public 등)를 통해 구현한다
- 객체 내부 구현이 변경되더라도 외부에 영향을 주지 않는다

``` swift
class BankAccount {
    private var balance: Int = 0  // 외부에서 직접 접근 불가

    func deposit(amount: Int) {
        guard amount > 0 else { return }
        balance += amount
    }

    func getBalance() -> Int {
        return balance
    }
}

let account = BankAccount()
account.deposit(amount: 1000)
// account.balance = -999  // 컴파일 에러 - private 접근 불가
print(account.getBalance()) // 1000
```

## 상속 (Inheritance)

- 기존 클래스의 속성과 메서드를 새로운 클래스가 물려받는 것
- 코드의 재사용성을 높이고, 계층적인 관계를 표현할 수 있다
- 자식 클래스는 부모 클래스의 기능을 확장하거나 재정의(오버라이딩)할 수 있다
- 상속의 남용은 강한 결합을 만들 수 있으므로, 상속보다 합성(Composition)을 우선 고려하는 것이 일반적인 권장사항이다

``` swift
class Animal {
    func speak() {
        print("...")
    }
}

class Dog: Animal {
    override func speak() {  // 부모의 메서드를 재정의
        print("멍멍")
    }

    func fetch() {  // 자식만의 기능 확장
        print("공 가져오기")
    }
}

let dog = Dog()
dog.speak()  // "멍멍" - 부모 메서드를 재정의
dog.fetch()  // "공 가져오기" - 자식 고유 기능
```

## 다형성 (Polymorphism)

- 같은 인터페이스나 메서드 호출이 객체의 타입에 따라 다르게 동작하는 것
- 오버라이딩(Runtime Polymorphism): 상속 관계에서 부모의 메서드를 자식이 재정의
- 오버로딩(Compile-time Polymorphism): 같은 이름의 메서드를 매개변수를 달리하여 여러 개 정의
- 다형성 덕분에 구체적인 타입을 몰라도 공통 인터페이스를 통해 객체를 다룰 수 있다

``` swift
class Animal {
    func speak() {
        print("...")
    }
}

class Cat: Animal {
    override func speak() { print("야옹") }
}

class Dog: Animal {
    override func speak() { print("멍멍") }
}

// 같은 타입(Animal)으로 다루지만 실제 동작은 각 객체에 따라 다르다
let animals: [Animal] = [Cat(), Dog()]
for animal in animals {
    animal.speak()
}
// "야옹"
// "멍멍"
```

## 추상화 (Abstraction)

- 복잡한 시스템에서 핵심적인 개념만 추출하고, 불필요한 세부사항을 숨기는 것
- 추상 클래스나 인터페이스(프로토콜)를 통해 구현한다
- 사용자는 "무엇을 하는지"만 알면 되고, "어떻게 하는지"는 알 필요가 없다
- 캡슐화와의 차이: 캡슐화는 내부 데이터를 숨기는 것이고, 추상화는 복잡성 자체를 숨기는 것

``` swift
// "무엇을 하는지"만 정의하고, "어떻게 하는지"는 숨긴다
protocol Payment {
    func pay(amount: Int)
}

class CardPayment: Payment {
    func pay(amount: Int) {
        // 카드 결제의 복잡한 내부 로직은 숨겨져 있다
        print("카드로 \(amount)원 결제")
    }
}

class CashPayment: Payment {
    func pay(amount: Int) {
        print("현금으로 \(amount)원 결제")
    }
}

// 사용하는 쪽에서는 구체적인 결제 방식을 몰라도 된다
func checkout(method: Payment, amount: Int) {
    method.pay(amount: amount)
}

checkout(method: CardPayment(), amount: 10000)  // "카드로 10000원 결제"
checkout(method: CashPayment(), amount: 5000)   // "현금으로 5000원 결제"
```

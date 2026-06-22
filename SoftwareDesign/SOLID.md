# SOLID 원칙

## SRP - 단일 책임 원칙 (Single Responsibility Principle)

- 클래스는 단 하나의 책임만 가져야 한다
- 클래스를 변경해야 하는 이유는 오직 하나뿐이어야 한다
- 책임이 여러 개이면 하나의 변경이 다른 책임에 영향을 줄 수 있다

``` swift
// Bad - 여러 책임이 섞여 있다
class UserManager {
    func saveUser(_ user: User) { /* DB 저장 */ }
    func sendEmail(_ user: User) { /* 이메일 발송 */ }
    func generateReport(_ user: User) -> String { /* 리포트 생성 */ }
}

// Good - 각 클래스가 하나의 책임만 가진다
class UserRepository {
    func save(_ user: User) { /* DB 저장 */ }
}

class EmailService {
    func send(to user: User) { /* 이메일 발송 */ }
}

class ReportGenerator {
    func generate(for user: User) -> String { /* 리포트 생성 */ }
}
```

## OCP - 개방-폐쇄 원칙 (Open-Closed Principle)

- 확장에는 열려 있고, 수정에는 닫혀 있어야 한다
- 기존 코드를 변경하지 않으면서 새로운 기능을 추가할 수 있어야 한다
- 프로토콜(인터페이스)과 추상화를 활용하여 달성한다

``` swift
// Bad - 새로운 할인 정책이 추가될 때마다 기존 코드를 수정해야 한다
class DiscountCalculator {
    func calculate(type: String, price: Int) -> Int {
        if type == "seasonal" {
            return price * 80 / 100
        } else if type == "membership" {
            return price * 90 / 100
        }
        // 새 할인 정책 추가 시 여기를 수정해야 함
        return price
    }
}

// Good - 새로운 할인 정책은 프로토콜을 채택하기만 하면 된다
protocol DiscountPolicy {
    func discount(_ price: Int) -> Int
}

class SeasonalDiscount: DiscountPolicy {
    func discount(_ price: Int) -> Int { price * 80 / 100 }
}

class MembershipDiscount: DiscountPolicy {
    func discount(_ price: Int) -> Int { price * 90 / 100 }
}

// 새 할인 정책 추가 시 기존 코드 수정 없이 새 클래스만 만들면 된다
class EmployeeDiscount: DiscountPolicy {
    func discount(_ price: Int) -> Int { price * 70 / 100 }
}

class PriceCalculator {
    func calculate(price: Int, policy: DiscountPolicy) -> Int {
        policy.discount(price)
    }
}
```

## LSP - 리스코프 치환 원칙 (Liskov Substitution Principle)

- 자식 클래스는 부모 클래스를 대체할 수 있어야 한다
- 부모 타입으로 동작하는 코드에 자식 타입을 넣어도 정상 동작해야 한다
- 자식 클래스가 부모의 계약(사전/사후 조건)을 위반하면 안 된다

``` swift
// Bad - 자식이 부모의 동작을 위반한다
class Bird {
    func fly() { print("날기") }
}

class Penguin: Bird {
    override func fly() {
        fatalError("펭귄은 날 수 없습니다")  // 부모의 계약 위반
    }
}

func makeBirdFly(_ bird: Bird) {
    bird.fly()  // Penguin이 들어오면 크래시
}

// Good - 날 수 있는 새와 없는 새를 분리한다
protocol Bird {
    func eat()
}

protocol Flyable {
    func fly()
}

class Sparrow: Bird, Flyable {
    func eat() { print("먹기") }
    func fly() { print("날기") }
}

class Penguin: Bird {
    func eat() { print("먹기") }
    // fly()가 없으므로 날 수 없다는 것이 명확
}
```

## ISP - 인터페이스 분리 원칙 (Interface Segregation Principle)

- 클라이언트는 자신이 사용하지 않는 메서드에 의존하지 않아야 한다
- 하나의 거대한 인터페이스보다 여러 개의 작은 인터페이스가 낫다

``` swift
// Bad - 사용하지 않는 메서드까지 구현해야 한다
protocol Worker {
    func work()
    func eat()
    func sleep()
}

class Robot: Worker {
    func work() { print("작업") }
    func eat() { /* 로봇은 먹지 않는데 구현해야 함 */ }
    func sleep() { /* 로봇은 자지 않는데 구현해야 함 */ }
}

// Good - 필요한 인터페이스만 채택한다
protocol Workable {
    func work()
}

protocol Eatable {
    func eat()
}

protocol Sleepable {
    func sleep()
}

class Human: Workable, Eatable, Sleepable {
    func work() { print("작업") }
    func eat() { print("식사") }
    func sleep() { print("수면") }
}

class Robot: Workable {
    func work() { print("작업") }
    // 불필요한 메서드를 구현할 필요가 없다
}
```

## DIP - 의존 역전 원칙 (Dependency Inversion Principle)

- 고수준 모듈이 저수준 모듈에 의존해서는 안 되며, 둘 다 추상화에 의존해야 한다
- 추상화가 세부사항에 의존해서는 안 되며, 세부사항이 추상화에 의존해야 한다

``` swift
// Bad - 고수준 모듈(OrderService)이 저수준 모듈(MySQLDatabase)에 직접 의존한다
class MySQLDatabase {
    func save(_ data: String) { print("MySQL에 저장") }
}

class OrderService {
    let database = MySQLDatabase()  // 구체 타입에 의존

    func createOrder(_ order: String) {
        database.save(order)  // DB를 바꾸려면 이 코드를 수정해야 함
    }
}

// Good - 둘 다 추상화(프로토콜)에 의존한다
protocol Database {
    func save(_ data: String)
}

class MySQLDatabase: Database {
    func save(_ data: String) { print("MySQL에 저장") }
}

class MongoDatabase: Database {
    func save(_ data: String) { print("MongoDB에 저장") }
}

class OrderService {
    let database: Database  // 추상 타입에 의존

    init(database: Database) {
        self.database = database
    }

    func createOrder(_ order: String) {
        database.save(order)  // DB를 바꿔도 이 코드는 수정할 필요 없음
    }
}

// 사용 시 원하는 구현체를 주입
let service = OrderService(database: MongoDatabase())
service.createOrder("주문 1")
```

# 함수(function)

> 예제 코드: [Source/function.py](Source/function.py)

- [기본 구조](#기본-구조)
- [매개변수와 인수](#매개변수와-인수)
- [입력값·반환값에 따른 4가지 형태](#입력값반환값에-따른-4가지-형태)
- [매개변수를 지정하여 호출하기](#매개변수를-지정하여-호출하기)
- [가변 인수 (\*args)](#가변-인수-args)
- [키워드 인수 (\*\*kwargs)](#키워드-인수-kwargs)
- [함수의 반환값은 언제나 하나](#함수의-반환값은-언제나-하나)
- [return의 또 다른 쓰임새 (조기 반환)](#return의-또-다른-쓰임새-조기-반환)
- [매개변수 초깃값 설정](#매개변수-초깃값-설정)
- [변수의 효력 범위(scope)](#변수의-효력-범위scope)
- [함수 밖의 변수 변경하기](#함수-밖의-변수-변경하기)
- [lambda](#lambda)
- [독스트링(Docstring)](#독스트링docstring)

## 기본 구조

입력값을 받아 어떤 일을 수행한 뒤 결과를 반환하는 코드 묶음이다. 반복되는 코드를 한 뭉치로 묶어 재사용하고, 프로그램을 기능 단위로 분리해 흐름을 파악하기 쉽게 만든다.

```python
def 함수_이름(매개변수):
    실행 코드
```

- `def`는 함수를 정의하는 예약어이다.
- `return`은 함수의 결괏값(반환값)을 돌려주는 명령어이다.

```python
def add(a, b):
    return a + b

a = 3
b = 4
c = add(a, b)   # add(3, 4)의 반환값을 c에 대입
print(c)   # 7
```

## 매개변수와 인수

매개변수(parameter)와 인수(argument)는 혼용되지만 가리키는 대상이 다르다.

- **매개변수**: 함수를 정의할 때 값을 받는 변수
- **인수**: 함수를 호출할 때 전달하는 입력값

```python
def add(a, b):   # a, b는 매개변수
    return a + b

add(3, 4)   # 3, 4는 인수
```

> 입력값을 인수·파라미터·매개변수 등으로, 반환값을 결괏값·출력값·리턴값 등으로 부르기도 한다. 표현은 달라도 의미는 같다.

## 입력값·반환값에 따른 4가지 형태

함수는 입력값과 반환값의 유무에 따라 네 가지로 나뉜다.

- **일반적인 함수** — 입력값도 반환값도 있음. 가장 흔한 형태다.

  ```python
  def add(a, b):
      return a + b

  c = add(3, 4)
  print(c)   # 7
  ```

  사용법: `반환값을_받을_변수 = 함수_이름(인수1, 인수2, ...)`

- **입력값이 없는 함수** — 괄호 안을 비운다.

  ```python
  def say():
      return 'Hi'

  a = say()
  print(a)   # Hi
  ```

  사용법: `반환값을_받을_변수 = 함수_이름()`

- **반환값이 없는 함수** — `return` 문이 없다. `print`로 출력하는 것과 값을 반환하는 것은 다르다.

  ```python
  def add(a, b):
      print(f"{a}, {b}의 합은 {a+b}입니다.")

  a = add(3, 4)   # 3, 4의 합은 7입니다.
  print(a)        # None
  ```

  사용법: `함수_이름(인수1, 인수2, ...)`

  > 반환값은 오직 `return` 명령어로만 생긴다. `return`이 없는 함수는 호출 결과로 값이 없음을 뜻하는 `None`을 반환한다.

- **입력값도 반환값도 없는 함수**

  ```python
  def say():
      print('Hi')

  say()   # Hi
  ```

  사용법: `함수_이름()`

## 매개변수를 지정하여 호출하기

호출할 때 `매개변수=값` 형태로 지정하면, 순서에 상관없이 값을 전달할 수 있다.

```python
def sub(a, b):
    return a - b

result = sub(a=7, b=3)   # a에 7, b에 3을 전달
print(result)   # 4

result = sub(b=5, a=3)   # 순서를 바꿔도 됨
print(result)   # -2
```

## 가변 인수 (\*args)

입력값의 개수가 몇 개일지 모를 때 매개변수 앞에 `*`을 붙인다. 전달된 값이 전부 **튜플**로 묶여 들어온다.

```python
def 함수_이름(*매개변수):
    실행 코드
```

```python
def add_money(*args):
    result = 0
    for i in args:
        result += i
    return result

print(add_money(1, 2, 3))                          # 6
print(add_money(1, 2, 3, 4, 5, 6, 7, 8, 9, 10))    # 55
```

> `args`는 arguments의 약자로 관례적으로 쓰는 이름일 뿐, `*pey`처럼 아무 이름이나 써도 된다.

- **일반 매개변수와 함께 쓰기** — 가변 인수 앞에 일반 매개변수를 둘 수 있다.

  ```python
  def add_mul(choice, *args):
      if choice == "add":
          result = 0
          for i in args:
              result += i
      elif choice == "mul":
          result = 1
          for i in args:
              result *= i
      return result

  print(add_mul('add', 1, 2, 3, 4, 5))   # 15
  print(add_mul('mul', 1, 2, 3, 4, 5))   # 120
  ```

## 키워드 인수 (\*\*kwargs)

`키워드=값` 형태의 인수를 받을 때 매개변수 앞에 `**`을 붙인다. 전달된 값이 전부 **딕셔너리**로 묶여 들어온다.

```python
def 함수_이름(**매개변수):
    실행 코드
```

```python
def print_kwargs(**kwargs):
    print(kwargs)

print_kwargs(a=1)                # {'a': 1}
print_kwargs(name='foo', age=3)  # {'name': 'foo', 'age': 3}
```

- **실용 예제** — 어떤 키워드든 자유롭게 받아 유연한 함수를 만들 수 있다.

  ```python
  def create_profile(**info):
      print("=== 프로필 정보 ===")
      for key, value in info.items():
          print(f"{key}: {value}")

  create_profile(이름='김철수', 나이='30', 직업='프로그래머', 취미='독서')
  # === 프로필 정보 ===
  # 이름: 김철수
  # 나이: 30
  # 직업: 프로그래머
  # 취미: 독서
  ```

- **함께 쓰기** — 일반 매개변수, `*args`, `**kwargs`는 반드시 이 순서로 써야 한다.

  ```python
  def mixed_function(name, *args, **kwargs):
      print(f"이름: {name}")
      print(f"추가 인수들: {args}")
      print(f"키워드 인수들: {kwargs}")

  mixed_function('홍길동', 1, 2, 3, age=25, city='서울')
  # 이름: 홍길동
  # 추가 인수들: (1, 2, 3)
  # 키워드 인수들: {'age': 25, 'city': '서울'}
  ```

## 함수의 반환값은 언제나 하나

여러 값을 쉼표로 반환해도 실제로는 **튜플 하나**로 묶여 반환된다.

```python
def add_and_mul(a, b):
    return a + b, a * b   # (a+b, a*b) 튜플로 반환

result = add_and_mul(3, 4)
print(result)   # (7, 12)

# 튜플을 나눠 받기(언패킹)
result1, result2 = add_and_mul(3, 4)
print(result1, result2)   # 7 12
```

`return`을 두 번 써도 두 값이 반환되지는 않는다. 함수는 **첫 `return`을 만나는 순간 값을 반환하고 즉시 빠져나간다.**

```python
def add_and_mul(a, b):
    return a + b
    return a * b   # 실행되지 않음

print(add_and_mul(2, 3))   # 5
```

## return의 또 다른 쓰임새 (조기 반환)

값 없이 `return`만 쓰면 특정 상황에서 함수를 즉시 빠져나갈 수 있다.

```python
def say_nick(nick):
    if nick == '바보':
        return   # 여기서 함수 종료
    print(f"나의 별명은 {nick}입니다.")

say_nick('야호')   # 나의 별명은 야호입니다.
say_nick('바보')   # 아무것도 출력하지 않음
```

## 매개변수 초깃값 설정

매개변수에 `man=True`처럼 초깃값을 주면, 호출 시 인수를 생략했을 때 그 값이 쓰인다.

```python
def say_myself(name, age, man=True):
    print(f"나의 이름은 {name}입니다.")
    print(f"나이는 {age}살입니다.")
    if man:
        print("남자입니다.")
    else:
        print("여자입니다.")

say_myself("양중창", 35)          # man 생략 → 기본값 True
# 나의 이름은 양중창입니다.
# 나이는 35살입니다.
# 남자입니다.

say_myself("양중창", 35, False)   # man에 False 전달
# 나의 이름은 양중창입니다.
# 나이는 35살입니다.
# 여자입니다.
```

> **초깃값이 있는 매개변수는 항상 뒤쪽에 놓아야 한다.** 초깃값이 없는 매개변수가 뒤에 오면 인터프리터가 어떤 값을 어디에 넣을지 판단할 수 없어 오류가 난다.
>
> ```python
> # def say_myself(name, man=True, age):   # SyntaxError
> #     non-default argument follows default argument
> ```

## 변수의 효력 범위(scope)

함수 안에서 선언한 변수(매개변수 포함)는 **함수 안에서만** 유효하며, 함수 밖의 같은 이름 변수와는 무관하다.

```python
a = 1
def vartest(a):
    a = a + 1   # 함수 안의 a와 밖의 a는 다른 변수

vartest(a)
print(a)   # 1: 밖의 a는 영향받지 않음
```

- 함수 밖의 변수를 **읽는 것**은 가능하다.

  ```python
  out = 1
  def vartest(input):
      return out + input   # 밖의 out=1을 읽음

  print(vartest(2))   # 3
  ```

- 하지만 함수 안에서 같은 이름에 **값을 대입하면** 함수 안에 새 변수를 만든 것이라, 밖의 변수는 바뀌지 않는다.

  ```python
  out = 1
  def vartest(input):
      out = input   # 함수 안에 새로운 out을 선언한 셈

  vartest(2)
  print(out)   # 1
  ```

- 리스트·딕셔너리 같은 **mutable(변경 가능) 자료형**은 매개변수로 받아도 내부에서 변경하면 원본이 함께 바뀐다.

  ```python
  def change_list(my_list):
      my_list.append(4)   # 원본 리스트를 직접 변경

  a = [1, 2, 3]
  change_list(a)
  print(a)   # [1, 2, 3, 4]
  ```

## 함수 밖의 변수 변경하기

- **1. return 사용하기** (권장) — 반환값을 받아 밖에서 다시 대입한다.

  ```python
  a = 1
  def vartest(a):
      a = a + 1
      return a

  a = vartest(a)
  print(a)   # 2
  ```

- **2. global 명령어 사용하기** — 함수 안에서 밖의 변수를 직접 쓰겠다고 선언한다.

  ```python
  a = 1
  def vartest():
      global a   # 함수 밖의 a를 직접 사용
      a = a + 1

  vartest()
  print(a)   # 2
  ```

  > `global`은 함수를 외부 변수에 종속시켜 독립성을 떨어뜨리므로, 되도록 쓰지 말고 `return` 방식을 권한다.

## lambda

이름 없이 함수를 한 줄로 간결하게 만드는 예약어로, `def`와 같은 역할을 한다. `return`이 없어도 표현식의 결과를 반환한다.

```python
함수_이름 = lambda 매개변수1, 매개변수2, ... : 표현식
```

```python
add = lambda a, b: a + b
result = add(3, 4)
print(result)   # 7
```

- 함수 자체도 값이므로 변수에 할당할 수 있다.

  ```python
  def add_function(a, b):
      return a + b

  add_var = add_function   # 함수를 변수에 할당
  print(add_var(1, 2))     # 3
  ```

## 독스트링(Docstring)

함수에 대한 설명을 문서화하는 방법이다. 함수 첫 줄에 삼중 따옴표(`"""`)로 둘러싼 문자열을 작성하며, `함수.__doc__`로 확인할 수 있다.

```python
def add(a, b):
    """
    두 숫자를 더하는 함수

    Parameters:
    a (int, float): 첫 번째 숫자
    b (int, float): 두 번째 숫자

    Returns:
    int, float: 두 숫자의 합
    """
    return a + b

print(add.__doc__)
# 두 숫자를 더하는 함수
#
# Parameters:
# a (int, float): 첫 번째 숫자
# b (int, float): 두 번째 숫자
#
# Returns:
# int, float: 두 숫자의 합
```

# 불(Bool)

> 예제 코드: [Source/bool.py](Source/bool.py)

- [불이란](#불이란)
- [자료형의 참과 거짓](#자료형의-참과-거짓)
- [bool() 로 확인하기](#bool-로-확인하기)
- [논리 연산자](#논리-연산자)

## 불이란

참(`True`)과 거짓(`False`) 두 값만 갖는 자료형. `True` / `False` 는 파이썬 예약어이며, 첫 글자를 반드시 대문자로 써야 한다. (`true`, `false` 는 에러)

```python
a = True
b = False
```

비교 연산의 결과가 바로 불 값이다.

```python
print(1 == 1)  # True
print(2 > 1)   # True
print(2 < 1)   # False
```

## 자료형의 참과 거짓

불 자료형이 아니어도, 조건문(`if`, `while`)에서는 값 자체가 참/거짓으로 취급된다. **비어 있으면 거짓, 값이 있으면 참**이라고 기억하면 된다.

| 값 | 참/거짓 | 설명 |
| --- | --- | --- |
| `"python"` | 참 | 비어 있지 않은 문자열 |
| `""` | 거짓 | 빈 문자열 |
| `[1, 2, 3]` | 참 | 비어 있지 않은 리스트 |
| `[]` | 거짓 | 빈 리스트 |
| `(1, 2, 3)` | 참 | 비어 있지 않은 튜플 |
| `()` | 거짓 | 빈 튜플 |
| `{'a': 1}` | 참 | 비어 있지 않은 딕셔너리 |
| `{}` | 거짓 | 빈 딕셔너리 |
| `1` | 참 | 0이 아닌 숫자 |
| `0` | 거짓 | 숫자 0 |
| `None` | 거짓 | 값이 없음 |

이 성질을 이용해 조건문을 간결하게 쓸 수 있다.

```python
# 리스트가 빌 때까지 반복
a = [1, 2, 3, 4]
while a:
    print(a.pop())  # 4, 3, 2, 1 -> 리스트가 비면 while 종료

# 빈 리스트는 거짓
if []:
    print("참")
else:
    print("거짓")  # 이쪽 실행
```

## bool() 로 확인하기

`bool()` 에 값을 넣으면 그 값이 참인지 거짓인지 직접 확인할 수 있다.

```python
print(bool('python'))   # True
print(bool(''))         # False
print(bool([1, 2, 3]))  # True
print(bool([]))         # False
print(bool(3))          # True
print(bool(0))          # False
```

## 논리 연산자

여러 조건을 조합할 때 사용한다.

| 연산자 | 의미 | 결과가 참일 때 |
| --- | --- | --- |
| `and` | 그리고 | 양쪽이 **모두** 참 |
| `or` | 또는 | **하나라도** 참 |
| `not` | 부정 | 참/거짓을 반대로 |

```python
print(True and False)  # False  <- 하나라도 거짓이면 False
print(True or False)   # True   <- 하나라도 참이면 True
print(not True)        # False  <- 반대로 뒤집음
```

- **`not` 은 참/거짓으로 취급되는 값에도 적용된다.**

  ```python
  print(not 1)  # False  <- 1은 참이므로 뒤집으면 False
  print(not 0)  # True   <- 0은 거짓이므로 뒤집으면 True
  ```

- **활용 예제**

  ```python
  x = 5
  y = 10
  print(x > 0 and y > 5)  # True  <- 둘 다 참
  print(x > 10 or y > 5)  # True  <- 뒤쪽이 참
  print(not x > y)        # True  <- (5 > 10)은 거짓, 뒤집어 True
  ```

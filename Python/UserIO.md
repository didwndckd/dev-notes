# 사용자 입출력(input / print)

> 예제 코드: [Source/user-IO.py](Source/user-IO.py)

- [input으로 입력받기](#input으로-입력받기)
- [입력값을 숫자로 변환하기](#입력값을-숫자로-변환하기)
- [print 자세히 알기](#print-자세히-알기)
- [sep 매개변수 — 구분자 설정](#sep-매개변수--구분자-설정)
- [end 매개변수 — 한 줄에 이어 출력](#end-매개변수--한-줄에-이어-출력)
- [실습: 간단한 계산기](#실습-간단한-계산기)

## input으로 입력받기

`input`은 사용자가 키보드로 입력한 값을 받아 변수에 담는다. 입력한 모든 것을 **문자열**로 저장한다.

```python
a = input()   # 프롬프트에 입력한 값이 a에 담긴다
print(a)
# abc
# abc
```

- **안내 문구 함께 띄우기** — 괄호 안에 문구를 넣으면 프롬프트로 표시된다.

  ```python
  a = input("안내문구")
  print(a)
  # 안내문구abc   ← 입력
  # abc           ← 출력
  ```

- 입력값은 항상 문자열(`str`)이라는 점에 주의한다.

  ```python
  number = input("숫자를 입력하세요: ")
  print(number)         # 3
  print(type(number))   # <class 'str'>
  ```

- 그래서 숫자처럼 보여도 `+`는 덧셈이 아니라 **문자열 연결**이 된다.

  ```python
  a = input("숫자 입력 a=")   # 3
  b = input("숫자 입력 b=")   # 4
  print(a + b)   # 34  ("3" + "4" → "34")
  ```

## 입력값을 숫자로 변환하기

숫자 계산을 하려면 `int()`나 `float()`로 자료형을 변환해야 한다.

- **정수로 변환** — `int()`

  ```python
  age = input("나이를 입력하세요: ")   # 35
  age = int(age)   # 문자열을 정수로 변환
  print(age + 1)   # 36
  ```

- **실수로 변환** — `float()`

  ```python
  height = input("키를 입력하세요(cm): ")   # 173.9
  height = float(height)   # 문자열을 실수로 변환
  print(height / 100)      # 1.739 (미터 단위)
  ```

- **한 줄에 변환** — `input`을 `int`(또는 `float`)로 바로 감쌀 수 있다.

  ```python
  age = int(input("나이를 입력하세요: "))   # 35
  print(type(age))   # <class 'int'>
  ```

## print 자세히 알기

`print`는 데이터를 출력하는 함수다. 숫자, 문자열, 리스트 등 어떤 자료형이든 출력할 수 있다.

```python
a = 123
print(a)   # 123
a = "Python"
print(a)   # Python
a = [1, 2, 3]
print(a)   # [1, 2, 3]
```

- **따옴표 문자열을 붙여 쓰면 `+` 연산과 같다.**

  ```python
  print("life" "is" "too short")      # lifeistoo short
  print("life" + "is" + "too short")  # lifeistoo short
  ```

- **쉼표(`,`)로 나열하면 사이에 공백이 자동으로 들어간다.**

  ```python
  print("life", "is", "too short")   # life is too short
  ```

## sep 매개변수 — 구분자 설정

`sep`으로 출력할 값들 사이의 구분자를 지정한다. 기본값은 공백(`' '`)이다. 쉼표로 나열할 때 공백이 붙는 것도 `sep`의 기본값이 공백이기 때문이다.

```python
print("2026", "08", "01", sep="-")    # 2026-08-01
print("점프", "투", "파이썬", sep="TO ")   # 점프TO 투TO 파이썬
```

## end 매개변수 — 한 줄에 이어 출력

`print`는 출력 후 `end` 값을 덧붙이는데, 기본값이 줄바꿈(`\n`)이라 매번 줄이 바뀐다. `end`를 바꾸면 같은 줄에 이어서 출력할 수 있다.

```python
for i in range(10):
    print(i, end=' ')
# 0 1 2 3 4 5 6 7 8 9
```

> 마지막 출력 뒤에 줄바꿈이 없어 프롬프트가 같은 줄에 나타날 수 있는데, 오류가 아니다.

## 실습: 간단한 계산기

지금까지 배운 입출력과 f 문자열 포매팅을 활용한 예제다.

```python
print("=== 간단한 계산기===")

# 사용자로부터 두 숫자 입력받기
num1 = float(input("첫 번째 숫자를 입력하세요: "))
num2 = float(input("두 번째 숫자를 입력하세요: "))

# 계산 결과 출력
print(f"{num1} + {num2} = {num1 + num2}")
print(f"{num1} - {num2} = {num1 - num2}")
print(f"{num1} * {num2} = {num1 * num2}")
if num2 != 0:
    print(f"{num1} / {num2} = {num1 / num2}")
else:
    print("0으로 나눌 수 없습니다.")
# === 간단한 계산기===
# 첫 번째 숫자를 입력하세요: 10
# 두 번째 숫자를 입력하세요: 3
# 10.0 + 3.0 = 13.0
# 10.0 - 3.0 = 7.0
# 10.0 * 3.0 = 30.0
# 10.0 / 3.0 = 3.3333333333333335
```

> 0으로 나누면 `ZeroDivisionError`가 발생하므로, 나눗셈 전에 `num2 != 0`인지 확인한다.

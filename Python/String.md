# 문자열(String)

> 예제 코드: [Source/string.py](Source/string.py)

- [문자열 만들기](#문자열-만들기)
- [따옴표 포함하기](#따옴표-포함하기)
- [여러 줄 문자열](#여러-줄-문자열)
- [이스케이프 코드](#이스케이프-코드)
- [문자열 연산](#문자열-연산)
- [문자열 길이(len)](#문자열-길이len)
- [인덱싱](#인덱싱)
- [슬라이싱](#슬라이싱)
- [문자열 포매팅 (%)](#문자열-포매팅-)
- [문자열 포매팅 (format 함수)](#문자열-포매팅-format-함수)
- [문자열 포매팅 (f-string)](#문자열-포매팅-f-string)
- [문자열 관련 함수](#문자열-관련-함수)
- [문자열은 immutable](#문자열은-immutable)

## 문자열 만들기

문자열을 만드는 방법은 4가지가 있다.

```python
"Hello World"                              # 큰따옴표
'Python is fun'                            # 작은따옴표
"""List is too short, You need python"""   # 큰따옴표 3개
'''Life is too short, You need python'''   # 작은따옴표 3개
```

## 따옴표 포함하기

문자열 안에 따옴표를 넣는 방법은 3가지다.

- **작은따옴표를 포함**: 큰따옴표(`"`)로 감싼다

  ```python
  food = "Python's favorite food is perl"
  print(food)  # Python's favorite food is perl
  ```

- **큰따옴표를 포함**: 작은따옴표(`'`)로 감싼다

  ```python
  say = '"Python is very easy." he says.'
  print(say)  # "Python is very easy." he says.
  ```

- **역슬래시(`\`)로 이스케이프**: 감싼 따옴표 종류와 상관없이 포함 가능

  ```python
  food = 'Python\'s favorite food is perl'
  say = "\"Python is very easy.\" he says."
  ```

## 여러 줄 문자열

- **이스케이프 코드 `\n`(줄바꿈) 삽입**

  ```python
  multiline = "Life is too short\nYou need Python"
  print(multiline)
  # Life is too short
  # You need Python
  ```

- **연속된 따옴표 3개 사용** (`"""~"""` / `'''~'''`)

  ```python
  multiline = """Life is too short
  You need python"""
  print(multiline)
  # Life is too short
  # You need python
  ```

## 이스케이프 코드

프로그래밍에서 사용할 수 있도록 미리 정해 둔 문자 조합.

| 코드 | 의미 |
| --- | --- |
| `\n` | 줄바꿈 |
| `\t` | 탭 간격 |
| `\\` | `\` 를 문자로 표현 |
| `\'` | 작은따옴표를 문자로 표현 |
| `\"` | 큰따옴표를 문자로 표현 |
| `\r` | 캐리지 리턴(커서를 현재 줄의 맨 앞으로 이동) |
| `\f` | 폼 피드(커서를 다음 줄로 이동) |
| `\a` | 벨소리(출력 시 PC 스피커에서 '삑' 소리) |
| `\b` | 백스페이스 |
| `\000` | 널 문자 |

## 문자열 연산

파이썬에서는 문자열을 더하거나 곱할 수 있다.

- **더하기(연결)**

  ```python
  head = "Python"
  tail = " is fun"
  print(head + tail)  # Python is fun
  ```

- **곱하기(반복)**

  ```python
  a = "python"
  print(a * 2)  # pythonpython

  # 응용
  print("=" * 50)
  print("My Program")
  print("=" * 50)
  # ==================================================
  # My Program
  # ==================================================
  ```

## 문자열 길이(len)

`len()` 함수로 문자열의 길이를 구한다. (공백도 길이에 포함된다)

```python
a = "Life is too short"
print(len(a))  # 17
```

## 인덱싱

문자열의 각 문자를 위치(인덱스)로 접근한다. 인덱스는 `0`부터 시작한다.

```python
#    0         1         2         3
#    0123456789012345678901234567890123
a = "Life is too short, You need Python"

print(a[3])   # e
print(a[0])   # L
print(a[12])  # s
```

- **음수 인덱스**: 문자열 뒤에서부터 접근한다. (`-1`이 마지막 문자)

  ```python
  print(a[-1])  # n  (맨 마지막 문자)
  print(a[-2])  # o
  print(a[-5])  # y
  print(a[-0])  # L  (-0 == 0, 첫 번째 문자)
  ```

## 슬라이싱

`a[시작:끝]` 형태로 문자열의 일부를 잘라낸다. **시작 인덱스는 포함, 끝 인덱스는 제외**한다. (`시작 <= i < 끝`)

```python
a = "Life is too short, You need Python"

print(a[0:4])  # Life   (0 <= i < 4)
print(a[0:3])  # Lif    (0 <= i < 3)
```

- **시작/끝 생략**: 생략하면 각각 문자열의 처음, 끝이 적용된다.

  ```python
  print(a[19:])  # You need Python  (19 ~ 끝)
  print(a[:17])  # Life is too short  (0 ~ 17 직전)
  print(a[:])    # Life is too short, You need Python  (전체)
  ```

- **음수 인덱스와 함께 사용**

  ```python
  print(a[19:-7])  # You need  (a[19] ~ a[-8])
  ```

- **활용 예: 문자열 나누기**

  ```python
  a = "20230331Rainy"
  date = a[:8]     # 20230331
  weather = a[8:]  # Rainy
  ```

- **문자열 바꾸기**: 문자열은 immutable이라 특정 인덱스만 변경할 수 없다. 슬라이싱으로 새 문자열을 만들어야 한다.

  ```python
  a = "Pithon"
  # a[1] = 'y'  # TypeError: immutable 자료형
  a = a[:1] + 'y' + a[2:]
  print(a)  # Python
  ```

## 문자열 포매팅 (%)

`%` 뒤에 값을 넣어 문자열 안에 삽입한다.

```python
"I eat %d apples." % 3           # I eat 3 apples.  (숫자 %d)
"I eat %s apples." % "five"      # I eat five apples.  (문자열 %s)

# 변수 대입
number = 10
"I eat %d apples." % number      # I eat 10 apples.

# 두 개 이상의 값: 튜플로 전달
number, day = 10, "three"
"I ate %d apples. so I was sick for %s days." % (number, day)
# I ate 10 apples. so I was sick for three days.
```

- **`%s`는 어떤 형태의 값이든 문자열로 변환해 넣는다**

  ```python
  "I have %s apples." % 3     # I have 3 apples.
  "rate is %s" % 3.234        # rate is 3.234
  "this is %s" % True         # this is True
  ```

- **`%` 문자 자체를 표현**: `%%` 를 사용한다.

  ```python
  "Error is %d%%" % 98  # Error is 98%
  ```

### 포맷 코드

| 코드 | 의미 |
| --- | --- |
| `%s` | 문자열(String) |
| `%c` | 문자(character) |
| `%d` | 정수(Integer) |
| `%f` | 부동소수(floating-point) |
| `%o` | 8진수 |
| `%x` | 16진수 |
| `%%` | 리터럴 `%` |

### 정렬과 공백, 소수점

- **문자열 정렬**: `%{N}s` 는 전체 길이를 `N`으로 고정하고, 모자란 만큼 공백으로 채운다.

  ```python
  "%10s" % "hi"      # '        hi'  (전체 10칸, 오른쪽 정렬)
  "%4s" % "123456"   # '123456'      (길면 그대로 출력)
  "%-10s" % "hi"     # 'hi        '  (-N: 왼쪽 정렬)
  ```

- **소수점 표현**: `%{S}.{N}f` — 전체 사이즈 `S`(0이면 제한 없음), 소수점 아래 `N`자리.

  ```python
  "%0.4f" % 3.12341234   # '3.1234'      (사이즈 제한 X, 소수점 4자리)
  "%10.4f" % 3.12341234  # '    3.1234'  (전체 10칸, 오른쪽 정렬)
  "%-10.4f" % 3.12341234 # '3.1234    '  (왼쪽 정렬)
  ```

## 문자열 포매팅 (format 함수)

`"...{}...".format(값)` 형태로 값을 넣는다. `{0}`, `{1}` 처럼 인덱스로 위치를 지정한다.

```python
"I eat {0} apples.".format(3)         # I eat 3 apples.

number = 3
"I eat {0} apples.".format(number)    # I eat 3 apples.

# 2개 이상의 값
"I ate {0} apples. so I was sick for {1} days.".format(10, "three")
# I ate 10 apples. so I was sick for three days.

# 이름으로 넣기
"I ate {number} apples.".format(number=10)

# 인덱스와 이름 혼용
"I ate {0} apples. so I was sick for {day} days.".format(10, day=3)
# I ate 10 apples. so I was sick for 3 days.
```

- **정렬**: `{인덱스:정렬기호길이}` (`<` 왼쪽, `>` 오른쪽, `^` 가운데). 변수명은 생략 가능.

  ```python
  "{0:<10}".format("hi")       # 'hi        '  (왼쪽)
  "{str:<10}".format(str="hi") # 'hi        '  (이름 사용)
  "{0:>10}".format("hi")       # '        hi'  (오른쪽)
  "{0:^10}".format("hi")       # '    hi    '  (가운데)
  ```

- **공백 채우기**: 정렬 기호 앞에 채울 문자를 지정한다.

  ```python
  "{0:=^10}".format("hi")  # '====hi===='
  "{0:!<10}".format("hi")  # 'hi!!!!!!!!'
  ```

- **소수점 표현**

  ```python
  y = 3.12341234
  "{0:0.4f}".format(y)         # '3.1234'
  "{number:10.4f}".format(number=y)  # '    3.1234'
  ```

- **`{}` 문자 자체 표현**: `{{ }}` 처럼 2개를 연속으로 쓴다.

  ```python
  "{{ and }}".format()  # { and }
  ```

## 문자열 포매팅 (f-string)

파이썬 **3.6 버전부터** 사용 가능. 문자열 앞에 `f`를 붙이고 `{}` 안에 변수나 식을 직접 넣는다. (3.6 미만에서는 사용 불가)

```python
name = "홍길동"
age = 30
f'나의 이름은 {name}입니다. 나이는 {age}입니다.'
# 나의 이름은 홍길동입니다. 나이는 30입니다.
```

- **식(expression)도 사용 가능**

  ```python
  age = 30
  f"나는 내년이면 {age + 1}살이 된다."  # 나는 내년이면 31살이 된다.
  ```

- **딕셔너리 참조**

  ```python
  d = {'name': '홍길동', 'age': 30}
  f"나의 이름은 {d['name']}입니다. 나이는 {d['age']}입니다."
  ```

- **정렬 / 공백 채우기** (format 함수와 동일한 형식)

  ```python
  f'{"hi":<10}'  # 'hi        '  (왼쪽)
  f'{"hi":>10}'  # '        hi'  (오른쪽)
  f'{"hi":^10}'  # '    hi    '  (가운데)
  f'{"hi":=^10}' # '====hi===='  (공백 채우기)
  ```

- **소수점 표현**

  ```python
  y = 3.12341234
  f'{y:0.4f}'  # '3.1234'
  f'{y:10.4f}' # '    3.1234'
  ```

- **`{}` 문자 자체 표현**

  ```python
  f'{{ and }}'  # { and }
  ```

- **숫자에 콤마(`,`) 삽입**

  ```python
  f"난 {1500000:,}원이 필요해"  # 난 1,500,000원이 필요해
  ```

## 문자열 관련 함수

| 함수 | 설명 | 예시 | 결과 |
| --- | --- | --- | --- |
| `count(x)` | 문자 `x`의 개수 | `"hobby".count("b")` | `2` |
| `find(x)` | `x`가 처음 나온 위치, 없으면 `-1` | `"Python is the best choice".find("b")` | `14` |
| `index(x)` | `find`와 같으나 없으면 **에러** | `"Life is too short".index("t")` | `8` |
| `join(seq)` | 주체 문자를 구분자로 끼워 넣음 | `",".join("abcd")` | `a,b,c,d` |
| `upper()` | 소문자 → 대문자 | `"hi".upper()` | `HI` |
| `lower()` | 대문자 → 소문자 | `"HI".lower()` | `hi` |
| `lstrip()` | 왼쪽 공백 제거 | `" hi ".lstrip()` | `hi ` |
| `rstrip()` | 오른쪽 공백 제거 | `" hi ".rstrip()` | ` hi` |
| `strip()` | 양쪽 공백 제거 | `" hi ".strip()` | `hi` |
| `replace(a, b)` | `a`를 `b`로 바꿈 | `"Life".replace("Life", "Leg")` | `Leg` |
| `split(x)` | `x` 기준으로 나눔(기본: 공백) | `"a b c".split()` | `['a','b','c']` |
| `isalpha()` | 알파벳으로만 구성됐는지 | `"Python".isalpha()` | `True` |
| `isdigit()` | 숫자로만 구성됐는지 | `"12345".isdigit()` | `True` |
| `startswith(x)` | `x`로 시작하는지 | `"Life".startswith("Li")` | `True` |
| `endswith(x)` | `x`로 끝나는지 | `"short".endswith("rt")` | `True` |

- **`join`** 은 문자열뿐 아니라 리스트도 받는다.

  ```python
  ",".join(["a", "b", "c", "d"])  # a,b,c,d
  "X".join("abcd")                # aXbXcXd
  ```

- **`split`** 은 구분자를 주지 않으면 공백(스페이스, 탭, 엔터)을 기준으로 나눈다.

  ```python
  "Life is too short".split()  # ['Life', 'is', 'too', 'short']
  "a:b:c:d".split(":")         # ['a', 'b', 'c', 'd']
  ```

- **`isalpha` / `isdigit`** 은 공백이 포함되면 `False`다. `isdigit`은 소수점(`.`)도 숫자로 인정하지 않는다.

  ```python
  "Python3".isalpha()   # False (숫자 포함)
  "Hello World".isalpha()  # False (공백)
  "12 34".isdigit()     # False (공백)
  "12.34".isdigit()     # False (소수점)
  ```

## 문자열은 immutable

문자열은 자체 값을 변경할 수 없는 **immutable(불변)** 자료형이다. `upper()`, `replace()` 같은 변환 함수는 **변환한 값을 반환**할 뿐 원본을 바꾸지 않는다.

```python
a = "hi"
print(a.upper())  # HI
print(a)          # hi  (원본은 그대로)

a = "Life is too short"
print(a.replace("Life", "Your leg"))  # Your leg is too short
print(a)                              # Life is too short  (원본 그대로)
```

- 원본을 바꾸려면 결과를 **다시 할당**해야 한다. (문자열 자체를 바꾸는 게 아니라, 변수에 새 값을 할당하는 개념)

  ```python
  a = "hi"
  a = a.upper()
  print(a)  # HI
  ```

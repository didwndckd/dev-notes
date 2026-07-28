# 반복문(for)

> 예제 코드: [Source/for.py](Source/for.py)

- [기본 구조](#기본-구조)
- [튜플로 받기(언패킹)](#튜플로-받기언패킹)
- [continue](#continue)
- [range 함수](#range-함수)
- [구구단 (for + range)](#구구단-for--range)
- [리스트 컴프리헨션](#리스트-컴프리헨션)
- [break](#break)
- [for-else 문](#for-else-문)
- [enumerate 함수](#enumerate-함수)
- [zip 함수](#zip-함수)

## 기본 구조

리스트·튜플·문자열 등의 요소를 첫 번째부터 마지막까지 차례로 변수에 대입하며 블록을 반복한다.

```python
for 변수 in 리스트(또는 튜플, 문자열):
    실행 코드
```

```python
test_list = ['one', 'two', 'three']
for i in test_list:
    print(i)
# one
# two
# three
```

- **응용 예제** — 5명의 점수 중 60점 이상이면 합격, 아니면 불합격

  ```python
  marks = [90, 25, 67, 45, 80]
  number = 0
  for mark in marks:
      number += 1
      if mark >= 60:
          print(f"{number}번 학생은 합격입니다.")
      else:
          print(f"{number}번 학생은 불합격입니다.")
  # 1번 학생은 합격입니다.
  # 2번 학생은 불합격입니다.
  # 3번 학생은 합격입니다.
  # 4번 학생은 불합격입니다.
  # 5번 학생은 합격입니다.
  ```

## 튜플로 받기(언패킹)

요소가 튜플이면 각 값이 자동으로 여러 변수에 나뉘어 대입된다.

```python
a = [(1, 2), (3, 4), (5, 6)]
for (first, last) in a:
    print(first + last)
# 3
# 7
# 11
```

## continue

`continue`를 만나면 이후 문장을 실행하지 않고 for 문의 처음으로 돌아간다.

```python
# 합격자에게만 축하 메시지
marks = [90, 25, 67, 45, 80]
number = 0
for mark in marks:
    number += 1
    if mark < 60:
        continue   # 다음 루프로 넘어감
    print(f"{number}번 학생 축하합니다. 합격입니다.")
# 1번 학생 축하합니다. 합격입니다.
# 3번 학생 축하합니다. 합격입니다.
# 5번 학생 축하합니다. 합격입니다.
```

## range 함수

연속된 숫자를 만들어 주는 함수로, for 문과 자주 함께 쓰인다.

```python
range(끝_숫자)              # 0 <= i < 끝_숫자
range(시작_숫자, 끝_숫자)   # 시작_숫자 <= i < 끝_숫자 (끝 숫자는 미포함)
```

```python
print(range(10))     # range(0, 10): 0~9 (시작 생략 시 기본값 0)
print(range(1, 11))  # range(1, 11): 1~10
```

- **1부터 10까지 더하기**

  ```python
  add = 0
  for i in range(1, 11):
      add += i
  print(add)  # 55
  ```

- **`len`과 함께 인덱스로 순회하기** — 앞의 `number` 변수를 `range`로 대체

  ```python
  marks = [90, 25, 67, 45, 80]
  for number in range(len(marks)):   # range(5) → 0~4
      if marks[number] < 60: continue
      print(f"{number + 1}번 학생 축하합니다. 합격입니다.")
  # 1번 학생 축하합니다. 합격입니다.
  # 3번 학생 축하합니다. 합격입니다.
  # 5번 학생 축하합니다. 합격입니다.
  ```

## 구구단 (for + range)

`for`를 중첩하면 구구단을 짧게 만들 수 있다. `print`의 `end` 매개변수로 줄바꿈 여부를 조절한다.

```python
for i in range(2, 10):        # 2~9
    for j in range(1, 10):    # 1~9
        print(i*j, end=" ")   # 줄바꾸지 않고 뒤에 공백만 추가
    print('')                 # 줄바꿈
# 2 4 6 8 10 12 14 16 18
# 3 6 9 12 15 18 21 24 27
# ...
# 9 18 27 36 45 54 63 72 81
```

> `print`의 `end` 기본값은 줄바꿈 문자(`\n`)이다. `end=" "`를 주면 같은 줄에 이어서 출력된다.

## 리스트 컴프리헨션

리스트 안에 `for` 문을 포함해 새 리스트를 간결하게 만드는 기법이다.

```python
[표현식 for 항목 in 반복_가능_객체 if 조건문]   # if 조건문은 생략 가능
```

```python
# 일반 for 문
a = [1, 2, 3, 4]
result = []
for num in a:
    result.append(num * 3)
print(result)  # [3, 6, 9, 12]

# 리스트 컴프리헨션
result = [num * 3 for num in a]
print(result)  # [3, 6, 9, 12]
```

- **조건 추가** — 짝수에만 3을 곱해 담기

  ```python
  a = [1, 2, 3, 4]
  result = [num * 3 for num in a if num % 2 == 0]
  print(result)  # [6, 12]
  ```

- **for 문 여러 개 사용** — 구구단의 모든 결과를 담기

  ```python
  result = [x * y for x in range(2, 10)
                  for y in range(1, 10)]
  print(result)  # [2, 4, 6, ..., 72, 81]
  ```

## break

`break`를 만나면 for 문을 강제로 빠져나간다.

```python
for i in range(10):
    if i == 5: break
    print(i)
# 0
# 1
# 2
# 3
# 4
```

## for-else 문

for 문이 **끝까지 수행되면** `else` 절이 실행되고, **`break`로 빠져나가면 실행되지 않는다.**

```python
# 정상 종료 → else 실행
for i in range(5):
    print(i)
else:
    print("for 문이 정상 종료되었습니다.")
# 0
# 1
# 2
# 3
# 4
# for 문이 정상 종료되었습니다.
```

```python
# break로 종료 → else 실행 안 됨
for i in range(5):
    if i == 3: break
    print(i)
else:
    print("for 문이 정상 종료되었습니다.")
# 0
# 1
# 2
```

> 리스트에서 원하는 값을 찾았는지 판단할 때 유용하다. `break` 없이 끝났다면 "찾지 못했다"는 의미로 `else`를 활용할 수 있다.

## enumerate 함수

인덱스와 요소를 함께 꺼낼 때 사용한다.

```python
fruits = ['apple', 'banana', 'orange']
for i, fruit in enumerate(fruits):
    print(f"{i}: {fruit}")
# 0: apple
# 1: banana
# 2: orange
```

- **시작 번호 변경** — 두 번째 인자로 시작값을 지정

  ```python
  for i, fruit in enumerate(fruits, 1):   # 1부터 시작
      print(f"{i}: {fruit}")
  # 1: apple
  # 2: banana
  # 3: orange
  ```

## zip 함수

여러 리스트를 앞에서부터 쌍으로 묶어 함께 순회한다.

```python
names = ['홍길동', '김철수', '이영희']
scores = [85, 92, 78]
for name, score in zip(names, scores):
    print(f"{name}: {score}점")
# 홍길동: 85점
# 김철수: 92점
# 이영희: 78점
```

- **세 개 이상도 가능**

  ```python
  names = ['홍길동', '김철수', '이영희']
  korean = [85, 92, 78]
  english = [90, 88, 95]
  for name, kor, eng in zip(names, korean, english):
      print(f"{name}: 국어 {kor}점, 영어 {eng}점")
  # 홍길동: 국어 85점, 영어 90점
  # 김철수: 국어 92점, 영어 88점
  # 이영희: 국어 78점, 영어 95점
  ```

> `zip`은 앞에서부터 쌍을 이루는 값만 묶고, **넘치는 값은 버린다.**
>
> ```python
> names = ['홍길동', '김철수', '이영희', '양중창']  # 4개
> scores = [85, 92, 78]                             # 3개
> print(list(zip(names, scores)))
> # [('홍길동', 85), ('김철수', 92), ('이영희', 78)]  → '양중창'은 버려짐
> ```

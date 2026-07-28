# 반복문(while)

> 예제 코드: [Source/while.py](Source/while.py)

- [기본 구조](#기본-구조)
- [break — 강제로 빠져나가기](#break--강제로-빠져나가기)
- [continue — 맨 처음으로 돌아가기](#continue--맨-처음으로-돌아가기)
- [무한 루프](#무한-루프)
- [while-else 문](#while-else-문)
- [중첩된 while 문](#중첩된-while-문)

## 기본 구조

조건문이 **참인 동안** 블록을 반복해서 수행한다. 조건이 거짓이 되면 반복을 멈추고 빠져나간다.

```python
while 조건:
    실행 코드
```

```python
# 열 번 찍어 안 넘어가는 나무 없다
treeHit = 0
while treeHit < 10:
    treeHit += 1
    print(f"나무를 {treeHit}번 찍었습니다.")
    if treeHit == 10:
        print("나무 넘어갑니다.")
# 나무를 1번 찍었습니다.
# ...
# 나무를 10번 찍었습니다.
# 나무 넘어갑니다.
```

- `treeHit`가 매 반복마다 1씩 증가하고, 10이 되면 `treeHit < 10`이 거짓이 되어 반복을 멈춘다.
- 조건에 쓰이는 변수는 while 문 이전에 미리 정의해 두어야 한다. (그렇지 않으면 조건 평가 시 "정의되지 않음" 오류)

- **사용자 입력으로 반복 제어하기**

  특정 값이 들어올 때까지 계속 입력받는 형태로도 자주 쓰인다.

  ```python
  prompt = """
  1. Add
  2. Del
  3. List
  4. Quit
  """
  number = 0
  while number != 4:      # 4가 들어오면 종료
      print(prompt)
      number = int(input())   # input(): 사용자 입력 받기
  # (메뉴를 출력하고 입력을 기다리며, 4를 입력하면 종료)
  #
  # 1. Add
  # 2. Del
  # 3. List
  # 4. Quit
  ```

## break — 강제로 빠져나가기

조건이 참이더라도 `break`를 만나면 즉시 while 문을 빠져나간다.

```python
# 커피가 남아있는 동안만 커피가 나온다
coffee = 10
money = 300
while money:            # money가 0이 아니므로 항상 참 → 무한 루프
    print("돈을 받았으니 커피를 줍니다.")
    coffee -= 1
    print(f"남은 커피의 양은 {coffee}개입니다.")
    if coffee == 0:
        print("커피가 다 떨어졌습니다. 판매를 중지합니다.")
        break           # 여기서 중단
# 돈을 받았으니 커피를 줍니다.
# 남은 커피의 양은 9개입니다.
# ...
# 돈을 받았으니 커피를 줍니다.
# 남은 커피의 양은 0개입니다.
# 커피가 다 떨어졌습니다. 판매를 중지합니다.
```

> `while money:`는 조건이 항상 참이라 그대로 두면 무한히 돈다. `coffee`가 0이 되는 순간 `break`로 탈출하는 구조다.

## continue — 맨 처음으로 돌아가기

`continue`를 만나면 이후 문장을 실행하지 않고 곧바로 while 문의 조건 검사로 돌아간다.

```python
# 홀수만 출력하기
a = 0
while a < 10:
    a += 1
    if a % 2 == 0: continue   # 짝수이면 print를 건너뛰고 다음 루프로
    print(a)
# 1
# 3
# 5
# 7
# 9
```

## 무한 루프

조건에 `True`를 주면 무한히 반복한다. 서버, 이벤트 처리, 입력 대기 같은 상황에서 자주 사용하며, 보통 안에서 `break`로 빠져나갈 조건을 함께 둔다.

```python
while True:
    실행 코드
```

```python
# 조금 더 사실적인 커피 자판기
coffee = 10
while True:
    money = int(input("돈을 넣어주세요: "))
    if money == 300:
        print("커피를 줍니다.")
        coffee -= 1
    elif money > 300:
        print(f"거스름돈 {money - 300}를 주고 커피를 줍니다.")
        coffee -= 1
    else:
        print("돈을 다시 돌려주고 커피를 주지 않습니다.")
        print(f"남은 커피의 양은 {coffee}개입니다.")

    if coffee == 0:
        print("커피가 다 떨어졌습니다. 판매를 중지합니다.")
        break
# 돈을 넣어주세요: 500
# 거스름돈 200를 주고 커피를 줍니다.
# 돈을 넣어주세요: 300
# 커피를 줍니다.
# 돈을 넣어주세요: 100
# 돈을 다시 돌려주고 커피를 주지 않습니다.
# 남은 커피의 양은 8개입니다.
# 돈을 넣어주세요:
```

## while-else 문

while 문에 `else`를 붙일 수 있다. **조건이 거짓이 되어 정상적으로 끝나면** `else` 절이 실행되고, **`break`로 빠져나가면 실행되지 않는다.**

```python
# 정상 종료 → else 실행
count = 0
while count < 3:
    print(f"카운트: {count}")
    count += 1
else:
    print("while 문이 정상 종료되었습니다.")
# 카운트: 0
# 카운트: 1
# 카운트: 2
# while 문이 정상 종료되었습니다.
```

```python
# break로 종료 → else 실행 안 됨
count = 0
while count < 5:
    print(f"카운트: {count}")
    if count == 2: break   # count가 2일 때 종료
    count += 1
else:
    print("while 문이 정상 종료되었습니다.")
# 카운트: 0
# 카운트: 1
# 카운트: 2
```

> 자주 쓰이지는 않지만, 반복이 중간에 끊기지 않고 끝까지 완료되었는지 확인할 때 유용하다.

## 중첩된 while 문

while 문 안에 또 다른 while 문을 둘 수 있다. 바깥쪽 반복 한 번마다 안쪽 반복이 처음부터 끝까지 수행된다.

```python
# 구구단 2단, 3단
i = 2
while i <= 3:
    j = 1
    while j <= 9:
        print(f"{i} x {j} = {i*j}")
        j += 1
    i += 1
# 2 x 1 = 2
# ...
# 2 x 9 = 18
# 3 x 1 = 3
# ...
# 3 x 9 = 27
```

> 중첩된 while 문에서 `break`나 `continue`는 **가장 가까운(안쪽) while 문에만** 영향을 준다.

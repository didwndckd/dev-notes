# 파일 읽고 쓰기(file I/O)

> 예제 코드: [Source/file_IO.py](Source/file_IO.py)

- [파일 열기와 파일 열기 모드](#파일-열기와-파일-열기-모드)
- [파일에 내용 쓰기 (w)](#파일에-내용-쓰기-w)
- [파일을 읽는 여러 가지 방법](#파일을-읽는-여러-가지-방법)
- [파일에 새로운 내용 추가하기 (a)](#파일에-새로운-내용-추가하기-a)
- [with문과 함께 사용하기](#with문과-함께-사용하기)
- [with문 안에서 만든 변수 사용하기](#with문-안에서-만든-변수-사용하기)
- [파일 처리 시 주의사항](#파일-처리-시-주의사항)

## 파일 열기와 파일 열기 모드

내장 함수 `open`은 '파일 경로(이름)'와 '파일 열기 모드'를 입력값으로 받아 **파일 객체**를 반환한다.

```python
파일_객체 = open(파일_경로(이름), 파일_열기_모드)
```

| 파일 열기 모드 | 설명 |
| --- | --- |
| `r` | 읽기 모드 — 파일을 읽기만 할 때 사용. 해당 경로에 파일이 없으면 에러 |
| `w` | 쓰기 모드 — 파일에 내용을 쓸 때 사용. 파일이 이미 존재하면 원래 내용이 모두 사라지고, 없으면 새로 생성된다 |
| `a` | 추가 모드 — 파일의 마지막에 새로운 내용을 추가할 때 사용. 파일이 없으면 생성, 있으면 내용 추가 |

파일을 열었으면 `close()`로 닫아 준다. 프로그램이 끝날 때 파이썬이 자동으로 닫아 주긴 하지만, 쓰기 모드로 열었던 파일을 닫지 않고 다시 사용하면 오류가 나므로 직접 닫는 것이 좋다.

```python
from pathlib import Path   # 테스트용 임시 디렉터리를 만들기 위해 추가

base_path = "temp"
Path(base_path).mkdir(exist_ok=True)   # 임시 폴더 생성
file_path = f"{base_path}/새파일.txt"
```

> `open`은 파일은 만들어 주지만 **디렉터리는 만들어 주지 않는다.** 경로상의 디렉터리가 없으면 에러가 나므로 미리 만들어 둬야 한다.
>
> 경로에 역슬래시(`\`)를 쓸 때는 `"C:\\doit\\새파일.txt"`처럼 2개를 쓰거나 `r"C:\doit\새파일.txt"`처럼 앞에 `r`(raw string)을 붙인다. `\n` 같은 이스케이프 문자로 해석되는 것을 막기 위해서다.

## 파일에 내용 쓰기 (w)

화면에 출력할 때 `print`를 쓰듯, 파일에 쓸 때는 파일 객체의 `write`를 쓴다. 둘의 차이는 데이터가 향하는 곳(모니터 화면 / 파일)뿐이다.

```python
f = open(file_path, 'w')   # 쓰기 모드로 파일 열기
for i in range(1, 11):
    data = f"{i}번째 줄입니다.\n"
    f.write(data)          # 파일에 내용 쓰기
f.close()                  # 파일 닫기
# temp/새파일.txt
# 1번째 줄입니다.
# 2번째 줄입니다.
# ...
# 10번째 줄입니다.
```

## 파일을 읽는 여러 가지 방법

읽기 모드(`r`)로 연 파일 객체에서 내용을 꺼내는 방법은 네 가지가 있다.

- **`readline`** — 한 줄만 꺼내온다.

  ```python
  f = open(file_path, 'r')
  line = f.readline()
  print(line)
  f.close()
  # 1번째 줄입니다.
  #
  ```

  > 줄 끝의 `\n`이 그대로 남아 있어서 `print`의 줄바꿈과 겹쳐 빈 줄이 하나 더 출력된다.

- **`readline` + 무한 루프** — 모든 줄을 한 줄씩 읽는다. `readline`은 더 이상 읽을 줄이 없으면 빈 문자열(`""`)을 반환하므로, 이를 종료 조건으로 삼는다.

  ```python
  f = open(file_path, 'r')
  while True:
      line = f.readline()   # 한 줄씩 읽음, 더 읽을 줄이 없으면 "" 반환
      if not line: break    # 더 이상 읽을 라인이 없으면 루프 탈출
      print(line)
  f.close()
  # 1번째 줄입니다.
  #
  # 2번째 줄입니다.
  #
  # ...
  ```

- **`readlines`** — 모든 줄을 읽어 각 줄을 요소로 가지는 **리스트**를 반환한다. 즉 `["1번째 줄입니다.\n", "2번째 줄입니다.\n", ..., "10번째 줄입니다.\n"]`이 된다.

  ```python
  f = open(file_path, 'r')
  lines = f.readlines()
  for line in lines:
      line = line.strip()   # 줄 끝의 줄 바꿈 문자 제거
      print(line)
  f.close()
  # 1번째 줄입니다.
  # 2번째 줄입니다.
  # ...
  # 10번째 줄입니다.
  ```

  > `readline`과 `readlines`는 `s` 하나 차이라 헷갈리기 쉽다. 줄 끝의 `\n`이 거슬리면 `strip()`으로 제거한다.

- **`read`** — 파일의 내용 **전체를 하나의 문자열**로 반환한다.

  ```python
  f = open(file_path, 'r')
  data = f.read()
  print(data)
  f.close()
  # 1번째 줄입니다.
  # 2번째 줄입니다.
  # ...
  # 10번째 줄입니다.
  ```

- **파일 객체를 `for`문과 함께 사용** — 파일 객체는 기본적으로 `for`문으로 줄 단위 순회가 가능하다.

  ```python
  f = open(file_path, 'r')
  for line in f:
      print(line)
  f.close()
  # 1번째 줄입니다.
  #
  # 2번째 줄입니다.
  #
  # ...
  ```

## 파일에 새로운 내용 추가하기 (a)

쓰기 모드(`w`)로 기존 파일을 열면 내용이 모두 사라진다. 원래 내용을 유지하면서 뒤에 덧붙이려면 추가 모드(`a`)로 연다.

```python
f = open(file_path, 'a')
for i in range(11, 20):
    data = f"{i}번째 줄입니다.\n"
    f.write(data)
f.close()
# temp/새파일.txt: 기존 내용 뒤에 11~19가 추가됨
# 1번째 줄입니다.
# ...
# 10번째 줄입니다.
# 11번째 줄입니다.
# ...
# 19번째 줄입니다.
```

## with문과 함께 사용하기

파일은 열었으면(`open`) 닫아야(`close`) 한다. `with`문을 쓰면 **블록을 벗어나는 순간 파일 객체가 자동으로 닫힌다.**

```python
# 기존 방식: 직접 열고 닫기
f = open(file_path, 'w')
f.write("Life is too short, you need python")
f.close()

# with 문: close()가 필요 없다
with open(file_path, 'w') as f:
    f.write("Life is too short, you need python")
```

- **`closed`로 파일이 닫혔는지 확인하기** — 파일이 닫혔으면 `True`, 열려 있으면 `False`를 반환한다.

  ```python
  with open(file_path, 'w') as file:
      file.write("Hello")
      print(file.closed)   # False: 아직 열려있음
  print(file.closed)       # True: with 블록을 벗어나 자동으로 닫힘
  ```

> `with`는 파일 전용 문법이 아니다. `__enter__`(진입 시 실행)와 `__exit__`(빠져나갈 때 실행) 메서드를 가진 객체 — **컨텍스트 매니저(context manager)** — 라면 무엇이든 `with`와 함께 쓸 수 있다. 파일 객체가 이 두 메서드를 갖고 있어서 `with`가 동작하는 것뿐이고, 락(`threading.Lock`)·DB 연결·소켓처럼 "잡았으면 놓아야 하는" 자원에도 똑같이 쓰인다. 블록 안에서 예외가 나도 `__exit__`은 반드시 실행되므로 `try`/`finally`보다 안전하고 짧다.

## with문 안에서 만든 변수 사용하기

파이썬에서 `if`, `for`, `while`, `with` 블록은 변수의 사용 범위를 제한하지 않는다(함수와는 다르다). 따라서 `with` 블록 안에서 만든 변수는 블록이 끝난 뒤에도 쓸 수 있다.

```python
with open(file_path, 'w') as f:
    content = "Hello, Python!"
    f.write(content)

print(content)   # Hello, Python!
```

> 단, 파일 객체 `f`는 `with` 블록을 벗어나면 자동으로 닫히므로 블록 밖에서 `f.write()`나 `f.read()` 같은 파일 작업은 할 수 없다. 닫힌 파일에 작업을 시도하면 오류가 발생한다.

## 파일 처리 시 주의사항

한글이 포함된 파일을 다룰 때는 **인코딩을 명시**하는 것이 좋다. 명시하지 않으면 운영체제마다 다른 기본 인코딩을 사용해 한글이 깨질 수 있다.

```python
file_path = f"{base_path}/한글파일.txt"

# 한글 파일 쓰기
with open(file_path, 'w', encoding="utf-8") as f:
    f.write("안녕하세요, 파이썬!")

# 한글 파일 읽기
with open(file_path, 'r', encoding="utf-8") as f:
    content = f.read()
    print(content)   # 안녕하세요, 파이썬!
```

> 컴퓨터는 문자를 숫자로 변환해 저장하는데, 어떤 문자를 어떤 숫자로 바꿀지 정하는 규칙이 **인코딩(Encoding)**이다. `UTF-8`은 한글·영어·이모지 등 전 세계 문자를 표현할 수 있는 가장 널리 쓰이는 방식이라, 이를 사용하면 어떤 컴퓨터에서든 한글이 깨지지 않는다.

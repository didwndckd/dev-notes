# 프로그램의 입출력(sys.argv)

> 예제 코드: [Source/program_IO.py](Source/program_IO.py)

- [명령어와 인수](#명령어와-인수)
- [sys 모듈로 인수 전달받기](#sys-모듈로-인수-전달받기)
- [응용: 전달받은 인수를 대문자로 바꾸기](#응용-전달받은-인수를-대문자로-바꾸기)

## 명령어와 인수

터미널에서 파일 내용을 출력하는 `cat a.txt` 같은 명령어를 떠올려 보자. `cat`은 뒤에 적힌 파일 이름을 **인수**로 받아 동작한다. 대부분의 명령어는 이렇게 인수를 전달받아 실행된다.

```
명령어 [인수1 인수2 ...]
```

> 윈도우 명령 프롬프트에서는 `cat a.txt` 대신 `type a.txt`를 사용한다.

파이썬 프로그램도 똑같이 실행할 때 인수를 전달받을 수 있다.

## sys 모듈로 인수 전달받기

`sys` 모듈의 `argv`는 프로그램 실행 시 전달된 인수를 담고 있는 **리스트**다. `import sys`로 모듈을 불러와서 쓴다.

- `argv[0]` — 실행한 프로그램의 파일 이름(경로)
- `argv[1]` 이후 — 뒤에 따라오는 인수가 차례대로 저장된다

```python
import sys

args = sys.argv[:]   # 전체(프로그램 이름 포함)
for i in args:
    print(i)
# 실행: python3 Python/Source/program_IO.py aaa bbb ccc
# Python/Source/program_IO.py   ← argv[0]: 해당 프로그램
# aaa                           ← argv[1]부터 전달 인수
# bbb
# ccc
```

보통은 프로그램 이름이 필요 없으므로 `sys.argv[1:]`처럼 슬라이싱해 인수만 꺼내 쓴다.

> `import`와 모듈을 만드는 방법은 05장에서 자세히 다룬다.

## 응용: 전달받은 인수를 대문자로 바꾸기

문자열 함수 `upper()`를 사용해 전달된 인수를 모두 대문자로 바꿔 출력하는 프로그램이다. `end=' '`를 줘서 한 줄에 이어 출력한다.

```python
import sys

args = sys.argv[1:]   # 인수부터
for i in args:
    print(i.upper(), end=' ')
# 실행: python3 Python/Source/program_IO.py life is too short, you need python
# LIFE IS TOO SHORT, YOU NEED PYTHON
```

> 인수는 공백을 기준으로 나뉜다. 공백이 포함된 값 하나를 통째로 전달하려면 `"too short"`처럼 따옴표로 묶어야 한다.

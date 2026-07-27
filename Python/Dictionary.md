# 딕셔너리(Dictionary)

> 예제 코드: [Source/dictionary.py](Source/dictionary.py)

- [딕셔너리 만들기](#딕셔너리-만들기)
- [쌍 추가와 삭제](#쌍-추가와-삭제)
- [Key로 Value 얻기](#key로-value-얻기)
- [선언 시 주의점](#선언-시-주의점)
- [관련 함수](#관련-함수)

## 딕셔너리 만들기

`Key: Value` 쌍으로 값을 저장하는 자료형. `{}` 중괄호로 묶으며, Key로 Value를 찾는다. (순서가 아니라 Key로 접근)

```python
dic = {'name': 'yjc', 'phone': '010-9999-1234', 'birth': '1118'}

a = {1: 'hi'}          # 정수 key, 문자열 value
a = {'a': [1, 2, 3]}   # 리스트도 value로 가능
a = {'a': 1, 1: 'a'}   # key, value 타입 혼용 가능
```

## 쌍 추가와 삭제

- **추가** — `딕셔너리[Key] = Value` 로 새 쌍을 넣는다.

  ```python
  a = {1: 'a'}
  a[2] = 'b'
  print(a)  # {1: 'a', 2: 'b'}

  a['name'] = 'yjc'
  a[3] = [1, 2, 3]
  print(a)  # {1: 'a', 2: 'b', 'name': 'yjc', 3: [1, 2, 3]}
  ```

- **삭제** — `del 딕셔너리[Key]`. 없는 Key를 지우면 에러.

  ```python
  a = {1: 'a', 2: 'b', 'name': 'yjc'}
  del a[1]
  print(a)  # {2: 'b', 'name': 'yjc'}

  del a[1]  # KeyError: 이미 없는 키
  ```

## Key로 Value 얻기

`딕셔너리[Key]` 로 값을 꺼낸다. **없는 Key로 접근하면 에러**가 난다. (에러 없이 얻으려면 아래 [`get`](#관련-함수) 사용)

```python
grade = {'yjc': 10, 'bms': 9}
print(grade['yjc'])    # 10
print(grade['bms'])    # 9
print(grade['nokey'])  # KeyError <- 없는 키
```

## 선언 시 주의점

- **Key는 중복될 수 없다** — 같은 Key를 여러 번 쓰면 마지막 값으로 덮어써진다.

  ```python
  a = {1: 'a', 1: 'b'}
  print(a)  # {1: 'b'}
  ```

- **Key로 쓸 수 있는 값** — 값이 변하지 않는(불변) 자료형만 Key가 될 수 있다. 리스트는 불가, 튜플은 가능.

  ```python
  a = {[1, 2, 3]: 123}  # TypeError: 리스트는 key 불가
  a = {(1, 2): 12}      # OK: 튜플은 key 가능
  print(a)  # {(1, 2): 12}
  ```

## 관련 함수

아래 표는 모두 다음 초기 상태에서 시작한다.

```python
a = {'name': 'yjc', 'phone': '010-9999-1234', 'birth': '1118'}
```

| 함수 | 의미 | 예시 | 결과 |
| --- | --- | --- | --- |
| `keys()` | Key 목록 | `a.keys()` | `dict_keys(['name', 'phone', 'birth'])` |
| `values()` | Value 목록 | `a.values()` | `dict_values(['yjc', '010-9999-1234', '1118'])` |
| `items()` | `(Key, Value)` 쌍 목록 | `a.items()` | `dict_items([('name', 'yjc'), ('phone', '010-9999-1234'), ('birth', '1118')])` |
| `get(Key)` | Key로 Value 얻기 | `a.get('name')` | `'yjc'` |
| `get(Key)` | 없는 Key면 `None` | `a.get('nokey')` | `None` |
| `get(Key, 기본값)` | 없을 때 기본값 반환 | `a.get('nokey', '정보없음')` | `'정보없음'` |
| `pop(Key)` | Value 꺼내고 요소 제거 | `a.pop('phone')` | `'010-9999-1234'` 반환, `a` → `{'name': 'yjc', 'birth': '1118'}` |
| `pop(Key, 기본값)` | 없을 때 기본값 반환 | `a.pop('nokey', '정보없음')` | `'정보없음'` |
| `clear()` | 모든 요소 삭제 | `a.clear()` | `a` → `{}` |
| `Key in 딕셔너리` | Key 존재 여부 | `'name' in a` | `True` |

- **`keys()`, `values()`, `items()`** 는 리스트가 아니라 전용 객체(`dict_keys` 등)를 반환한다. 반복문에 바로 쓸 수 있고, 리스트가 필요하면 `list()`로 변환한다.

  ```python
  a = {'name': 'yjc', 'phone': '010-9999-1234', 'birth': '1118'}

  for k in a.keys():
      print(k)  # name, phone, birth

  print(list(a.keys()))  # ['name', 'phone', 'birth']
  ```

- **`get` 은 `딕셔너리[Key]` 와 달리 없는 Key에도 에러가 나지 않는다.**

  ```python
  a = {'name': 'yjc'}
  print(a.get('name'))            # yjc
  print(a.get('nokey'))           # None
  print(a.get('nokey', '정보없음'))  # 정보없음  <- 기본값 지정
  ```

- **`in` 으로 Key 존재 여부를 확인**한다. (Value가 아니라 Key 기준)

  ```python
  a = {'name': 'yjc', 'phone': '010-9999-1234'}
  print('name' in a)   # True
  print('nokey' in a)  # False
  ```

- **`pop` 도 `get` 처럼 기본값을 줄 수 있다.**

  ```python
  a = {'name': 'yjc', 'phone': '010-9999-1234', 'birth': '1118'}
  print(a.pop('phone'))          # 010-9999-1234
  print(a)                       # {'name': 'yjc', 'birth': '1118'}
  print(a.pop('nokey'))          # KeyError <- 기본값 없으면 에러
  print(a.pop('nokey', '정보없음'))  # 정보없음
  ```

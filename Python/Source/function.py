# 함수 선언
# def 함수_이름(매개변수):
#   실행 코드

def add(a, b):
    return a + b

a = 3
b = 4
c = add(a, b)
print(c) # 7

# 매개변수와 인수
def add(a, b): # a, b는 매개변수
    return a + b
add(3, 4) # 3, 4는 인수

# 입력값이 없는 함수
def say():
    return 'Hi'
a = say()
print(a) # Hi

# 반환값이 없는 함수
def add(a, b):
    print(f"{a}, {b}의 합은 {a+b}입니다.")
a = add(3, 4) # 3, 4의 합은 7입니다.
print(a) # None

# 입력값도, 반환값도 없는 함수
def say():
    print('Hi')
say() # Hi

# 매개변수를 지정하여 호출하기
def sub(a, b):
    return a - b
result = sub(a=7, b=3) #a에 7, b에 3을 전달
print(result) # 4
# 매개변수를 지정하면 순서 상관없이 사용 가능
result = sub(b=5, a=3) # b에 5, a에 3을 전달
print(result) # -2

# 입력값이 몇개가 될지 모르는 경우
# def 함수_이름(*매개변수):
#   실행 코드
def add_money(*args):
    result = 0
    for i in args:
        result += i
    return result
result = add_money(1, 2, 3)
print(result) # 6
result = add_money(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
print(result) # 55

# 여러개의 입력 + 단일 입력
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
result = add_mul('add', 1, 2, 3, 4, 5)
print(result) # 15
result = add_mul('mul', 1, 2, 3, 4, 5)
print(result) # 120

# 키워드 매개변후, kwargs
# 키워드=값 형태로 매개변수를 받을 때 사용
# def 함수_이름(**매개변수):
#   수행 코드
def print_kwargs(**kwargs):
    print(kwargs)
print_kwargs(a=1) # {'a': 1}
print_kwargs(name='foo', age=3) # {'name': 'foo', 'age': 3}
print_kwargs(name='홍길동', age=25, city='서울', job='개발자') # {'name': '홍길동', 'age': 25, 'city': '서울', 'job': '개발자'}
# 키워드 매개변수의 실용적 예
def create_profile(**info):
    print("=== 프로필 정보 ===")
    for key, value in info.items():
        print(f"{key}: {value}")
create_profile(이름='김철수', 나이='30', 직업='프로그래머', 취미='독서')
# 실행 결과
# === 프로필 정보 ===
# 이름: 김철수
# 나이: 30
# 직업: 프로그래머
# 취미: 독서

# 일반 매개변수, 가변 매채변수(*args), 키워드 배개변수(**kwargs) 함께 사용
def mixed_function(name, *args, **kwargs):
    print(f"이름: {name}")
    print(f"추가 인수들: {args}")
    print(f"키워드 인수들: {kwargs}")

mixed_function('홍길동', 1, 2, 3, age=25, city='서울')
# 실행 결과
# 이름: 홍길동
# 추가 인수들: (1, 2, 3)
# 키워드 인수들: {'age': 25, 'city': '서울'}

# 반환값은 언제나 하나이다

# 쉼표로 여러 값을 반환한 경우: 튜플로 나옴
def add_and_mul(a, b):
    return a+b, a*b
result = add_and_mul(3, 4)
print(result) # (7, 12) (더한값, 곱한값)

# return을 여러번 한 경우: 먼저 return한 값만 나온다.
def add_and_mul(a, b):
    return a+b
    return a*b
result = add_and_mul(2, 3)
print(result) # 5, 곱한값은 나오지 않음

# return의 또다른 쓰임새(조기 반환)
def say_nick(nick):
    if nick == '바보': return
    print(f"나의 별명은 {nick}입니다.")
say_nick('야호') # 나의 별명은 야호입니다.
say_nick('바보') # 아무것도 하지않음.


# 매개변수 초기값 미리 설정하기
def say_myself(name, age, man=True):
    print(f"나의 이름은 {name}입니다.")
    print(f"나이는 {age}살입니다.")
    if man:
        print("남자입니다.")
    else:
        print("여자입니다.")
say_myself("양중창", 35) # man 기본값 True 적용
# 실행 결과
# 나의 이름은 양중창입니다.
# 나이는 35살입니다.
# 남자입니다.
say_myself("양중창", 35, False)
# 실행 결과
# 나의 이름은 양중창입니다.
# 나이는 35살입니다.
# 여자입니다.

# 매개변수 초기값 설정시 주의점
# 초기값을 설정하고싶은 매개변수는 항상 뒤쪽에 놓아야 한다.
# def say_myself(name, man=True, age): # SyntaxError
#     print(f"나의 이름은 {name}입니다.")
#     print(f"나이는 {age}살입니다.")
#     if man:
#         print("남자입니다.")
#     else:
#         print("여자입니다.")
# 예를 들어 say_myself('양중창', 27)이라고 호출한다고 했을 때 인터프리터는 27을 man에 넣을지 age에 넣을지 판단할 수 없다.

# 함수 안에서 선언한 변수의 효력 범위

# 함수 외부에 같은 이름의 변수가 선언 되어있어도 내부에서 선언한 변수를 사용함.
a = 1
def vartest(a):
    a = a + 1 # 내부 선언된 a와 외부의 a가 다름
vartest(a)
print(a) # 1: 외부 a에는 영향이 없음

# 매개변수 이름을 바꿔도 마찬가지
def vartest(hello):
    hello = hello + 1
vartest(a)
print(a) # 1

# 외부 변수 읽기는 가능함
out = 1
def vartest(input):
    return out + input # 외부 변수 out=1
result = vartest(2)
print(result) # 3

# 외부 변수에 새로운 값을 대입하는것은 안됨
out = 1
def vartest(input):
    out = input # 결국 out이라는 변수를 함수 내에 새로 선언한것
vartest(2)
print(out) # 1

# 리스트와 같이 객체의 변경 함수를 호출하는건 됨
arr = [1, 2, 3]
def vartest(input):
    arr.append(input)
vartest(4)
print(arr) # [1, 2, 3, 4]

# 함수 안에서 함수 밖의 변수 변경하기
# return 사용(사실 이건 함수 안에서 변경이라고 보긴 어렵다, 결과 반환 받아서 외부에서 바꿔준거라서)
a = 1
def vartest(a):
    a = a + 1
    return a
a = vartest(a)
print(a)

# global 명령어 사용
a = 1
def vartest():
    global a # 함수 밖에 있는 a를 직접 사용 하겠다.
    a = a + 1
vartest()
print(a) # 2

# 함수 선언시에 없던 변수도 호출 전에만 선언해두면 정상 동작 한다.
def vartest():
    global unknown
    unknown += 1
 
unknown = 1
vartest() # 2

# 리스트나 딕셔너리는와 같은 mutable 자료형은 외부 변수를 직접 참조하지 않고 매개변수를 사용해도 함수 내에서 변경 가능하다.
def change_list(list):
    list.append(4) # 리스트에 값을 추가
a = [1, 2, 3]
change_list(a)
print(a) # [1, 2, 3, 4]


# lambda: 이름 없는 함수, 변수 할당 또는 매개변수로 전달 가능?
# 함수_이름 = lambda 매개변수1, 매개변수2, ... : 매개변수를_이용한_표현식
add = lambda a, b: a+b # lambda로 만든 함수는 return 명령어가 없어도 결괏값을 반환한다.
result = add(3, 4)
print(result) # 7

# 함수도 변수에 할당 가능
def add_function(a, b):
    return a+b
add_var = add_function
result = add_var(1, 2)
print(result) # 3

# 함수의 독스트링(Docstring)
# 함수에 대한 설명을 문서화 하는 방법
# 함수 첫줄에 삼중 따옴표로 둘러싼 문자열을 작성
def add(a, b):
    """
    두 숫자를 더하는 함수

    Parameters:
    a (int, float): 첫 번째 숫자
    b (int, float): 두 번째 숫자

    Returns:
    int, floats: 두 숫자의 합
    """
    return a + b
print(add.__doc__)
# 결과
# 두 숫자를 더하는 함수

# Parameters:
# a (int, float): 첫 번째 숫자
# b (int, float): 두 번째 숫자

# Returns:
# int, floats: 두 숫자의 합

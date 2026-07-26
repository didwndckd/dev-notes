# 문자열 만드는 방법
# 큰따옴표
"Hello World"
# 작은따옴표
'Python is fun'
# 큰따옴표 * 3
"""List is too short, You need python"""
# 작은따옴표 * 3
'''Life is too short, You need python'''

# 1. 작은 따옴표 포함하기 "로 감싼다
# 예시 문자: Python's favorite food is perl

food = "Python's favorite food is perl"
print(food) # 정상 출력

# food = 'Python's favorite food is perl' <- 구문 오류

# 2. 문자열에 큰따옴표 포함하기: '로 감싼다
# 예시 문자: "Python is very easy." he says.
say = '"Python is very easy." he says.'
print(say) # 정상 출력

# 3. 역슬래시를 사용해서 작은따옴표와 큰따옴표를 문자열에 포함하기
food = 'Python\'s favorite food is perl'
say = "\"Python is very easy. he says."


# 여러줄인 문자열을 변수에 대입하고 싶을 때
# 예시 문장: Life is too short
#          You need python

# 1. 줄을 바꾸기 위한 이스케이프 코드(\n) 삽입
multiline = "Life is too short\nYou need Python"
print(multiline)

# 2. 연속된 3개 따옴표 사용: """~""" / '''~'''
multiline = '''Life is too short
You need python2'''
print(multiline)
multiline = """Life is too short
You need python"""
print(multiline)

# 이스케이프 코드란?: 프로그래밍에 사용할 수 있도록 미리 정해둔 문자 조합
# \n: 줄바꿈
# \t: 탭 간격
# \\: \를 문자로 표현
# \': 작은따옴표를 문자로 표현
# \": 큰따옴표를 문자로 표현
# \r: 캐리지 리턴(줄 바꿈 문자, 커서를 현재 줄의 가장 앞으로 이동)
# \f: 폼 피드(줄바꿈 문자, 커서를 현재 줄의 다음 줄로 이동)
# \a: 벨소리(출력할 때 PC 스피커에서 '삑' 소리가 남)
# \b: 백스페이스
# \000: 널 문자


# 문자열 연산: 파이썬에서는 문자열을 더하거나 곱할 수 있다.
# 문자열 더해서 연결하기
head = "Python"
tail = " is fun"
print(head + tail) # Python is fun

# 문자열 곱하기
a = "python"
print(a * 2) # pythonpython
# 곱하기 응용
print("=" * 50) 
print("My Prohram") 
print("=" * 50) 
# 결과
# ==================================================
# My Prohram
# ==================================================


# 문자열 길이 구하기
a = "Life is too short"
len = len(a)
print(len) # 17


# 문자열 인덱싱
#    01234567890....
a = "Life is too short, You need Python"
print(a[3]) # e
print(a[0]) # L
print(a[12]) # s
print(a[-1]) # n -인덱스: 문자열 뒤에서부터 따라서 맨 마지막 문자 n
print(a[-0]) # L -를 붙여도 0은 0임 따라서 맨 첫번째 L
print(a[-2]) # o
print(a[-5]) # y


# 문자열 슬라이싱
a = "Life is too short, You need Python"

# 각 인덱스 접근, 결합
print(a[0] + a[1] + a[2] + a[3]) # 'Life'

# 범위 슬라이싱(리스트나 튜플에서도 사용 가능한 기법)
print(a[0:4]) # 'Life' 0:4 -> 0 <= i < 4
print(a[0:3]) # 'Lif' 0:3 -> 0 <= i < 3

# a[시작 번호:끝 번호], 생략 시 문자열의 시작, 끝 인덱스가 반영된다
print(a[19:]) # 'You need Python' 19: -> 19 ~ 마지막까지
print(a[:17]) # 'Life is too short' :17 -> 0 ~ 17까지
print(a[:]) # 'Life is too short, You need Python' : -> 0 ~ 마지막까지

# -인덱스
print(a[19:-7]) # 'You need' -> a[19] ~ a[-8]

# 슬라이싱으로 문자열 나누기 예제
a = "20230331Rainy"
date = a[:8] # 0~7
weather = a[8:] # 8~끝
print(date) # 20230331
print(weather) # Rainy

# 문자열 바꾸기 예제 Pithon -> Python
a = "Pithon"
# a[1] = 'y' error: 문자열의 요솟값은 바꿀 수 없음, immutable 자료형
# 바꾸려면 결국 새로 만들어야함
a = a[:1] + 'y' + a[2:]
print(a) # Python 굳이 이렇게 할것같지는 않지만 immutable이라는 내용이 중요


# 문자열 포매팅(%)

# 숫자 %d
a = "I eat %d apples." % 3
print(a) # I eat 3 apples.

# 문자 %s
a = "I eat %s apples." % "five"
print(a) # I eat five apples.

# 변수 대입
number = 10
a = "I eat %d apples." % number
print(a) # I eat 10 apples.

# 두개 이상의 값 넣기: %(a, b, c, ...)
number = 10
day = "three"
a = "I ate %d apples. so I was sick for %s days." % (number, day)
print(a) # I ate 10 apples. so I was sick for three days.

# %s는 어떠한 형태의 값이든 변환해 넣을 수 있다
a = "I have %s apples." % 3
print(a) # I have 3 apples.

a = "rate is %s" % 3.234
print(a) # rate is 3.234

a = "this is %s" % True
print(a) # this is True

# %d와 %를 같이 쓸때는 %% 사용: ex) 12%
# a = "Error is %d%" % 98
a = "Error is %d%%" % 98
print(a) # Error is 98%

# 문자열 포멧 코드
# %s: 문자열(String)
# %c: 문자(character)
# %d: 정수(Integer)
# %f: 부동소수(floating-point)
# %o: 8진수
# %x: 16진수
# %%: Literal %(문자 % 자체)

# 포맷 코드와 숫자 함께 사용하기

# 문자 사이즈 지정 %{N}s -> N개로 문자열을 고정한다, 모자란 길이는 공백으로 대체
a = "%10s" % "hi" # 전체 길이가 10개인 문자열 공간에 대입되는 값을 오른쪽으로 정렬, 앞의 나머지는 공백
print(a) #         hi

a = "%4s" % "123456" # 값이 지정한 길이보다 길면 그대로 노출됨
print(a) # 123456

a = "%-10s:end" % "hi" # %{-N}: 는 왼쪽 정렬
print(a) # hi        :end

a = "%-4s:end" % "123456" # 마찬가지로 사이즈가 넘치면 그대로 나옴
print(a) # 123456:en

# 소수점 표현 %{S}.{N}f -> S(0은 제한 X)개의 총 사이즈, N개의 소수점 숫자 갯수
a = "%0.4f" % 3.12341234 # 사이즈 제한 X, 소수점 4자리
print(a) # 3.1234

a = "%10.4f" %3.12341234 # 10자리, 소수점 4자리
print(a) #     3.1234

a = "%-10.4f:end" %3.12341234 # 10자리, 소수점 4자리, 좌측 정렬
print(a) # 3.1234    :end

# format 함수를 사용한 포매팅

# 문자
a = "I eat {0} apples.".format(3)
print(a) # I eat 3 apples.

# 숫자
number = 3
a = "I eat {0} apples.".format(number)
print(a) # I eat 3 apples.

# 2개 이상의 값
number = 10
day = "three"
a = "I ate {0} apples. so I was sick for {1} days.".format(number, day)
print(a) # I ate 10 apples. so I was sick for three days.

# 이름으로 넣기
a = "I ate {number} apples. so I was sick for {day} days.".format(number=10, day="three")
print(a) # I ate 10 apples. so I was sick for three days.

# 인덱스와 이름 혼용
a = "I ate {0} apples. so I was sick for {day} days.".format(10, day=3)
print(a) # I ate 10 apples. so I was sick for 3 days.

# 포멧 함수 + 형식 {변수명:형식}, 변수명 생략 시 인덱스 번호, 형식은 기존과 동일

# 왼쪽 정렬(인덱스)
a = "{0:<10}:end".format("hi")
print(a) # hi        :end

# 왼쪽 정렬(이름으로 넣기)
a = "{str:<10}:end".format(str="hi")
print(a) # hi        :end

# 오른쪽 정렬
a = "start:{0:>10}".format("hi")
print(a) # start:        hi

# 가운데 정렬
a = "start:{0:^10}:end".format("hi")
print(a) # start:    hi    :end

# 공백 채우기
a = "{0:=^10}".format("hi")
print(a) # ====hi====
a = "{0:!<10}".format("hi")
print(a) # hi!!!!!!!!

# 소수점 표현하기
y = 3.12341234
a = "{0:0.4f}".format(y)
print(a) # 3.1234
a = "start:{number:10.4f}".format(number=y)
print(a) # start:    3.1234

# {} 문자 표현 하기 {}를 포매팅이 아닌 문자 그대로 하용하고싶은 경우 {{}} 처럼 2개를 연속해서 사용
a = "{{ and }}".format()
print(a)

# f 문자열 포매팅
# 파이썬 3.6 버전부터는 f 문자열 포매팅 기능 사용 가능, 3.6 미만 버전에서는 사용할 수 없으므로 주의
name = "홍길동"
age = 30
a = f'나의 이름은 {name}입니다. 나이는 {age}입니다.'
print(a) # 나의 이름은 홍길동입니다. 나이는 30입니다.

# f 문자열 보매팅은 위와 같이 name, age와 같은 변수값을 생성하고 참조 가능 따라서 다음과 같은것도 된다.
age = 30
a = f"나는 내년이면 {age + 1}살이 된다."
print(a) # 나는 내년이면 31살이 된다.

d = {'name': '홍길동', 'age': 30}
a = f"나의 이름은 {d['name']}입니다. 나이는 {d['age']}입니다."
print(a) # 나의 이름은 홍길동입니다. 나이는 30입니다.

# 정렬
# 왼쪽 정렬
a = f'{"hi":<10}:end'
print(a) # hi        :end
# 오른쪽 정렬
a = f'start:{"hi":>10}'
print(a) # start:        hi
# 가운데 정렬
a = f'start:{"hi":^10}:end'
print(a) # start:    hi    :end
# 공백 채우기
a = f'{"hi":=^10}'
print(a) # ====hi====

# 소수점
y = 3.12341234
# 소수점 4자리만
a = f'{y:0.4f}'
print(a) # 3.1234
# 사이즈 10, 소수점 4자리
a = f'start:{y:10.4f}'
print(a) # start:    3.1234

# {} 문자로 사용
a = f'{{ and }}'
print(a) # { and }

# f 문자열로 금액에 콤마(,) 삽입
# 예제: "난 1500000원이 필요해"(150만원)
a = f"난 {1500000:,}원이 필요해"
print(a) # 난 1,500,000원이 필요해


# 문자열 관련 함수
# 문자 개수 - count: 문자열에서 파라미터로 전달한 문자의 개수 반환
a = "hobby"
result = a.count("b") # a 문자열에서 "b"의 개수
print(result) # 2

# 위치 찾기 - find: 해당 문자가 처음으로 나온 위치(0부터) 반환, 없는 경우 -1 반환
a = "Python is the best choice"
result = a.find("b") # b의 위치
print(result) # 14

result = a.find("k") # k의 위치
print(result) # -1

# 위치 찾기 2 - index: find와 동일하게 해당 문자가 처음으로 나온 위치(0부터) 반환, 없는 경우 에러 발생
a = "Life is too short"
result = a.index("t")
print(result) # 8
# result = a.index("k") # 에러

# 문자열 삽입 - join: 함수 주체가 되는 문자를 separator로 사용, 전달받은 문자 사이에 끼워넣는다.
a = ",".join("abcd")
print(a) # a,b,c,d

a = ",".join(["a", "b", "c", "d"])
print(a) # a,b,c,d

a = "X".join("abcd")
print(a) # aXbXcXd

# 소문자 -> 대문자 - upper
a = "hi".upper()
print(a) # HI

# 대문자 -> 소문자 - lower
a = "HI".lower()
print(a) # hi

# 왼쪽 공백 제거 - lstrip
a = " hi :end".lstrip()
print(a) # hi   :end

# 오른쪽 공백 제거 - rstrip
a = "start: hi ".rstrip()
print(a) # start: hi

# 양쪽 공백 제거 - strip
a = " hi ".strip()
print(a) # hi

# 문자열 바꾸기 - replace
a = "Life is too short".replace("Life", "Your leg")
print(a) # Your leg is too short

# 문자열 나누기 - split
a = "Life is too short".split() # 기본적으로 공백([Space], [Tab], [Enter])을 기준으로 나눔
print(a) # ['Life', 'is', 'too', 'short']

a = "a:b:c:d".split(";") # 나누는 기준이 될 문자 제공 가능
print(a) # ['a:b:c:d']

# 문자열이 알파벳으로만 구성되어 있는지 확인 - isalpha
a = "Python".isalpha()
print(a) # True

a = "Python3".isalpha()
print(a) # False

# 공백도 안됨
a = "Hello World".isalpha()
print(a) # False


# 문자열이 숫자로만 구성되어 있는지 확인 - isdigit
a = "12345".isdigit()
print(a) # True

a = "1234a".isdigit()
print(a) # False

# 마찬가지로 공백 안됨
a = "12 34".isdigit()
print(a) # False

# 소수점도 안됨
a = "12.34".isdigit()
print(a) # False

# 문자열이 특정 문자(열)로 시작하는지 확인하기 - startswith
a = "Life is too short".startswith("Life")
print(a) # True
a = "Life is too short".startswith("short")
print(a) # False

# 문자열이 특정 문자(열)로 끝나는지 확인하기 - endswith
a = "Life is too short".endswith("short")
print(a) # True
a = "Life is too short".endswith("Life")
print(a) # False

# 문자열은 자체의 값을 변경할 수 없는 immutable 자료형임, 변환 함수를 사용해도 변환한 값을 반환하는것이고 원본에 대한 변경은 하지 않는다.
# upper는 대문자 변환 후 반환 함수, 원본 데이터를 바꾸지 않는다.
a = "hi"
print(a.upper()) # HI
# a는 HI일까 hi일까?
print(a) # hi

# replace도 마찬가지
a = "Life is too short"
print(a.replace("Life", "Your leg")) # Your leg is too short
print(a) # Life is too short

# 다만 a = 으로 재할당 하는 경우에는 변경됨, 이것은 String 자체를 바꾸는 개념이 아니고 a 변수에 새로운 값을 할당하는 개념으로 봐야함
a = "hi"
a = a.upper()
print(a) # HI
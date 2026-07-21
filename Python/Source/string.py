# [1] 문자열 만드는 방법
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

# [2]여러줄인 문자열을 변수에 대입하고 싶을 때
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
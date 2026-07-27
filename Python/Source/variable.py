# 변수 선언: 변수_이름 = 변수에_저장할_값
# 타입 선언은 필요 없음, 알아서 판단함
a = 1
b = "python"
c = [1, 2, 3]

# 변수 명명 규칙
# 1. 영문자, 숫자, 언더스코더(_)만 사용 가능
# 2. 숫자로 시작할 수 없음
# 3. 예약어는 사용 불가
# 4. 대소문자를 구분함

# 올바른 변수명
name = "홍길동"
age = 25
user_name = "gildong"
userName = "gildong"
_private = "비공개"
count1 = 1

# 잘못된 변수명
# 1name = "홍길동" # 숫자로 시작 (오류)
# user-name = "홍길동" # 하이픈(-) 사용 (오류)
# if = 10 # 예약어 사용 (오류)

# 파이썬 예약어
# False, None, True, and, as, assert, break, class, continue, def, 
# del, elif, else, except, finally, for, from, global, if, import, 
# in, is, lambda, nonlocal, not, or, pass, raise, return, try, 
# while, with, yield

# 변수란?
# 파이썬에서 변수는 객체를 가리키는것
a = [1, 2, 3] # [1, 2, 3]이 메모리에 생성되고 a는 [1, 2, 3]이 저장된 메모리 주소를 가리킴
print(id(a)) # 4364176768: 메모리 주소이므로 메번 바뀐다

# 리스트 복사 예시
a = [1, 2, 3]
b = a # b에 a 자체(주소)를 할당
# a, b는 같은 주소를 가리킴
print(id(a)) # 4341583744
print(id(b)) # 4341583744
print(a is b) # True
# a를 바꾸면 b도 바뀌어있음
a[1] = 4
print(a) # [1, 4, 3]
print(b) # [1, 4, 3]

# [:] 이용 하기
a = [1, 2, 3]
b = a[:] # a의 값을 읽어서 b에 할당
a[1] = 4
# a를 수정해도 b는 그대로
print(a) # [1, 4, 3]
print(b) # [1, 2, 3]
print(a is b) # False

# copy 모듈 이용
from copy import copy
a = [1, 2, 3]
b = copy(a)
a[1] = 4
# a를 수정해도 b는 그대로
print(a) # [1, 4, 3]
print(b) # [1, 2, 3]
print(a is b) # False

# 변수를 만드는 여러가지 방법
# 튜플로 a, b에 대입
a, b = ('python', 'life')
print(a) # python
print(b) # life
(a, b) = 'python', 'life'
print(a) # python
print(b) # life
a, b = 'python', 'life'
print(a) # python
print(b) # life

# 리스트로 만들기
[a, b] = ['python', 'life']
print(a) # python
print(b) # life

# 여러개의 변수에 같은 값 대입
a = b = 'python'
print(a) # python
print(b) # python

# 두개의 변수 값 바꾸기
a = 3
b = 5
a, b = b, a
print(a) # 5
print(b) # 3

a = {'x': 1}
b = a.copy()
print(a)
print(b)
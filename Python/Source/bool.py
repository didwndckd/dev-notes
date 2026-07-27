# bool 자료형: 참(True), 거짓(False)를 나타내는 자료형
# True, False는 파이썬의 예약어, true, false는 안됨

# bool 선언
a = True
b = False

# 조건 반환값
print(1 == 1) # True
print(2 > 1) # True
print(2 < 1) # False

# 자료형의 참과 거짓
# 배열
a = [1, 2, 3, 4]
while a:
    print(a.pop()) # 4, 3, 2, 1

if []: # 거짓
    print("참")
else:
    print("거짓")

# 문자열
if "python": # "참"
    print("참")
else:
    print("거짓")

# bool 연산
print(bool('python')) # True
print(bool('')) # False
print(bool([1, 2, 3])) # True
print(bool([])) # False
print(bool(0)) # False
print(bool(3)) # True

# 논리 연산자
# and: 양쪽이 전부 True이면 True
print(True and True) # True
print(True and False) # False
print(False and True) # False
print(False and False) # False

# or: 하나라도 True이면 True
print(True or True) # True
print(True or False) # True
print(False or True) # True
print(False or False ) # False

# not: 참과 거짓을 반대로 바꾼다
print(not True) # False
print(not False) # True
print(not 1) # False
print(not 0) # True

# 활용 예제
x = 5
y = 10
print(x > 0 and y > 5) # True
print(x > 10 or y > 5) # True
print(not x > y) # True
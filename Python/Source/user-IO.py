# 사용자 입력 활용
a = input() # 프롬프트에 입력한 값이 a에 담긴다.
print(a)
# 실행 결과
# abc
# abc

# 안내 문구와 함께 입력을 받을 수 있음
a = input("안내문구") 
print(a)
# 실행 결과
# 안내문구abc
# abc

number = input("숫자를 입력하세요: ")
print(number)
print(type(number))
# 실행 결과
# 숫자를 입력하세요: 3
# 3
# <class 'str'>

# 따라서 숫자 입력을 두개 받아서 더해도 숫자의 더하기 연산이 아닌 문자의 더하기 연산이 실행됨
a = input("숫자 입력 a=")
b = input("숫자 입력 b=")
print(a + b)
# 실행 결과
# 숫자 입력 a=3
# 숫자 입력 b=4
# 34

# 정수로 변환하기
age = input("나이를 입력하세요: ")
age = int(age) # 문자열을 정수로 변환
print(age + 1)
# 실행 결과
# 나이를 입력하세요: 35
# 36

# 실수로 변환하기
height = input("키를 입력하세요(cm): ")
height = float(height) # 문자열을 실수로 변환
print(height / 100) # 미터 단위로 변환
# 실행 결과
# 키를 입력하세요(cm): 173.9
# 1.739

# input과 int(또는 float)를 한줄에 작성할 수도 있다.
age = int(input("나이를 입력하세요: "))
print(type(age))
# 실행 결과
# 나이를 입력하세요: 35
# <class 'int'>

# print 자세히 알기
# 기본 사용
a = 123
print(a) # 123
a = "Python"
print(a) # Python
a = [1, 2, 3]
print(a) # [1, 2, 3]

# 따옴표로 둘러싸인 문자열은 + 연산과 동일
print("life" "is" "too short") # lifeistoo short
print("life"+"is"+"too short") # lifeistoo short

# 문자열 띄어쓰기는 쉼표로 할 수 있음
print("life", "is", "too short") # life is too short

# sep 매개변수로 구분자 설정
# sep의 기본값은 공백(' ')임, 쉼표로 구분했을 때 공백이 자동으로 추가된것도 sep의 기본값이 공백이기 때문
print("2026", "08", "01", sep="-") # 2026-08-01
print("점프", "투", "파이썬", sep="TO ") # 점프TO 투TO 파이썬

# 한줄에 결괏값 출력하기
# end의 기본값은 줄바꿈(\n)이다.
for i in range(10):
    print(i, end=' ')
# 실행 결과
# 0 1 2 3 4 5 6 7 8 9 % : 마지막 %는 줄바꿈이 없어서 프롬프트가 나타난것

print('')
# 실습: 간단한 계산기 만들기
print("=== 간단한 계산기===")
# 사용자로부터 두 숫자 입력받기
num1 = float(input("첫 번째 숫자를 입력하세요: "))
num2 = float(input("두 번째 숫자를 입력하세요: "))

# 계산 결과 출력
print(f"{num1} + {num2} = {num1 + num2}")
print(f"{num1} - {num2} = {num1 - num2}")
print(f"{num1} * {num2} = {num1 * num2}")
if num2 != 0:
    print(f"{num1} / {num2} = {num1 / num2}")
else:
    print("0으로 나눌 수 없습니다.")
# 실행 결과
# === 간단한 계산기===
# 첫 번째 숫자를 입력하세요: 10
# 두 번째 숫자를 입력하세요: 2
# 10.0 + 2.0 = 12.0
# 10.0 - 2.0 = 8.0
# 10.0 * 2.0 = 20.0
# 10.0 / 2.0 = 5.0
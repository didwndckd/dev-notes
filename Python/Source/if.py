# if 문의 기본 구조
# if bool(조건):
#   실행 코드
# elif bool(조건):
#   실행 코드
# else:
#   실행 코드
 
# ex) 돈이 10000원 이상이면 택시를 탄다, 1000원 이상이면 버스를 탄다, 그 아래는 걸어간다.
money = 10000
if money >= 10000:
    print("택시")
elif money >= 1000:
    print("버스")
else:
    print("뚜벅")

# 조건문은 해당 조건에 속하는 모든 문장에 들여쓰기를 해야함, 들여쓰기 깊이는 블럭 내부에서는 모두 같아야 한다.
if True:
    print("1")
# print("2") # Error: 들여쓰기를 하지 않음
    print("3")
        # print("4") # Error 들여쓰기를 더 함
else: # 블럭이 다르면 들여쓰기 깊이가 달라도 괜찮음 들여쓰기를 맞추는 기준은 조건에 해당하는 블럭을 기준으로함
        print("1")
        print("2")

# 조건문의 조건으로 들어갈 수 있는것(bool)
# 결국은 bool타입이 들어가는것인데 여러가지가 있음
# 비교 연산자: ==, <, >, !=, <=, >=
# 논리 연산자: and, or, not
# 리스트, 튜플, 문자열등의 자료형에 해당 데이터가 있는지 여부: in, not in
print(1 in [1, 2, 3]) # True
print(1 not in [1, 2, 3]) # False
print(1 in (1, 2, 3)) # True
print("1" in "123") # True
print(1 in set([1, 2, 3])) # True
print('a' in {'a': 1}) # True: 딕셔너리는 키를 기본으로 보는듯
print(1 in {'a': 1}) # False

# pass: 해당 조건에서 아무것도 하지않고 넘어가고싶은 경우
pocket = ['money', 'paper', 'cellphone']
if 'money' in pocket:
     pass # 여기는 비워두면 에러라서 아무것도 하지 않으려면 pass를 넣는다.
else:
     print("뚜벅")

# 조건문 한줄로 적기, 한줄짜리 코드는 : 바로 옆에 사용 가능
if 'card' in pocket: pass
else: print("뚜벅")

# match-case 문
# 파이썬 3.10부터 사용 가능
# match value: value와 ==를 만족하는 경우 실행
grade = 'B'
match grade:
     case 'A':
          print("탁월한 성적입니다.")
     case 'B':
          print("우수한 성적입니다.")
     case 'C':
          print("보통입니다.")
     case _: # 생략 가능
          print("노력이 필요합니다.")
# 우수한 성적입니다.

# 여러 패턴을 하나의 케이스에서 처리하기
match grade:
     case 'A' | 'B' | 'C':
          print("합격입니다.")
     case _:
          print("불합격입니다.")
# 합격입니다.

# 비교 연산자의 연쇄 사용
# 수학처럼 a < x < b 형태로 이어서 쓸 수 있다. (a < x) and (x < b)와 같은 의미
x = 5
print(1 < x < 10)    # True: 1 < x 이고 x < 10
print(10 <= x <= 20) # False
print((1 < x) and (x < 10)) # True: 위와 동일한 의미

# 조건부 표현식(삼항 연산자)
# 변수 = 참일_때_값 if 조건 else 거짓일_때_값
score = 85
result = "합격" if score >= 60 else "불합격"
print(result) # 합격

# if-else로 풀어 쓴 동일한 코드
if score >= 60:
    result = "합격"
else:
    result = "불합격"
print(result) # 합격
          
     
          
          
          
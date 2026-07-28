# for 문의 기본 구조
# for 변수 in 리스트(또는 튜플, 문자열):
#   실행 코드

# 전형적인 for 문(리스트)
test_list = ['one', 'two', 'three']
for i in test_list:
    print(i)
# 실행 결과
# one
# two
# three

# 튜플
# a 리스트의 요소값이 튜플이기에 각각의 요소가 자동으로 (first, last)에 대입된다.
a = [(1, 2), (3, 4), (5, 6)]
for (first, last) in a:
    print(first + last)
# 실행 결과
# 3
# 7
# 11

# 응용 예제: 총 5명의 학생이 시험을 보았는데 시험 점수가 60점 이상이면 합격, 그렇지 않으면 불합격이다. 결과를 보여주시오
marks = [90, 25, 67, 45, 80]
number = 0
for mark in marks:
    number += 1
    if mark >= 60:
        print(f"{number}번 학생은 합격입니다.")
    else:
        print(f"{number}번 학생은 불합격입니다.")
# 실행 결과
# 1번 학생은 합격입니다.
# 2번 학생은 불합격입니다.
# 3번 학생은 합격입니다.
# 4번 학생은 불합격입니다.
# 5번 학생은 합격입니다.

# continue문: while과 마찬가지로 continue를 만난 다음 라인을 실행하지 않고 다음 루프로 넘어간다.
# 예제: 합격자만 축하 메시지 전달
marks = [90, 25, 67, 45, 80]
number = 0
for mark in marks:
    number += 1
    if mark < 60:
        continue # 다음 루프로 넘어감
    print(f"{number}번 학생 축하합니다. 합격입니다.")
# 실행 결과
# 1번 학생 축하합니다. 합격입니다.
# 3번 학생 축하합니다. 합격입니다.
# 5번 학생 축하합니다. 합격입니다.

# for 문과 함께 자주 사용하는 range 함수
# range(시작_숫자, 끝_숫자): 시작 숫자 <= i < 끝 숫자
print(range(10)) # range(0, 10): 0~9, 시작_숫자는 생략 가능, 기본값 0
print(range(1, 11)) # range(1, 11): 1~10

# range 예제: 1부터 10까지 더하기
add = 0
for i in range(1, 11):
    add += i
print(add) # 55

# range 예제: 앞에서 number를 사용하던것을 range로 대체
marks = [90, 25, 67, 45, 80]
for number in range(len(marks)):
    if marks[number] < 60: continue
    print(f"{number + 1}번 학생 축하합니다. 합격입니다.")
# 실행 결과
# 1번 학생 축하합니다. 합격입니다.
# 3번 학생 축하합니다. 합격입니다.
# 5번 학생 축하합니다. 합격입니다.

# for와 range를 이용한 구구단
for i in range(2, 10): # 2~9
    for j in range(1, 10): # 1~9
        print(i*j, end=" ") # 줄바꾸지 않고 뒤에 공백만 추가
    print('') # 줄바꿈
# 실행 결과
# 2 4 6 8 10 12 14 16 18 
# 3 6 9 12 15 18 21 24 27 
# 4 8 12 16 20 24 28 32 36 
# 5 10 15 20 25 30 35 40 45 
# 6 12 18 24 30 36 42 48 54 
# 7 14 21 28 35 42 49 56 63 
# 8 16 24 32 40 48 56 64 72 
# 9 18 27 36 45 54 63 72 81 

# 리스트 컴프리헨션: 리스트 안에 for 문을 포함하는 기법
# 기본 사용 방법: [표현식(반환값?) for 항목 in 반복_가능_객체 if 조건문]
# 예제: a 리스트의 각 요소들에 3을 곱한 결과를 result에 담기
# 일반 for 문 사용
a = [1, 2, 3, 4]
result = []
for num in a:
    result.append(num * 3)
print(result) # [3, 6, 9, 12]

# 리스트 컴프리핸션 사용
a = [1, 2, 3, 4]
result = [num * 3 for num in a]
print(result) # [3, 6, 9, 12]

# 조건 추가 예제: [1, 2, 3, 4]중 짝수만 3을 곱해서 담기
a = [1, 2, 3, 4]
result = [num * 3 for num in a if num % 2 == 0] # 2, 4만 3 곱해서 담는다.
print(result) # [6, 12]

# for문을 여러개 사용하는 경우
# [표현식 for 항목1 in 반복_가능_객체1 if 조건문1
#       for 항목2 in 반복_가능_객체2 if 조건문2
#       ...
#       for 항목n in 반복_가능_객체n if 조건문n]
# 예제: 구구단
result = [x * y for x in range(2, 10)
                for y in range(1, 10)]
print(result) # [2, 4, 6, 8, 10, 12, 14, 16, 18, 3, 6, 9, 12, 15, 18, 21, 24, 27, 4, 8, 12, 16, 20, 24, 28, 32, 36, 5, 10, 15, 20, 25, 30, 35, 40, 45, 6, 12, 18, 24, 30, 36, 42, 48, 54, 7, 14, 21, 28, 35, 42, 49, 56, 63, 8, 16, 24, 32, 40, 48, 56, 64, 72, 9, 18, 27, 36, 45, 54, 63, 72, 81]

# for 문과 break 문
# while과 마찬가지로 루프 탈출
for i in range(10):
    if i == 5: break
    print(i)
# 실행 결과
# 0
# 1
# 2
# 3
# 4

# for-else 문
# while과 마찬가지로 for 문이 끝까지 수행되었을 때 else 구문 실행
for i in range(5):
    print(i)
else:
    print("for 문이 정상 종료되었습니다.")
# 실행 결과
# 0
# 1
# 2
# 3
# 4
# for 문이 정상 종료되었습니다.

# break로 빠져나간 케이스
for i in range(5):
    if i == 3: break
    print(i)
else:
    print("for 문이 정상 종료되었습니다.")
# 실행 결과
# 0
# 1
# 2

# enumerate 함수 활용
# enumerate: 인덱스와 요소가 함께 나온다
fruits = ['apple', 'banana', 'orange']
for i, fruit in enumerate(fruits):
    print(f"{i}: {fruit}")
# 실행 결과
# 0: apple
# 1: banana
# 2: orange

# enumerate의 시작 번호 변경
for i, fruit in enumerate(fruits, 1): # 1부터 인덱스 시작
    print(f"{i}: {fruit}")
# 실행 결과
# 1: apple
# 2: banana
# 3: orange

# zip 함수로 여러 리스트 함께 순회하기
names = ['홍길동', '김철수', '이영희']
scores = [85, 92, 78]
for name, score in zip(names, scores):
    print(f"{name}: {score}점")
# 실행 결과
# 홍길동: 85점
# 김철수: 92점
# 이영희: 78점

# 세개 이상도 가능
names = ['홍길동', '김철수', '이영희']
korean = [85, 92, 78]
english = [90, 88, 95]
for name, kor, eng in zip(names, korean, english):
    print(f"{name}: 국어 {kor}점, 영어{eng}점")
# 실행 결과
# 홍길동: 국어 85점, 영어90점
# 김철수: 국어 92점, 영어88점
# 이영희: 국어 78점, 영어95점

# zip 사용시 앞에서부터 쌍을 이루는 값들만 튜플로 묶여 나온다, 넘치는 값은 버려진다.
names = ['홍길동', '김철수', '이영희', '양중창'] # 4개
scores = [85, 92, 78] # 3개
zip = zip(names, scores)
print(list(zip)) # [('홍길동', 85), ('김철수', 92), ('이영희', 78)] -> '양중창'은 버려짐
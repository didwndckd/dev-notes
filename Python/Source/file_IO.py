from pathlib import Path # 테스트용 임시 디렉터리를 만들기 위해 추가
base_path = "temp"
Path(base_path).mkdir(exist_ok=True) # 임시 폴더 생성

# 파일 열기
# 파일_객체 = open(파일_경로(이름), 파일_열기_모드): 기본적으로 해당 디렉터리가 없으면 안된다.
# 파일열기모드
# r: 읽기 모드: 파일을 읽기만 할 때 사용. -> 해당 경로에 파일이 없으면 에러
# w: 쓰기 모드: 파일에 내용을 쓸 때 사용. -> 해당 경로에 파일이 원래 파일이 이미 존재하면 원래 있던 내용이 모두 사라지고, 해당 파일이 존재하지 않으면 새로운 파일이 생성된다.
# a: 추가 모드: 파일의 마지막에 새로운 내용을 추가할 때 사용. -> 파일이 없으면 생성 있으면 내용 추가
file_path = f"{base_path}/새파일.txt"

# 파일 쓰기 모드(w)로 열어서 내용 쓰기
f = open(file_path, 'w') # 쓰기 모드로 파일 열기
for i in range(1, 11):
    data = f"{i}번째 줄입니다.\n"
    f.write(data) # 파일에 내용 쓰기
f.close() # 파일 닫기
# 실행 결과: temp/새파일.txt
# 1번째 줄입니다.
# 2번째 줄입니다.
# 3번째 줄입니다.
# 4번째 줄입니다.
# 5번째 줄입니다.
# 6번째 줄입니다.
# 7번째 줄입니다.
# 8번째 줄입니다.
# 9번째 줄입니다.
# 10번째 줄입니다.

# 파일을 읽기(r)
# readline: 한줄 꺼내오기
f = open(file_path, 'r')
line = f.readline()
print(line)
f.close()
# 실행 결과 temp/새파일.txt(마지막에 \n이 있어서 공백도 출력됨)
# 1번째 줄입니다.
#

# 모든 줄 읽기
f = open(file_path, 'r')
while True:
    line = f.readline() # 무한 루프를 돌면서 한줄씩 읽음, 더이상 읽을 줄이 없으면 빈 문자열("") 반환
    if not line: break # 더이상 읽을 라인이 없는 경우 루프 탈출
    print(line)
f.close()
# 실행 결과 temp/새파일.txt
# 1번째 줄입니다.

# 2번째 줄입니다.

# 3번째 줄입니다.

# 4번째 줄입니다.

# 5번째 줄입니다.

# 6번째 줄입니다.

# 7번째 줄입니다.

# 8번째 줄입니다.

# 9번째 줄입니다.

# 10번째 줄입니다.


# readlines: 모든 라인 꺼내오기
f = open(file_path, 'r')
lines = f.readlines()
for line in lines:
    line = line.strip() # 줄 끝의 줄 바꿈 문자 제거
    print(line)
f.close()
# 실행 결과: temp.새파일.txt
# 1번째 줄입니다.
# 2번째 줄입니다.
# 3번째 줄입니다.
# 4번째 줄입니다.
# 5번째 줄입니다.
# 6번째 줄입니다.
# 7번째 줄입니다.
# 8번째 줄입니다.
# 9번째 줄입니다.
# 10번째 줄입니다.

# read: 전체 문자열 반환
f = open(file_path, 'r')
data = f.read()
print(data)
f.close()
# 실행 결과: temp.새파일.txt
# 1번째 줄입니다.
# 2번째 줄입니다.
# 3번째 줄입니다.
# 4번째 줄입니다.
# 5번째 줄입니다.
# 6번째 줄입니다.
# 7번째 줄입니다.
# 8번째 줄입니다.
# 9번째 줄입니다.
# 10번째 줄입니다.

# 파일 객체를 for문과 함께 사용: 파일 객체는 기본적으로 for 문과 함께 파일을 줄 단위로 읽을 수 있음.
f = open(file_path, 'r')
for line in f:
    print(line)
f.close()
# 실행 결과: temp.새파일.txt
# 1번째 줄입니다.

# 2번째 줄입니다.

# 3번째 줄입니다.

# 4번째 줄입니다.

# 5번째 줄입니다.

# 6번째 줄입니다.

# 7번째 줄입니다.

# 8번째 줄입니다.

# 9번째 줄입니다.

# 10번째 줄입니다.

# 파일에 새로운 내용 추가하기(a)
f = open(file_path, 'a')
for i in range(11, 20):
    data = f"{i}번째 줄입니다.\n"
    f.write(data)
f.close()
# 실행 결과: temp.새파일.txt: 11~19가 추가됨.
# 1번째 줄입니다.
# 2번째 줄입니다.
# 3번째 줄입니다.
# 4번째 줄입니다.
# 5번째 줄입니다.
# 6번째 줄입니다.
# 7번째 줄입니다.
# 8번째 줄입니다.
# 9번째 줄입니다.
# 10번째 줄입니다.
# 11번째 줄입니다.
# 12번째 줄입니다.
# 13번째 줄입니다.
# 14번째 줄입니다.
# 15번째 줄입니다.
# 16번째 줄입니다.
# 17번째 줄입니다.
# 18번째 줄입니다.
# 19번째 줄입니다.

# with문과 함께 사용
# 기존 파일 열고 닫기: 열었으면 닫아줘야함
f = open(file_path, 'w') # 파일을 쓰기 모드로 연다
f.write("Life is too short, you need python") # 파일에 내용 쓰기
f.close() # 파일 닫기

# with 문을 사용하면 with 블록을 벗어나는 순간 열린 라일 객체 f가 자동으로 닫힌다.
with open(file_path, 'w') as f:
    f.write("Life is too short, you need python")

# 파일이 닫혔는지 확인하기 - closed
with open(file_path, 'w') as file:
    file.write("Hello")
    print(file.closed) # False: 아직 열려있음
print(file.closed) # True: with 블록을 벗어나 자동으로 닫힘

# with 문 안에서 만든 변수는 with 블록이 끝난 후에도 사용 가능하다.
# 파이썬에서 fi, for, while, with 블록은 변수 사용 범위를 제한하지 않음.(함수와는 다르게)
# 다만 f(파일) 객체는 with 블록이 벗어나면 자동으로 닫히므로 블록 밖에서 f.write()나 f.read()같은 파일 작업은 할 수 없음, 닫힌 파일에서 작업을 시도하면 오류가 발생한다.
with open(file_path, 'w') as f:
    content = "Hello, Python!"
    f.write(content)
print(content) # Hello, Python!

# 파일 처리시 주의사항
# 한글이 포함된 파일을 다룰때는 인코딩을 명시하면 좋다.
# 인코딩을 명시하지 않으면 운영체제마다 다른 기본 인코딩을 사용하여 한글이 깨질 수 있다.
# 한글 파일 쓰기
file_path = f"{base_path}/한글파일.txt"
with open(file_path, 'w', encoding="utf-8") as f:
    f.write("안녕하세요, 파이썬!")

# 한글 파일 읽기
with open(file_path, 'r', encoding="utf-8") as f:
    content = f.read()
    print(content) # 안녕하세요, 파이썬!

# 명령 프롬프트
# 명령어 [인수1 인수2 ...]

# sys 모듈 사용하기
import sys

# 프로그램 실행 시 전달받은 인수 출력하기
args = sys.argv[:]
for i in args:
    print(i)
# 실행: : python3 Python/Source/program_IO.py aaa bbb ccc
# 0번(해당 프로그램): Python/Source/program_IO.py
# 1번~: 전달 인수
# 실행결과
# Python/Source/program_IO.py
# aaa
# bbb
# ccc

args = sys.argv[1:] # 인수부터
for i in args:
    print(i.upper(), end=' ')

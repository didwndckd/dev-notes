# 집합(set): 수학의 집합 개념과 동일한 자료형, 중복을 허용하지 않고 순서가 없는 데이터 모임

# 집합 자료형 만들기
# 배열 기반
s1 = set([1, 2, 3, 4])
print(s1) # {1, 2, 3, 4}
# 문자열 기반
s2 = set("Hello")
print(s2) # {'e', 'o', 'l', 'H'}
# {} 사용
s3 = {1, 2, 3}
print(s3) # {1, 2, 3}
# 비어있는 집합: {}로 만들면 딕셔너리임
s5 = set()
print(s5) # set()

# 리스트 변환
s1 = set([1, 2, 3]) 
print(list(s1)) # [1, 2, 3]

# 튜플 변환
s1 = set([1, 2, 3])
print(tuple(s1)) # (1, 2, 3)

# 교집합, 합집합, 차집합
s1 = set([1, 2, 3, 4, 5, 6])
s2 = set([4, 5, 6, 7, 8, 9])

# 교집합
print(s1 & s2) # {4, 5, 6}
print(s1.intersection(s2)) # {4, 5, 6}

# 합집합
print(s1 | s2) # {1, 2, 3, 4, 5, 6, 7, 8, 9}
print(s1.union(s2)) # {1, 2, 3, 4, 5, 6, 7, 8, 9}

# 차집합
print(s1 - s2) # {1, 2, 3}
print(s2 - s1) # {8, 9, 7}
print(s1.difference(s2)) # {1, 2, 3}
print(s2.difference(s1)) # {8, 9, 7}

# 관련 함수
# 값 추가 - add
s1 = set([1, 2, 3])
s1.add(4)
print(s1) # {1, 2, 3, 4}

# 값 여러개 추가 - update
s1 = set([1, 2, 3])
s1.update([4, 5, 6])
print(s1) # {1, 2, 3, 4, 5, 6}

# 특정 값 제거 - remove
s1 = set([1, 2, 3])
s1.remove(2)
print(s1) # {1, 3}
# s1.remove(4) # Error: 없는 값을 제거하려고 하면 에러

# 특정값 제거 - discard
s1 = set([1, 2, 3])
s1.discard(2)
print(s1) # {1, 3}
s1.discard(4) # 없는 값을 제거하려 해도 에러 발생하지 않음
print(s1) # {1, 3}

# 모든 값 제거 - clear
s1 = set([1, 2, 3])
s1.clear()
print(s1) # set()

l1 = [1, 2, 3]
s1 = set(l1)
print(s1)
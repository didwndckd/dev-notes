# 딕셔너리: Key: Value 쌍 자료구조

# 딕셔너리 선언: {Key1: Value1, Key2: Value2, ...}
dic = {'name': 'yjc', 'phone': '010-9999-1234', 'birth': '1118'}
# 정수 key, 문자열 value
a = {1: 'hi'}
# 리스트 value 가능
a = {'a': [1, 2, 3]}
# 여러 타입의 key, value 혼용 가능
a = {'a': 1, 1: 'a'}

# 딕셔너리 쌍 추가하기
a = {1: 'a'}
a[2] = 'b'
print(a) # {1: 'a', 2: 'b'}
a['name'] = 'yjc'
print(a) # {1: 'a', 2: 'b', 'name': 'yjc'}
a[3] = [1, 2, 3]
print(a) # {1: 'a', 2: 'b', 'name': 'yjc', 3: [1, 2, 3]}

# 요소 삭제 하기
del a[1]
print(a) # {2: 'b', 'name': 'yjc', 3: [1, 2, 3]}
# del a[1] # Error: 없는 값을 지우려고 하면 에러

# key로 value 뽑기
grade = {'yjc': 10, 'bms': 9}
print(grade['yjc']) # 10
print(grade['bms']) # 9
# print(grade['nokey']) # Error: 없는 값에 접근하면 에러

# 딕셔너리 선언시 주의점
# 중복 키 사용 시 덮어써짐
a = {1: 'a', 1: 'b'}
print(a) # {1: 'b'}
# 리스트는 키로 사용할 수 없음
# a = {[123]: 123} # Error
# 튜플은 키로 사용 가능
a = {(1, 2): 12}
print(a) # {(1, 2): 12}

# 관련 함수
# Key 리스트 만들기 - keys
a = {'name': 'yjc', 'phone': '010-9999-1234', 'birth': '1118'}
print(a.keys()) # dict_keys(['name', 'phone', 'birth'])
# 반복문 사용 가능
for k in a.keys():
    print(k) # name, phone, birth
# 리스트로 변환
print(list(a.keys())) # ['name', 'phone', 'birth']

# Value 리스트 만들기 - values
a = {'name': 'yjc', 'phone': '010-9999-1234', 'birth': '1118'}
print(a.values()) # dict_values(['yjc', '010-9999-1234', '1118'])

# Key, Value 쌍 얻기 - items: (Key, Value) 튜플 dict_items 객체로 반환
a = {'name': 'yjc', 'phone': '010-9999-1234', 'birth': '1118'}
print(a.items()) # dict_items([('name', 'yjc'), ('phone', '010-9999-1234'), ('birth', '1118')])

# Key, Value 모두 제거 - clear
a = {'name': 'yjc', 'phone': '010-9999-1234', 'birth': '1118'}
a.clear()
print(a) # {}

# Key로 Value 얻기 - get
a = {'name': 'yjc', 'phone': '010-9999-1234', 'birth': '1118'}
print(a.get('name')) # yjc
print(a.get('phone')) # 010-9999-1234
print(a.get('nokey')) # None: a[key] 접근과 달리 에러가 발생하지 않고 None을 반환한다.
print(a.get('nokey', '정보없음')) # 정보없음: 키가 없는 경우 디폴트값을 반환하게 할 수 있음.

# 해당 key가 딕셔너리 안에 있는지 조사하기 - in
a = {'name': 'yjc', 'phone': '010-9999-1234', 'birth': '1118'}
print('name' in a) # True
print('nokey' in a) # False

# Key로 Value 꺼내기 - pop: Key에 해당하는 값 꺼내오고 요소 제거
a = {'name': 'yjc', 'phone': '010-9999-1234', 'birth': '1118'}
print(a.pop('phone')) # 010-9999-1234
print(a) # {'name': 'yjc', 'birth': '1118'}
# print(a.pop('nokey')) # Error 없는 키를 pop 하려고 하면 에러 발생
print(a.pop('nokey', '정보없음')) # 정보없음: 디폴트 값을 지정하면 에러 발생하지 않고 반환


a = {
    'name': 'yjc', 
    'phone': '010-9999-1234', 
    'birth': '1118'
    }

print(a)
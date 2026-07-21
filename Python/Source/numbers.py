# 정수형
a = 123
print(a)
a = -178
print(a)
a= 0
print(a)

# 실수형
a = 1.2
print(a)
a = 3.45
print(a)

# e(n)은 10의n제곱
a = 4.24E10 # 4.24 * 10^10 = 42400000000.0
print(a)
a = 4.24e-10 # 4.24 * 10^-10 = 0.000000000424
print(a)

# 8진수 0o(n)
a = 0o177
print(a) # 127

# 16진수 0x(n)
a = 0x8ff
print(a) # 2303

#사칙연산
a = 3
b = 4
print(a + b) # 7
print(a - b) # -1
print(a * b) # 12
print(a / b) # 0.75

# 제곱 연산자(**)
a = 3
b = 4
print(a ** b) # 3^4 = 81

# 나머지(모듈러)연산자(%)
print(7 % 3) # 1
print(3 % 7) # 3

# 나눗셈 이후 몫을 반환하는 연산자(//)
print(7 / 4) # 1.75
print(7 // 4) # 1

# 연산 후 할당(+=, -=, *=, /=, //=, %=, **=)
a = 1
a = a + 1
print(a) # 2
a = 1
a += 1
print(a) # 2
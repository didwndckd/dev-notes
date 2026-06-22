# 모듈 링크 방식별 구성 실험

> 각 모듈을 Static/Dynamic Library 또는 Static/Dynamic Framework로 구성했을 때 빌드 산출물이 어떻게 달라지는지 비교

## Mach-O

Mach-O(Mach Object)는 Apple 플랫폼의 실행 파일 / 라이브러리 / 프레임워크 내부 바이너리가 사용하는 파일 포맷이다. Xcode Build Settings의 **Mach-O Type** 옵션으로 타겟이 어떤 형태의 Mach-O 파일로 빌드될지(Executable, Static Library, Dynamic Library 등) 결정된다.

- **Static / Dynamic**은 Mach-O Type이 결정한다.
- **Library / Framework**는 타겟의 Product Type이 결정한다. Framework는 Mach-O 바이너리를 번들 디렉터리로 감싼 형태이다.

## Excutable

- 실행 파일

## Static Library

- 파일 형식:  `.a`
- **excutable file**에 포함된다.

## Dynamic Library

- 파일 형식: ``.dylib``
- Dynamic library에 대한 참조만 **excutable file**에 포함된다.

## 모듈 구성 실험

- 샘플 구성

  - Tuist를 사용하여 구성
  - `ModuleA`, `ModuleB`, `ModuleC`, `ModuleCommon`
  - 각각의 모듈에는 `{ModuleName}Instance.swift` 파일이 존재한다.
  - 모든 모듈의(앱 타겟 포함) Build Setting
    - Other Linker Flags: -ObjC
    - -all_Load는 심볼의 중복을 만들 수 있음
      - 신경쓰면 중복 안하게 할수도 있음
  - Build Phases
    - Embed Frameworks에 모듈을 포함하는것은 최종 앱 타겟이다.
    - Link Binary With Libraries에 모듈을 포함하는것은 최종 앱 타겟이다.
    - 기본 Tuist generate 사용
    - 각 모듈마다 추가 하게되면 .a 파일의 심볼이 달라지지만 결과적으로 **excutable file**에는 동일한 심볼(거의) 구성을 이룸
  
- 확인 방법

  - 빌드된 앱의 파일 구성 확인

  - 빌드된 **excutable file**의 파일 용량 확인

  - 빌드된 **excutable file**의 심볼 정보를 출력

    - ``` sh
      $ nm Mach_O_Sample_App.app/Mach_O_Sample_App| grep "\.o"
      ```

- 타겟별 graph 이미지

![1_Tuist_Graph_Targets](Assets/1_Tuist_Graph_Targets.avif)



### Case 1.

![2_Case1](Assets/2_Case1.png)

| 결과                                            | 설명                                                         |
| ----------------------------------------------- | :----------------------------------------------------------- |
| <img src=Assets/3_Case1_nm.png width=400>       | 빌드된 앱 **excutable file**에 **object file** 심볼이 포함되어있다. |
| <img src=Assets/4_Case1_capacity.png width=400> | 최종 앱 **excutable file**의 용량은 250,064바이트(약250KB)   |



### Case 2.

![5_Case2](Assets/5_Case2.png)

Case1과 달리 `ModuleA`가 `ModuleB`, `ModuleC`에 종속성을 갖기 때문에 ModuleA의 사이즈가 커지며 중복이 발생하고 사이즈가 커질줄 알았다.

`ModuleA`에 **Link Binary With Libraries**에 `ModuleB`, `ModuleC`를 추가하면 libModuleA.a에 해당 라이브러리의 심볼이 포함 되지만 최종 **excutable file**에서는 중복 포함되지 않는다.

하지만 Case1과 심볼 구성과 **excutable file**의 용량이 정확하게 같았다.

- 종속성을 갖는 모듈에 코드가 포함된다.❌ 
- **excutable file**에 포함된다. ✅

| 결과                                            | 설명                                                         |
| ----------------------------------------------- | :----------------------------------------------------------- |
| <img src=Assets/6_Case2_nm.png width=400>       | 빌드된 앱 **excutable file**에 **object file** 심볼이 포함되어있다. |
| <img src=Assets/7_Case2_capacity.png width=400> | 최종 앱 **excutable file**의 용량은 250,064바이트(약250KB)   |



### Case 3.

![8_Case3](Assets/8_Case3.png)

`ModuleCommon`을 Dynamic Library로 세팅 해보았다.

tuist generate 실패

`tuist generate` 실패

![9_Case3_generate](Assets/9_Case3_generate.png)

그래서 강제로 Xcode Build Settings에서 Mach-O Type을 바꿔서 빌드 해봤지만 심볼을 찾을 수 없다며 실패

![10_Case3_build](Assets/10_Case3_build.png)



### Case 4.

![11_Case4](Assets/11_Case4.png)

`ModuleCommon`을 Dynamic Framework로 세팅 해보았다.

- 앱 패키지 구성에 `ModuleCommon.framework`가 생긴다.
- Dynamic Framework는 따로 **excutable file**이 생성됨

| 결과                                                         | 설명                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| <img src=Assets/12_Case4_finder.png width=400>               | App 패키지 구성                                              |
| <img src=Assets/13_Case4_nm_app.png width=400>               | 앱의 **excutable file** 에 `ModuleCommen`의 심볼은 포함되지 않는다. |
| <img src=Assets/14_Case4_nm_framework.png width=400>         | `CommonModule`의 **excutable file**에 내부 목적 코드 심볼이 포함된다. |
| <img src=Assets/15_Case4_app_capacity.png width=400>         | `CommonModule`이 빠지면서 앱의 **excutable file** 용량이 줄어들었다.(255KB -> 248KB) |
| <img src=Assets/16_Case4_app_package_capacity.png width =400> | 하지만 앱 패키지의 용량은 140KB 정도 늘었다.                 |



### Case 5.

![17_Case5](Assets/17_Case5.png)

`ModuleCommon`을 Static Framework로 세팅 해보았다.

| 결과                                             | 설명                                                         |
| ------------------------------------------------ | ------------------------------------------------------------ |
| <img src=Assets/18_Case5_nm.png width=400>       | 빌드된 앱 **excutable file**에 **object file** 심볼이 포함되어있다. |
| <img src=Assets/19_Case5_capacity.png width=400> | 최종 앱 **excutable file**의 용량은 250,080바이트(약250KB)로 **Static Library**를 사용했을때 보다 살짝 늘었다. |



### Case 6.

![20_Case6](Assets/20_Case6.png)

`ModuleA`, `ModuleB`, `ModuleC`를 **Dynamic Library**로 구성하고 `ModuleCommon`을 **Static Library**로 구성했다.

tuist generate 실패

![21_Case6_generate](Assets/21_Case6_generate.png)

**Static Library**와 **Dynamic Library**는 공존할 수 없나보다... 여기서의 **Dynamic Library**는 Framework가 아님 **Dynamic Framework**는 가능. 

그만 알아보도록 하자....



### Case7.

![22_Csae7](Assets/22_Csae7.png)

`ModuleA`, `ModuleB`, `ModuleC`는 **Dynamic Framework**로 구성하고 `ModuleCommon`은 **Static Library**로 구성했다.

- tuist generate는 가능

- 하지만 몇가지 문제점이 있음

  - **Dynamic Framework**는 각각 **excutable file**이 생성 되는데 해당 모듈이 종속성을 갖는 **Static Library**를 포함 하기 때문에 최종 앱 패키지의 사이즈가 불필요하게 커진다.

  - `ModuleA`, `ModuleB`, `ModuleC`에서 사용하는  `ModuleCommon`의 **Singleton** 인스턴스를 각각 다른 인스턴스로 인식한다.

  - 빌드했을 때 `ModuleCommen`내부의 클래스가 종속되어있는 **Dynamic Framework**에서 중복 정의되고 있음을 경고한다.

    ```
    objc[37671]: Class _TtC12ModuleCommon20ModuleCommonInstance is implemented in both 
    /.../ModuleC.framework/ModuleC (0x102bb4218) and /.../ModuleB.framework/ModuleB (0x102ba0218). 
    One of the two will be used. Which one is undefined.
    
    objc[37671]: Class _TtC12ModuleCommon20ModuleCommonInstance is implemented in both 
    /.../ModuleC.framework/ModuleC (0x102bb4218) and /.../ModuleA.framework/ModuleA (0x102b44218). 
    One of the two will be used. Which one is undefined.
    ```

| 결과                                                         | 설명                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| <img src=Assets/23_Case7_nm_ModuleA.png width=400>           | `ModuleA.framework`의 **excutable file**에 `ModuleCommon`의 심볼이 포함되어 있다. |
| <img src=Assets/24_Case7_nm_ModuleB.png width=400>           | `ModuleB.framework`의 **excutable file**에 `ModuleCommon`의 심볼이 포함되어 있다. |
| <img src=Assets/25_Case7_nm_ModuleC.png width=400>           | `ModuleC.framework`의 **excutable file**에 `ModuleCommon`의 심볼이 포함되어 있다. |
| <img src=Assets/26_Case7_app_capacity.png width=400>         | `ModuleCommon`이 빠지면서 앱의 **excutable file** 용량은 줄어듬 |
| <img src=Assets/27_Case7_app_package_capacity.png width=400> | 하지만 앱 패키지의 용량은 약 678KB로 꽤 많이 늘어남.         |



### Case 8.

![28_Case8.png](Assets/28_Case8.png)

모든 모듈을 **Dynamic Framework**로 구성 해보았다.

- 모든 모듈이 자신의 **Object File**만 포함한다.
- `ModuleCommon`의 **Singleton** 인스턴스를 모두 같은 인스턴스로 취급한다.

| 결과                                                    | 설명                                            |
| ------------------------------------------------------- | ----------------------------------------------- |
| <img src=Assets/29_Case8_nm_ModuleA.png width=400>      | `ModuleA`에는 자신의 목적 파일만 포함한다.      |
| <img src=Assets/30_Case8_nm_ModuleB.png width=400>      | `ModuleB`에는 자신의 목적 파일만 포함한다.      |
| <img src=Assets/31_Case8_nm_ModuleC.png width=400>      | `ModuleC`에는 자신의 목적 파일만 포함한다.      |
| <img src=Assets/32_Case8_nm_ModuleCommon.png width=400> | `ModuleCommon`에는 자신의 목적 파일만 포함한다. |



## 결론

- **Static Library**의 **Object file**은 종속성을 가지는 모듈이 아니라 **excutable file**에 포함된다. 
- 여러개의 **Dynamic Framework**가 하나의 **Static Library**에  종속성을 갖게 되면 몇가지 문제점이 있다.
  - **Dynamic Framework**는 각각의 **excutable file**을 만들기 때문에 종속성을 가지는 **Static Library**가 각각의 **Dynamic Framework**에 포함되어 중복이 발생한다.
  - 각각의 **Dynamic Framework**에서  **Static Library**의 **Singleton** 인스턴스는 서로 다른 인스턴스로 취급한다.


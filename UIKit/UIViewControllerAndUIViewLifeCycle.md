# UIViewController & UIView LifeCycle

> **Start**는 **메소드가 시작되었음**을, **End**는 **메소드가 끝난 것**을 의미한다. 만약 시작점과 끝점이 다를 경우 중간에 다른 많은 메소드들이 있다는 것을 의미한다.

## 1. ViewController(VC)— init(coder:) **Start / End**

- unarchiver로 ViewController를 초기화한다. 스토리보드로 VC를 초기화하는 경우 nib파일에서 unarchive되며 불리게 된다.

2. VC — awakeFromNib **Start / End**

- IB/nib 파일에서 로드되고 초기화가 다 되었다는 것을 알려준다. 이 메소드가 불릴 때는 이 VC와 관련된 Outlet, Action이 모두 연결되었다는 것을 보장한다.

3. VC — willMove(toParentViewController:) **Start / End**

- parentVC가 childVC를 추가할 때 childVC에서 불리게 되며 이 때 ParentView는 NavigationVC, TabBarVC가 될 수 있다.

4. VC — prefersStatusBarHidden, preferredStatusBarUpdateAnimation 등 StatusBar의 모습과 관련된 메소드들이 불린다.

## 5. VC — loadView() **Start**

- View를 로드하거나 만들어 VC의 view 프로퍼티에 할당한다.
- 스토리보드에 View가 존재할 경우 Nib 파일로부터 로드하지만 그렇지 않은 경우 plain한 View를 만들게 된다.
- 스토리보드로 View를 만들경우 이 메소드를 오버라이드하면 안 된다. 오직 새로운 뷰를 만들어 할당할 경우에 사용한다.

## 6. View — init(coder:) **Start**

- VC가 가지고 있는 View를 초기화하고 view 프로퍼티에 assign한다.

7. View — layerClass **Start / End**

- View의 layer를 그리는 데 쓰이는 기본적인 CALayer의 인스턴스를 반환한다.

8. View — setNeedsDisplay() **Start / End**

- View의 전체 바운드를 다시 그릴 필요가 있다라는 것을 마크해두는 것이다. 바로 다시 그려지지 않고 다음 그리기 주기에 그려진다.
- CAEAGLayer(OpenGL 컨텐트 그리기를 지원하는 Layer)를 통해 그리는 View는 영향이 없고 오로지 UIKit이나 CoreGraphics로 그려지는 것들만 영향을 받는다.
- 여러 번 불릴 수 있다.

9. View — translatesAutoresizingMaskIntoConstraints **Start / End**

- AutoLayout을 적용할 때 AutoresizingMask를 No로 해주는 것으로 Default 값은 Yes지만 IB로 View를 추가할 경우 No가 된다.

10. View — addConstraints(_:) / addConstraint(_:) **Start / End**

- 여러 번 addContstraint(_:) 호출하며 영향을 받는 View에 제약을 추가한다.
- 영향받는 View에는 subView들도 들어간다.
- constraint의 isActive 프로퍼티를 true로 해도 이 메소드와 영향은 같다.

## 11. View — init(coder:) **End**

12. View —willMove(toSuperview:) **Start / End**

- View에게 Superview가 바뀐다고 알려주는 메소드로 init(coder:)가 완료된 뒤 호출된다.
- 이 메소드는 기본적으로 Superview가 바뀌는 것을 알려주는 역할만 수행하며 SubClass는 이것을 오버라이드하여 Superview가 바뀔 때 하는 작업을 정의할 수 있다.
- newSuperview는 nil이 될 수 있다.

13. View — didMoveToSuperview() **Start / End**

- 마찬가지로 View에게 Superview가 바뀌었다고 알려주는 메소드이다.

14. View — awakeFromNib() **Start / End**

- View가 IB 또는 nib 파일로 부터 로드, 생성되었다는 의미이다.
- VC 때와 마찬가지로 Outlet, Action 연결이 모두 완료되었다는 것을 보장한다.

## 15. VC — loadView() **End**

16. VC — prepare(for:sender:) **Start / End**

- VC와 View의 awakeFromNib()의 호출이 완료되었다는 것은 모든 Outlet, Action의 연결이 되었다는 뜻이므로 segue를 준비하라는 뜻이다.

## 17. VC — viewDidLoad() Start / End

- View의 로드가 모두 끝났다는 의미이다.
- 다른 커스텀 초기화 작업을 여기서 해주면 된다.

## 18. VC — viewWillAppear() **Start / End**

- VC의 View가 이제 보일 준비를 한다는 뜻으로 이는 곧 View Hierarchy에 곧 포함될 것이란 말이 된다.
- view가 어떻게 보여질지 보여지기 전 꾸밀 수 있는 기회이다.

19. View — willMove(toWindow:) **Start / End**

- 새로운 View Hierarchy에 들어가게 되므로 View Hierarchy의 root에 해당되는 window 객체가 바뀐다는 의미이다.
- 이 메소드는 기본적으로 window 객체가 바뀌는 것을 알려주는 역할만 수행하며 SubClass는 이것을 오버라이드하여 window 객체가 바뀔 때 하는 작업을 정의할 수 있다.
- newWindow는 nil이 될 수 있다.

20. View — needsUpdateConstraints() **Start / End**

- View의 제약들이 갱신되어야 할 필요를 나타내는 메소드로 지금 불릴 때는 true를 반환한다.
- *cf) 추측이지만 새로운 View Hierarchy에 들어가 이제 컨텐트를 실제로 보여주기 때문에(intrinsic content size… 등을 고려해야 하기 때문에) 제약들을 갱신해야 하는 건지도 모르겠다.(***피드백 부탁드립니다.***)*

21. View — didMoveToWindow() **Start / End**

- window 객체가 바뀐 것이 완료했다고 알려주는 메소드이다.

22. View — translatesAutoresizingMaskIntoConstraints **Start / End**

- 여러 번 불리며 다시 제약들을 갱신할 준비를 한다.

23. View — updateConstraints() **Start**

- 제약들을 갱신한다.

24. View — intrinsicContentSize **Start / End**

- 고유 사이즈를 리턴하여 View를 layout하는데 반영한다.

25. View — updateConstraints() **End**

26. VC — updateViewConstraints() **Start / End**

- VC가 가지는 View의 제약들을 갱신할 필요가 있기에 불린다.

27. VC — viewWillLayoutSubviews() **Start / End**

- VC의 View가 이제 Subview들을 배치하기시작할 때 VC에게 알려주는 메소드이다.
- VC에게 시점을 알려주는 역할만 하는 메소드이다.

28. View — layoutSubviews() **Start / End**

- 하위 View들을 배치한다.
- iOS 5.1 이하 버전에서는 아무것도 하지 않지만 그 이상에서는 그 동안 설정한 제약들을 바탕으로 하위 View들의 사이즈와 위치를 정한다.
- 여러 번 불릴 수 있다.
- 이것을 강제로 호출하는 것은 바람직하지 못하며 setNeedsLayout()을 통해 다음 그리기 주기 때 다시 그려지던지 아니면 layoutIfNeeded()를 통해 바로 업데이트하게끔 한다.

29. View — alignmentRectInsets **Start / End**

- 커스텀 뷰가 그것의 컨텐트를 고려해 inset을 맞출 때 물어보는 것으로 frame만 고려하는 것이 아니라 View의 컨텐트를 기반으로 View의 정렬을 맞추게 한다.

30. VC — viewDidLayoutSubviews() **Start / End**

## 31. View — draw(_:) Start / End

- 전달된 CGRect 타입의 rect 값으로 View를 그린다.

## 32. VC — viewDidAppear() **Start / End**

- View가 화면에 나타나는 때를 알려준다.

33. VC — didMove(toParentViewController:) **Start / End**

- ParentVC에 VC가 더해졌다는 것을 의미한다.
- View가 구성되고 보여진 후에 더해진다는 것을 알 수 있다.
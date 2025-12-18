# 💻 DEVELOPMENT GUIDE: PIP iOS App (SwiftUI)

안녕하세요! 이 문서는 우리가 함께 만들어갈 PIP 앱의 iOS 개발을 위한 나침반입니다. 데이터 분석의 세계에서 앱 개발의 세계로 오신 것을 환영합니다! 모든 것이 낯설게 느껴질 수 있지만, 이 가이드가 든든한 길잡이가 되어줄 것입니다.

우리의 목표는 Figma로 디자인한 아름답고 직관적인 경험을 실제 작동하는 앱으로 완벽하게 구현하는 것입니다. 이 문서는 그 여정을 위한 기술적인 약속과 지도를 담고 있습니다.

---

## 1. 🏛️ 우리 앱의 건축 설계: MVVM 아키텍처

우리는 **MVVM (Model-View-ViewModel)** 이라는 설계 방식을 따를 것입니다. 처음에는 복잡해 보일 수 있지만, 역할 분담을 통해 오히려 작업을 훨씬 쉽게 만들어주는 매우 효율적인 방법입니다.

*   **🎨 View (화면)**: 사용자가 눈으로 보고 터치하는 모든 것입니다. Figma로 디자인한 바로 그 화면이죠. SwiftUI 코드로 작성되며, 화면을 그리고 사용자 입력을 받는 역할만 합니다.
    *   *(예: `HomeView.swift`는 스와이프 카드 UI를 보여주는 역할)*
*   **🧠 ViewModel (두뇌)**: `View`의 두뇌 역할을 합니다. "사용자가 카드를 오른쪽으로 스와이프했네? 그럼 '긍정'으로 기록하고, 다음 카드를 보여줘야지!" 와 같은 모든 판단과 로직을 처리합니다. `View`에 필요한 데이터를 가공해서 전달합니다.
    *   *(예: `HomeViewModel.swift`는 오늘의 기록 목록을 가지고 있고, 스와이프 액션을 처리함)*
*   **📦 Model (데이터 상자)**: 순수한 데이터 덩어리입니다. 앱에서 사용하는 데이터의 모양을 정의합니다. 예를 들어, '감정 기록'은 날짜, 텍스트, 감정 점수 등을 담고 있는 '상자'와 같습니다.
    *   *(예: `JournalEntry.swift`는 날짜, 내용, 사용자가 선택한 감정 등을 담는 구조체)*
*   **🚚 Service (배송 트럭)**: `ViewModel`의 요청에 따라 데이터를 가져오거나 저장하는 '배송 트럭'입니다. Firebase(우리 앱의 창고)와 통신하여 데이터를 안전하게 배달하는 역할을 전담합니다.
    *   *(예: `FirebaseService.swift`는 새로운 감정 기록을 Firestore에 저장하는 코드를 담고 있음)*

**왜 이렇게 나눌까요?** 디자이너가 화면(`View`)을 수정하는 동안, 개발자는 데이터 처리 로직(`ViewModel`)을 동시에 작업할 수 있습니다. 각자 역할이 명확해서 코드가 섞이지 않고, 테스트와 유지보수가 훨씬 쉬워집니다.

---

## 2. 🧰 기술 도구함 (Tech Stack)

우리 프로젝트 주방에서 사용할 핵심 도구들입니다.

| 영역 | 주요 도구 | 역할 (쉽게 말해) |
| :--- | :--- | :--- |
| **UI 프레임워크** | **SwiftUI** | Figma 디자인을 실제 코드로 구현하는 '디자인 도구' |
| **상태 관리** | **Combine** | 데이터가 바뀌면 화면도 자동으로 바뀌게 하는 '실시간 연결선' |
| **데이터베이스**| **Firebase Firestore**| 모든 사용자 데이터를 안전하게 보관하는 '클라우드 창고' |
| **서버 로직** | **Firebase Cloud Functions**| 복잡한 데이터 분석 등, 앱이 하기 힘든 일을 처리하는 '외부 전문가'|
| **의존성 관리** | **Swift Package Manager**| Firebase 같은 외부 도구를 쉽게 설치/관리하는 '설치 매니저' (`pip`와 비슷!) |
| **테스트** | **XCTest** | 우리 앱이 계획대로 잘 작동하는지 확인하는 '품질 검사원' |

---

## 3. 🗺️ 기능 개발 지도 (Feature Development Map)

Figma 디자인과 기획안을 바탕으로, 각 탭을 어떻게 개발할지 구체적으로 그려봅시다.

### 3.1. 🏠 Home (Journaling)

*   **사용자 목표:** "오늘 내게 무슨 일이 있었고, 나는 무엇을 느꼈는가?"
*   **핵심 기능:** 데이터 수집, 시각화
*   **개발 전략:**
    1.  **스와이프 UI:** 틴더(Tinder)처럼 좌/우로 스와이프하여 감정을 기록하는 UI를 구현합니다. SwiftUI의 `DragGesture`를 활용하여 사용자 제스처에 따라 카드가 움직이고, 특정 지점을 넘어가면 다음 카드를 보여주는 로직을 `HomeViewModel`에서 처리합니다.
    2.  **게이미피케이션:** 기록을 완료할 때마다 그날의 데이터를 나타내는 **보석(Jewel)**이 생성되는 시각적 피드백을 제공합니다. 이 보석은 `View`에 애니메이션 효과와 함께 나타나 사용자에게 성취감을 줍니다.
    3.  **데이터 저장:** 스와이프가 완료되면 `HomeViewModel`은 `FirebaseService`를 통해 해당 기록(`JournalEntry` 모델)을 Firestore에 저장합니다.

### 3.2. 💎 Insight

*   **사용자 목표:** "나는 무엇을 개선해야 할까?"
*   **핵심 기능:** 일/주/월 단위 인사이트 리포트 제공
*   **개발 전략:**
    1.  **오브(Orb) 시각화:** 사용자의 데이터를 분석하여 얻은 복합적인 인사이트를 **오브(Orb)** 형태로 시각화합니다. Orb는 색상, 크기, 내부 패턴 등을 파라미터로 받아 동적으로 생성되는 재사용 가능한 SwiftUI `View`로 만듭니다.
    2.  **대시보드:** `InsightViewModel`은 Firestore에서 사용자의 기록을 집계하고 분석하여 점수 예측, 추세 등을 계산합니다. 이 데이터는 대시보드 UI에 시각적으로 표현됩니다.
    3.  **스토리 형식 리포트:** 개별 리포트를 클릭하면 인스타그램 스토리처럼 전체 화면으로 나타나고, 화면을 탭하면 다음 리포트로 넘어가는 UI를 구현합니다. `TabView`나 `UIPageViewController`를 SwiftUI와 연동하여 구현할 수 있습니다.

### 3.3. 🎯 Goals

*   **사용자 목표:** "내가 되고 싶은 모습은 무엇이고, 얼마나 가까워졌나?"
*   **핵심 기능:** 행동 교정 프로그램 제안 및 진행 상황 추적
*   **개발 전략:**
    1.  **젬(Gems) 시각화:** 각 프로그램의 성격과 유형을 나타내는 **젬(Gems)**을 디자인에 맞춰 구현합니다. 젬 또한 Orb처럼 파라미터를 받아 동적으로 모양과 색상이 변하는 SwiftUI `View`로 만듭니다.
    2.  **진행 상황 시각화:** 프로그램의 진행률을 보여주기 위해 SwiftUI의 기본 차트나 커스텀 `Shape` 및 `Path`를 사용하여 원형 프로그레스 바, 라인 차트 등을 구현합니다.
    3.  **검색 및 제안:** `GoalViewModel`에서 사용자가 참여할 수 있는 프로그램 목록을 관리하고, 검색 기능을 구현하여 사용자가 원하는 프로그램을 찾을 수 있도록 합니다.

### 3.4. 🏆 Status

*   **사용자 목표:** "나는 지금까지 무엇을 해냈는가?"
*   **핵심 기능:** 달성 현황, 뱃지, 통계 비교
*   **개발 전략:**
    1.  **달성 현황 UI:** 연속 기록일, 총 기록 개수, 완료한 프로그램 수를 `StatusViewModel`에서 계산하여 화면에 표시합니다.
    2.  **뱃지 시스템:** 특정 조건을 만족했을 때(예: 30일 연속 기록) 얻게 되는 뱃지를 시각화합니다. 뱃지 목록은 `GridView`를 사용하여 깔끔하게 보여줍니다.
    3.  **가치관 분석:** 다른 사용자와의 익명화된 데이터 비교는 `Firebase Cloud Functions`에서 복잡한 계산을 처리하고, 앱은 그 결과만 받아서 시각화에 집중합니다. (MVP 이후 고려)

---

## 4. ✨ 디자인 시스템 구현 (Design System in Code)

Figma의 디자인을 코드로 옮겨, 언제든 재사용할 수 있는 부품으로 만듭니다.

### 4.1. 색상 (Colors)

`Assets.xcassets`에 색상을 등록하거나, `Color` 익스텐션(Extension)을 만들어 사용합니다. 이렇게 하면 "Teal-Bright"처럼 의미 있는 이름으로 색상을 사용할 수 있어 실수를 줄일 수 있습니다.

**`Color+Extensions.swift` 예시:**
```swift
import SwiftUI

extension Color {
    // Background
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#000000"), Color(hex: "#202020")]),
        startPoint: .top,
        endPoint: .bottom
    )

    // Accent: Teal System
    static let tealLogo = Color(hex: "#31B0B0")
    // ... 나머지 색상 추가
    
    // Text
    static let primaryText = Color.white
}
```

### 4.2. 타이포그래피 (Typography)

`Pretendard` 폰트를 일관되게 적용하기 위해 `Font` 익스텐션을 만듭니다.

**`Font+Extensions.swift` 예시:**
```swift
import SwiftUI

extension Font {
    static func pretendard(size: CGFloat, weight: PretendardWeight = .regular) -> Font {
        return .custom("Pretendard-\(weight.rawValue)", size: size)
    }
}

enum PretendardWeight: String {
    case bold = "Bold"
    case medium = "Medium"
    case regular = "Regular"
    // ... 나머지 굵기 추가
}
```

### 4.3. 핵심 시각 요소: Gems, Orbs, Jewels

이들은 단순한 이미지가 아닌, 데이터에 따라 모습이 변하는 살아있는 객체입니다. 각각 별도의 SwiftUI `View` 파일로 만듭니다.

**`OrbView.swift` (가상 코드):**
```swift
struct OrbView: View {
    let brightness: Double // 데이터 완성도 (0.0 ~ 1.0)
    let complexity: Int    // 데이터 특성 (기하학적 다양성)
    let uncertainty: Double // 모델 불확실성 (네온 섀도우)

    var body: some View {
        ZStack {
            // 1. 기본 도형: complexity에 따라 다른 모양
            // 2. 글래스 효과: .background(.ultraThinMaterial)
            // 3. 밝기 조절: .brightness(brightness)
            // 4. 네온 섀도우: .shadow(color: .tealLogo.opacity(uncertainty), radius: 20)
        }
    }
}
```

---

## 5. 🛠️ 개발 환경 설정 및 폴더 구조

1.  **Firebase 설정:** Firebase 콘솔에서 iOS 앱을 만들고, `GoogleService-Info.plist` 파일을 다운받아 `PIP_Project/PIP_Project/` 폴더에 넣습니다.
2.  **폰트 설정:** `03_Development/assets/fonts/`의 폰트 파일들을 Xcode 프로젝트에 추가하고, `Info.plist`에 "Fonts provided by application" 항목을 등록합니다.
3.  **프로젝트 열기:** `PIP_Project/PIP_Project.xcodeproj` 파일을 Xcode로 열어 개발을 시작합니다.

**추천 폴더 구조 (`PIP_Project/PIP_Project/` 내부):**
```
├── Application/         // 앱의 시작점 (PIP_ProjectApp.swift)
├── Views/               // 화면 (View)
│   ├── Home/
│   ├── Insight/
│   ├── Goals/
│   └── Status/
├── ViewModels/          // 두뇌 (ViewModel)
├── Models/              // 데이터 상자 (Model)
├── Services/            // 배송 트럭 (Service)
├── Components/          // 재사용 부품 (Gems, Orbs, Buttons...)
├── Extensions/          // 확장 도구 (Color+, Font+...)
└── Resources/
    └── Assets.xcassets  // 이미지, 색상 등 리소스
```

---
이 가이드가 당신의 손에 들린 지도가 되길 바랍니다. 막히는 부분이 있다면 언제든지 다시 질문해주세요. 함께 멋진 앱을 만들어봅시다!

# 🎯 온보딩 플로우 설계: 목표 기반 개인화 시작

이 문서는 PIP 앱의 초기 온보딩 경험을 설계합니다. 사용자가 처음 앱을 켰을 때 목표를 설정하고, 데이터 수집의 목적을 이해하며, 기대할 수 있는 인사이트를 미리 경험할 수 있도록 합니다.

---

## 1. 온보딩 플로우의 핵심 가치

### 1.1. 왜 목표 기반 온보딩인가?

**문제점:**
- 사용자가 앱의 가치를 즉시 이해하지 못함
- 어떤 데이터를 왜 수집해야 하는지 불명확
- 초기 사용 후 이탈률이 높음

**해결책:**
- **목표 설정을 통한 개인화**: 사용자의 구체적인 목표를 설정하여 앱을 "나만의 도구"로 만들기
- **데이터 수집 목적 명확화**: 수집하는 데이터가 목표 달성에 어떻게 도움이 되는지 설명
- **인사이트 가치 미리보기**: 목표 달성 후 받을 수 있는 인사이트를 시뮬레이션으로 보여주기

### 1.2. 핵심 원칙

1. **차분한 명료함 (Calm Clarity)**: 압도적이지 않으면서도 명확한 정보 제공
2. **점진적 공개**: 한 번에 모든 것을 보여주지 않고, 단계별로 정보 제공
3. **즉각적 가치 제공**: 온보딩 중에도 사용자가 "아, 이게 나에게 도움이 되겠구나"를 느낄 수 있도록
4. **게이미피케이션**: 목표 설정과 데이터 수집을 즐거운 경험으로 만들기

---

## 2. 온보딩 플로우 구조

### 2.1. 전체 플로우 다이어그램

```
LaunchView
    ↓
[온보딩 체크] → 이미 완료? → MainTabView
    ↓ 아니오
WelcomeView (1단계)
    ↓
GoalSelectionView (2단계)
    ↓
DataCollectionIntroView (3단계)
    ↓
InsightPreviewView (4단계)
    ↓
OnboardingCompleteView (5단계)
    ↓
MainTabView (첫 Gem 생성 유도)
```

### 2.2. 단계별 상세 설계

#### **1단계: WelcomeView - 환영 및 가치 제안**

**목적**: PIP가 무엇인지, 왜 사용해야 하는지 간단히 소개

**내용:**
- PIP 로고 및 브랜딩
- 핵심 가치 제안: "나를 이해하는 가장 스마트한 방법"
- 간단한 설명: "당신의 감정, 행동, 신체 데이터를 분석하여 개인화된 인사이트를 제공합니다"
- "시작하기" 버튼

**UX 특징:**
- 최소한의 텍스트
- 시각적 메타포 (Gem/Orb) 미리보기
- 부드러운 애니메이션

**소요 시간**: 약 10-15초

---

#### **2단계: GoalSelectionView - 목표 설정 (틴더 스타일)**

**목적**: 사용자의 구체적인 목표를 설정하여 개인화된 경험 제공

**UI/UX (틴더 스타일)**:
- 틴더처럼 카드를 좌우로 스와이프하여 목표 선택
- 카드 스택 형식으로 목표 카테고리 표시:
  - 🧘 웰니스 & 마음의 평온
  - 💪 생산성 향상
  - 😊 감정 관리
  - 🏃 신체 건강
  - 👥 사회적 관계
  - 📚 학습 & 성장
  - ✨ 커스텀 목표 (직접 입력)
- **좌측 스와이프**: 관심 없음 (다음 카드로)
- **우측 스와이프**: 선택 (목표에 추가)
- **상단 스와이프**: 나중에 보기
- 선택한 목표는 하단에 표시 (최대 2개)
- 한 두개의 목표 선택 후 "다음" 버튼 활성화

**인터랙션:**
- 각 카테고리를 Gem 형태의 카드로 표시
- 스와이프 시 부드러운 애니메이션
- 선택 시 Gem이 밝아지는 피드백
- 최소 1개, 최대 2개 선택 권장

**데이터 저장:**
- 선택한 목표들을 `UserProfile.initialGoals`에 저장
- 이후 Goal 뷰에서 자동으로 생성

**UX 특징:**
- 틴더처럼 직관적인 스와이프 인터랙션
- 시각적으로 매력적인 Gem 카드
- 선택 피드백이 즉각적
- 부담 없는 선택 (나중에 변경 가능 안내)

**소요 시간**: 약 30-60초

---

#### **3단계: ProgramSelectionView - 프로그램 선택**

**목적**: 선택한 목표에 맞는 구체적인 프로그램 제시 및 선택

**UI/UX:**
- 선택한 목표에 맞는 프로그램 목록 표시
- 각 프로그램 카드 클릭 시 상세 정보:
  - **간단한 설명**: 프로그램이 무엇인지
  - **기대 효과**: 어떤 효과를 기대할 수 있는지
  - **필요한 데이터 목록**: 어떤 데이터를 수집해야 하는지
- 프로그램 선택 후 "시작하기" 버튼

**소요 시간**: 약 1-2분

---

#### **4단계: DataConsentView - 민감 정보 동의**

**목적**: 필요한 데이터에 대한 명시적 동의 수집

**내용:**
- 선택한 프로그램에 필요한 데이터 목록:
  - 날씨
  - 스크린타임
  - 위치
  - 심박수
  - 걸음수
  - 건강 데이터 (수면, 활동량 등)
- 각 데이터별:
  - 수집 목적 설명
  - 사용 방법 설명
  - 개인정보 보호 정책 링크
  - 개별 동의 토글

**인터랙션:**
- 필수 데이터와 선택 데이터 구분
- 필수 데이터는 동의 필수
- 선택 데이터는 선택적 동의
- "모두 동의" 옵션 제공 (선택 데이터 포함)

**데이터 저장:**
```swift
UserDataCollectionSettings(
    accountId: accountId,
    enabledDataTypes: ["mood", "stress", "weather", "location", "heartRate", "steps"],
    permissions: DataPermissions(
        screenTime: .granted,
        healthKit: .granted,
        location: .granted,
        // ...
    ),
    // ...
)
```

**UX 특징:**
- 명확한 정보 제공
- 사용자 선택권 존중
- 투명한 데이터 사용 정책

**소요 시간**: 약 1-2분

---

#### **4단계: InsightPreviewView - 인사이트 미리보기**

**목적**: 데이터 수집 후 받을 수 있는 인사이트를 시뮬레이션으로 보여주기

**내용:**
- 목표별 맞춤 인사이트 예시:
  - 예시 1: "이번 주 감정 패턴 분석"
    - 시각화: Orb 애니메이션
    - 텍스트: "당신의 감정 점수가 평균 0.72로, 이전 주 대비 5% 상승했습니다"
  
  - 예시 2: "목표 달성 예측"
    - 시각화: 진행률 차트
    - 텍스트: "현재 진행 속도라면 목표 달성까지 약 3주가 소요될 것으로 예상됩니다"

- 인사이트의 가치 강조:
  - "이런 인사이트를 통해 당신만의 최적의 패턴을 발견할 수 있습니다"
  - "데이터가 쌓일수록 더 정확하고 개인화된 인사이트를 받을 수 있습니다"

**UX 특징:**
- 실제 인사이트 뷰와 유사한 디자인
- 애니메이션으로 생동감 제공
- "이제 시작하기" 버튼으로 다음 단계 유도

**소요 시간**: 약 30-45초

---

#### **5단계: OnboardingCompleteView - 완료 및 첫 기록 유도**

**목적**: 온보딩 완료를 축하하고, 첫 저널 기록을 유도

**내용:**
- 축하 메시지: "준비가 완료되었습니다!"
- 첫 Gem 생성 유도:
  - "지금 바로 첫 번째 저널을 작성하고 당신만의 Gem을 만들어보세요"
  - "매일의 기록이 모여 당신을 이해하는 데이터가 됩니다"
  
- 빠른 시작 가이드:
  - "하단 탭바의 Write 탭에서 카드를 스와이프하여 감정을 기록하세요"
  - "기록이 완료되면 오늘의 Gem이 생성됩니다"

**인터랙션:**
- "첫 기록 시작하기" 버튼 → MainTabView로 이동 (Write 탭 자동 활성화)
- "나중에 하기" 버튼 → MainTabView로 이동 (Home 탭 표시)

**UX 특징:**
- 성취감을 주는 디자인
- 명확한 다음 액션 제시
- 부담 없는 선택권 제공

**소요 시간**: 약 15-20초

---

## 3. 데이터 모델

### 3.1. OnboardingState

```swift
struct OnboardingState: Codable {
    var isCompleted: Bool
    var completedSteps: [OnboardingStep]
    var selectedGoals: [GoalCategory]
    var completedAt: Date?
    var skippedSteps: [OnboardingStep]
}

enum OnboardingStep: String, Codable {
    case welcome
    case goalSelection
    case dataCollectionIntro
    case insightPreview
    case onboardingComplete
}
```

### 3.2. UserProfile 확장

```swift
// 기존 UserProfile에 추가
struct UserProfile: Codable {
    // ... 기존 필드들
    
    // 온보딩 관련
    var onboardingState: OnboardingState
    var initialGoals: [GoalCategory]  // 온보딩에서 선택한 초기 목표
    var firstJournalDate: Date?        // 첫 저널 작성 날짜
}
```

### 3.3. OnboardingGoal (임시 목표)

```swift
struct OnboardingGoal: Identifiable, Codable {
    let id: UUID
    var category: GoalCategory
    var title: String
    var description: String
    var iconName: String
    var isSelected: Bool
}
```

---

## 4. 구현 전략

### 4.1. 앱 진입점 수정

**현재 구조:**
```
LaunchView → MainTabView
```

**수정 후 구조:**
```
LaunchView → OnboardingCheck → OnboardingFlow 또는 MainTabView
```

### 4.2. OnboardingCheck 로직

```swift
struct OnboardingCheckView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        Group {
            if viewModel.shouldShowOnboarding {
                OnboardingFlowView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            viewModel.checkOnboardingStatus()
        }
    }
}
```

### 4.3. OnboardingFlowView

```swift
struct OnboardingFlowView: View {
    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedGoals: [GoalCategory] = []
    
    var body: some View {
        ZStack {
            PrimaryBackground()
                .ignoresSafeArea()
            
            switch currentStep {
            case .welcome:
                WelcomeView(onNext: { currentStep = .goalSelection })
            case .goalSelection:
                GoalSelectionView(
                    selectedGoals: $selectedGoals,
                    onNext: { currentStep = .dataCollectionIntro }
                )
            case .dataCollectionIntro:
                DataCollectionIntroView(
                    selectedGoals: selectedGoals,
                    onNext: { currentStep = .insightPreview }
                )
            case .insightPreview:
                InsightPreviewView(
                    selectedGoals: selectedGoals,
                    onNext: { currentStep = .onboardingComplete }
                )
            case .onboardingComplete:
                OnboardingCompleteView(
                    onStart: {
                        // 온보딩 완료 처리
                        // MainTabView로 이동 + 첫 저널 유도
                    }
                )
            }
        }
    }
}
```

---

## 5. UX 고려사항

### 5.1. 진행률 표시

- 상단에 진행 바 또는 단계 인디케이터 표시
- 예: "1 / 5" 또는 점으로 표시

### 5.2. 뒤로가기 처리

- 각 단계에서 뒤로가기 가능
- 단, WelcomeView에서는 뒤로가기 없음 (앱 종료 또는 건너뛰기)

### 5.3. 건너뛰기 옵션

- DataCollectionIntroView와 InsightPreviewView에서 "건너뛰기" 제공
- 건너뛴 단계는 나중에 다시 볼 수 있도록 설정에 옵션 제공

### 5.4. 애니메이션

- 단계 전환 시 부드러운 페이드/슬라이드 애니메이션
- Gem/Orb 시각화 시 미묘한 애니메이션으로 생동감 제공

### 5.5. 접근성

- VoiceOver 지원
- 다이나믹 타입 지원
- 색상 대비 준수

---

## 6. 온보딩 완료 후 첫 경험

### 6.1. MainTabView 첫 진입 시

- **Write 탭 자동 활성화** (선택한 경우): 온보딩에서 "첫 기록 시작하기" 선택 시 바로 Write 탭으로 이동
- **Write 탭 강조**: 처음 사용자를 위해 Write 탭 버튼에 시각적 강조 (예: 맥박 애니메이션)
- **튜토리얼 툴팁**: Write 탭에서 "카드를 스와이프하여 감정을 기록하세요" 가이드 제공

### 6.2. 첫 저널 작성 후

- **축하 애니메이션**: 첫 저널 작성 완료 시 특별한 애니메이션
- **자동 이동**: Home 탭으로 자동 이동하여 생성된 첫 Gem 표시
- **뱃지 부여**: "첫 Gem" 뱃지 자동 부여
- **인사이트 안내**: "데이터가 쌓이면 더 많은 인사이트를 받을 수 있습니다"

### 6.3. 5개 탭의 역할

- **Home**: 일일 기록된 Gem 확인 (Railroad 뷰)
- **Insight**: 데이터 분석 및 인사이트 조회
- **Write**: 카드 스와이프를 통한 일일 감정/신체/행동 기록 (新)
- **Goal**: 목표 설정 및 진행도 추적
- **Status**: 전체 현황 및 설정

---

## 7. 온보딩 재진입

### 7.1. 설정에서 다시 보기

- Status 탭 → Settings → "온보딩 다시 보기" 옵션
- 선택한 단계부터 다시 시작 가능

### 7.2. 목표 변경

- GoalView에서 온보딩에서 설정한 초기 목표 수정 가능
- 목표 추가/삭제 시 관련 인사이트도 업데이트

---

## 8. 측정 지표 (Analytics)

온보딩의 효과를 측정하기 위한 지표:

- **온보딩 완료율**: 시작한 사용자 중 완료한 비율
- **목표 선택 분포**: 어떤 목표가 가장 많이 선택되는지
- **첫 저널 작성율**: 온보딩 완료 후 첫 저널을 작성한 비율
- **온보딩 완료 후 7일 리텐션**: 온보딩 완료 후 7일 후에도 사용하는 비율
- **건너뛴 단계**: 어떤 단계가 가장 많이 건너뛰어지는지

---

## 9. 향후 개선 사항

### 9.1. 개인화 강화

- 사용자의 응답에 따라 온보딩 플로우 동적 조정
- 더 많은 목표 카테고리 추가
- 목표별 맞춤 인사이트 예시 확대

### 9.2. 게이미피케이션 강화

- 온보딩 중에도 작은 성취감 제공
- 진행률에 따른 시각적 보상

### 9.3. 소셜 요소

- 친구 초대 기능 (온보딩 완료 후)
- 목표 공유 기능

---

## 10. 구현 우선순위

### Phase 1 (MVP)
- [ ] OnboardingState 모델 생성
- [ ] OnboardingCheck 로직 구현
- [ ] WelcomeView 구현
- [ ] GoalSelectionView 구현
- [ ] 기본 플로우 연결

### Phase 2
- [ ] DataCollectionIntroView 구현
- [ ] InsightPreviewView 구현
- [ ] OnboardingCompleteView 구현
- [ ] 첫 저널 유도 로직

### Phase 3
- [ ] 애니메이션 및 시각화 개선
- [ ] 접근성 개선
- [ ] Analytics 연동
- [ ] 온보딩 재진입 기능

---

**작성일**: 2025.12  
**버전**: 1.0  
**상태**: 설계 완료

# 🛠️ 06. Analytics Implementation Plan

**작성일**: 2026.01.15
**버전**: 1.0

---

## 1. 개요
`05_Analytics_Strategy.md`에서 정의한 **Session-Based Batching** 전략을 구현합니다.
기존 `AnalyticsService`의 기능을 활용하여, 앱 전반(`WriteView`, `Onboarding`, `Navigation`)에 로그 수집 로직을 연결합니다.

## 2. User Review Required
> [!IMPORTANT]
> **Privacy Compliance**: `Privacynfo.xcprivacy` 파일에 수집 항목 정의가 필요합니다. (추후 작업)
> **Session Logic**: `WriteView` 이탈 시(저장 안 하고 닫기) `status: aborted`로 로그가 남도록 구현해야 합니다.

## 3. Proposed Changes

### A. AnalyticsService Refinement
#### [MODIFY] [AnalyticsService.swift](file:///Users/neo/ACCEL/PIP_Project/PIP_Project/PIP_Project/Services/Analytics/AnalyticsService.swift)
- `logEvent`를 `currentSessionLog`의 `metrics`에 단순 카운팅하는 로직 확인 및 보완.
- `metrics` 딕셔너리에 `step` 배열 외에 `input_counts` 등을 쉽게 추가할 수 있는 Helper 메서드 추가.

### B. Write Flow Integration
#### [MODIFY] [WriteViewModel.swift](file:///Users/neo/ACCEL/PIP_Project/PIP_Project/PIP_Project/ViewModels/WriteViewModel.swift)
- **Session Start**: `init` 또는 `onAppear` 시점에서 `AnalyticsService.shared.startSession(name: "write_flow")` 호출.
- **Interaction Tracking**: 카드 스와이프(`accumulate`), 슬라이더 조작 시 `AnalyticsService.shared.logEvent("input_interaction")` 호출.
- **Session End (Success)**: `commitSession` 성공 시 `AnalyticsService.shared.endSession(status: "completed")` 호출.
- **Session End (Abort)**: `WriteSheet`가 닫힐 때(`onDisappear`) 저장이 안 되었다면 `endSession(status: "aborted")` 호출.

### C. Navigation & System Integration
#### [NEW] [AnalyticsModifier.swift](file:///Users/neo/ACCEL/PIP_Project/PIP_Project/PIP_Project/Utilities/AnalyticsModifier.swift)
- SwiftUI `ViewModifier` 생성.
- `onAppear`: `AnalyticsService.shared.trackScreenView(name)` 호출.
- `onDisappear`: 체류 시간 계산 로직은 `AnalyticsService` 내부에서 처리하므로 단순 트리거.

#### [MODIFY] [PIP_ProjectApp.swift](file:///Users/neo/ACCEL/PIP_Project/PIP_Project/PIP_Project/PIP_ProjectApp.swift)
- `ScenePhase` 감지 로직 추가.
- `.background` 진입 시 `AnalyticsService.shared.endNavigationSession()` 호출하여 플러시.
- `.active` 진입 시 `AnalyticsService.shared.startNavigationSession()` 호출.

## 4. Verification Plan

### 3.1. Automated Verification (Logs)
1. **Console Log Check**:
   - 앱 실행 및 네비게이션 시 `📊 [Analytics] Buffered screen view: ...` 로그 확인.
   - 앱 백그라운드 전환 시 `📊 [Analytics] Navigation session flushed. Count: ...` 로그 확인.

### 3.2. Manual Verification (Firestore)
1. **Navigation**:
   - 앱 실행 -> 탭 이동(Home -> Insight -> Write) -> 홈 버튼 눌러 백그라운드 전환.
   - Firebase Console > `analytic_logs` 컬렉션 확인.
   - 최신 문서의 `metrics.steps` 배열에 이동 경로가 저장되었는지 확인.
2. **Write Flow**:
   - Write 버튼 클릭 -> 카드 몇 장 넘기기 -> "닫기" 버튼 (저장 X).
   - Firebase Console 확인 -> `status: "aborted"`, `card_swipe_count` 확인.
   - 다시 Write 진입 -> 끝까지 작성 -> 저장.
   - Firebase Console 확인 -> `status: "completed"`.

# 📊 05. Analytics Strategy & Metrics

**작성일**: 2026.01.15
**버전**: 1.0
**상태**: 초안 (Draft)

---

이 문서는 40년차 Engagement 마케터의 조언을 바탕으로 PIP 프로젝트의 앱 개선을 위한 **핵심 분석 지표 (North Star Metrics)**와 이를 수집하기 위한 **로그 설계 (Logging Design)**를 정의합니다.

목표는 사용자가 PIP 앱에서 느끼는 가치와 이탈 지점을 정확히 파악하여, 데이터 기반으로 UX를 지속적으로 개선하는 것입니다.

---

## 1. 핵심 분석 지표 (North Star Metrics)

우리는 다음 4가지 카테고리의 지표를 통해 서비스의 건전성을 측정합니다.

### 1.1. 🧭 네비게이션 및 체류 지표 (Navigation & Stickiness)
사용자가 앱 내에서 길을 잃지 않고 목적을 달성하는지 확인합니다.

*   **화면별 평균 체류 시간 (Average Time on Screen)**
    *   **목표**: `InsightView` / `AnalysisCardView` (긴 체류 권장), `WriteView` (짧고 효율적인 체류 권장)
    *   **분석 방법**: 화면 진입 시점(`onAppear`)과 이탈 시점(`onDisappear`)의 차이를 계산.
*   **화면 전환 경로 (User Flow/Pathways)**
    *   **주요 경로**: `HomeView` → `WriteView` → `HomeView` (데일리 저널링 루틴)
    *   **분석 방법**: `previous_screen` 파라미터를 통해 유입 경로 추적.
*   **이탈률 (Bounce/Exit Rate per Screen)**
    *   **집중 모니터링**: `Onboarding` 단계별 이탈률, `WriteView` 진입 후 저장 없이 이탈하는 비율.

### 1.2. 🌪️ 퍼널 전환 지표 (Funnel Conversion)
단순 방문자를 충성 유저로 전환시키는 핵심 단계의 효율성을 측정합니다.

*   **온보딩 퍼널 (Onboarding Funnel)**
    *   단계: `Welcome` → `GoalSelection` → `ProgramSelection` → `DataConsent` → `InsightPreview` → `Complete`
    *   **지표**: 단계별 전환율 (Conversion Rate) 및 전체 완료율.
*   **핵심 액션 전환율 (Key Action Conversion)**
    *   **Gem 생성 (Journaling)**: `WriteView` 진입 대비 `save_card` 완료 비율.
    *   **프로그램 참여**: `ProgramDetailView` 조회 대비 `enroll_program` 클릭 비율.

### 1.3. 🔄 사용자 리텐션 지표 (Retention & Loyalty)
사용자의 꾸준한 습관 형성을 측정합니다.

*   **코호트 리텐션 (Cohort Retention)**
    *   **기준**: 첫 Gem 생성일(D-Day) 기준 D+1, D+7, D+30 재방문 및 Gem 생성 비율.
    *   **분석**: `subject_id` (Anonymous ID) 기준 코호트 분석.
*   **사용자 고착도 (Stickiness - DAU/MAU)**
    *   월간 활성 사용자(MAU) 대비 일간 활성 사용자(DAU) 비율.
    *   PIP와 같은 데일리 웰니스 앱은 20% 이상을 목표로 함.

### 1.4. 💎 인게이지먼트 질적 지표 (Quality of Engagement)
단순 접속을 넘어선 깊이 있는 상호작용을 측정합니다.

*   **세션당 이벤트 수 (Events per Session)**
    *   한 번 접속 시 발생하는 의미 있는 상호작용(스크롤, 탭, 드래그 등) 수.
    *   예: `OrbView` 인터랙션, 차트 스크러빙 횟수.
*   **세션당 체류 시간 (Session Duration)**
    *   앱 실행(Foreground)부터 종료(Background)까지의 총 시간.

---

## 2. Analytic Logs 설계 (Cost-Optimized Schema)

Firebase 비용 절감(Document Writes 최소화)과 UX 저해 방지(Non-blocking)를 위해 **Session-Based Batching** 전략을 사용합니다.
개별 이벤트마다 로그를 남기는 대신, 하나의 세션(예: 네비게이션, 글쓰기 등)이 끝날 때 묶어서 하나의 Document로 저장합니다.

### 2.1. Log Document 구조 (`analytic_logs` collection)

모든 로그는 `analytic_logs/{log_id}` 경로에 저장되며, `subject_id`로 익명화됩니다.

```json
{
  "id": "UUID",
  "subject_id": "UUID (IdentityMapping verified)",
  "category": "navigation" | "write_view" | "onboarding" | "general",
  "sessionType": "navigation_session" | "write_flow_morning" | ...,
  "startTime": Timestamp,
  "endTime": Timestamp,
  "status": "completed" | "aborted",
  "metrics": {
    "total_duration": 120.5,
    "screen_view_count": 5,
    "steps": [ ... ] // Array of batched events
  }
}
```

### 2.2. 카테고리별 상세 Metrics 구조

**A. Navigation Session (Batched)**
*   앱 사용 중 발생하는 화면 이동을 `metrics.steps` 배열에 모아서 저장합니다.
*   **Trigger**: 앱 진입 시 `startNavigationSession` → 백그라운드 전환 시 `endNavigationSession` (Flush)

| Metrics Key | Type | Description |
| :--- | :--- | :--- |
| `steps` | `Array<Object>` | `[{ "type": "screen_view", "screen_name": "home", "timestamp": 123... }, { "to_tab": "insight", "duration": 5.2 }]` |
| `total_duration` | `Double` | 세션 전체 지속 시간 (초) |

**B. Write Flow Session**
*   글쓰기 시작부터 완료/취소까지의 흐름을 기록합니다.
*   **Trigger**: `WriteView` 진입 시 시작 → 저장(`save_card`) 완료 시 종료

| Metrics Key | Type | Description |
| :--- | :--- | :--- |
| `card_swipe_count` | `Int` | 카드를 넘긴 횟수 |
| `input_interaction_count` | `Int` | 슬라이더, 버튼 등 입력 조작 횟수 |
| `write_mode` | `String` | `card` (기본) |

**C. Onboarding Session**
*   온보딩 과정의 단계별 이탈 포인트를 파악합니다.

| Metrics Key | Type | Description |
| :--- | :--- | :--- |
| `last_step_index` | `Int` | 마지막으로 도달한 단계 인덱스 (0~4) |
| `completed_steps` | `Array<String>` | `["welcome", "goal_selection"]` |

### 2.3. Optimization Logic (구현 반영)
1.  **Memory Buffering**: `logEvent` 호출 시 즉시 DB에 쓰지 않고 메모리(`eventLogs`/`navigationEvents`)에 적재합니다.
2.  **Batch Write**: `endSession`(또는 `endNavigationSession`) 호출 시점에만 Firestore에 1회 쓰기를 수행합니다.
3.  **Background Flush**: 앱이 백그라운드로 내려갈 때(`scenePhase` 감지) 자동으로 세션을 종료하고 저장하여 데이터 손실을 방지합니다.

---

## 3. Apple 개인정보 보호 정책 준수 (iOS Compliance)

iOS 앱 스토어 심사 지침(App Store Review Guidelines 5.1.1) 및 App Privacy(Nutrition Labels) 요구사항을 준수하기 위해 다음 원칙을 따릅니다.

### 3.1. 수집 데이터의 정의 및 분류
App Store Connect의 "앱이 수집하는 개인정보" 섹션에 기재해야 할 항목입니다.

| 데이터 유형 | 수집 항목 | 목적 | Apple 분류 |
| :--- | :--- | :--- | :--- |
| **Identifiers** | `subject_id` (User ID) | 사용자 식별 및 데이터 연결 | **User ID** (App Functionality) |
| **Usage Data** | `screen_view`, `button_click`, `duration` | UX 개선 및 제품 상호작용 분석 | **Product Interaction** (Analytics) |
| **Diagnostics** | `app_close` (crash, performance tags) | 앱 안정성 모니터링 | **Crash Data**, **Performance Data** (Analytics) |
| **Health & Fitness** | `mood_score`, `stress_level` | 핵심 서비스 기능 제공 | **Health**, **Fitness** (App Functionality) |

### 3.2. 개인정보 보호 원칙
1.  **IDFA 미사용**: 광고 목적의 추적(Tracking)을 하지 않으므로 `IDFA`를 수집하지 않으며, **AppTrackingTransparency(ATT)** 팝업을 띄우지 않습니다.
    *   대신, `IDFV` (Identifier for Vendor) 또는 자체 생성 `UUID`를 사용하여 기기/설치별 고유성을 확보합니다.
2.  **Fingerprinting 방지**: 기기를 식별하기 위해 배터리 잔량, 디스크 용량, 정밀 기기 모델명 등 불필요한 하드웨어 정보를 조합하여 수집하지 않습니다.
3.  **데이터 최소화**: 분석에 꼭 필요한 데이터만 전송하며, 민감한 개인정보(이름, 이메일 등)는 `analytic_logs`에 직접 포함하지 않고 `user_profiles`에만 안전하게 보관합니다.
4.  **HealthKit 데이터 분리**: HealthKit을 통해 가져온 데이터(걸음 수 등)는 마케팅/광고 목적으로 사용하지 않으며, 오직 건강 분석 서비스 제공 목적으로만 사용합니다.

---

## 4. 구현 가이드

1.  **AnalyticsService**: `logEvent(category, eventName, params)` 메서드 구현.
2.  **ViewModifier**: SwiftUI 뷰에 `.trackScreen(name)` Modifier를 부착하여 `onAppear`/`onDisappear` 자동 추적.
3.  **Session Manager**: 앱 라이프사이클을 감지하여 `session_id` 생성 및 `app_open`/`app_close` 로깅 관리.
4.  **Privacy Manifest**: `PrivacyInfo.xcprivacy` 파일에 위에서 정의한 수집 항목을 명시하여 Apple의 자동 개인정보 감지 시스템에 대응합니다.

---

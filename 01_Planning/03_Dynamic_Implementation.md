# ⚙️ 03. 동적 구현 및 진행 상황

이 문서는 Firebase 연동, 기능 구현 등 지속적으로 변경되는 동적인 개발 현황을 추적하고 기록합니다.

---

## 목차

1.  [Firebase 연동 진행 상황](#1-firebase-연동-진행-상황) (`FIREBASE_INTEGRATION_PROGRESS.md`)
2.  [UserStats 업데이트 구현 상세](#2-userstats-업데이트-구현-상세) (`USERSTATS_UPDATE_IMPLEMENTATION.md`)

---

## 1. Firebase 연동 진행 상황
(Source: `01_Planning/FIREBASE_INTEGRATION_PROGRESS.md`)

# 🔥 Firebase Integration Progress (2026-01-08)

이 문서는 [DB_MODEL_DESIGN.md](./DB_MODEL_DESIGN.md)에 정의된 21개 테이블의 Firebase 연동 진행 상황을 추적합니다.

## 📊 전체 진행률

**완료:** 7 / 21 테이블 (33%)
**진행 중:** 8 테이블 (UI 개선 및 완성 필요)
**미구현:** 6 테이블 (서버 전용 또는 향후 작업)

**마지막 업데이트:** 2026-01-09
**주요 변경:** UserStats 업데이트 구현 완료, TimeSlotBarChart MVP 완성

---

## 🗂️ 계층별 상세 진행 상황

### 🔐 Identity Layer (100% 완료)

| 테이블 | 상태 | 구현 내용 | 비고 |
|---|---|---|---|
| **user_accounts** | ✅ 완료 | Firebase Auth 통합 완료 | AuthService.swift |
| **identity_mappings** | ✅ 완료 | IdentityMappingService 구현 | 암호화 매핑 로직 완성 |
| **anonymous_user_identities** | ✅ 완료 | 자동 생성 로직 완성 | IdentityMappingService 내부 |

**완료율:** 3/3 (100%)

---

### 👤 User Profile Layer (100% 완료)

| 테이블 | 상태 | 구현 내용 | Firestore 경로 |
|---|---|---|---|
| **user_profiles** | ✅ 완료 | CRUD 전체 구현 | `users/{accountId}/profile/data` |
| **user_stats** | ✅ 완료 | 생성/읽기/업데이트 구현 | `users/{accountId}/stats/summary` |

**완료율:** 2/2 (100%)

**구현 상세:**
- ✅ OnboardingViewModel: 온보딩 완료 시 UserProfile + UserStats 생성
- ✅ HomeViewModel: UserStats 조회 (Records, Streaks)
- ✅ **StatusView**: 사용자 Nickname 표시 UI 구현됨 (ProfileHeaderSection에서 `displayName` 사용). **Fix:** now uses active `DataService` (DataServiceManager) by default so real SignUp data (Firestore) appears instead of Mock. Also fixed profile doc mismatch (Auth wrote to `profile/info` → now writes to `profile/data`, and `FirebaseDataService` now falls back to `profile/info` for backward-compatibility).

---

### 🔬 Time Series Data Layer (33% 완료)

| 테이블 | 상태 | 구현 내용 | Firestore 경로 |
|---|---|---|---|
| **time_series_data_points** | ✅ 완료 | 읽기/쓰기 구현 | `anonymous_users/{anonId}/time_series/{dataId}` |
| **ml_feature_vectors** | ⏸️ 보류 | 서버 전용 테이블 | N/A |
| **ml_model_outputs** | ⏸️ 보류 | 서버 전용 테이블 | N/A |

**완료율:** 1/3 (33%)

**구현 상세:**
- ✅ WriteViewModel: TimeSeriesDataPoint 저장 기능 구현
- ⏳ **WriteView 슬라이더/그래프**: MVP 시간대별 바 차트 구현 (TimeSlotBarChart). 입력값 배열 저장 지원 및 MockData 예시 추가. UI 미세조정 필요

---

### 📊 Aggregation Layer (50% 완료)

| 테이블 | 상태 | 구현 내용 | Firestore 경로 |
|---|---|---|---|
| **daily_gems** | ✅ 완료 | 읽기/쓰기 구현 | `users/{accountId}/daily_gems/{gemId}` |
| **period_reports** | ❌ 미구현 | 모델 미정의 | - |

**완료율:** 1/2 (50%)

**구현 상세:**
- ✅ HomeViewModel: 지난 7일 DailyGems 조회 + 스트릭 계산
- ✅ GemDetailView: 특정 날짜 Gem 상세보기
- ⚠️ **HomeView "Today" 표시 버그**: Gem이 없어도 "Today" 표시됨 → **TODO**

---

### 💡 Insight & Visualization Layer (0% 완료)

| 테이블 | 상태 | 구현 내용 | 비고 |
|---|---|---|---|
| **insights** | ❌ 미구현 | 모델 존재, Firestore 연동 필요 | InsightView에서 사용 예정 |
| **orb_visualizations** | ❌ 미구현 | 모델 존재, Firestore 연동 필요 | OrbView에서 사용 예정 |
| **insight_analysis_cards** | ❌ 미구현 | 모델 존재, Firestore 연동 필요 | DashboardView에서 사용 예정 |
| **prediction_data** | ❌ 미구현 | 모델 미정의 | - |

**완료율:** 0/4 (0%)

---

### 🎯 Goal & Program Layer (60% 완료)

| 테이블 | 상태 | 구현 내용 | Firestore 경로 |
|---|---|---|---|
| **goals** | ✅ 완료 | 전체 CRUD 구현 | `users/{accountId}/goals/{goalId}` |
| **programs** | ✅ 완료 | 읽기 구현 (글로벌 카탈로그) | `programs/{programId}` |
| **user_program_enrollments** | ❌ 미구현 | 모델 존재, Firestore 연동 필요 | - |
| **program_specific_data_points** | ❌ 미구현 | 모델 미정의 | - |
| **program_success_metrics** | ❌ 미구현 | 모델 미정의 | - |

**완료율:** 2/5 (40%)

**구현 상세:**
- ✅ GoalViewModel: fetchGoals, saveGoal, updateGoal, deleteGoal 완성
- ✅ OnboardingViewModel: 추천 Programs 조회 및 선택 기능

---

### 🏆 Achievement & Status Layer (0% 완료)

| 테이블 | 상태 | 구현 내용 | 비고 |
|---|---|---|---|
| **badges** | ❌ 미구현 | 모델 존재(Achievement), Firestore 연동 필요 | StatusView에서 사용 예정 |
| **value_analysis** | ❌ 미구현 | 모델 존재, Firestore 연동 필요 | StatusView에서 사용 예정 |

**완료율:** 0/2 (0%)

---

## 🚀 최근 완료 작업 (2026-01-08~09)

### ✅ 완료된 작업
1. **WriteViewModel: UserStats 자동 업데이트**
   - `saveCard()` 메서드: TimeSeriesDataPoint + DailyGem 저장 후 자동으로 `updateUserStats()` 호출
   - `updateUserStats()`: 새로운 날짜인지 판별하여 totalGemsCreated, totalDaysActive 증가
   - `calculateAndUpdateStreak()`: 로컬 데이터 기반 currentStreak/longestStreak 정확 계산

2. **TimeSlotBarChart MVP 구현 완성**
   - 6구간 바 차트 (mood_timeline) UI 완성
   - 드래그로 값 입력 가능
   - `SwipeableCardView`에 통합, `WriteViewModel`에 배열 값 저장 지원
   - MockData에 예시 데이터 추가

3. **HomeViewModel 개선**
   - 자정 자동 새로고침 기능 (Streak 업데이트)
   - NotificationCenter를 통한 카드 저장 감지 (실시간 새로고침)
   - Combine Publisher 기반 데이터 바인딩

4. **DataService 인프라 안정화**
   - DataServiceManager.shared: 활성 서비스 싱글톤 관리
   - MockDataService/FirebaseDataService 패리티 확보
   - MainActor 동시성 처리 완료

### 📈 코드 통계
- WriteViewModel: 500 라인 (UserStats 통합)
- HomeViewModel: 398 라인 (자동 새로고침 포함)
- 전체 Views: 5개 탭 구조 완성 (Home, Insight, Write, Goal, Status)

---

## 📋 다음 작업 (Priority Order)

### 🔴 High Priority - UI 버그 수정 & 완성

| 작업 | 위치 | 설명 | 상태 |
|---|---|---|---|
| ⚠️ **HomeView "Today" 버그** | HomeView.swift | Gem이 없을 때도 "Today" 표시됨 | 미해결 |
| ✅ **StatusView Nickname 표시** | StatusView.swift | ProfileHeaderSection에서 `displayName` 표시 | ✅ 완료 |
| 🔄 **WriteView 그래프 UX 개선** | [WriteView.swift](../PIP_Project/PIP_Project/Views/Home/Sections/WriteView.swift) | TimeSlotBarChart 사용성 개선 및 다른 입력 방식 테스트 | 진행 중 |
| 📝 **OnboardingFlow 구현** | Views/Onboarding/ | GoalSelectionView, DataConsentView 등 전체 온보딩 UI 구현 | 미시작 |

### 🟡 Medium Priority - Insight Layer 연동

| 작업 | 테이블 | 설명 | 진행률 |
|---|---|---|---|
| InsightView 데이터 연동 | insights, orb_visualizations | OrbView 데이터 바인딩 및 렌더링 | 0% |
| DashboardView 구현 | insight_analysis_cards | 카드 목록 조회 및 스토리 형식 렌더링 | 0% |
| PredictionView 구현 | prediction_data | 예측 데이터 시각화 | 0% |

### 🟢 Low Priority - Program & Advanced Features

| 작업 | 테이블 | 설명 | 진행률 |
|---|---|---|---|
| Program Enrollment 기능 | user_program_enrollments | 사용자가 프로그램에 참여하는 기능 | 0% |
| Program 진행 데이터 | program_specific_data_points | 프로그램 전용 데이터 수집 | 0% |
| Value Analysis View | value_analysis | StatusView에서 월간 값 분석 표시 | 0% |
| Badges & Achievement | badges | StatusView에서 배지 목록 표시 | 0% |

---

## 📁 관련 파일

### Core Services
- [DataServiceProtocol.swift](../PIP_Project/PIP_Project/Services/DataServiceProtocol.swift)
- [FirebaseDataService.swift](../PIP_Project/PIP_Project/Services/FirebaseDataService.swift)
- [MockDataService.swift](../PIP_Project/PIP_Project/Services/MockDataService.swift)
- [DataServiceManager.swift](../PIP_Project/PIP_Project/Services/DataServiceManager.swift)

### ViewModels
- [OnboardingViewModel.swift](../PIP_Project/PIP_Project/ViewModels/OnboardingViewModel.swift)
- [HomeViewModel.swift](../PIP_Project/PIP_Project/ViewModels/HomeViewModel.swift)
- [GoalViewModel.swift](../PIP_Project/PIP_Project/ViewModels/GoalViewModel.swift)

### Views
- [HomeView.swift](../PIP_Project/PIP_Project/Views/Home/HomeView.swift) ⚠️ 버그 수정 필요
- [WriteView.swift](../PIP_Project/PIP_Project/Views/Home/Sections/WriteView.swift) ⚠️ 그래프 구현 필요

---

## 🎯 마일스톤

- [x] **Phase 1: Auth & Identity** (완료 - 2025.12)
- [x] **Phase 2: User Profile & Goals & DailyGems** (완료 - 2026.01.08)
- [x] **Phase 2.5: UserStats Auto Update** (완료 - 2026.01.09)
- [ ] **Phase 3: UI Bug Fixes & Onboarding** ← 현재 단계
- [ ] **Phase 4: Insight Layer Integration**
- [ ] **Phase 5: Advanced Features (Program Enrollment, Value Analysis)**

---

**마지막 업데이트:** 2026-01-09  
**커밋:** `WriteViewModel.updateUserStats()` 구현 완료  
**다음 포커스:** HomeView "Today" 버그 수정, OnboardingFlow 구현

---

## 2. UserStats 업데이트 구현 상세
(Source: `01_Planning/USERSTATS_UPDATE_IMPLEMENTATION.md`)

# WriteView → UserStats 업데이트 구현 완료

## 📋 개요
**상태**: ✅ **완료**  
**작업 날짜**: 2026년 1월 9일  
**우선순위**: 1순위 (핵심 통계 정확성)

## 🎯 구현 목표
WriteView에서 카드를 저장할 때 DailyGem 뿐만 아니라 UserStats도 함께 업데이트하여 사용자의 통계 데이터를 실시간으로 동기화

## 📝 구현 세부사항

### 1. WriteViewModel.saveCard() 메서드 개선

#### 변경 사항:
```swift
// 새로운 날짜인지 확인 (데이터포인트 추가 전에 체크)
let calendar = Calendar.current
let today = calendar.startOfDay(for: now)
let isNewGem = !localDataPoints.contains { point in
    calendar.startOfDay(for: point.timestamp) == today
}

// 데이터 저장 후 UserStats 업데이트
await updateUserStats(for: now, isNewGem: isNewGem)
```

**핵심**:
- 데이터 추가 전에 "새로운 날짜"인지 판별
- `isNewGem` 플래그를 `updateUserStats()`에 전달

### 2. updateUserStats() 메서드 (신규 추가)

#### 기능:
- `fetchUserStats()`로 현재 UserStats 조회
- 다음 필드 업데이트:
  - `totalDataPoints += 1` (항상 증가)
  - `totalGemsCreated += 1` (새로운 날에만)
  - `totalDaysActive += 1` (새로운 날에만)
  - `currentStreak` & `longestStreak` (재계산)
  - `lastUpdated = Date()` (현재 시간)
- `updateUserStats()`로 Firebase에 저장

#### 구현 코드:
```swift
private func updateUserStats(for date: Date, isNewGem: Bool) async {
    // 1. UserStats 조회
    // 2. 필드 업데이트
    //    - totalDataPoints += 1
    //    - isNewGem인 경우: totalGemsCreated += 1, totalDaysActive += 1
    // 3. Streak 계산
    // 4. Firebase에 업데이트
}
```

### 3. calculateAndUpdateStreak() 메서드 (신규 추가)

#### 기능:
- 로컬 `localDataPoints`에서 날짜 집합 생성
- 어제부터 거슬러 올라가며 연속 기록된 일수 계산
- `currentStreak` 업데이트
- `longestStreak`이 현재 streak보다 작으면 갱신

#### 로직:
```
1. 로컬 데이터에서 unique한 날짜들 추출
2. 어제부터 시작하여 과거로 거슬러감
3. 데이터가 없는 날을 만날 때까지 연속 기록 일수 카운트
4. currentStreak = 카운트된 일수
5. longestStreak이 currentStreak보다 작으면 업데이트
```

**예시**:
- 어제 기록있음 ✓
- 그 전날 기록있음 ✓
- 그 전전날 기록있음 ✓
- 그 전전전날 기록없음 ✗
→ currentStreak = 3

## 🔄 데이터 흐름

```
WriteView.saveCard()
    ↓
WriteViewModel.saveCard()
    ├─ TimeSeriesDataPoint 생성 & 로컬 저장
    ├─ DailyGem 생성/업데이트 & 저장
    └─ UserStats 업데이트 & 저장 ✨ (신규)
        ├─ fetchUserStats() 조회
        ├─ updateUserStats() 계산
        │   ├─ totalDataPoints += 1
        │   ├─ totalGemsCreated & totalDaysActive (isNewGem 확인)
        │   └─ currentStreak & longestStreak 재계산
        └─ updateUserStats() 저장
    
    ↓
HomeViewModel.loadInitialData() (자동 새로고침)
    └─ UserStats 반영 ✓
```

## 📊 업데이트되는 필드

| 필드 | 로직 | 설명 |
|---|---|---|
| `totalDataPoints` | `+= 1` (항상) | 저장된 모든 데이터 포인트 누계 |
| `totalGemsCreated` | `+= 1` (isNewGem) | 새로운 날짜의 첫 기록일 때만 증가 |
| `totalDaysActive` | `+= 1` (isNewGem) | 기록한 총 일수 |
| `currentStreak` | 재계산 | 로컬 데이터 기반 어제부터의 연속 기록일 |
| `longestStreak` | 갱신 (currentStreak > oldLongest) | 역대 최장 streak |
| `lastUpdated` | `= Date()` | 마지막 업데이트 시간 |

## ✅ 검증 체크리스트

- [x] WriteViewModel.saveCard()에서 `isNewGem` 플래그 생성
- [x] UserStats 조회 로직 구현
- [x] 필드 업데이트 로직 구현
- [x] Streak 계산 헬퍼 함수 구현
- [x] Firebase 업데이트 호출
- [x] 에러 핸들링 및 로깅
- [x] MockDataService 호환성 확인
- [x] WriteView → saveCard 호출 경로 확인

## 🔧 기술 세부사항

### Combine 패턴
```swift
dataService.fetchUserStats()
    .sink(receiveCompletion: {...}, receiveValue: {...})
```

### Async/Await 패턴
```swift
await withCheckedContinuation { continuation in
    // Combine Publisher를 async/await로 변환
}
```

## 📌 주의사항

1. **로컬 vs 서버 데이터**
   - Streak 계산은 로컬 `localDataPoints` 기반
   - 서버 동기화 전의 로컬 상태로 계산됨

2. **새로운 날짜 판별**
   - `Calendar.startOfDay()`로 시간 부분 제거
   - UTC 기준이 아닌 기기의 로컬 타임존 기준

3. **비동기 처리**
   - UserStats 업데이트는 비동기 (await 필요)
   - WriteView에서 이미 async 컨텍스트에서 호출됨

## 🚀 다음 단계 (2순위)

- [ ] 온보딩 완료 시 Goal 자동 생성
- [ ] UserProgramEnrollment 모델 생성 및 저장
- [ ] Streak → UserStats 동기화 (HomeViewModel에서)

---

**작성자**: GitHub Copilot  
**마지막 수정**: 2026년 1월 9일

# 🔥 Firebase Integration Progress (2026-01-08)

이 문서는 [DB_MODEL_DESIGN.md](./DB_MODEL_DESIGN.md)에 정의된 21개 테이블의 Firebase 연동 진행 상황을 추적합니다.

## 📊 전체 진행률

**완료:** 7 / 21 테이블 (33%)
**진행 중:** 8 테이블 (UI 개선 및 완성 필요)
**미구현:** 6 테이블 (서버 전용 또는 향후 작업)

---

## 🗂️ 계층별 상세 진행 상황

### 🔐 Identity Layer (100% 완료)

| 테이블 | 상태 | 구현 내용 | 비고 |
|--------|------|-----------|------|
| **user_accounts** | ✅ 완료 | Firebase Auth 통합 완료 | AuthService.swift |
| **identity_mappings** | ✅ 완료 | IdentityMappingService 구현 | 암호화 매핑 로직 완성 |
| **anonymous_user_identities** | ✅ 완료 | 자동 생성 로직 완성 | IdentityMappingService 내부 |

**완료율:** 3/3 (100%)

---

### 👤 User Profile Layer (100% 완료)

| 테이블 | 상태 | 구현 내용 | Firestore 경로 |
|--------|------|-----------|----------------|
| **user_profiles** | ✅ 완료 | CRUD 전체 구현 | `users/{accountId}/profile/data` |
| **user_stats** | ✅ 완료 | 생성/읽기/업데이트 구현 | `users/{accountId}/stats/summary` |

**완료율:** 2/2 (100%)

**구현 상세:**
- ✅ OnboardingViewModel: 온보딩 완료 시 UserProfile + UserStats 생성
- ✅ HomeViewModel: UserStats 조회 (Records, Streaks)
- ⚠️ **StatusView**: 사용자 Nickname 표시 미구현 → **TODO**

---

### 🔬 Time Series Data Layer (33% 완료)

| 테이블 | 상태 | 구현 내용 | Firestore 경로 |
|--------|------|-----------|----------------|
| **time_series_data_points** | ✅ 완료 | 읽기/쓰기 구현 | `anonymous_users/{anonId}/time_series/{dataId}` |
| **ml_feature_vectors** | ⏸️ 보류 | 서버 전용 테이블 | N/A |
| **ml_model_outputs** | ⏸️ 보류 | 서버 전용 테이블 | N/A |

**완료율:** 1/3 (33%)

**구현 상세:**
- ✅ WriteViewModel: TimeSeriesDataPoint 저장 기능 구현
- ⚠️ **WriteView 슬라이더/그래프**: 시간대별 그래프 렌더링 미구현 → **TODO**

---

### 📊 Aggregation Layer (50% 완료)

| 테이블 | 상태 | 구현 내용 | Firestore 경로 |
|--------|------|-----------|----------------|
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
|--------|------|-----------|------|
| **insights** | ❌ 미구현 | 모델 존재, Firestore 연동 필요 | InsightView에서 사용 예정 |
| **orb_visualizations** | ❌ 미구현 | 모델 존재, Firestore 연동 필요 | OrbView에서 사용 예정 |
| **insight_analysis_cards** | ❌ 미구현 | 모델 존재, Firestore 연동 필요 | DashboardView에서 사용 예정 |
| **prediction_data** | ❌ 미구현 | 모델 미정의 | - |

**완료율:** 0/4 (0%)

---

### 🎯 Goal & Program Layer (60% 완료)

| 테이블 | 상태 | 구현 내용 | Firestore 경로 |
|--------|------|-----------|----------------|
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
|--------|------|-----------|------|
| **badges** | ❌ 미구현 | 모델 존재(Achievement), Firestore 연동 필요 | StatusView에서 사용 예정 |
| **value_analysis** | ❌ 미구현 | 모델 존재, Firestore 연동 필요 | StatusView에서 사용 예정 |

**완료율:** 0/2 (0%)

---

## 🚀 최근 완료 작업 (2026-01-08)

### ✅ 완료된 작업
1. **DataServiceProtocol 확장**
   - UserProfile, Goals, Programs, DailyGems, UserStats 메서드 추가

2. **FirebaseDataService 구현**
   - UserProfile: `saveUserProfile`, `fetchUserProfile`, `updateUserProfile`
   - Goals: `fetchGoals`, `saveGoal`, `updateGoal`, `deleteGoal`
   - Programs: `fetchPrograms`, `fetchProgram`, `fetchRecommendedPrograms`
   - DailyGems: `fetchDailyGems`, `saveDailyGem`
   - UserStats: `fetchUserStats`, `updateUserStats`

3. **MockDataService 구현**
   - 모든 Firebase 메서드와 동일한 인터페이스 구현
   - JSON 파일 기반 로컬 CRUD 동작

4. **ViewModel 연동**
   - OnboardingViewModel: 온보딩 완료 시 UserProfile + UserStats 생성
   - HomeViewModel: DailyGems + UserStats 조회
   - GoalViewModel: Goals 전체 CRUD 연동

5. **Infrastructure**
   - DataServiceManager.shared 싱글톤 추가
   - AppEnvironment.current 컴파일 플래그 지원
   - MainActor 동시성 문제 해결

### 🔧 기술적 개선사항
- Combine Publisher 기반 반응형 데이터 흐름
- 프로토콜 기반 의존성 주입으로 테스트 가능한 아키텍처
- Firebase Auth UID를 accountId로 사용
- Privacy-first: PII 데이터는 `users/{accountId}` 아래 저장

---

## 📋 다음 작업 (Priority Order)

### 🔴 High Priority - UI 버그 수정

| 작업 | 위치 | 설명 |
|------|------|------|
| ⚠️ **HomeView "Today" 버그** | [HomeView.swift](../PIP_Project/PIP_Project/Views/Home/HomeView.swift) | Gem이 없을 때도 "Today" 표시됨. RailroadView 로직 수정 필요 |
| ⚠️ **StatusView Nickname 표시** | StatusView.swift | UserProfile에서 displayName 조회하여 표시 필요 |
| ⚠️ **WriteView 시간대별 그래프** | [WriteView.swift](../PIP_Project/PIP_Project/Views/Home/Sections/WriteView.swift) | 슬라이더 설정 카드에서 시간대별 그래프 렌더링 구현 필요 |

### 🟡 Medium Priority - Insight Layer 연동

| 작업 | 테이블 | 설명 |
|------|--------|------|
| InsightView 연동 | insights, orb_visualizations | OrbView 데이터 바인딩 |
| DashboardView 연동 | insight_analysis_cards | 카드 목록 조회 및 렌더링 |

### 🟢 Low Priority - Program Enrollment

| 작업 | 테이블 | 설명 |
|------|--------|------|
| Program 등록 기능 | user_program_enrollments | 사용자가 프로그램에 참여하는 기능 |
| Program 진행 데이터 | program_specific_data_points | 프로그램 전용 데이터 수집 |

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

- [x] **Phase 1: Auth & Identity** (완료)
- [x] **Phase 2: User Profile & Goals** (완료)
- [ ] **Phase 3: UI Bug Fixes** ← 현재 단계
- [ ] **Phase 4: Insight Layer Integration**
- [ ] **Phase 5: Program Enrollment**

---

**마지막 업데이트:** 2026-01-08
**커밋:** `7a1f7a9` - feat(firebase): implement UserProfile, Goals, and DailyGems CRUD operations

# 🚀 01. PIP 프로젝트 인덱스

이 문서는 PIP 프로젝트의 마스터 인덱스로, 모든 핵심 정보와 문서로 연결되는 단일 진실 공급원(Single Source of Truth)입니다.

---

##  목차

1.  [프로젝트 개요 및 현황](#1-프로젝트-개요-및-현황)
2.  [DB 설계 및 연동 추천 스케줄](#2-db-설계-및-연동-추천-스케줄)
3.  [기술 스택 및 아키텍처](#3-기술-스택-및-아키텍처)
4.  [핵심 워크플로우](#4-핵심-워크플로우)
5.  [상세 문서 링크](#5-상세-문서-링크)

---

## 1. 프로젝트 개요 및 현황

(Source: `PROJECT_HANDOVER.md`, `AI_WORKFLOW_AND_CONTEXT.md`)

### 1.1. 프로젝트 비전 및 목표

**프로젝트명:** PIP (Personal Intelligence Platform)
**슬로건:** "나를 이해하는 가장 스마트한 방법, PIP"

**핵심 목표:**
-   개인 데이터 기반의 **PIP Score** 제공
-   AI 기반 **딥 인사이트**를 통한 맞춤형 웰니스/생산성 솔루션 제공
-   심리, 행동, 신체 데이터를 통합 분석하여 웰니스 증진과 생산성 향상 지원

### 1.2. 현재 프로젝트 상태 (2026.01.09 기준)

*   **Design System**: ✅ 완료 (컬러, 타이포그래피)
*   **DB 모델**: ✅ 설계 완료 (TimeSeriesDataPoint 중심, 21개 테이블)
*   **Firebase 연동**: 🔄 진행 중 (Identity/Profile/TimeSeries/Aggregation Layer 완료, 33%)
*   **Views 구현**: 🔄 진행 중 (HomeView 완성, WriteView 시간대별 그래프 MVP 완성)

*   **최근 완료 사항 (2026.01.08~09):**
    *   ✅ WriteViewModel: `saveCard()` → `updateUserStats()` 자동 호출 구현
    *   ✅ `calculateAndUpdateStreak()`: 로컬 데이터 기반 streak 정확 계산
    *   ✅ UserStats: totalDataPoints, totalGemsCreated, totalDaysActive 자동 업데이트
    *   ✅ TimeSlotBarChart: 6구간 바 차트 (mood_timeline) MVP 구현
    *   ✅ FirebaseDataService: UserProfile, Goals, Programs, DailyGems, UserStats CRUD 완성
    *   ✅ DataServiceManager: 싱글톤 패턴으로 활성 서비스 관리
    *   ✅ HomeViewModel: 자정 자동 새로고침, 스트릭 계산, UserStats 조회

*   **다음 진행 작업 (우선순위순):**
    *   🔴 HomeView "Today" 버그 수정 (Gem 없을 때도 표시됨)
    *   🔴 WriteView 그래프 UX 개선 및 테스트
    *   🟡 InsightView 연동 (insights, orb_visualizations)
    *   🟡 OnboardingFlow 구현 및 시작 연동
    *   🟢 Program Enrollment 기능

---

## 2. DB 설계 및 연동 추천 스케줄

소규모 ML/AI 프로젝트의 일반적인 DB 연동 및 개발 기간은 약 3주에서 5주 정도 소요될 수 있습니다.

| 단계 | 주요 작업 | 예상 기간 |
| :--- | :--- | :--- |
| **1단계** | **DB 모델링 및 설계 확정** | **2-3일** |
| | - `DB_MODEL_DESIGN` 기반으로 최종 데이터 모델 검토 및 확정<br>- `DATABASE_SCHEMA_DBDIAGRAM.sql` 업데이트 | |
| **2단계** | **Firebase 연동 및 기본 CRUD 구현** | **5-7일** |
| | - Firebase 프로젝트 설정 및 SDK 연동<br>- 주요 데이터 모델(Users, Goals 등)에 대한 생성/읽기/수정/삭제 기능 구현 | |
| **3단계** | **핵심 로직 및 AI 데이터 플로우 구현** | **7-10일** |
| | - `USERSTATS_UPDATE` 등 핵심 비즈니스 로직 구현<br>- AI 모델과 연동될 데이터의 입출력 파이프라인 구축 | |
| **4단계** | **View-ViewModel 데이터 바인딩** | **5-7일** |
| | - `VIEWS_VIEWMODELS_IMPLEMENTATION_PLAN` 기반으로 화면과 데이터 연동<br>- 각 View에서 필요한 데이터를 ViewModel을 통해 Firebase로부터 가져오도록 구현 | |
| **5단계** | **통합 테스트 및 안정화** | **3-5일** |
| | - 온보딩부터 전체 기능까지의 E2E(End-to-End) 테스트<br>- 발견된 버그 수정 및 성능 최적화 | |
| **총 예상 기간** | | **약 3-5주** |

---

## 3. 기술 스택 및 아키텍처

(Source: `PROJECT_HANDOVER.md`, `AI_WORKFLOW_AND_CONTEXT.md`)

### 3.1. 기술 스택

| 영역 | 확정 도구/기술 | 결정 사유 |
| :--- | :--- | :--- |
| **버전 관리** | **GitHub** | 모든 기획/코드의 시계열적 기록 및 CI/CD 연동 허브 역할. |
| **프론트엔드 (App)** | **SwiftUI (Native iOS)** | 네이티브 성능 극대화 및 최신 iOS 기능과의 완벽한 통합을 위해 선택. |
| **백엔드/분석** | **Firebase (Firestore + Cloud Functions)** | 1인 개발에 최적화된 BaaS. 복잡한 PIP Score 분석은 Cloud Functions로 분리하여 효율성 확보. |
| **CI/CD** | **GitHub Actions / Xcode Cloud** | Vercel과 같은 자동화 경험을 모바일 환경에 적용하여 빌드 및 배포 안정성 확보. |

### 3.2. 아키텍처 패턴: MVVM

PIP 앱은 **MVVM (Model-View-ViewModel)** 패턴을 따릅니다.

-   **View (SwiftUI):** UI만 담당하며, 비즈니스 로직이 없습니다.
-   **ViewModel (ObservableObject):** View와 Model 사이의 중재자. 사용자 액션을 처리하고 데이터를 가공하여 View에 전달합니다.
-   **Model (Codable):** 순수한 데이터 구조를 정의합니다.
-   **Service:** Firebase와의 통신 등 데이터 CRUD 작업을 담당합니다.

---

## 4. 핵심 워크플로우

(Source: `AI_WORKFLOW_AND_CONTEXT.md`)

### 4.1. Git 브랜치 전략

-   `main`: 프로덕션 준비 코드
-   `feature/[기능명]`: 새 기능 개발
-   `fix/[버그명]`: 버그 수정
-   `refactor/[대상]`: 리팩토링

### 4.2. 커밋 메시지 컨벤션

`[타입] 간단한 제목 (50자 이내)`

-   **타입:** `feat`, `fix`, `refactor`, `style`, `docs`, `test`, `chore`

### 4.3. 디렉토리 구조

-   `01_Planning/`: 기획 문서 (`.md` 형식)
-   `02_Design_Assets/`: 디자인 마스터 소스
-   `03_Development/`: AI/ML 모델 개발
-   `04_Distribution/`: 배포 및 심사 자료
-   `PIP_Project/`: iOS 앱 소스 코드

---

## 5. 상세 문서 링크

-   [**`02_Static_Architecture.md`**](./02_Static_Architecture.md): DB 모델, 온보딩 플로우, View/ViewModel 설계 및 구현 현황 (v1.1)
-   [**`03_Dynamic_Implementation.md`**](./03_Dynamic_Implementation.md): Firebase 연동 진행 상황, 마일스톤, 다음 작업 우선순위 (v1.2)
-   [**`DATABASE_SCHEMA_DBDIAGRAM.sql`**](./DATABASE_SCHEMA_DBDIAGRAM.sql): 전체 데이터베이스 스키마 (21 테이블, Firestore 구조)

---

## 🔗 빠른 참조

**현재 진행 중인 작업:**
- 🔴 HomeView "Today" 버그 수정
- 🔴 WriteView UX 개선
- 🟡 OnboardingFlow UI 구현

**최근 완료:**
- ✅ WriteViewModel: UserStats 자동 업데이트
- ✅ TimeSlotBarChart: MVP 구현
- ✅ HomeViewModel: 자정 자동 새로고침

**마지막 업데이트:** 2026.01.09  
**관리자:** GitHub Copilot

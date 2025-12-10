# 🚀 RELEASE PLAN: PIP 프로젝트 출시 및 배포 전략

이 문서는 MVP(최소 기능 제품) 출시를 위한 목표 설정, 필수 체크리스트, 그리고 배포 단계를 관리합니다.

## 1. 🎯 MVP 출시 목표 (Minimum Viable Product)

| 목표 영역 | 측정 지표 (KPI) | 초기 목표 (v1.0.0) |
| :--- | :--- | :--- |
| **비즈니스** | 설치 수 (Acquisition) | 출시 첫 달 1,000 다운로드 달성 |
| **핵심 기능** | 일일 활성 사용자 수 (DAU) | DAU 10% 유지 (전체 설치 대비) |
| **재무** | 유료 구독 전환율 (Trial to Paid) | 2% 달성 (향후 수익 모델 확정 후) |
| **웰니스 증진** | 주간 평균 PIP Score 개선 사용자 비율 | 15% 이상 |

## 2. 📝 App Store 심사 및 메타데이터 준비 (`04/AppStore_Metadata`)

### 2.1. 필수 메타데이터 체크리스트

* **앱 이름:** [PIP: Personal Intelligence Platform] (최종 확정)
* **부제:** [심리, 행동, 신체 분석 기반의 AI 웰니스 코치]
* **키워드:** (최대 100자) [Wellness, AI, Habit, Productivity, Journal, Mind, Sleep, Health]
* **앱 설명 (Short Description):** [PIP Score로 나를 정확히 파악하고, AI 인사이트로 최적의 일상을 설계하세요.] (최대 170자)
* **앱 설명 (Long Description):** (`04/AppStore_Metadata/long_description.md` 파일 별도 작성)

### 2.2. 필수 에셋 (`04/Screenshots` 및 `02/App_Icons`)

| 에셋 종류 | 필수 규격 | 상태 |
| :--- | :--- | :--- |
| **스크린샷** | 6.7인치 (1290x2796) 최소 5장 | [미완료] (Figma `04_App Store` 페이지 작업 필요) |
| **아이콘** | 1024x1024 (App Store Connect 용) | [미완료] (`02_Design_Assets/App_Icons`에 저장) |
| **개인정보 보호 정책 URL** | [미완료] (웹사이트 또는 Notion 페이지 필요) |

## 3. 🚀 배포 및 릴리즈 관리 (`04/Release_Notes`)

### 3.1. 릴리즈 버전 관리

* **v1.0.0 (MVP):** 핵심 기능 7가지 중 5가지 이상 필수 기능 완성.
* **v1.0.1:** 버그 수정 및 마이너 UI 개선.
* **v1.1.0:** 핵심 기능 7가지 완전 구현 및 새로운 데이터 시각화 도입.

### 3.2. 릴리즈 노트 작성 원칙

* **Git Tag 기반:** 모든 메인 릴리즈는 GitHub에 **Git Tag** (예: `v1.0.0`)로 기록됩니다.
* **사용자 중심:** 릴리즈 노트는 기술적 변경 대신 **사용자가 체감할 수 있는 개선 사항**을 중심으로 작성합니다.
    * **예시 (v1.0.0):** "PIP Score가 오늘부터 제공됩니다. 심리, 행동, 신체 데이터를 통합하여 지금 당신의 상태를 점수로 확인하세요."

## 4. 📢 마케팅 및 피드백 계획

* **초기 채널:** 개인 블로그, 개발 커뮤니티(Side Project), 지인 피드백.
* **피드백 수집:** 앱 내 피드백 기능 또는 Firebase Crashlytics/Analytics를 통한 사용자 행동 분석.
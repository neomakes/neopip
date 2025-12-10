# 🚀 PROJECT HANDOVER: PIP 프로젝트 설계 결정 마스터

## I. 프로젝트 진행 현황 및 시작점 (Status: 2025. 12. 10.)

* **현재 완료 상태:** 00\_1 (핵심 컬러 팔레트 정의) 완료.
* **다음 진행 작업:** 00\_2 (폰트 스타일 정의) 및 00\_3 (아이콘 세트 정의).
* **핵심 비전:** Black/Platinum 기반의 지적인 미니멀리즘 UX/UI.

---

## II. 시스템 및 설계 결정 기록 (Architecture Decision Records, ADR)

### 2.1. 기술 스택 및 연동 구조 확정

| 영역 | 확정 도구/기술 | 결정 사유 |
| :--- | :--- | :--- |
| **버전 관리** | **GitHub** | 모든 기획/코드의 시계열적 기록 및 CI/CD 연동 허브 역할. |
| **백엔드/분석** | **Firebase (Firestore + Cloud Functions)** | 1인 개발에 최적화된 BaaS (Backend as a Service). 복잡한 PIP Score 분석은 Cloud Functions로 분리하여 효율성 확보. |
| **CI/CD** | **GitHub Actions / Xcode Cloud** | Vercel과 같은 자동화 경험을 모바일 환경에 적용하여 빌드 및 배포 안정성 확보. |

### 2.2. 디자인 시스템 (00\_1 완료)

PIP의 지적인 미니멀리즘 콘셉트를 강화하기 위해 Black/Platinum을 기본으로 사용하며, 데이터의 상태를 명확히 구분하는 액센트 컬러를 정의했습니다.

| 역할 (Figma Style Name) | Hex Code | 의미 및 사용 목적 |
| :--- | :--- | :--- |
| **Background/Platinum** | `#E5E5E5` | 주 배경색. 미니멀하고 눈의 피로를 줄임. |
| **Primary/Black** | `#121212` | 주 텍스트 및 아이콘, 딥 분석 모드 배경. |
| **Accent/Amber\_Flame** | `#FF8A00` | **긍정 지표/성장.** PIP Score 활성 영역. |
| **Accent/Tiger\_Flame** | `#D94800` | **주의/경고 지표.** 스트레스 레벨, PIP Score 하락 영역. |
| **System/French\_Blue** | `#3A8EDF` | 시스템 요소, 중립적인 데이터 시각화. |
| **System/Wellness** | `#4CAF50` | 웰니스 달성, 습관 성공 상태. |

### 2.3. GitHub 기반 디렉토리 구조 확정

프로젝트의 모든 자산은 다음 구조를 따릅니다. **모든 기획 파일은 `.md` 형식으로 Git에 기록됩니다.**

* `01_Planning/`: 기획 문서 및 설계 결정 기록.
* `02_Design_Assets/`: 디자인 마스터 소스 (Figma Exports, Branding).
* `03_Development/`: 앱 코드 (`src/screens`, `src/services`) 및 백엔드 로직 (`src/functions`).
* `04_Distribution/`: 배포 및 심사 자료.

---

## III. 다음 작업 계획 (Focus: 00\_2)

**[🔥 즉시 시작]** `00_Design System` 페이지에서 PIP의 가독성과 지적인 분위기를 높일 폰트 스타일(크기, 굵기)을 정의합니다.

* **논의 필요:** 폰트 종류 (예: SF Pro, Pretendard 등 산세리프 계열)
* **목표:** H1, H2, Body, Caption 스타일을 정의하고 Figma에 등록.
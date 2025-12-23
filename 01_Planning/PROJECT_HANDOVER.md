# 🚀 PROJECT HANDOVER: PIP 프로젝트 설계 결정 마스터

## I. 프로젝트 진행 현황 및 시작점 (Status: 2025. 12. 23. 업데이트)

### 📊 전체 진행도
- **Design System**: ✅ 완료 (컬러, 타이포그래피)
- **DB 모델**: ✅ 설계 완료 (TimeSeriesDataPoint 중심)
- **Views 구현**: 🔄 진행 중 (HomeView 기본 완성, RailRoad 동적 배치 완성)

* **현재 완료 상태:**
    * ✅ `00_1` (핵심 컬러 팔레트), `00_2` (폰트 스타일) 정의 완료
    * ✅ **Xcode 프로젝트 생성 및 초기 설정 완료**
    * ✅ **`.gitignore` 파일에 Xcode 및 macOS 관련 항목 추가 완료**
    * ✅ **MockDataService 구현 완료 (최근 30일 데이터 생성)**
    * ✅ **HomeView 기본 구현 완료**
      - 고정 헤더 (\"Hi, UserName\" + Records/Streaks)
      - RailRoadView와의 레이아웃 통합
      - StatItem 정렬 개선 (아이콘 + 숫자 수직 중앙 정렬)
    * ✅ **RailRoadView 동적 배치 완성**
      - 오늘 Gem 중앙 고정, 과거 Gems 양쪽 확산
      - 투명도 및 스케일 동적 조정
      - 불필요한 streak 텍스트 제거
    * ✅ **currentStreak 계산 로직 수정**
      - 오늘 데이터 포함하여 정확한 연속 기록 일수 반영

* **최근 진행 사항 (2025.12.23)**
    * `MockDataService.generateMockData()`: 오늘 데이터 포함하도록 수정
    * `StatItem`: HStack(alignment: .center) + baselineOffset(-4)로 정렬 개선
    * `HomeView` 헤더: \"Hi, UserName\" 폰트 크기 증대 (.pip.title1 → .pip.hero)
    * `RailRoadView`: \"Current Streak: X days\" 텍스트 제거

* **다음 진행 작업:**
    * WriteView 구현 (카드 스와이프 입력)
    * InsightView 구현 (Orb 시각화)
    * GoalView & StatusView 구현
    * 온보딩 플로우 구현
    
* **핵심 비전:** **다크 모드(Black) 기반**의 지적인 미니멀리즘 UX/UI

---

## II. 시스템 및 설계 결정 기록 (Architecture Decision Records, ADR)

### 2.1. 기술 스택 및 연동 구조 확정

| 영역 | 확정 도구/기술 | 결정 사유 |
| :--- | :--- | :--- |
| **버전 관리** | **GitHub** | 모든 기획/코드의 시계열적 기록 및 CI/CD 연동 허브 역할. |
| **프론트엔드 (App)** | **SwiftUI (Native iOS)** | 네이티브 성능 극대화 및 최신 iOS 기능과의 완벽한 통합을 위해 선택. |
| **백엔드/분석** | **Firebase (Firestore + Cloud Functions)** | 1인 개발에 최적화된 BaaS. 복잡한 PIP Score 분석은 Cloud Functions로 분리하여 효율성 확보. |
| **CI/CD** | **GitHub Actions / Xcode Cloud** | Vercel과 같은 자동화 경험을 모바일 환경에 적용하여 빌드 및 배포 안정성 확보. |

### 2.2. 디자인 시스템 (00\_1, 00\_2 완료)

PIP의 지적인 미니멀리즘 콘셉트를 강화하기 위해 **다크 모드**를 중심으로 디자인 시스템을 확정했습니다.

#### 2.2.1. 컬러 팔레트 (Dark Mode Standard)

| 역할 (Figma Style Name) | Hex Code | 의미 및 사용 목적 |
| :--- | :--- | :--- |
| **Background/Black** | `#121212` | 앱의 주 배경색. 다크 모드 UI의 기반. |
| **Text/Platinum** | `#E5E5E5` | 기본 텍스트. 높은 가독성을 제공. |
| **Accent/Amber\_Flame** | `#FF8A00` | **긍정 지표/성장.** PIP Score 활성 영역. |
| **Accent/Tiger\_Flame** | `#D94800` | **주의/경고 지표.** 스트레스 레벨, PIP Score 하락 영역. |
| **System/French\_Blue** | `#3A8EDF` | 시스템 요소, 중립적인 데이터 시각화. |

#### 2.2.2. 타이포그래피 (Pretendard)

한글/영문 모두 뛰어난 가독성을 제공하고, 정보의 위계를 명확히 표현하기 위해 **Pretendard** 폰트를 채택했습니다.

| 역할 (Figma Style Name) | 크기/굵기 | 사용 목적 |
| :--- | :--- | :--- |
| **Display/H1** | 32pt / SemiBold | PIP Score 등 가장 강조할 핵심 수치. |
| **Headline/H2** | 24pt / Medium | 주요 섹션 제목. |
| **Title/H3** | 18pt / SemiBold | 카드 및 내비게이션 바 제목. |
| **Body/Default** | 16pt / Regular | 일반 본문 텍스트. |
| **Caption/Small** | 12pt / Regular | 보조 설명 및 레이블. |

### 2.3. GitHub 기반 디렉토리 구조 확정

프로젝트의 모든 자산은 다음 구조를 따릅니다. **모든 기획 파일은 `.md` 형식으로 Git에 기록됩니다.**

* `01_Planning/`: 기획 문서 및 설계 결정 기록.
* `02_Design_Assets/`: 디자인 마스터 소스 (Figma Exports, Branding).
* `03_Development/`: **AI/ML 모델 개발** (Python 스크립트, 학습 모델 등). 앱 소스 코드는 `PIP_Project/` 디렉토리로 이전.
* `04_Distribution/`: 배포 및 심사 자료.

---

## III. 다음 작업 계획 (Focus: 00\_3)

**[🔥 즉시 시작]** `00_Design System` 페이지에서 앱의 핵심 기능을 표현할 아이콘 스타일(Line vs Solid)과 세트를 정의합니다.

* **논의 필요:** 아이콘 스타일 통일성, 필수 아이콘 목록 (예: 홈, 분석, 설정 등)
* **목표:** 핵심 아이콘 20여 종을 확정하고 Figma Component로 등록.
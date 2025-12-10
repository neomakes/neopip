# 🎨 BRANDING GUIDE: PIP 디자인 시스템 상세 매뉴얼

이 문서는 Figma의 디자인 시스템을 앱 코드 (`03_Development/src/theme`)로 구현하기 위한 최종 가이드라인을 제공합니다.

## 1. 🌈 컬러 팔레트 (Color Palette)

`PROJECT_HANDOVER.md`에 정의된 핵심 컬러와, 코드 사용을 위한 역할 정의입니다.

| 역할 (Figma Style Name) | Hex Code | 코드 변수명 (예: Swift/Dart) | 사용 목적 |
| :--- | :--- | :--- | :--- |
| **Background/Platinum** | `#E5E5E5` | `Color.platinum` | 주 배경색, 카드 및 모달의 기본 배경. |
| **Primary/Black** | `#121212` | `Color.deepBlack` | 주 텍스트, 아이콘, 딥 분석 모드 배경. |
| **Accent/Amber_Flame** | `#FF8A00` | `Color.amberFlame` | **긍정 지표, 성장, 핵심 CTA 버튼 활성.** |
| **Accent/Tiger_Flame** | `#D94800` | `Color.tigerFlame` | **주의, 경고, 스트레스 지표.** |
| **System/French_Blue** | `#3A8EDF` | `Color.frenchBlue` | 중립적인 데이터 시각화 (예: 스케줄러 기본 블록). |
| **System/Wellness** | `#4CAF50` | `Color.wellnessGreen` | 웰니스 달성, 습관 성공 상태. |
| **Text/Secondary** | `#808080` | `Color.secondaryText` | 보조 텍스트, 캡션, 비활성 상태의 아이콘. |

## 2. 🔤 타이포그래피 (Typography) - **[미완료]**

PIP의 **지적인 미니멀리즘**을 완성할 폰트 종류와 스케일을 정의합니다. **(다음 작업 00\_2에서 확정 후 업데이트)**

**[폰트 선택]**
* **폰트 종류:** [선택된 산세리프 폰트 이름]
* **사용 이유:** [가독성, 미니멀리즘, OS 기본 지원 등]

| 역할 (Figma Style Name) | 크기 (pt) | 굵기 (Weight) | 사용 목적 |
| :--- | :--- | :--- | :--- |
| **Display/H1** | 32pt | Bold (700) | 메인 대시보드 PIP Score 숫자. |
| **Headline/H2** | 24pt | SemiBold (600) | 주요 섹션 제목. |
| **Title/H3** | 18pt | Medium (500) | 카드 제목, 모달 제목. |
| **Body/Default** | 16pt | Regular (400) | 일반적인 본문 텍스트. |
| **Body/Accent** | 16pt | SemiBold (600) | 본문 내 강조 텍스트. |
| **Caption/Small** | 12pt | Regular (400) | 보조 설명, 날짜 정보, 레이블. |

## 3. 🖼️ 아이콘 & 로고 원칙 (Iconography)

* **스타일:** 미니멀한 라인 아이콘(Line Icon) 및 솔리드 아이콘(Solid Icon) 혼용.
* **크기 표준:** `24pt`, `18pt` 표준 정의.
* **로고 사용:** `Primary/Black` 또는 `Background/Platinum` 위에만 사용 가능.

## 4. 🧱 컴포넌트 간격 및 그리드 (Spacing & Grid)

* **Spacing Rule:** **8pt 기반의 간격 규칙** 사용 (8, 16, 24, 32, 48pt).
* **Layout Grid:** 모바일 화면 기준, **8열 그리드 시스템**을 사용하여 레이아웃 유연성 확보.

---

## 5. 🔜 다음 작업 목록 및 상태

이 가이드 완성 후, Figma와 개발 준비 단계에서 진행해야 할 핵심 업무 목록입니다.

### A. Figma 디자인 시스템 완성 (00\_Design System)

| 단계 | 작업 내용 | 목표 상태 |
| :--- | :--- | :--- |
| **00\_2** | **폰트(Typography) 스타일 정의** | **[진행 예정]** `BRANDING_GUIDE.md` 업데이트 및 Figma Text Styles 등록. |
| **00\_3** | **아이콘 세트 제작/정의** | **[진행 예정]** 핵심 기능 아이콘 제작 및 Figma Components 등록. |
| **00\_4** | **레이아웃 그리드 정의** | **[진행 예정]** 8pt Spacing Rule Figma 설정 완료. |
| **00\_5** | **핵심 컴포넌트 제작** | **[진행 예정]** 버튼, PIP Score 게이지 등 재사용 컴포넌트 제작. |

### B. 주요 문서 및 스크린 제작

| 단계 | 작업 내용 | 목표 상태 |
| :--- | :--- | :--- |
| **01 (Low-Fi)** | **와이어프레임 설계** | **[진행 예정]** 7가지 기능의 사용자 흐름(Flow) 및 레이아웃 정의. |
| **02 (High-Fi)** | **앱 스크린 제작** | **[진행 예정]** 완성된 디자인 시스템을 적용하여 최종 UI 화면 제작. |
| **문서 (`03`)** | **DEVELOPMENT\_GUIDE.md 작성** | **[추후 작성]** Firebase 연동 및 Cloud Functions 배포 매뉴얼 준비. |
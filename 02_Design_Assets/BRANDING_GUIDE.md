# 🎨 BRANDING GUIDE: PIP 디자인 시스템 상세 매뉴얼

이 문서는 Figma의 디자인 시스템을 앱 코드 (`03_Development/src/theme`)로 구현하기 위한 최종 가이드라인을 제공합니다.

## 1. 🌈 컬러 팔레트 (Color Palette)

`PROJECT_HANDOVER.md`에 정의된 핵심 컬러와, 코드 사용을 위한 역할 정의입니다. **다크 모드**를 기준으로 재정의되었습니다.

| 역할 (Figma Style Name) | Hex Code | 코드 변수명 (예: Swift/Dart) | 사용 목적 |
| :--- | :--- | :--- | :--- |
| **Background/Black**      | `#121212`  | `Color.black`         | 앱의 주 배경색 (다크 모드 기준). |
| **Text/Platinum**         | `#E5E5E5`  | `Color.platinum`      | 기본 텍스트, 본문, 제목 등에 사용. |
| **Accent/Amber_Flame**    | `#FF8A00`  | `Color.amberFlame`    | 긍정 지표, 성장, 핵심 CTA 버튼 활성. |
| **Accent/Tiger_Flame**    | `#D94800`  | `Color.tigerFlame`    | 주의, 경고, 스트레스 지표. |
| **System/French_Blue**    | `#3A8EDF`  | `Color.frenchBlue`    | 중립적인 데이터 시각화, 보조 UI 요소. |

## 2. 🔤 타이포그래피 (Typography) - **[완료]**

PIP의 **지적인 미니멀리즘**과 **뛰어난 가독성**을 위해 Pretendard 폰트를 사용합니다.

**[폰트 선택]**
* **폰트 종류:** **Pretendard**
* **사용 이유:** 한글/영문 모두 아름답게 표현하며, 다양한 굵기를 지원하여 정보의 위계를 명확하게 전달할 수 있습니다. Android와 iOS에서 일관된 경험을 제공합니다.

| 역할 (Figma Style Name) | 크기 (pt) | 굵기 (Weight) | Pretendard 굵기 | 사용 목적 |
| :--- | :--- | :--- | :--- | :--- |
| **Display/H1** | 32pt | SemiBold (600) | Pretendard SemiBold | **PIP Score** 숫자 등 가장 중요하고 강조될 수치. |
| **Headline/H2** | 24pt | Medium (500) | Pretendard Medium | 주요 섹션 제목 (정보 전달의 핵심). |
| **Title/H3** | 18pt | SemiBold (600) | Pretendard SemiBold | 카드 제목, 내비게이션 바 타이틀. (가독성을 위해 Medium보다 약간 굵게) |
| **Body/Default** | 16pt | Regular (400) | Pretendard Regular | 일반적인 본문 텍스트, 저널 내용. **(가장 높은 가독성 필요)** |
| **Body/Accent** | 16pt | Medium (500) | Pretendard Medium | 본문 내 강조 텍스트, 리스트 아이템의 핵심 정보. |
| **Caption/Small** | 12pt | Regular (400) | Pretendard Regular | 보조 설명, 날짜/시간 정보, 레이블. |

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
| **00\_2** | **폰트(Typography) 스타일 정의** | **[완료]** `BRANDING_GUIDE.md` 업데이트 및 Figma Text Styles 등록. |
| **00\_3** | **아이콘 세트 제작/정의** | **[진행 예정]** 핵심 기능 아이콘 제작 및 Figma Components 등록. |
| **00\_4** | **레이아웃 그리드 정의** | **[진행 예정]** 8pt Spacing Rule Figma 설정 완료. |
| **00\_5** | **핵심 컴포넌트 제작** | **[진행 예정]** 버튼, PIP Score 게이지 등 재사용 컴포넌트 제작. |

### B. 주요 문서 및 스크린 제작

| 단계 | 작업 내용 | 목표 상태 |
| :--- | :--- | :--- |
| **01 (Low-Fi)** | **와이어프레임 설계** | **[진행 예정]** 7가지 기능의 사용자 흐름(Flow) 및 레이아웃 정의. |
| **02 (High-Fi)** | **앱 스크린 제작** | **[진행 예정]** 완성된 디자인 시스템을 적용하여 최종 UI 화면 제작. |
| **문서 (`03`)** | **DEVELOPMENT\_GUIDE.md 작성** | **[추후 작성]** Firebase 연동 및 Cloud Functions 배포 매뉴얼 준비. |
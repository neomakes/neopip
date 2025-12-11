# 🌟 PIP: Personal Intelligence Platform

**"나를 이해하는 가장 스마트한 방법, PIP"**

PIP는 개인의 심리, 행동, 신체 데이터를 통합 분석하여 웰니스 증진과 생산성 향상을 지원하는 AI 기반 종합 솔루션입니다. 본 프로젝트는 1인 개발을 위한 **GitHub 중심의 미니멀하고 체계적인 통합 관리 구조**를 따릅니다.

## 1. 💡 프로젝트 개요 및 핵심 목표

| 항목 | 내용 |
| :--- | :--- |
| **목표** | 개인 데이터 기반의 **PIP Score** 제공 및 AI 기반 **딥 인사이트**를 통한 맞춤형 웰니스/생산성 솔루션 제공. |
| **개발 대상** | iOS (주력) 및 Android (확장 고려) 크로스 플랫폼 앱. |
| **콘셉트** | Black & Platinum 기반의 **지적인 미니멀리즘** (Accent: Amber Flame, Tiger Flame, French Blue). |
| **핵심 기능** | 통합 개인 대시보드(PIP Score), AI 딥 인사이트 저널링, 바이오 리듬 최적화 스케줄러 등 7가지. |

---

## 2. ⚙️ 기술 스택 및 주요 도구

| 영역 | 주요 도구 및 언어 | 역할 |
| :--- | :--- | :--- |
| **버전 관리/협업** | GitHub (Git) | 모든 코드 및 기획 문서의 시계열적 버전 관리 및 CI/CD 연동 허브. |
| **프론트엔드 (App)** | **SwiftUI** (Native iOS) | 네이티브 성능을 극대화하고 최신 iOS 기능을 활용하기 위해 선택. |
| **백엔드/데이터베이스** | **Firebase Firestore & Storage** | 사용자 데이터 저장, 오디오/미디어 파일 저장. |
| **인텔리전스 엔진** | **Firebase Cloud Functions (Node.js/TypeScript)** | PIP Score 계산 및 딥 인사이트 분석 로직 실행. |
| **디자인/UI/UX** | **Figma** | 디자인 시스템 구축, 와이어프레임, 최종 화면 디자인. |
| **CI/CD 및 배포** | GitHub Actions (테스트/빌드 자동화), Xcode Cloud (iOS 배포 자동화). | 코드 푸시 시 자동 테스트 및 App Store Connect 연동. |

---

## 3. 🌐 통합 작업 흐름 다이어그램: 시스템 아키텍처

이 다이어그램은 **GitHub를 중심**으로 기획, 백엔드 분석, 그리고 최종적인 iOS 및 Android 배포까지의 데이터 및 코드 흐름을 보여줍니다.

```mermaid
graph TD
    subgraph sg1 ["01. 기획 및 디자인 (GitHub)"]
        A["Figma (디자인)"] --> B(02_Design_Assets);
        C["Markdown (기획)"] --> D(01_Planning);
    end

    subgraph sg2 ["02. 개발 (GitHub)"]
        D & B --> E(GitHub Repository);
        E --> F(PIP_Project: SwiftUI 앱);
        E --> G(03_Development: ML 모델 개발);
    end

    subgraph sg3 ["03. 인텔리전스 엔진 (Firebase)"]
        G -- 모델 학습/배포 --> H[Firebase ML / Functions];
        H -- 분석 결과 --> I[Firebase Firestore, DB];
    end

    subgraph sg4 ["04. 앱 및 데이터 연동"]
        I -- 실시간 데이터 --> F;
        H -- ML 모델 --> F;
        F -- 빌드/배포 --> J{Xcode Cloud / App Store};
    end

    J --> K[04_Distribution];
```

> **핵심:** 기획/코드/백엔드 로직이 모두 GitHub에서 관리되며, Firebase를 데이터 허브 및 분석 플랫폼으로 활용합니다.

## 4. 🧠 앱 내부 코드 흐름 다이어그램: 인텔리전스 처리

이 흐름은 PIP의 핵심인 **데이터 기반 인사이트 제공 과정**을 나타냅니다. 데이터가 앱 내부에서 어떻게 `services`를 거쳐 `functions`(백엔드)로 이동하고, 분석 후 `screens`에 표시되는지를 보여줍니다.

```mermaid
graph TD
    subgraph sg_ui ["01. UI Layer (SwiftUI)"]
        A[Views] -- 사용자 액션 --> B[ViewModels];
    end

    subgraph sg_logic ["02. Business Logic & Data"]
        B -- 데이터 요청 --> C[Services];
        C -- 데이터 모델 --> D[Models];
    end

    subgraph sg_backend ["03. Backend (Firebase)"]
        C -- CRUD, 함수 호출 --> E[Firebase: Firestore, Functions, ML];
        E -- 데이터/결과 반환 --> C;
    end

    subgraph sg_update ["04. UI Update (State Management)"]
        C -- 업데이트 된 모델 --> B;
        B -- `@Published` 프로퍼티 --> A;
        A -- 화면 새로고침 --> F(최신 데이터 표시);
    end

    subgraph sg_common ["05. Common"]
       G[Resources: Assets, Fonts] --> A;
    end
```

> **핵심:** UI(`screens`, `components`)는 데이터 처리(`services`)와 분리되어 있으며, 복잡한 계산은 **`functions`** (Cloud Functions)에서 처리된 후 **Firestore**를 통해 다시 앱으로 전달됩니다.

---

## 5. 📁 프로젝트 디렉토리 구조 (최적화)

| 경로 | 역할 및 책임 | 주요 문서 |
| :--- | :--- | :--- |
| `01_Planning/` | **[기획]** 프로젝트 기획 관련 모든 문서 관리. | `PROJECT_HANDOVER.md` |
|     ├── `PRD/` | 제품 요구사항 명세서(PRD) 관리. | |
|     ├── `Research/` | 시장 조사, 경쟁 분석 등 리서치 자료 보관. | |
|     └── `User_Stories/` | 사용자 스토리 및 요구사항 정의. | |
| `02_Design_Assets/` | **[디자인]** 앱 디자인 관련 모든 시각 자산 관리. | `BRANDING_GUIDE.md` |
|     ├── `App_Icons/` | 플랫폼별 앱 아이콘 소스 파일. | |
|     ├── `Branding/` | 로고, 컬러 팔레트 등 브랜드 아이덴티티 가이드. | |
|     └── `Figma_Exports/` | Figma에서 추출된 UI 컴포넌트, 화면 등 디자인 자산. | |
| `03_Development/` | **[ML 개발]** PIP Score 등 AI/ML 모델 개발 및 실험을 위한 공간. | `DEVELOPMENT_GUIDE.md` |
| `PIP_Project/` | **[iOS 앱 코드]** SwiftUI 기반의 네이티브 iOS 앱 소스 코드. | `PIP_Project.xcodeproj` |
| `04_Distribution/` | **[배포]** 앱 스토어 배포와 관련된 모든 자료. | `RELEASE_PLAN.md` |
|     ├── `AppStore_Metadata/` | App Store 제출용 메타데이터 및 정보. | |
|     ├── `Release_Notes/` | 각 버전별 변경 사항을 기록하는 릴리즈 노트. | |
|     └── `Screenshots/` | 스토어 제출용 앱 스크린샷. | |

## 6. ▶️ 개발 시작 및 실행 가이드

### 시작하기

1.  **코드 클론:** 본 GitHub 저장소를 클론합니다.
2.  **Figma 확인:** `02_Design_Assets` 내의 가이드 및 Figma 원본을 통해 디자인 시스템을 숙지합니다.
3.  **Firebase 초기화:** Firebase 프로젝트를 생성하고, `GoogleService-Info.plist` 파일을 `PIP_Project/PIP_Project/` 디렉토리에 추가합니다. (상세 내용은 `DEVELOPMENT_GUIDE.md` 참고)
4.  **CI/CD 설정:** `.github/workflows/` 파일을 확인하고, GitHub Actions 및 Xcode Cloud와의 연동을 완료합니다.

### 🚀 빌드 및 실행

1.  **Xcode 실행:** `PIP_Project/PIP_Project.xcodeproj` 파일을 Xcode로 엽니다.
2.  **시뮬레이터 선택:** Xcode 상단에서 실행할 iOS 시뮬레이터(예: iPhone 15 Pro)를 선택합니다.
3.  **빌드 및 실행:** `Cmd + R` 또는 ▶ (실행) 버튼을 클릭하여 앱을 빌드하고 시뮬레이터에서 실행합니다.
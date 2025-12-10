# 💻 DEVELOPMENT GUIDE: PIP 프로젝트 개발 매뉴얼

이 문서는 `03_Development` 폴더의 코드를 기반으로, 앱 개발 및 백엔드 로직 배포를 위한 환경 설정과 워크플로우를 안내합니다.

## 1. ⚙️ 개발 환경 설정 및 초기화

### 1.1. 크로스 플랫폼 환경 (예: Flutter / React Native) 설정

(고객님의 최종 기술 스택에 따라 업데이트 필요)

### 1.2. Firebase 프로젝트 초기화

1.  **Firebase CLI 설치:** 터미널에서 Firebase Command Line Interface를 설치합니다.
    ```bash
    npm install -g firebase-tools
    ```
2.  **프로젝트 연결:** VS Code 터미널에서 Firebase에 로그인하고, PIP 프로젝트 ID를 연결합니다.
    ```bash
    firebase login
    firebase use --add  # PIP 프로젝트 ID 연결
    ```
3.  **환경 파일 설정 (보안 필수):**
    * **iOS/Android 설정 파일** (`GoogleService-Info.plist` 등)은 **절대 Git에 커밋하지 않습니다.**
    * `.gitignore` 파일에 해당 파일을 명시했는지 재확인하세요.

## 2. 🔗 백엔드 (Firebase Cloud Functions) 연동

### 2.1. Cloud Functions 로컬 환경 설정

1.  `03_Development/src/functions/` 폴더로 이동합니다.
2.  **Node.js/TypeScript 환경 초기화:**
    ```bash
    npm install
    # 또는 yarn install (Dependencies 설정)
    ```
3.  **로컬 테스트:** 분석 로직 개발 시, 배포 전 로컬에서 함수를 테스트합니다.
    ```bash
    firebase emulators:start --only functions,firestore
    ```

### 2.2. 백엔드 로직 배포 (PIP Score 엔진)

`functions` 폴더의 분석 로직이 완성되면, 다음 명령어로 Firebase 서버에 배포합니다.

```bash
cd 03_Development/src/functions
firebase deploy --only functions
````

> **주의:** 이 로직은 `03_Development/src/models`의 데이터 구조와 일치해야 합니다.

## 3\. 💾 데이터 모델 (Data Models) 관리

### 3.1. 스키마 정의 (`03/src/models`)

  * `03_Development/src/models` 폴더에 Firestore 컬렉션 및 문서 구조를 Dart/JS 코드로 명확하게 정의합니다.
  * **PIP Score, JournalEntry, UserProfile** 등 핵심 데이터 모델을 먼저 정의합니다.

### 3.2. 프론트엔드 연동 (`03/src/services`)

  * `03_Development/src/services` 내의 파일들은 **모든 DB CRUD** (Create, Read, Update, Delete) 작업을 담당합니다.
  * `functions`와 DB 간의 상호작용은 이 `services` 계층을 통해 이루어져야 합니다.

## 4\. 🚀 CI/CD 및 버전 관리

### 4.1. 브랜치 전략

  * `main`: 프로덕션 및 App Store/Play Store에 배포되는 안정적인 코드.
  * `develop`: 기능 개발이 통합되는 메인 개발 브랜치.
  * `feature/<기능명>`: 개별 기능을 개발할 때 사용하는 브랜치.

### 4.2. GitHub Actions 설정 (`.github/workflows`)

CI/CD 자동화를 위해 `.github/workflows` 폴더에 YAML 파일을 설정합니다.

1.  **테스트 자동화:** `develop` 브랜치에 푸시될 때마다 모든 유닛 테스트를 자동으로 실행합니다.
2.  **코드 분석:** 코딩 컨벤션 및 정적 분석을 수행하여 코드 품질을 유지합니다.

## 5\. 🎨 디자인 시스템 통합 (`03/src/theme`)

`02_Design_Assets/BRANDING_GUIDE.md`를 참고하여 컬러, 폰트, 간격 정의를 코드로 변환합니다.

  * 예시 (Dart/Swift): `Color.amberFlame` 등의 변수를 정의하여 UI 코드에서 직접 Hex Code를 사용하지 않도록 합니다.

<!-- end list -->

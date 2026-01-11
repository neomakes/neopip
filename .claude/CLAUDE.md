# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PIP (Personal Intelligence Platform)** is a native iOS wellness app that analyzes personal mind, behavior, and physical data using ML/AI models. The app follows a privacy-first architecture with SwiftUI, Firebase backend, and MVVM pattern.

- **Primary Language**: Swift 5.0
- **UI Framework**: SwiftUI (100% native)
- **Deployment Target**: iOS 17.0+
- **Architecture**: MVVM with Protocol-Oriented Service Layer
- **Backend**: Firebase (Firestore, Auth, Cloud Functions)
- **Dependencies**: Firebase iOS SDK 12.7.0 (via Swift Package Manager)

## Build & Run Commands

### Building and Running

```bash
# Open Xcode project
open PIP_Project/PIP_Project.xcodeproj

# Build from command line
xcodebuild -project PIP_Project/PIP_Project.xcodeproj \
  -scheme PIP_Project \
  -configuration Debug \
  build

# Run in simulator
xcodebuild -project PIP_Project/PIP_Project.xcodeproj \
  -scheme PIP_Project \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  test
```

### Testing

```bash
# Run all unit tests
xcodebuild test -project PIP_Project/PIP_Project.xcodeproj \
  -scheme PIP_Project \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0'

# Run specific test
xcodebuild test -project PIP_Project/PIP_Project.xcodeproj \
  -scheme PIP_Project \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.0' \
  -only-testing:PIP_ProjectTests/PIP_ProjectTests/testExample
```

### Build Configurations

The project supports three build environments controlled via compiler flags:

- **Mock Mode**: Set `USE_MOCK_DATA` - Uses bundled JSON data, no Firebase needed
- **Development**: Set `DEV` - Uses development Firebase project
- **Production**: Default - Uses production Firebase project

## High-Level Architecture

### MVVM with Protocol-Oriented Service Layer

```
┌─────────────────────────────────────────────────────────┐
│  SwiftUI Views (Presentation Layer)                     │
│  - HomeView, InsightView, GoalView, StatusView          │
│  - Components: GemView, TabBar, Charts                  │
└─────────────┬───────────────────────────────────────────┘
              │ @ObservedObject / @StateObject
              ▼
┌─────────────────────────────────────────────────────────┐
│  ViewModels (@MainActor, ObservableObject)              │
│  - Inject DataServiceProtocol                           │
│  - Use @Published for reactive state                    │
│  - Process business logic                               │
└─────────────┬───────────────────────────────────────────┘
              │ Combine Publishers
              ▼
┌─────────────────────────────────────────────────────────┐
│  DataServiceProtocol (Abstraction Layer)                │
│  - 15+ async methods returning AnyPublisher             │
│  - Enables testability via dependency injection         │
└────────┬────────────────────────────┬───────────────────┘
         │                            │
   ┌─────▼────────┐          ┌────────▼──────────────┐
   │ MockData     │          │ FirebaseDataService   │
   │ Service      │          │ - Firestore CRUD      │
   │ - JSON files │          │ - IdentityMapping     │
   │ - Instant    │          │ - Privacy layer       │
   └──────────────┘          └───────────────────────┘
```

### Key Architectural Patterns

1. **Dependency Injection via Protocols**
   - `DataServiceProtocol` defines the contract for all data operations
   - ViewModels accept the protocol, not concrete implementations
   - `DataServiceManager` selects MockDataService or FirebaseDataService based on build config
   - Enables easy testing without Firebase

2. **Privacy-First Identity Architecture**
   - Three-tier system: `user_accounts` → `identity_mappings` → `anonymous_user_identities`
   - IdentityMappingService separates PII from analytics data
   - Uses KeychainService for local caching, EncryptionService for mappings
   - Firebase collections:
     - `users/{accountId}` - Personal user data
     - `identity_mappings/{mappingId}` - Encrypted bridge (server-only)
     - `anonymous_users/{anonymousUserId}` - All ML/AI analytics data

3. **Centralized Design System**
   - `DesignSystem.swift` contains all typography, colors, and layout constants
   - Typography: `.pip.hero`, `.pip.title1`, `.pip.body`, etc. (Pretendard font)
   - Colors: `Color.pip.home.*`, `Color.pip.insight.*`, etc.
   - Layouts: `CGFloat.PIPLayout.tabbarHeight`, `.railroadWidth`, etc.
   - **NEVER hardcode values** - always reference DesignSystem

4. **Reactive State Management with Combine**
   - All async operations return `AnyPublisher<Result, Error>`
   - Use `.receive(on: DispatchQueue.main)` for UI updates
   - ViewModels use `@Published` for observable state
   - SwiftUI automatically subscribes and re-renders

### Data Flow Example

```swift
// 1. User action in View
Button("Load") { homeViewModel.loadInitialData() }

// 2. ViewModel calls Service
func loadInitialData() {
    dataService.fetchDailyGems(from: startDate, to: endDate)
        .receive(on: DispatchQueue.main)
        .sink { [weak self] result in
            switch result {
            case .success(let gems):
                self?.dailyGems = gems  // @Published triggers UI update
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
        .store(in: &cancellables)
}

// 3. Service implementation (Mock or Firebase)
func fetchDailyGems(from: Date, to: Date) -> AnyPublisher<Result<[DailyGem], Error>, Never> {
    // Mock: Load from JSON
    // Firebase: Query Firestore
}
```

## File Organization & Naming Conventions

### Directory Structure

```
PIP_Project/PIP_Project/PIP_Project/
├── Application/          # App entry point (PIP_ProjectApp.swift)
├── Views/                # SwiftUI views organized by feature
│   ├── Home/            # HomeView + related sections
│   ├── Insights/        # InsightView + sections (Dashboard, Orb)
│   ├── Goal/            # GoalView + sections
│   ├── Status/          # StatusView + sections
│   └── Shared/          # Reusable cross-feature views
├── ViewModels/           # Business logic layer (@MainActor)
├── Models/               # Data models (Codable) organized by domain
│   ├── Data/            # TimeSeriesDataPoint, DailyGem
│   ├── Features/        # InsightAnalysisCard, OrbVisualization
│   ├── Identity/        # IdentityMapping, AnonymousUserIdentity
│   └── User/            # UserProfile, UserStats
├── Services/             # Protocol-based service layer
│   ├── Identity/        # IdentityMappingService, KeychainService
│   └── DataServiceProtocol.swift
├── Components/           # Reusable UI components (GemView, TabBar)
├── Extensions/           # Swift extensions
├── Resources/            # DesignSystem.swift, Assets.xcassets
└── MockData/             # JSON files for development
```

### Naming Conventions

- **Views**: `[Feature]View.swift` (e.g., `HomeView.swift`)
- **ViewModels**: `[Feature]ViewModel.swift` (e.g., `HomeViewModel.swift`)
- **Models**: `[ModelName].swift` (e.g., `DailyGem.swift`)
- **Services**: `[ServiceName]Service.swift` (e.g., `FirebaseDataService.swift`)
- **Components**: `[ComponentName].swift` (e.g., `GemView.swift`)
- **Extensions**: `[Type]+[Purpose].swift` (e.g., `Color+PIP.swift`)

## Working with the Codebase

### When Creating New Features

1. **Read DesignSystem.swift first** - Understand available colors, fonts, layouts
2. **Follow MVVM strictly**:
   - Views: Only UI, no business logic
   - ViewModels: Business logic, inject DataServiceProtocol
   - Services: Data operations, return Publishers
3. **Use existing patterns**:
   - Mark ViewModels with `@MainActor`
   - Use `@Published` for observable state
   - Inject `dataService: DataServiceProtocol` in ViewModel init
   - Use `#Preview` macros for SwiftUI previews
4. **Never hardcode design values** - Use `DesignSystem.swift` constants
5. **Organize large views into sections** - See `InsightView/Sections/` for examples

### When Modifying Views

- **Check if ViewModel exists** - Connect via `@StateObject` or `@ObservedObject`
- **Use DesignSystem**:
  - Fonts: `Text("Hello").font(.pip.hero)`
  - Colors: `Color.pip.home.buttonAddGrad1`
  - Layouts: `CGFloat.PIPLayout.tabbarHeight`
- **Add Preview** - Every view should have a `#Preview` block
- **Section-based composition** - Split complex views into smaller section views

### When Adding New Data Models

1. Place in appropriate subdirectory under `Models/`
2. Conform to `Codable` for Firebase/JSON serialization
3. Add to `DataServiceProtocol` if it needs CRUD operations
4. Implement in `MockDataService` first with JSON data
5. Implement in `FirebaseDataService` later (mark TODOs if not ready)

### When Working with Firebase

- **Development flow**:
  1. Start with MockDataService (instant feedback)
  2. Add JSON test data to `MockData/` directory
  3. Implement Firebase methods when backend is ready
- **Environment configuration**: Set via `AppEnvironment.swift`
- **Privacy**: Always use IdentityMappingService for user data
- **Testing**: Use MockDataService to test without Firebase connection

### Code Style Guidelines

```swift
// MARK: - File structure
import SwiftUI

// MARK: - Main View/ViewModel
@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Properties
    @Published var dailyGems: [DailyGem] = []
    private let dataService: DataServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }

    // MARK: - Public Methods
    func loadInitialData() {
        // Implementation
    }

    // MARK: - Private Methods
    private func calculateStreak() -> Int {
        // Implementation
    }
}

// MARK: - Preview
#Preview {
    HomeView(viewModel: HomeViewModel(dataService: MockDataService.shared))
}
```

## MockData System

The app includes an extensive mock data system for development without Firebase:

- **Location**: `PIP_Project/PIP_Project/MockData/`
- **Structure**: Organized by feature (Common, Home, Insight, Goal, Status, Write)
- **Runtime behavior**: JSON files copied to Documents directory (bundle is read-only)
- **Validation**: Auto-validates and corrects JSON format for InsightStory files
- **Usage**: Set `USE_MOCK_DATA` compiler flag to enable

## Design System Key Concepts

### Visual Metaphors: Gems & Orbs

- **Gems**: Represent daily data collection with unique properties
  - **Brightness**: Data completeness (more data = brighter)
  - **Geometry**: Data characteristics (emotion, physical, behavior)
  - **Neon Shadow**: AI model uncertainty

- **Orbs**: Represent ML model quality and predictions
  - **brightness**: Model reconstruction performance (0.0-1.0)
  - **borderBrightness**: Today's prediction accuracy (0.0-1.0)
  - **uniqueFeatures**: User-specific characteristics (determines color gradient)

### Component Development

When creating data visualization components (Gems, Orbs, Charts):

1. **Data-driven rendering** - Use SwiftUI, not static images
2. **Parameterized** - Accept brightness, uncertainty, color theme as parameters
3. **Reusable** - Design for multiple contexts
4. **Example structure**:

```swift
struct OrbView: View {
    let brightness: Double      // 0.0 ~ 1.0
    let borderBrightness: Double
    let uniqueFeatures: Int

    var body: some View {
        ZStack {
            // Base shape based on uniqueFeatures
            // Apply glass effect
            // Adjust brightness
            // Add neon glow shadow
        }
    }
}
```

## Testing Strategy

### Current Test Setup

- **Unit Tests**: `PIP_ProjectTests/` - Uses Swift Testing framework (not XCTest)
- **UI Tests**: `PIP_ProjectUITests/` - Uses XCUITest
- **Testability features**:
  - Protocol-oriented services enable easy mocking
  - ViewModels accept protocols, not concrete implementations
  - MockDataService available without Firebase

### Writing Testable Code

```swift
// ✅ Good - Testable
final class HomeViewModel: ObservableObject {
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }
}

// Test
let mockService = MockDataService.shared
let viewModel = HomeViewModel(dataService: mockService)

// ❌ Bad - Hard to test
final class HomeViewModel: ObservableObject {
    private let dataService = FirebaseDataService() // Tightly coupled
}
```

## Important Project Documentation

Key documentation files to reference:

- **README.md**: Project overview, tech stack, development workflow
- **01_Planning/AI_WORKFLOW_AND_CONTEXT.md**: Comprehensive AI collaboration guide, all project context
- **01_Planning/PROJECT_HANDOVER.md**: Architecture decisions, current status, ADRs
- **01_Planning/DB_MODEL_DESIGN.md**: Database schema, 21 tables, ERD diagrams
- **02_Design_Assets/BRANDING_GUIDE.md**: Brand philosophy, UX principles, visual metaphors
- **03_Development/DEVELOPMENT_GUIDE.md**: MVVM explanation, detailed tech stack

## Environment Configuration

### Build Configurations

Edit scheme or set compiler flags:

```bash
# Mock mode (no Firebase)
SWIFT_ACTIVE_COMPILATION_CONDITIONS = USE_MOCK_DATA

# Development mode (dev Firebase)
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEV

# Production mode (default)
# No special flags
```

### Firebase Setup

1. Add `GoogleService-Info.plist` to `PIP_Project/PIP_Project/`
2. For production, add `GoogleService-Info-Prod.plist`
3. AppDelegate selects config based on build flags

### Runtime Behavior

- App starts with `LaunchView` (1 second splash)
- `DataServiceManager` selects service based on build config:
  - Mock: Instant data from bundled JSON
  - Firebase: Network required, Firebase project setup needed

## Common Pitfalls to Avoid

1. **Don't hardcode design values** - Always use `DesignSystem.swift`
2. **Don't put business logic in Views** - Use ViewModels
3. **Don't forget @MainActor on ViewModels** - Required for thread safety
4. **Don't skip .receive(on: DispatchQueue.main)** - UI updates must be on main thread
5. **Don't tightly couple to Firebase** - Always use DataServiceProtocol
6. **Don't bypass IdentityMappingService** - Privacy-first architecture is critical
7. **Don't create computed properties that aren't truly computed** - Use @Published for mutable state

## Project Philosophy

### Documentation-First Approach

- All planning, decisions, and architecture documented in Markdown
- GitHub is the "single source of truth"
- AI-assisted development workflow documented
- Comprehensive inline code comments with `// MARK:` sections

### Privacy-First Design

- Anonymous IDs separate from user accounts
- Encryption for identity mappings
- GDPR-compliant deletion requests
- KeychainService for secure local storage

### Modern Swift Practices

- Protocol-oriented programming
- Combine for reactive patterns
- SwiftUI for declarative UI
- Swift Package Manager for dependencies
- Codable for serialization
- @MainActor for thread safety

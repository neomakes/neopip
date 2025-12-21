# 📱 Views 및 ViewModels 구현 기획안

**작성일**: 2025.12  
**버전**: 1.0  
**상태**: 기획 완료

---

## 📋 목차

1. [전체 구조](#1-전체-구조)
2. [HomeView 및 ViewModel](#2-homeview-및-viewmodel)
3. [InsightView 및 ViewModel](#3-insightview-및-viewmodel)
4. [GoalView 및 ViewModel](#4-goalview-및-viewmodel)
5. [StatusView 및 ViewModel](#5-statusview-및-viewmodel)
6. [온보딩 Views](#6-온보딩-views)
7. [공통 컴포넌트](#7-공통-컴포넌트)
8. [구현 우선순위](#8-구현-우선순위)

---

## 1. 전체 구조

### 1.1. 디렉토리 구조

```
PIP_Project/
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── WriteSheet.swift (카드 기반 입력)
│   │   ├── RailroadView.swift (타임라인)
│   │   └── GemCardView.swift (Gem 시각화)
│   ├── Insight/
│   │   ├── InsightView.swift
│   │   ├── OrbView.swift (Orb 시각화)
│   │   ├── DashboardView.swift (예측 대시보드)
│   │   └── AnalysisCardView.swift (카드뉴스)
│   ├── Goal/
│   │   ├── GoalView.swift
│   │   ├── ProgramListView.swift
│   │   ├── ProgressView.swift (BarLineChart, RadarChart)
│   │   └── ProgramDetailView.swift (인스타 스토리 형식)
│   ├── Status/
│   │   ├── StatusView.swift
│   │   ├── ProfileView.swift
│   │   ├── AchievementView.swift
│   │   └── ValueAnalysisView.swift
│   └── Onboarding/
│       ├── GoalSelectionView.swift (틴더 스타일)
│       ├── ProgramSelectionView.swift
│       └── DataConsentView.swift
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── InsightViewModel.swift
│   ├── GoalViewModel.swift
│   ├── StatusViewModel.swift
│   └── OnboardingViewModel.swift
└── Components/
    ├── Gem/
    │   ├── GemView.swift (오픈소스 gem 애셋)
    │   └── Gem3DView.swift
    ├── Charts/
    │   ├── BarLineChartView.swift
    │   ├── RadarChartView.swift
    │   └── LineChartView.swift
    └── Cards/
        ├── SwipeableCardView.swift (틴더 스타일)
        └── AnalysisCardPageView.swift
```

### 1.2. MVVM 아키텍처

```
View (SwiftUI)
  ↓ @StateObject, @ObservedObject
ViewModel (ObservableObject)
  ↓ Service Layer
Service (Repository Pattern)
  ↓ Firebase / MockData
Models
```

---

## 2. HomeView 및 ViewModel

### 2.1. HomeView 구조

```swift
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showWriteSheet = false
    
    var body: some View {
        ZStack {
            // 배경
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // 상단: 통계
                    StatsHeaderView(
                        totalRecords: viewModel.totalDataPoints,
                        currentStreak: viewModel.currentStreak
                    )
                    
                    // RailRoad: 타임라인
                    RailroadView(
                        gems: viewModel.dailyGems,
                        onGemTap: { gem in
                            // Gem 상세 보기
                        }
                    )
                }
            }
            
            // 우측 하단: 기록 버튼
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showWriteSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.teal)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showWriteSheet) {
            WriteSheet(viewModel: viewModel)
        }
    }
}
```

### 2.2. WriteSheet (카드 기반 입력)

```swift
struct WriteSheet: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var currentCardIndex = 0
    @State private var cardData: [CardData] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 카드 스택
            ZStack {
                ForEach(Array(cardData.enumerated()), id: \.offset) { index, card in
                    if index >= currentCardIndex && index < currentCardIndex + 3 {
                        SwipeableCardView(
                            card: card,
                            index: index - currentCardIndex,
                            onSwipeLeft: {
                                // 다음 카드로
                                withAnimation {
                                    currentCardIndex += 1
                                }
                            },
                            onSwipeRight: {
                                // 이전 카드로
                                withAnimation {
                                    currentCardIndex = max(0, currentCardIndex - 1)
                                }
                            },
                            onCheck: {
                                // 저장하고 다음 카드로
                                viewModel.saveCardData(card)
                                withAnimation {
                                    currentCardIndex += 1
                                }
                            }
                        )
                        .offset(x: CGFloat(index - currentCardIndex) * 20)
                        .scaleEffect(1.0 - CGFloat(abs(index - currentCardIndex)) * 0.05)
                    }
                }
            }
            
            // 되돌리기 버튼
            if currentCardIndex > 0 {
                VStack {
                    HStack {
                        Button("되돌리기") {
                            withAnimation {
                                currentCardIndex -= 1
                            }
                        }
                        .padding()
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            cardData = viewModel.generateCards()
        }
    }
}
```

### 2.3. HomeViewModel

```swift
@MainActor
class HomeViewModel: ObservableObject {
    @Published var dailyGems: [DailyGem] = []
    @Published var totalDataPoints: Int = 0
    @Published var currentStreak: Int = 0
    @Published var isLoading = false
    
    private let dataService: DataServiceProtocol
    
    init(dataService: DataServiceProtocol = DataService.shared) {
        self.dataService = dataService
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        // DailyGems 로드
        dailyGems = await dataService.fetchDailyGems()
        
        // 통계 로드
        let stats = await dataService.fetchUserStats()
        totalDataPoints = stats.totalDataPoints
        currentStreak = stats.currentStreak
    }
    
    func generateCards() -> [CardData] {
        // 목표에 따라 카드 생성
        // 마음, 행동, 신체 카드 + 프로그램 카드
        var cards: [CardData] = []
        
        // 마음 카드
        cards.append(CardData(
            type: .mind,
            title: "오늘 기분은 어땠나요?",
            inputs: [
                .slider(key: "mood", label: "기분", range: 0...100),
                .slider(key: "stress", label: "스트레스", range: 0...100),
                .slider(key: "energy", label: "에너지", range: 0...100),
                .slider(key: "focus", label: "집중도", range: 0...100)
            ],
            textInput: .optional(key: "notes", placeholder: "오늘의 한 줄")
        ))
        
        // 행동 카드
        cards.append(CardData(
            type: .behavior,
            title: "오늘의 행동은?",
            inputs: [
                .slider(key: "productivity", label: "생산성", range: 0...100),
                .slider(key: "socialActivity", label: "사회적 활동", range: 0...100)
            ],
            textInput: .optional(key: "notes", placeholder: "메모")
        ))
        
        // 신체 카드
        cards.append(CardData(
            type: .physical,
            title: "오늘의 신체 상태는?",
            inputs: [
                .slider(key: "sleepScore", label: "수면 점수", range: 0...100),
                .slider(key: "fatigue", label: "피로도", range: 0...100)
            ],
            textInput: .optional(key: "notes", placeholder: "메모")
        ))
        
        return cards
    }
    
    func saveCardData(_ card: CardData) async {
        // TimeSeriesDataPoint 생성
        let dataPoint = TimeSeriesDataPoint(
            // ... cardData 기반으로 생성
        )
        
        await dataService.saveDataPoint(dataPoint)
        
        // DailyGem 업데이트
        await updateDailyGem(for: Date())
    }
    
    private func updateDailyGem(for date: Date) async {
        // 해당 날짜의 DailyGem 생성/업데이트
    }
}
```

---

## 3. InsightView 및 ViewModel

### 3.1. InsightView 구조

```swift
struct InsightView: View {
    @StateObject private var viewModel = InsightViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Orb (최상단)
                OrbView(orb: viewModel.currentOrb)
                    .frame(height: 300)
                
                // Dashboard (예측 대시보드)
                DashboardView(
                    predictions: viewModel.predictions,
                    onCategoryChange: { category in
                        viewModel.selectedCategory = category
                    }
                )
                
                // Analysis (카드뉴스)
                ForEach(viewModel.analysisCards) { card in
                    AnalysisCardView(card: card)
                }
            }
        }
        .background(Color.black)
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
}
```

### 3.2. OrbView

```swift
struct OrbView: View {
    let orb: OrbVisualization?
    
    var body: some View {
        ZStack {
            // Orb 내부 (고유 Feature 기반 색상)
            Circle()
                .fill(
                    LinearGradient(
                        colors: orb?.colorGradient.map { Color(hex: $0) } ?? [.teal, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(orb?.brightness ?? 0.5)  // brightness = 재생성 성능
                .frame(width: 200, height: 200)
            
            // Orb 테두리 (예측 정확도)
            Circle()
                .stroke(
                    Color.white,
                    lineWidth: 4
                )
                .opacity(orb?.borderBrightness ?? 0.5)  // borderBrightness = 예측 정확도
                .frame(width: 200, height: 200)
        }
    }
}
```

### 3.3. DashboardView

```swift
struct DashboardView: View {
    let predictions: [PredictionData]
    let onCategoryChange: (DataCategory) -> Void
    
    @State private var selectedCategory: DataCategory = .mind
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 카테고리 선택 (슬라이딩)
            CategoryPicker(
                selectedCategory: $selectedCategory,
                onCategoryChange: onCategoryChange
            )
            
            // 예측 값 및 신뢰도
            ForEach(filteredPredictions) { prediction in
                PredictionCard(
                    prediction: prediction,
                    category: selectedCategory
                )
            }
        }
        .padding()
    }
    
    private var filteredPredictions: [PredictionData] {
        predictions.filter { /* 카테고리별 필터링 */ }
    }
}
```

### 3.4. AnalysisCardView (인스타 스토리 형식)

```swift
struct AnalysisCardView: View {
    let card: InsightAnalysisCard
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(card.pages.enumerated()), id: \.offset) { index, page in
                AnalysisCardPageView(page: page)
                    .tag(index)
            }
        }
        .tabViewStyle(.page)
        .frame(height: 500)
        
        // 하단: 하트 버튼, 수락 버튼
        HStack {
            Button(action: {
                // 좋아요
            }) {
                Image(systemName: card.isLiked ? "heart.fill" : "heart")
                    .foregroundColor(card.isLiked ? .red : .white)
            }
            
            Spacer()
            
            ForEach(card.actionProposals) { proposal in
                Button(action: {
                    // 행동 수락 (캘린더, 알람 등)
                }) {
                    Text("수락")
                }
            }
        }
        .padding()
    }
}
```

### 3.5. InsightViewModel

```swift
@MainActor
class InsightViewModel: ObservableObject {
    @Published var currentOrb: OrbVisualization?
    @Published var predictions: [PredictionData] = []
    @Published var analysisCards: [InsightAnalysisCard] = []
    @Published var selectedCategory: DataCategory = .mind
    @Published var isLoading = false
    
    private let insightService: InsightServiceProtocol
    
    init(insightService: InsightServiceProtocol = InsightService.shared) {
        self.insightService = insightService
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Orb 로드
        currentOrb = await insightService.fetchCurrentOrb()
        
        // 예측 데이터 로드
        predictions = await insightService.fetchPredictions()
        
        // 분석 카드 로드
        analysisCards = await insightService.fetchAnalysisCards()
    }
    
    func likeCard(_ cardId: UUID) async {
        await insightService.likeAnalysisCard(cardId)
        // UI 업데이트
    }
    
    func acceptAction(_ actionId: UUID) async {
        await insightService.acceptActionProposal(actionId)
        // 캘린더, 알람 등 실행
    }
}
```

---

## 4. GoalView 및 ViewModel

### 4.1. GoalView 구조

```swift
struct GoalView: View {
    @StateObject private var viewModel = GoalViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Program List (3D 일러스트)
                if let currentProgram = viewModel.currentProgram {
                    Program3DView(program: currentProgram)
                        .frame(height: 200)
                }
                
                // Progress (BarLineChart, RadarChart)
                ProgressView(
                    progress: viewModel.progress,
                    baselineProgress: viewModel.baselineProgress
                )
                
                // Programs (카드뉴스)
                ForEach(viewModel.availablePrograms) { program in
                    ProgramCardView(program: program)
                        .onTapGesture {
                            viewModel.selectedProgram = program
                        }
                }
            }
        }
        .background(Color.black)
        .sheet(item: $viewModel.selectedProgram) { program in
            ProgramDetailView(program: program)
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
}
```

### 4.2. ProgramDetailView (인스타 스토리 형식)

```swift
struct ProgramDetailView: View {
    let program: Program
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            // 페이지 1: 프로그램 설명
            ProgramDescriptionPage(program: program)
                .tag(0)
            
            // 페이지 2: 인기도
            ProgramPopularityPage(program: program)
                .tag(1)
            
            // 페이지 3: 사용자 평가
            ProgramReviewsPage(program: program)
                .tag(2)
        }
        .tabViewStyle(.page)
    }
}
```

### 4.3. GoalViewModel

```swift
@MainActor
class GoalViewModel: ObservableObject {
    @Published var currentProgram: Program?
    @Published var progress: GoalProgress?
    @Published var baselineProgress: GoalProgress?
    @Published var availablePrograms: [Program] = []
    @Published var selectedProgram: Program?
    @Published var isLoading = false
    
    private let goalService: GoalServiceProtocol
    
    init(goalService: GoalServiceProtocol = GoalService.shared) {
        self.goalService = goalService
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        // 현재 진행 중 프로그램
        currentProgram = await goalService.fetchCurrentProgram()
        
        // 진행 상황
        progress = await goalService.fetchProgress()
        baselineProgress = await goalService.fetchBaselineProgress()
        
        // 사용 가능한 프로그램 목록
        availablePrograms = await goalService.fetchAvailablePrograms()
    }
}
```

---

## 5. StatusView 및 ViewModel

### 5.1. StatusView 구조

```swift
struct StatusView: View {
    @StateObject private var viewModel = StatusViewModel()
    @State private var showSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Profile (상단)
                ProfileView(
                    profile: viewModel.userProfile,
                    stats: viewModel.userStats,
                    onSettingsTap: {
                        showSettings = true
                    }
                )
                
                // Achievement (중간)
                AchievementView(achievements: viewModel.achievements)
                
                // Value (하단)
                ValueAnalysisView(analysis: viewModel.valueAnalysis)
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            Task {
                await viewModel.loadData()
            }
        }
    }
}
```

### 5.2. StatusViewModel

```swift
@MainActor
class StatusViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var userStats: UserStats?
    @Published var achievements: [Achievement] = []
    @Published var valueAnalysis: ValueAnalysis?
    @Published var isLoading = false
    
    private let statusService: StatusServiceProtocol
    
    init(statusService: StatusServiceProtocol = StatusService.shared) {
        self.statusService = statusService
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        userProfile = await statusService.fetchUserProfile()
        userStats = await statusService.fetchUserStats()
        achievements = await statusService.fetchAchievements()
        valueAnalysis = await statusService.fetchValueAnalysis()
    }
}
```

---

## 6. 온보딩 Views

### 6.1. GoalSelectionView (틴더 스타일)

```swift
struct GoalSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var cardStack: [GoalCard] = []
    @State private var selectedGoals: [GoalCategory] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // 카드 스택
            ZStack {
                ForEach(Array(cardStack.enumerated()), id: \.offset) { index, card in
                    if index < 3 {
                        SwipeableCardView(
                            card: card,
                            index: index,
                            onSwipeLeft: {
                                // 다음 카드로
                                withAnimation {
                                    cardStack.removeFirst()
                                }
                            },
                            onSwipeRight: {
                                // 선택
                                selectedGoals.append(card.category)
                                withAnimation {
                                    cardStack.removeFirst()
                                }
                            }
                        )
                    }
                }
            }
            
            // 선택된 목표 표시
            VStack {
                Spacer()
                HStack {
                    ForEach(selectedGoals, id: \.self) { goal in
                        Text(goal.rawValue)
                            .padding()
                            .background(Color.teal)
                    }
                }
            }
        }
    }
}
```

---

## 7. 공통 컴포넌트

### 7.1. GemView (오픈소스 gem 애셋)

```swift
struct GemView: View {
    let gem: DailyGem
    
    var body: some View {
        // 오픈소스 gem 애셋 사용
        // gemType에 따라 다른 형태 표시
        switch gem.gemType {
        case .sphere:
            SphereGemView(brightness: gem.brightness, colorTheme: gem.colorTheme)
        case .crystal:
            CrystalGemView(brightness: gem.brightness, colorTheme: gem.colorTheme)
        case .diamond:
            DiamondGemView(brightness: gem.brightness, colorTheme: gem.colorTheme)
        // ...
        }
    }
}
```

### 7.2. SwipeableCardView (틴더 스타일)

```swift
struct SwipeableCardView: View {
    let card: CardData
    let index: Int
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    let onCheck: () -> Void
    
    @State private var dragOffset = CGSize.zero
    
    var body: some View {
        CardContentView(card: card)
            .offset(dragOffset)
            .rotationEffect(.degrees(Double(dragOffset.width / 20)))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        if abs(value.translation.width) > 100 {
                            if value.translation.width > 0 {
                                onSwipeRight()
                            } else {
                                onSwipeLeft()
                            }
                        } else {
                            withAnimation {
                                dragOffset = .zero
                            }
                        }
                    }
            )
    }
}
```

---

## 8. 구현 우선순위

### Phase 1: 기본 구조 (1주)
- [ ] 프로젝트 구조 설정
- [ ] 기본 ViewModels 생성
- [ ] MockData 서비스 구현
- [ ] 공통 컴포넌트 (GemView, Charts)

### Phase 2: HomeView (2주)
- [ ] HomeView 기본 레이아웃
- [ ] RailroadView 구현
- [ ] WriteSheet (카드 기반 입력)
- [ ] SwipeableCardView 구현
- [ ] 데이터 저장 로직

### Phase 3: InsightView (2주)
- [ ] OrbView 구현
- [ ] DashboardView 구현
- [ ] AnalysisCardView (인스타 스토리 형식)
- [ ] 예측 데이터 표시

### Phase 4: GoalView (1주)
- [ ] ProgramListView
- [ ] ProgressView (Charts)
- [ ] ProgramDetailView

### Phase 5: StatusView (1주)
- [ ] ProfileView
- [ ] AchievementView
- [ ] ValueAnalysisView

### Phase 6: 온보딩 (1주)
- [ ] GoalSelectionView (틴더 스타일)
- [ ] ProgramSelectionView
- [ ] DataConsentView

### Phase 7: 통합 및 최적화 (1주)
- [ ] Firebase 연동
- [ ] 성능 최적화
- [ ] 애니메이션 개선
- [ ] 테스트

---

**작성일**: 2025.12  
**버전**: 1.0  
**상태**: 기획 완료  
**다음 단계**: Phase 1 시작

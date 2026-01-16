import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var dataServiceManager: DataServiceManager
    
    @State private var selectedTab: Int = 0
    @State private var previousTab: Int = 0 // Track previous for logging
    @State private var showWriteSheet: Bool = false
    @State private var tabStartTime: Date = Date()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        ZStack {
            PrimaryBackground().ignoresSafeArea()

            // Content area with view models
            MainTabContent(
                dataService: dataServiceManager.dataService,
                selectedTab: $selectedTab,
                showWriteSheet: $showWriteSheet
            )
            .ignoresSafeArea(edges: [.bottom, .horizontal])
            
            // Bottom TabBar Area (overlaps HomeView)
            VStack(spacing: 0) {
                Spacer()
                TabBar(selectedTab: $selectedTab, onCenterButtonTapped: {
                    showWriteSheet = true
                })
            }
            .ignoresSafeArea(edges: .bottom)
        }

        .onAppear {
             // Initialize timer & Start Session
             tabStartTime = Date()
             previousTab = selectedTab
             AnalyticsService.shared.startNavigationSession()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Determine if we need to restart a session
                AnalyticsService.shared.startNavigationSession()
                // Reset tab timer to avoid huge duration from background time
                tabStartTime = Date()
            } else if newPhase == .background {
                // Record the final tab dwell time before suspending
                let tabName = getTabName(for: selectedTab)
                let duration = Date().timeIntervalSince(tabStartTime)
                AnalyticsService.shared.trackScreenTime(screenName: tabName, duration: duration)
                
                // Flush to Firestore
                AnalyticsService.shared.endNavigationSession()
            }
        }
        .onChange(of: selectedTab) { newTab in
            // 1. Log Time Spent on Previous Tab
            let prevTabName = getTabName(for: previousTab)
            let duration = Date().timeIntervalSince(tabStartTime)
            AnalyticsService.shared.trackScreenTime(screenName: prevTabName, duration: duration)
            
            // 2. Log Switch Event
            let newTabName = getTabName(for: newTab)
            AnalyticsService.shared.trackTabSwitch(from: prevTabName, to: newTabName)
            
            // 3. Reset
            previousTab = newTab
            tabStartTime = Date()
        }
    }
    
    private func getTabName(for index: Int) -> String {
        switch index {
        case 0: return "home"
        case 1: return "insight"
        case 2: return "write_trigger"
        case 3: return "goal"
        case 4: return "status"
        default: return "unknown_\(index)"
        }
    }
}

// MARK: - Main Tab Content
// Separate view to properly manage ViewModels lifecycle
private struct MainTabContent: View {
    let dataService: DataServiceProtocol
    @Binding var selectedTab: Int
    @Binding var showWriteSheet: Bool
    
    // MARK: - ViewModels
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var insightViewModel: InsightViewModel
    @StateObject private var goalViewModel: GoalViewModel
    @StateObject private var statusViewModel: StatusViewModel
    
    init(dataService: DataServiceProtocol, selectedTab: Binding<Int>, showWriteSheet: Binding<Bool>) {
        self.dataService = dataService
        self._selectedTab = selectedTab
        self._showWriteSheet = showWriteSheet
        
        // Initialize all view models with the selected data service
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(dataService: dataService))
        _insightViewModel = StateObject(wrappedValue: InsightViewModel(dataService: dataService))
        _goalViewModel = StateObject(wrappedValue: GoalViewModel(dataService: dataService))
        _statusViewModel = StateObject(wrappedValue: StatusViewModel(dataService: dataService))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch selectedTab {
                case 0: 
                    HomeView(viewModel: homeViewModel, showWriteOverlay: $showWriteSheet, onWriteRequested: {
                        showWriteSheet = true
                    })
                case 1: 
                    InsightView(viewModel: insightViewModel)
                case 2: 
                    HomeView(viewModel: homeViewModel, showWriteOverlay: $showWriteSheet, onWriteRequested: {
                        showWriteSheet = true
                    })
                case 3: 
                    GoalView(viewModel: goalViewModel)
                case 4: 
                    StatusView(viewModel: statusViewModel)
                default: 
                    HomeView(viewModel: homeViewModel, showWriteOverlay: $showWriteSheet, onWriteRequested: {
                        showWriteSheet = true
                    })
                }
            }
            .id(selectedTab)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(DataServiceManager(environment: .mock))
}

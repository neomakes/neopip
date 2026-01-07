import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var dataServiceManager: DataServiceManager
    
    @State private var selectedTab: Int = 0
    @State private var showWriteSheet: Bool = false
    
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

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showWriteSheet: Bool = false
    
    // MARK: - ViewModels
    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var insightViewModel: InsightViewModel
    @StateObject private var goalViewModel: GoalViewModel
    @StateObject private var statusViewModel: StatusViewModel
    
    // MARK: - Data Service
    private let dataService: DataServiceProtocol
    
    init(useFirebase: Bool) {
        if useFirebase {
            // Use the real Firebase data service
            self.dataService = FirebaseDataService()
        } else {
            // Use the mock data service for development and testing
            self.dataService = MockDataService.shared
        }
        
        // Initialize all view models with the selected data service
        _homeViewModel = StateObject(wrappedValue: HomeViewModel(dataService: dataService))
        _insightViewModel = StateObject(wrappedValue: InsightViewModel(dataService: dataService))
        _goalViewModel = StateObject(wrappedValue: GoalViewModel(dataService: dataService))
        _statusViewModel = StateObject(wrappedValue: StatusViewModel(dataService: dataService))
    }
    
    var body: some View {
        ZStack {
            PrimaryBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    switch selectedTab {
                    case 0: HomeView(viewModel: homeViewModel, showWriteOverlay: $showWriteSheet, onWriteRequested: {
                        showWriteSheet = true
                    })
                    case 1: InsightView(viewModel: insightViewModel)
                    case 2: HomeView(viewModel: homeViewModel, showWriteOverlay: $showWriteSheet, onWriteRequested: {
                        showWriteSheet = true
                    })
                    case 3: GoalView(viewModel: goalViewModel)
                    case 4: StatusView(viewModel: statusViewModel)
                    default: HomeView(viewModel: homeViewModel, showWriteOverlay: $showWriteSheet, onWriteRequested: {
                        showWriteSheet = true
                    })
                    }
                }
                .id(selectedTab)
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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

#Preview {
    MainTabView(useFirebase: false)
}

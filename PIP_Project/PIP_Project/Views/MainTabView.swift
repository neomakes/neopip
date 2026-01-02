import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showWriteSheet: Bool = false
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var insightViewModel = InsightViewModel()
    @StateObject private var goalViewModel = GoalViewModel()
    @StateObject private var statusViewModel = StatusViewModel()
    
    var body: some View {
        ZStack {
            PrimaryBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    switch selectedTab {
                    case 0: HomeView(showWriteOverlay: $showWriteSheet, onWriteRequested: {
                        showWriteSheet = true
                    })
                    case 1: InsightView(viewModel: insightViewModel)
                    case 2: HomeView(showWriteOverlay: $showWriteSheet, onWriteRequested: {
                        showWriteSheet = true
                    })
                    case 3: GoalView(viewModel: goalViewModel)
                    case 4: StatusView()
                    default: HomeView(showWriteOverlay: $showWriteSheet, onWriteRequested: {
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
    MainTabView()
}

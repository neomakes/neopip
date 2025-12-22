import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showWriteSheet: Bool = false
    @StateObject private var homeViewModel = HomeViewModel()
    
    var body: some View {
        ZStack {
            PrimaryBackground().ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    switch selectedTab {
                    case 0: HomeView()
                    case 1: InsightView()
                    case 2: WriteView()
                    case 3: GoalView()
                    case 4: StatusView()
                    default: HomeView()
                    }
                }
                .id(selectedTab)
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom TabBar Area
                TabBar(selectedTab: $selectedTab, showWriteSheet: $showWriteSheet)
            }
            .ignoresSafeArea(edges: [.bottom, .horizontal])
        }
    }
}

#Preview {
    MainTabView()
}

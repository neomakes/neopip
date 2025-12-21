// Location: Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // LAYER 1: Background
            PrimaryBackground()
                .ignoresSafeArea()
            
            // LAYER 2: Content Switcher
            Group {
                switch selectedTab {
                case 0: HomeView()
                case 1: InsightView()
                case 2: GoalView()
                case 3: StatusView()
                default: HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(selectedTab)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            
            // LAYER 3: TabBar
            TabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}

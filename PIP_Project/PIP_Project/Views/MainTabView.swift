// Location: Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showWriteSheet: Bool = false
    
    private let tabs = ["home", "insight", "goal", "status"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // LAYER 1: Background
            PrimaryBackground()
                .ignoresSafeArea()
            
            // LAYER 2: Content Switcher
            Group {
                switch selectedTab {
                case 0: HomeView(showWriteSheet: $showWriteSheet)
                case 1: InsightView()
                case 2: GoalView()
                case 3: StatusView()
                default: HomeView(showWriteSheet: $showWriteSheet)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(selectedTab)
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
            
            // LAYER 3: Bottom Bar Area (TabBar + Write Button)
            VStack {
                Spacer()
                
                // Notion-style layout: TabBar on left, Write button on right
                HStack(alignment: .center, spacing: 12) {
                    // Tab Bar (4 icons)
                    LiquidGlassTabBar(selectedTab: $selectedTab, tabs: tabs)
                    
                    // Floating Write Button (separate, right side)
                    FloatingWriteButton {
                        showWriteSheet = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}

// Location: Views/HomeView.swift
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedGem: GemRecord?
    let onWriteRequested: (() -> Void)?
    
    init(onWriteRequested: (() -> Void)? = nil) {
        self.onWriteRequested = onWriteRequested
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 고정 헤더: "Hi, User" + Records/Streaks
            fixedStatsHeader
            
            // 세로 스크롤 RailRoad (과거 6일 + 오늘 = 7개)
            // 헤더 아래부터 하단까지 확장
            VStack(spacing: 0) {
                // 헤더만큼의 공간 확보
                Spacer()
                    .frame(height: 120)  // fixedStatsHeader 높이 (approximate)
                
                // RailRoad가 남은 공간을 모두 차지
                RailroadView(
                    gemRecords: viewModel.last7Days,
                    onGemTap: { gem in
                        selectedGem = gem
                    },
                    onWriteRequested: onWriteRequested ?? {},
                    currentStreak: viewModel.currentStreak  // 계산된 스트릭 사용
                )
                .onAppear {
                    print("🏠 [HomeView] Appeared - last7Days count: \(viewModel.last7Days.count)")
                    print("🏠 [HomeView] dailyGems count: \(viewModel.dailyGems.count)")
                    print("🏠 [HomeView] isLoading: \(viewModel.isLoading)")
                }
                
                Spacer()  // TabBar 위까지 확장
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $selectedGem) { gem in
            GemDetailView(gemRecord: gem, viewModel: viewModel)
        }
    }
    
    // MARK: - Fixed Stats Header
    /// VStack layout:
    /// - Step 1: "Hi, Username"
    /// - Step 2: VStack aligned Records / Streaks
    ///   - Each is HStack (Icon + Value)
    private var fixedStatsHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            // "Hi, 사용자명"
            Text("Hi, \(viewModel.userName ?? "User")")
                .font(.pip.hero)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
            
            // VStack: Records와 Streaks를 위아래로 배치
            if let stats = viewModel.userStats {
                VStack(alignment: .leading, spacing: 12) {
                    // Records (HStack: Icon + Value)
                    StatItem(
                        iconName: "icon_records",
                        value: "\(stats.totalDataPoints)",
                        valueColor: .pip.home.numRecords
                    )
                    
                    // Streaks (HStack: Icon + Value)
                    StatItem(
                        iconName: "icon_streaks",
                        value: "\(stats.currentStreak)",
                        valueColor: .pip.home.numStreaks
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    Color.black.opacity(0.8),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Stat Item Component (Simplified)
/// Display only Icon + Value (label is included in icon asset)
struct StatItem: View {
    let iconName: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Image(iconName)
                .resizable()
                .frame(width: 40, height: 40)
            
            Text(value)
                .font(.pip.hero)
                .foregroundColor(valueColor)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HomeView()
    }
}

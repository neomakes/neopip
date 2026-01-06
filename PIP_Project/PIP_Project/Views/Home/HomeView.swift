// Location: Views/HomeView.swift
import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @State private var selectedGem: GemRecord?
    let showWriteOverlay: Binding<Bool>?
    let onWriteRequested: (() -> Void)?
    
    init(viewModel: HomeViewModel, showWriteOverlay: Binding<Bool>? = nil, onWriteRequested: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.showWriteOverlay = showWriteOverlay
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

            // Write overlay (shown when binding is true)
            if let overlay = showWriteOverlay, overlay.wrappedValue {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            overlay.wrappedValue = false
                        }

                    WriteView(isPresented: overlay)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                }
                .animation(.easeInOut, value: overlay.wrappedValue)
            }

            // Floating write button (bottom-right) — visible on Home; hidden while Write overlay is presented
            if let overlay = showWriteOverlay {
                if !overlay.wrappedValue {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    overlay.wrappedValue = true
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.pip.tabBar.buttonAddGrad1,
                                                    Color.pip.tabBar.buttonAddGrad2
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: CGFloat.PIPLayout.tabbarAddButtonSize, height: CGFloat.PIPLayout.tabbarAddButtonSize)
                                        .shadow(radius: 6)

                                    Image("icon_write")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: CGFloat.PIPLayout.tabbarAddButtonSize * 0.75, height: CGFloat.PIPLayout.tabbarAddButtonSize * 0.75)
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.trailing, CGFloat.PIPLayout.tabbarHorizontalPadding)
                            .padding(.bottom, CGFloat.PIPLayout.safeAreaBottomHeight + 80)
                        }
                    }
                }
            } else {
                // No binding provided — fall back to callback behavior (show button)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            onWriteRequested?()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.pip.tabBar.buttonAddGrad1,
                                                Color.pip.tabBar.buttonAddGrad2
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: CGFloat.PIPLayout.tabbarAddButtonSize, height: CGFloat.PIPLayout.tabbarAddButtonSize)
                                    .shadow(radius: 6)

                                Image("icon_write")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: CGFloat.PIPLayout.tabbarAddButtonSize * 0.75, height: CGFloat.PIPLayout.tabbarAddButtonSize * 0.75)
                                    .foregroundColor(.white)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.trailing, CGFloat.PIPLayout.tabbarHorizontalPadding)
                        .padding(.bottom, CGFloat.PIPLayout.safeAreaBottomHeight + 80)
                    }
                }
            }
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
            VStack(alignment: .leading, spacing: 12) {
                // Records (HStack: Icon + Value) — computed from dailyGems
                StatItem(
                    iconName: "icon_records",
                    value: "\(viewModel.totalGemsCreated)",
                    valueColor: .pip.home.numRecords
                )

                // Streaks (HStack: Icon + Value) — computed from dailyGems
                StatItem(
                    iconName: "icon_streaks",
                    value: "\(viewModel.currentStreak)",
                    valueColor: .pip.home.numStreaks
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
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
        HomeView(viewModel: HomeViewModel(dataService: MockDataService.shared))
    }
}

// Location: Views/HomeView.swift
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var localization = LocalizationService.shared
    @Binding var showWriteSheet: Bool
    @State private var selectedGem: DailyGem?
    
    init(showWriteSheet: Binding<Bool> = .constant(false)) {
        self._showWriteSheet = showWriteSheet
    }
    
    var body: some View {
        // Do NOT add PrimaryBackground() here.
        // The background is already provided by MainTabView.
        ZStack(alignment: .top) {
            // Main scrollable content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Spacer for fixed header
                    Spacer()
                        .frame(height: 80)
                    
                    // Railroad View (Vertical Timeline with perspective)
                    railroadSection
                    
                    // Loading & Error States
                    stateViews
                    
                    // Bottom padding for TabBar
                    Spacer()
                        .frame(height: 120)
                }
            }
            
            // Fixed Stats Header (Top Left) - Always visible
            fixedStatsHeader
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showWriteSheet) {
            WriteSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedGem) { gem in
            GemDetailView(gem: gem, viewModel: viewModel)
        }
    }
    
    // MARK: - Fixed Stats Header
    private var fixedStatsHeader: some View {
        VStack {
            if let stats = viewModel.userStats {
                HStack(spacing: 32) {
                    // Total Records
                    StatItem(
                        iconName: "icon_records",
                        value: "\(stats.totalDataPoints)",
                        label: "totalRecords".localized,
                        valueColor: .pip.home.numRecords
                    )
                    
                    // Current Streak
                    StatItem(
                        iconName: "icon_streaks",
                        value: "\(stats.currentStreak)",
                        label: "streakRecords".localized,
                        valueColor: .pip.home.numStreaks
                    )
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    // Gradient fade for visual separation
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.9),
                            Color.black.opacity(0.7),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            Spacer()
        }
    }
    
    // MARK: - Railroad Section
    private var railroadSection: some View {
        Group {
            if !viewModel.dailyGems.isEmpty {
                // Sort by date (newest first for display, but reverse for railroad - oldest at top)
                let sortedGems = viewModel.dailyGems.sorted { $0.date < $1.date }
                
                VStack(spacing: 0) {
                    // Railroad view with perspective (oldest at top, newest at bottom)
                    RailroadView(
                        gems: Array(sortedGems.suffix(30)), // Show last 30 days
                        onGemTap: { gem in
                            selectedGem = gem
                        }
                    )
                    .padding(.horizontal, 20)
                }
            } else if !viewModel.isLoading {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("No records yet")
                        .font(.pip.title2)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Tap the + button to start your first record")
                        .font(.pip.body)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 100)
            }
        }
    }
    
    // MARK: - State Views
    private var stateViews: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding()
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .font(.pip.caption)
                    .foregroundColor(.red)
                    .padding()
            }
            
            #if DEBUG
            debugInfo
            #endif
        }
    }
    
    // MARK: - Debug Info
    #if DEBUG
    private var debugInfo: some View {
        Group {
            if !viewModel.dailyGems.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Debug: \(viewModel.dailyGems.count) gems")
                        .font(.pip.caption)
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }
    #endif
    
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

// MARK: - Stat Item Component
struct StatItem: View {
    let iconName: String
    let value: String
    let label: String
    let valueColor: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.pip.hero)
                    .foregroundColor(valueColor)
                
                Text(label)
                    .font(.pip.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HomeView()
    }
}

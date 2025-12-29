// PIP_Project/PIP_Project/Views/Status/Sections/StatsCardsSection.swift
import SwiftUI

// MARK: - Stats Cards Section
struct StatsCardsSection: View {
    @ObservedObject var viewModel: StatusViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Wins
            StatsCard(
                iconName: "icon_wins",
                value: "\(viewModel.userStats?.totalProgramsCompleted ?? 0)",
                valueColor: .pip.status.numWins
            )
            
            // Records
            StatsCard(
                iconName: "icon_records",
                value: "\(viewModel.userStats?.totalDataPoints ?? 0)",
                valueColor: .pip.status.numRecords
            )
            
            // Streaks
            StatsCard(
                iconName: "icon_streaks",
                value: "\(viewModel.userStats?.currentStreak ?? 0)",
                valueColor: .pip.status.numStreaks
            )
        }
    }
}

struct StatsCard: View {
    let iconName: String
    let value: String
    let valueColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
            
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}
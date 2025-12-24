// Location: Views/StatusView.swift
import SwiftUI

enum AppRoute: Hashable {
    case settings
    case licenses
}

struct StatusView: View {
    @StateObject private var viewModel = StatusViewModel()
    @State private var path = NavigationPath()
    @State private var selectedAchievementIndex = 0
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color.clear
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: - Profile Section
                        ProfileHeaderSection(
                            viewModel: viewModel,
                            path: $path
                        )
                        .padding(.bottom, 5)
                        
                        // MARK: - Stats Cards Section
                        StatsCardsSection(viewModel: viewModel)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        
                        // MARK: - Achievements Section
                        if !viewModel.achievements.isEmpty {
                            AchievementsSection(
                                achievements: viewModel.achievements,
                                selectedIndex: $selectedAchievementIndex
                            )
                            .padding(.bottom, 30)
                        }
                        
                        // MARK: - Values Section
                        if let valueAnalysis = viewModel.valueAnalysis {
                            ValuesSection(valueAnalysis: valueAnalysis)
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 30)
                    }
                }
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .settings:
                        SettingsView(path: $path)
                    case .licenses:
                        LicenseView()
                    }
                }
            }
        }
        .onAppear {
            setNavigationTransparency()
        }
    }
    
    private func setNavigationTransparency() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Profile Header Section
struct ProfileHeaderSection: View {
    @ObservedObject var viewModel: StatusViewModel
    @Binding var path: NavigationPath
    
    var body: some View {
        VStack(spacing: 0) {
            // Background section with settings and greeting
            VStack(spacing: 4) {
                // Settings button in top-right
                HStack {
                    Spacer()
                    Button(action: {
                        path.append(AppRoute.settings)
                    }) {
                        Image("icon_setting")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 16)
                
                // Greeting
                Text("Hi \(viewModel.userProfile?.displayName ?? "NEO")!")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .frame(height: 150)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        randomColor()
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .ignoresSafeArea(edges: .horizontal)
            
            // Profile image
            VStack(spacing: 0) {
                if let profileImageName = viewModel.userProfile?.profileImageURL {
                    Image(profileImageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 2))
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.top, -75)
        }
    }
    
    private func randomColor() -> Color {
        let colors: [Color] = [
            Color(red: 0.5, green: 0.85, blue: 0.85),
            Color(red: 0.8, green: 0.4, blue: 0.6),
            Color(red: 0.4, green: 0.7, blue: 0.9),
            Color(red: 0.6, green: 0.5, blue: 0.8),
            Color(red: 0.3, green: 0.8, blue: 0.6)
        ]
        return colors.randomElement() ?? Color(red: 0.5, green: 0.85, blue: 0.85)
    }
}

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

// MARK: - Achievements Section
struct AchievementsSection: View {
    let achievements: [Achievement]
    @Binding var selectedIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(alignment: .center, spacing: 6) {
                    Image("title_logo_8")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                    
                    Text("Achievements")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Achievement carousel with navigation buttons integrated
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Left navigation button
                    Button(action: {
                        withAnimation {
                            selectedIndex = max(0, selectedIndex - 1)
                        }
                    }) {
                        Image("icon_expand_left")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                    .disabled(selectedIndex == 0)
                    .opacity(selectedIndex == 0 ? 0.5 : 1.0)
                    
                    // Achievement item
                    ZStack {
                        if selectedIndex < achievements.count {
                            let achievement = achievements[selectedIndex]
                            
                            VStack(spacing: 12) {
                                // Preview image or gradient
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: achievement.colorScheme.map { Color(hex: $0) }),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    VStack(spacing: 0) {
                                        Spacer()
                                        HStack(spacing: 0) {
                                            Spacer()
                                            Image("3d_shape_\(Int.random(in: 1...15))")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 100, height: 100)
                                                .blendMode(.screen)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                }
                                .frame(height: 100)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(achievement.title)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(achievement.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        withAnimation {
                                            if value.translation.width < -50 {
                                                selectedIndex = min(achievements.count - 1, selectedIndex + 1)
                                            } else if value.translation.width > 50 {
                                                selectedIndex = max(0, selectedIndex - 1)
                                            }
                                        }
                                    }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right navigation button
                    Button(action: {
                        withAnimation {
                            selectedIndex = min(achievements.count - 1, selectedIndex + 1)
                        }
                    }) {
                        Image("icon_expand_right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                    .disabled(selectedIndex == achievements.count - 1)
                    .opacity(selectedIndex == achievements.count - 1 ? 0.5 : 1.0)
                }
                
                // Navigation dots at bottom (separated from card)
                HStack(spacing: 8) {
                    Spacer()
                    ForEach(0..<achievements.count, id: \.self) { index in
                        Circle()
                            .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                withAnimation {
                                    selectedIndex = index
                                }
                            }
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Values Section
struct ValuesSection: View {
    let valueAnalysis: ValueAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image("title_logo3")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                
                Text("Values")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                // Left side: Bar chart
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(valueAnalysis.topValues.prefix(3), id: \.id) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            HStack(spacing: 8) {
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.1))
                                    
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(getColorForValue(item.score))
                                        .frame(width: CGFloat(item.score) * 80)
                                }
                                .frame(height: 8)
                                
                                Text(String(format: "%.0f%%", item.score * 100))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .frame(width: 30)
                            }
                        }
                    }
                }
                .frame(maxWidth: 120, alignment: .leading)
                
                Spacer()
                
                // Right side: Radar chart
                let radarDataItems = valueAnalysis.topValues.map { item in
                    RadarChartDataItem(
                        iconName: item.name.lowercased(),
                        value: item.score,
                        displayValue: String(format: "%.0f%%", item.score * 100)
                    )
                }
                let radarDataSet = RadarChartDataSet(
                    title: "Values",
                    data: radarDataItems,
                    dataColor: Color(red: 0.5, green: 0.7, blue: 0.8)
                )
                RadarChartView(dataSet: radarDataSet)
                    .frame(width: 140, height: 140)
            }
            .padding(12)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
            
            // Comparison info
            if let comparison = valueAnalysis.comparisonData {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Compared to others")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Percentile")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            
                            Text(String(format: "%.1f%%", comparison.userPercentile))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Divider()
                            .foregroundColor(.white.opacity(0.2))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Average Score")
                                .font(.system(size: 11))
                                .foregroundColor(.gray)
                            
                            Text(String(format: "%.2f", comparison.averageScore))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private func getColorForValue(_ value: Double) -> Color {
        switch value {
        case 0.8...:
            return Color(red: 0.3, green: 0.8, blue: 0.6)
        case 0.6...:
            return Color(red: 0.8, green: 0.7, blue: 0.3)
        default:
            return Color(red: 0.8, green: 0.4, blue: 0.3)
        }
    }
}

// MARK: - Settings and License Views
struct SettingsView: View {
    @Binding var path: NavigationPath
    
    var body: some View {
        List {
            Section(header: Text("Legal").foregroundColor(.gray)) {
                Button(action: {
                    path.append(AppRoute.licenses)
                }) {
                    Label("Open Source Licenses", systemImage: "text.book.closed.fill")
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            
            Section(header: Text("Device Info").foregroundColor(.gray)) {
                LabeledContent("Version", value: "1.0.0 (Build 2025)")
                    .listRowBackground(Color.white.opacity(0.05))
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}

struct LicenseView: View {
    var body: some View {
        List(LicenseData.items) { item in
            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Author: \(item.author)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Text(item.licenseType)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    if let url = URL(string: item.url) {
                        Link("Source", destination: url)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
        }
        .navigationTitle("Licenses")
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let rgb = Int(hex, radix: 16) ?? 0
        
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

#Preview {
    StatusView()
}

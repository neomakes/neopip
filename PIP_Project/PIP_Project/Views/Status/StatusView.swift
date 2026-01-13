// Location: Views/Status/StatusView.swift
import SwiftUI

enum StatusRoute: Hashable {
    case settings
    case licenses
}

struct StatusView: View {
    @ObservedObject var viewModel: StatusViewModel
    @State private var path = NavigationPath()
    @State private var selectedAchievementIndex = 0
    
    init(viewModel: StatusViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                PrimaryBackground()
                    .ignoresSafeArea()
                
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
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        
                        // MARK: - Achievements Section
                        AchievementsSection(
                            achievements: viewModel.achievements,
                            selectedIndex: $selectedAchievementIndex
                        )
                        .padding(.bottom, 20)
                        
                        // MARK: - Values Section
                        ValuesSection(valueAnalysis: viewModel.valueAnalysis)
                        
                        Spacer(minLength: 100)
                    }
                }
                .navigationDestination(for: StatusRoute.self) { route in
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
            viewModel.loadInitialData()
        }
    }
    
    private func setNavigationTransparency() {
        // Navigation transparency is handled by SwiftUI NavigationStack
        // No additional UIKit configuration needed
    }
}

#Preview {
    StatusView(viewModel: StatusViewModel(dataService: MockDataService.shared))
}

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
                        }
                        
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

//
//  StatusViewModel.swift
//  PIP_Project
//
//  StatusView의 ViewModel
//

import Foundation
import Combine
import SwiftUI

@MainActor
class StatusViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userStats: UserStats?
    @Published var achievements: [Achievement] = []
    @Published var valueAnalysis: ValueAnalysis?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let dataService: DataServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol = MockDataService.shared) {
        self.dataService = dataService
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 초기 데이터 로드
    func loadInitialData() {
        isLoading = true
        errorMessage = nil
        
        // UserStats 로드
        dataService.fetchUserStats()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] stats in
                    self?.userStats = stats
                }
            )
            .store(in: &cancellables)
        
        // Mock Achievements 생성
        createMockAchievements()
        
        // Mock ValueAnalysis 생성
        createMockValueAnalysis()
    }
    
    // MARK: - Private Methods
    
    private func createMockAchievements() {
        achievements = [
            Achievement(
                id: UUID(),
                accountId: UUID(),
                programId: UUID(),
                title: "21일 감정 일기 완료",
                description: "21일간 꾸준히 감정을 기록했습니다",
                category: .consistency,
                unlockedDate: Date(),
                isUnlocked: true,
                illustration3D: AchievementIllustration3D(
                    modelId: "achievement_21days",
                    modelURL: nil,
                    previewImageURL: nil,
                    colorScheme: ["#82EBEB", "#40DBDB"]
                ),
                colorScheme: ["#82EBEB", "#40DBDB", "#31B0B0"],
                iconName: "achievement_21days",
                createdAt: Date()
            )
        ]
    }
    
    private func createMockValueAnalysis() {
        valueAnalysis = ValueAnalysis(
            id: UUID(),
            accountId: UUID(),
            analysisDate: Date(),
            topValues: [
                ValueItem(
                    id: UUID(),
                    name: "건강",
                    score: 0.75,
                    description: "신체적 웰빙에 높은 가치를 둡니다",
                    trend: .increasing
                ),
                ValueItem(
                    id: UUID(),
                    name: "성장",
                    score: 0.68,
                    description: "개인적 성장에 관심이 많습니다",
                    trend: .stable
                )
            ],
            valueDistribution: [
                "health": 0.75,
                "personalGrowth": 0.68,
                "relationships": 0.55
            ],
            comparisonData: ComparisonData(
                userPercentile: 72.5,
                averageScore: 0.65,
                uniqueAspects: ["높은 일관성", "명확한 목표 의식"]
            ),
            insights: [
                "건강에 대한 가치가 높아 신체 데이터 수집에 적극적입니다",
                "성장 지향적 성향이 강해 목표 달성률이 높습니다"
            ],
            createdAt: Date()
        )
    }
}

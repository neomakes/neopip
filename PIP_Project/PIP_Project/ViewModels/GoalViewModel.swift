//
//  GoalViewModel.swift
//  PIP_Project
//
//  GoalView의 ViewModel
//

import Foundation
import Combine
import SwiftUI

@MainActor
class GoalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var activeGoals: [Goal] = []
    @Published var availablePrograms: [Program] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 초기 데이터 로드
    func loadInitialData() {
        isLoading = true
        createMockGoals()
        createMockPrograms()
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func createMockGoals() {
        activeGoals = [
            Goal(
                id: UUID(),
                accountId: UUID(),
                title: "감정 관리 개선",
                description: "일상적인 스트레스를 효과적으로 관리하기",
                category: .emotional,
                targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                startDate: Date(),
                status: .active,
                progress: 0.45,
                gemVisualization: GemVisualization(
                    gemType: .crystal,
                    colorTheme: .teal,
                    brightness: 0.7,
                    size: 1.0,
                    customShape: nil
                ),
                milestones: [],
                relatedDataPointIds: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
    
    private func createMockPrograms() {
        availablePrograms = [
            Program(
                id: UUID(),
                name: "21일 감정 일기 프로그램",
                description: "21일간 꾸준한 감정 기록을 통해 자신의 감정 패턴을 이해하고 관리하는 프로그램",
                category: .emotional,
                duration: 21,
                difficulty: .beginner,
                gemVisualization: GemVisualization(
                    gemType: .diamond,
                    colorTheme: .amber,
                    brightness: 0.8,
                    size: 1.0,
                    customShape: nil
                ),
                illustration3D: ProgramIllustration3D(
                    modelId: "emotion_program_3d",
                    modelURL: nil,
                    previewImageURL: nil,
                    colorScheme: ["#82EBEB", "#FFA500"]
                ),
                popularity: 0.85,
                rating: 4.5,
                reviewCount: 234,
                userCount: 1234,
                steps: [],
                prerequisites: nil,
                tags: ["감정", "일기", "21일"],
                expectedEffects: [
                    "감정 인식 능력 향상",
                    "스트레스 관리 개선",
                    "자기 이해도 증가"
                ],
                requiredDataTypes: ["mood", "stress", "energy"],
                userReviews: nil,
                isRecommended: true,
                createdAt: Date()
            )
        ]
    }
}

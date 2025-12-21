//
//  InsightViewModel.swift
//  PIP_Project
//
//  InsightView의 ViewModel
//

import Foundation
import Combine
import SwiftUI

@MainActor
class InsightViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var orbVisualization: OrbVisualization?
    @Published var predictions: [PredictionData] = []
    @Published var analysisCards: [InsightAnalysisCard] = []
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
        
        // Mock Orb 생성
        createMockOrb()
        
        // Mock Predictions 생성
        createMockPredictions()
        
        // Mock Analysis Cards 생성
        createMockAnalysisCards()
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func createMockOrb() {
        // 오늘 날짜 기준 Mock Orb 생성
        let mockAnonymousUserId = UUID()
        
        orbVisualization = OrbVisualization(
            id: UUID(),
            anonymousUserId: mockAnonymousUserId,
            date: Date(),
            brightness: Double.random(in: 0.6...0.9), // 사용자 모델 재생성 성능
            borderBrightness: Double.random(in: 0.7...0.95), // 오늘 예측 정확도
            complexity: Int.random(in: 3...8),
            uncertainty: Double.random(in: 0.1...0.3),
            uniqueFeatures: [
                "mood_variance": Double.random(in: 0.3...0.7),
                "energy_consistency": Double.random(in: 0.5...0.9),
                "sleep_pattern": Double.random(in: 0.4...0.8)
            ],
            timeSeriesFeatures: [:],
            categoryWeights: [
                "mind": Double.random(in: 0.3...0.5),
                "behavior": Double.random(in: 0.2...0.4),
                "physical": Double.random(in: 0.2...0.4)
            ],
            gemType: .sphere,
            colorTheme: .teal,
            size: 1.0,
            colorGradient: ["#82EBEB", "#40DBDB", "#31B0B0"],
            dataPointIds: [],
            mlModelOutputId: nil,
            createdAt: Date()
        )
    }
    
    private func createMockPredictions() {
        let calendar = Calendar.current
        var predictions: [PredictionData] = []
        
        for dayOffset in 1...7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            
            predictions.append(PredictionData(
                id: UUID(),
                anonymousUserId: UUID(),
                targetDate: date,
                predictedMindScore: Double.random(in: 0.6...0.9),
                predictedBehaviorScore: Double.random(in: 0.5...0.85),
                predictedPhysicalScore: Double.random(in: 0.55...0.9),
                confidence: Double.random(in: 0.7...0.95),
                uncertainty: Double.random(in: 0.1...0.3),
                trendContext: "최근 패턴을 기반으로 한 예측",
                createdAt: Date()
            ))
        }
        
        self.predictions = predictions
    }
    
    private func createMockAnalysisCards() {
        let mockInsightId = UUID()
        
        analysisCards = [
            InsightAnalysisCard(
                id: UUID(),
                insightId: mockInsightId,
                anonymousUserId: UUID(),
                title: "이번 주 감정 패턴 분석",
                subtitle: "당신의 감정 점수가 평균 0.72로, 이전 주 대비 5% 상승했습니다",
                cardType: .explanation,
                pages: [
                    AnalysisCardPage(
                        id: UUID(),
                        pageNumber: 1,
                        contentType: .text,
                        content: PageContent(
                            text: "이번 주 감정 패턴 분석",
                            headline: "긍정적인 변화가 보입니다",
                            body: "최근 7일간의 데이터를 분석한 결과, 당신의 감정 점수가 꾸준히 상승하고 있습니다.",
                            mantra: nil
                        ),
                        visualizations: nil
                    )
                ],
                actionProposals: [],
                isLiked: false,
                likedAt: nil,
                acceptedActions: [],
                createdAt: Date()
            )
        ]
    }
}

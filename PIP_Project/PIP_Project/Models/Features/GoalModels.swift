//
//  GoalModels.swift
//  PIP_Project
//
//  Goal & Program Models
//

import Foundation

// MARK: - Goal
/// 목표
/// Firestore의 users/{accountId}/goals/{goalId}에 저장
struct Goal: Identifiable, Codable {
    let id: UUID
    var accountId: UUID
    var title: String
    var description: String?
    var category: GoalCategory
    var targetDate: Date?
    var startDate: Date
    var status: GoalStatus
    var progress: Double           // 0.0 ~ 1.0 (진행률)
    var gemVisualization: GemVisualization
    var milestones: [Milestone]
    var relatedDataPointIds: [String]    // 관련 TimeSeriesDataPoint ID 배열
    var createdAt: Date
    var updatedAt: Date
    
    var accountIdString: String {
        accountId.uuidString
    }
    
    var goalIdString: String {
        id.uuidString
    }
}

enum GoalStatus: String, Codable {
    case active       // 진행 중
    case paused       // 일시 정지
    case completed    // 완료
    case cancelled    // 취소
}

struct GemVisualization: Codable {
    var gemType: GemType
    var colorTheme: ColorTheme
    var brightness: Double         // 진행률에 따라 조절
    var size: Double
    var customShape: String?       // 커스텀 형태 ID
}

struct Milestone: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var targetDate: Date?
    var completedDate: Date?
    var isCompleted: Bool
    var progress: Double
}

// MARK: - Program
/// 프로그램
/// Firestore의 programs/{programId}에 저장 (공유 가능)
struct Program: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var category: GoalCategory
    var duration: Int              // 일 단위
    var difficulty: DifficultyLevel
    var gemVisualization: GemVisualization
    
    // 3D 일러스트 정보
    var illustration3D: ProgramIllustration3D?
    
    // 인기도 및 평가
    var popularity: Double          // 0.0 ~ 1.0 (인기도 점수)
    var rating: Double?             // 1.0 ~ 5.0 (평균 평점)
    var reviewCount: Int            // 리뷰 수
    var userCount: Int             // 사용자 수
    
    // 프로그램 상세
    var steps: [ProgramStep]
    var prerequisites: [String]?
    var tags: [String]
    var expectedEffects: [String]   // 기대 효과 목록
    var requiredDataTypes: [String] // 필요한 데이터 타입 ID 배열
    
    // 사용자 평가
    var userReviews: [ProgramReview]?  // 최근 리뷰들
    
    var isRecommended: Bool        // AI 추천 여부
    var createdAt: Date
    
    var programIdString: String {
        id.uuidString
    }
}

struct ProgramIllustration3D: Codable {
    var modelId: String            // 3D 모델 ID
    var modelURL: String?          // 3D 모델 URL
    var previewImageURL: String?   // 프리뷰 이미지 URL
    var colorScheme: [String]      // 색상 스키마 (Hex 배열)
}

struct ProgramReview: Identifiable, Codable {
    let id: UUID
    var accountId: UUID
    var programId: UUID
    var rating: Double             // 1.0 ~ 5.0
    var comment: String?
    var createdAt: Date
    
    var accountIdString: String {
        accountId.uuidString
    }
}

enum DifficultyLevel: String, Codable {
    case beginner
    case intermediate
    case advanced
}

struct ProgramStep: Identifiable, Codable {
    let id: UUID
    var order: Int
    var title: String
    var description: String
    var duration: Int?             // 분 단위
    var isCompleted: Bool
    var completedDate: Date?
}

// MARK: - Goal Progress
/// 목표 진행 상황
/// Firestore의 users/{accountId}/goals/{goalId}/progress/{progressId}에 저장
struct GoalProgress: Identifiable, Codable {
    let id: UUID
    var goalId: UUID
    var accountId: UUID
    var date: Date
    var progress: Double           // 0.0 ~ 1.0
    var activitiesCompleted: Int
    var activitiesTotal: Int
    var notes: String?
    var createdAt: Date
    
    var goalIdString: String {
        goalId.uuidString
    }
    
    var accountIdString: String {
        accountId.uuidString
    }
}

// MARK: - Goal Recommendation
/// 목표 추천
/// Firestore의 users/{accountId}/goal_recommendations/{recommendationId}에 저장
struct GoalRecommendation: Identifiable, Codable {
    let id: UUID
    var accountId: UUID
    var goalId: UUID?                     // 기존 목표 ID (없으면 새로 생성)
    var title: String
    var description: String
    var category: GoalCategory
    var confidence: Double                // 추천 신뢰도
    var reasoning: String                 // 추천 이유
    var expectedImpact: Double            // 예상 효과 (0.0 ~ 1.0)
    var basedOnInsights: [String]         // 기반 인사이트 ID들 (String 배열)
    var createdAt: Date
    
    var accountIdString: String {
        accountId.uuidString
    }
}

// MARK: - Goal Recommendation Input
/// 목표 추천 알고리즘 입력
/// Firestore에 저장하지 않고, 쿼리로 생성
struct GoalRecommendationInput: Codable {
    var accountId: UUID
    var anonymousUserId: UUID
    var timeSeriesWindow: TimeSeriesWindow?
    var currentGoals: [String]             // 현재 활성 목표 ID들
    var userPreferences: UserPreferences
    var mlFeatures: [String: Double]       // ML 모델 특징값
}

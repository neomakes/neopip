//
//  GoalModels.swift
//  PIP_Project
//
//  Goal & Program Models
//

import Foundation
import CryptoKit

// MARK: - Enums (Re-define for GoalModels)

/// Generate deterministic UUIDs from arbitrary strings (used for legacy/mock IDs)
extension UUID {
    static func deterministicUUID(from string: String) -> UUID {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        let bytes: [UInt8] = Array(hash.prefix(16))
        let uuid: uuid_t = (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuid: uuid)
    }
}

public enum GemTypeForGoal: String, Codable {
    case sphere
    case diamond
    case crystal
    case prism
    case custom
}

public enum ColorThemeForGoal: String, Codable {
    case teal
    case amber
    case tiger
    case blue
    
    var hexColor: String {
        switch self {
        case .teal:
            return "#14B8A6"
        case .amber:
            return "#F59E0B"
        case .tiger:
            return "#FF6B35"
        case .blue:
            return "#3B82F6"
        }
    }
}

// MARK: - Type Aliases for GoalModels
// These are explicitly namespaced to avoid collisions

// MARK: - User Preferences (for GoalRecommendationInput)
enum AppThemeForGoal: String, Codable {
    case dark
    case light
    case system
}

struct UserPreferencesForGoal: Codable {
    var theme: AppThemeForGoal
    var notificationsEnabled: Bool
    var language: String
    var timeZone: String
}

// MARK: - Time Series Window (for GoalRecommendationInput)
struct TimeSeriesWindowForGoal: Codable {
    var startDate: Date
    var endDate: Date
    var aggregatedFeatures: [String: Double]  // 집계된 특징값
    var trendFeatures: [String: Double]       // 트렌드 특징값
    var seasonalityFeatures: [String: Double]? // 계절성 특징값
}

// MARK: - Goal
/// 목표
/// Firestore의 users/{accountId}/goals/{goalId}에 저장
struct Goal: Identifiable, Codable {
    let id: UUID
    var accountId: String
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
    var gemType: GemTypeForGoal
    var colorTheme: ColorThemeForGoal
    var gradientColors: [String]? // Add gradient colors for richer background
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
    
    var storyFileName: String {
        // Generate filename based on program index or id
        // For now, use a simple mapping based on name
        switch name {
        case "21-Day Emotional Journal Program":
            return "P001-UUID-0001-0001"
        case "Morning Meditation Habit":
            return "P002-UUID-0002-0002"
        case "Weekly Reading Goal":
            return "P003-UUID-0003-0003"
        default:
            return programIdString
        }
    }

    // Custom Decoding: allow string IDs that are not standard UUIDs (legacy/mock data)
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, duration, difficulty, gemVisualization, illustration3D, popularity, rating, reviewCount, userCount, steps, prerequisites, tags, expectedEffects, requiredDataTypes, userReviews, isRecommended, createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idString = try container.decode(String.self, forKey: .id)
        if let uuid = UUID(uuidString: idString) {
            id = uuid
        } else {
            id = UUID.deterministicUUID(from: idString)
        }

        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(GoalCategory.self, forKey: .category)
        duration = try container.decode(Int.self, forKey: .duration)
        difficulty = try container.decode(DifficultyLevel.self, forKey: .difficulty)
        gemVisualization = try container.decode(GemVisualization.self, forKey: .gemVisualization)
        illustration3D = try container.decodeIfPresent(ProgramIllustration3D.self, forKey: .illustration3D)
        popularity = try container.decode(Double.self, forKey: .popularity)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        reviewCount = try container.decode(Int.self, forKey: .reviewCount)
        userCount = try container.decode(Int.self, forKey: .userCount)
        steps = try container.decodeIfPresent([ProgramStep].self, forKey: .steps) ?? []
        prerequisites = try container.decodeIfPresent([String].self, forKey: .prerequisites)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        expectedEffects = try container.decodeIfPresent([String].self, forKey: .expectedEffects) ?? []
        requiredDataTypes = try container.decodeIfPresent([String].self, forKey: .requiredDataTypes) ?? []
        userReviews = try container.decodeIfPresent([ProgramReview].self, forKey: .userReviews)
        isRecommended = try container.decodeIfPresent(Bool.self, forKey: .isRecommended) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    // Preserve Encodable conformance explicitly and implement encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(category, forKey: .category)
        try container.encode(duration, forKey: .duration)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encode(gemVisualization, forKey: .gemVisualization)
        try container.encodeIfPresent(illustration3D, forKey: .illustration3D)
        try container.encode(popularity, forKey: .popularity)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encode(reviewCount, forKey: .reviewCount)
        try container.encode(userCount, forKey: .userCount)
        try container.encode(steps, forKey: .steps)
        try container.encodeIfPresent(prerequisites, forKey: .prerequisites)
        try container.encode(tags, forKey: .tags)
        try container.encode(expectedEffects, forKey: .expectedEffects)
        try container.encode(requiredDataTypes, forKey: .requiredDataTypes)
        try container.encodeIfPresent(userReviews, forKey: .userReviews)
        try container.encode(isRecommended, forKey: .isRecommended)
        try container.encode(createdAt, forKey: .createdAt)
    }

    // Explicit memberwise initializer to preserve previous usage sites (Program(...))
    init(
        id: UUID,
        name: String,
        description: String,
        category: GoalCategory,
        duration: Int,
        difficulty: DifficultyLevel,
        gemVisualization: GemVisualization,
        illustration3D: ProgramIllustration3D?,
        popularity: Double,
        rating: Double?,
        reviewCount: Int,
        userCount: Int,
        steps: [ProgramStep],
        prerequisites: [String]?,
        tags: [String],
        expectedEffects: [String],
        requiredDataTypes: [String],
        userReviews: [ProgramReview]?,
        isRecommended: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.duration = duration
        self.difficulty = difficulty
        self.gemVisualization = gemVisualization
        self.illustration3D = illustration3D
        self.popularity = popularity
        self.rating = rating
        self.reviewCount = reviewCount
        self.userCount = userCount
        self.steps = steps
        self.prerequisites = prerequisites
        self.tags = tags
        self.expectedEffects = expectedEffects
        self.requiredDataTypes = requiredDataTypes
        self.userReviews = userReviews
        self.isRecommended = isRecommended
        self.createdAt = createdAt
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
    var accountId: String
    var programId: UUID
    var rating: Double             // 1.0 ~ 5.0
    var comment: String?
    var createdAt: Date
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

    enum CodingKeys: String, CodingKey {
        case id, order, title, description, duration, isCompleted, completedDate, day
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idString = try container.decode(String.self, forKey: .id)
        if let uuid = UUID(uuidString: idString) {
            id = uuid
        } else {
            id = UUID.deterministicUUID(from: idString)
        }
        order = (try? container.decode(Int.self, forKey: .order)) ?? (try? container.decode(Int.self, forKey: .day)) ?? 0
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        completedDate = try container.decodeIfPresent(Date.self, forKey: .completedDate)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(order, forKey: .order)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(completedDate, forKey: .completedDate)
    }
} 

// MARK: - Goal Progress
/// 목표 진행 상황
/// Firestore의 users/{accountId}/goals/{goalId}/progress/{progressId}에 저장
struct GoalProgress: Identifiable, Codable {
    let id: UUID
    var goalId: UUID
    var accountId: String
    var date: Date
    var progress: Double           // 0.0 ~ 1.0
    var activitiesCompleted: Int
    var activitiesTotal: Int
    var notes: String?
    var createdAt: Date
    
    var goalIdString: String {
        goalId.uuidString
    }
}

// MARK: - Goal Recommendation
/// 목표 추천
/// Firestore의 users/{accountId}/goal_recommendations/{recommendationId}에 저장
struct GoalRecommendation: Identifiable, Codable {
    let id: UUID
    var accountId: String
    var goalId: UUID?                     // 기존 목표 ID (없으면 새로 생성)
    var title: String
    var description: String
    var category: GoalCategory
    var confidence: Double                // 추천 신뢰도
    var reasoning: String                 // 추천 이유
    var expectedImpact: Double            // 예상 효과 (0.0 ~ 1.0)
    var basedOnInsights: [String]         // 기반 인사이트 ID들 (String 배열)
    var createdAt: Date
}
// MARK: - Program Progress
/// 프로그램 진행 상황 (메트릭 및 스토리 포함)
/// Firestore의 users/{accountId}/goals/{goalId}/program_progress/{programId}에 저장
struct ProgramProgress: Identifiable, Codable {
    let id: UUID
    var programId: UUID
    var goalId: UUID
    var accountId: String
    
    // 메트릭 데이터
    var beforeMetrics: [String: Double]    // 프로그램 시작 전 메트릭 (mood, stress, energy 등)
    var currentMetrics: [String: Double]   // 현재 메트릭
    var improvementRate: Double            // 개선율 (0.0 ~ 1.0)
    
    // 진행률 히스토리
    var progressHistory: [ProgressPoint]   // 날짜별 진행 데이터
    
    // 스토리 데이터
    var stories: [ProgramStory]            // Program execution stories (Instagram format)
    
    // 레이더 차트 데이터
    var radarChartData: [RadarDataPoint]   // 초기 vs 현재 메트릭 비교용
    
    var createdAt: Date
    var updatedAt: Date
    
    var programIdString: String {
        programId.uuidString
    }
    
    var goalIdString: String {
        goalId.uuidString
    }
}

// MARK: - Progress Point
/// 목표 진행 포인트 (BarLineChart용)
struct ProgressPoint: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date
    var goalProgress: Double               // 현재 Goal 진행률 (0.0 ~ 1.0)
    var presentProgress: Double            // 기준선/예상치 (0.0 ~ 1.0)
    var sessionsCompleted: Int
    var sessionsPlanned: Int
}

// MARK: - Radar Data Point
/// 레이더 차트 데이터 포인트
struct RadarDataPoint: Identifiable, Codable {
    var id: UUID = UUID()
    var label: String                      // "Mood", "Stress", "Energy" 등
    var beforeValue: Double                // 초기 값 (0.0 ~ 1.0)
    var afterValue: Double                 // 현재 값 (0.0 ~ 1.0)
    var improvement: Double {               // 자동 계산
        afterValue - beforeValue
    }
}

// MARK: - Program Story
/// Program story (Instagram story format)
/// Stored in Firestore at users/{accountId}/goals/{goalId}/program_progress/{programId}/stories/{storyId}
struct ProgramStory: Identifiable, Codable {
    let id: UUID
    var programId: UUID
    var title: String
    var subtitle: String?
    var pages: [ProgramStoryPage]
    var colorTheme: ColorThemeForGoal?  // Add color theme for background
    var gradientColors: [ColorThemeForGoal]?  // Add gradient colors for richer background
    var isViewed: Bool = false
    var isLiked: Bool = false
    var viewedAt: Date?
    var createdAt: Date
    var isGenerated: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, programId, title, subtitle, pages, colorTheme, gradientColors, isViewed, isLiked, viewedAt, createdAt, isGenerated
    }
    
    var programIdString: String {
        programId.uuidString
    }
    
    // Default initializer
    init(id: UUID, programId: UUID, title: String, subtitle: String?, pages: [ProgramStoryPage], colorTheme: ColorThemeForGoal? = nil, gradientColors: [ColorThemeForGoal]? = nil, isViewed: Bool = false, isLiked: Bool = false, viewedAt: Date? = nil, createdAt: Date, isGenerated: Bool = false) {
        self.id = id
        self.programId = programId
        self.title = title
        self.subtitle = subtitle
        self.pages = pages
        self.colorTheme = colorTheme
        self.gradientColors = gradientColors
        self.isViewed = isViewed
        self.isLiked = isLiked
        self.viewedAt = viewedAt
        self.createdAt = createdAt
        self.isGenerated = isGenerated
    }
    
    // Custom decoder for ISO 8601 date strings
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        programId = try container.decode(UUID.self, forKey: .programId)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        pages = try container.decode([ProgramStoryPage].self, forKey: .pages)
        colorTheme = try container.decodeIfPresent(ColorThemeForGoal.self, forKey: .colorTheme)
        gradientColors = try container.decodeIfPresent([ColorThemeForGoal].self, forKey: .gradientColors)
        isViewed = try container.decodeIfPresent(Bool.self, forKey: .isViewed) ?? false
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        viewedAt = try container.decodeIfPresent(Date.self, forKey: .viewedAt)
        isGenerated = try container.decodeIfPresent(Bool.self, forKey: .isGenerated) ?? false
        
        // Handle createdAt as ISO 8601 string
        let dateString = try container.decode(String.self, forKey: .createdAt)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            createdAt = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match expected format")
        }
    }
}

// MARK: - Story Page
/// 스토리 페이지
struct ProgramStoryPage: Identifiable, Codable {
    var id: UUID = UUID()
    var pageNumber: Int
    var contentType: ProgramStoryPageContentType
    var content: ProgramStoryPageContent
    var visualizations: [ProgramStoryVisualization]?
}

enum ProgramStoryPageContentType: String, Codable {
    case text           // 텍스트
    case image          // 이미지
    case tip            // 팁/조언
    case milestone      // 마일스톤
    case motivation     // 동기부여
    case mixed          // 혼합
}

struct ProgramStoryPageContent: Codable {
    var headline: String?
    var body: String?
    var imageName: String?
    var mantra: String?                    // 동기 부여 문구
}

struct ProgramStoryVisualization: Codable {
    var type: ProgramStoryVisualizationType
    var data: [String: String]?            // 그래프 데이터 등
}

enum ProgramStoryVisualizationType: String, Codable {
    case progress      // 진행률
    case metric        // 메트릭
    case comparison    // 비교
    case chart         // 차트
}
// MARK: - Goal Recommendation Input
/// 목표 추천 알고리즘 입력
/// Firestore에 저장하지 않고, 쿼리로 생성
struct GoalRecommendationInput: Codable {
    var accountId: String
    var anonymousUserId: UUID
    var timeSeriesWindow: TimeSeriesWindowForGoal?
    var currentGoals: [String]             // 현재 활성 목표 ID들
    var userPreferences: UserPreferencesForGoal
    var mlFeatures: [String: Double]       // ML 모델 특징값
}

// MARK: - Program Enrollment
/// 프로그램 등록 (사용자가 선택한 프로그램)
/// Firestore의 users/{accountId}/program_enrollments/{enrollmentId}에 저장
struct ProgramEnrollment: Identifiable, Codable {
    let id: UUID
    var accountId: String              // Firebase Auth UID
    var anonymousUserId: UUID?         // Anonymous User ID (나중에 설정)
    var programId: UUID
    var status: ProgramEnrollmentStatus
    var startDate: Date
    var targetCompletionDate: Date?
    var actualCompletionDate: Date?
    var initialMetrics: [String: Double]?  // 프로그램 시작 시 초기값
    var successProgress: Double        // 0.0 ~ 1.0 (진행률)
    var successRate: Double?           // 0.0 ~ 1.0 (완료 후 계산)
    var createdAt: Date
    var updatedAt: Date
    
    var enrollmentIdString: String {
        id.uuidString
    }
    
    var programIdString: String {
        programId.uuidString
    }
}

enum ProgramEnrollmentStatus: String, Codable {
    case active       // 진행 중
    case completed    // 완료
    case paused       // 일시 정지
    case abandoned    // 포기
}

//
//  StatusModels.swift
//  PIP_Project
//
//  Status & Achievement Models
//

import Foundation

// MARK: - User Stats
/// 사용자 통계
/// Firestore의 users/{accountId}/stats에 저장
struct UserStats: Codable {
    var accountId: String          // Firebase Auth UID (String, not UUID)
    var totalDataPoints: Int       // 총 데이터 포인트 수 (기록 수)
    var totalDaysActive: Int
    var currentStreak: Int         // 현재 연속 기록 일수
    var longestStreak: Int         // 최장 연속 기록 일수
    var totalGoalsCompleted: Int
    var totalProgramsCompleted: Int
    var averageEmotionScore: Double
    var totalGemsCreated: Int
    var lastUpdated: Date
}

// MARK: - Badge
/// 뱃지
/// Firestore의 users/{accountId}/badges/{badgeId}에 저장
struct Badge: Identifiable, Codable {
    let id: UUID
    var accountId: String          // Firebase Auth UID (String, not UUID)
    var name: String
    var description: String
    var iconName: String           // 아이콘 이름
    var category: BadgeCategory
    var rarity: BadgeRarity
    var unlockedDate: Date?
    var isUnlocked: Bool
    var progress: Double           // 0.0 ~ 1.0 (뱃지 달성 진행률)
    var requirement: BadgeRequirement
    var createdAt: Date

    var badgeIdString: String {
        id.uuidString
    }
}

enum BadgeCategory: String, Codable {
    case consistency   // 일관성
    case achievement   // 성취
    case milestone     // 마일스톤
    case special       // 특별
}

enum BadgeRarity: String, Codable {
    case common
    case rare
    case epic
    case legendary
}

struct BadgeRequirement: Codable {
    var type: RequirementType
    var targetValue: Int
    var currentValue: Int
}

enum RequirementType: String, Codable {
    case totalDataPoints   // 총 데이터 포인트 수 (기록 수)
    case streakDays        // 연속 기록 일수
    case goalsCompleted    // 완료한 목표 수
    case programsCompleted // 완료한 프로그램 수
    case custom            // 커스텀
}

// MARK: - Achievement
/// 성취 (달성한 프로그램의 3D 일러스트)
/// Firestore의 users/{accountId}/achievements/{achievementId}에 저장
struct Achievement: Identifiable, Codable {
    let id: UUID
    var accountId: String
    var programId: UUID?           // 달성한 프로그램 ID
    var title: String
    var description: String
    var category: AchievementCategory
    var unlockedDate: Date?
    var isUnlocked: Bool
    
    // 3D 일러스트 정보
    var illustration3D: AchievementIllustration3D?
    
    // 달성 패턴에 따른 색상
    var colorScheme: [String]       // Hex 색상 배열 (뱃지 전시용)
    
    var iconName: String?
    var createdAt: Date
}

struct AchievementIllustration3D: Codable {
    var modelId: String            // 3D 모델 ID
    var modelURL: String?          // 3D 모델 URL
    var previewImageURL: String?   // 프리뷰 이미지 URL
    var colorScheme: [String]      // 색상 스키마 (Hex 배열)
}

enum AchievementCategory: String, Codable {
    case consistency
    case growth
    case exploration
    case mastery
}

// MARK: - Value Analysis
/// 가치관 분석
/// Firestore의 users/{accountId}/value_analysis/{analysisId}에 저장
struct ValueAnalysis: Identifiable, Codable {
    let id: UUID
    var accountId: String
    var analysisDate: Date
    var topValues: [ValueItem]
    var valueDistribution: [String: Double]  // ValueCategory.rawValue를 키로 사용
    var comparisonData: ComparisonData?
    var insights: [String]
    var createdAt: Date
}

struct ValueItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var score: Double              // 0.0 ~ 1.0
    var description: String?
    var trend: TrendDirection
}

enum ValueCategory: String, Codable {
    case health
    case relationships
    case career
    case personalGrowth
    case leisure
    case spirituality
}

struct ComparisonData: Codable {
    var userPercentile: Double    // 0.0 ~ 100.0 (사용자 백분위)
    var averageScore: Double      // 전체 평균 점수
    var uniqueAspects: [String]   // 사용자만의 고유한 특성
}

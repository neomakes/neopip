//
//  UserProfileModels.swift
//  PIP_Project
//
//  User Profile & Settings Models
//

import Foundation

// MARK: - User Profile
/// 사용자 프로필 (PII 포함)
/// Firestore의 users/{accountId}/profile에 저장
struct UserProfile: Codable {
    var accountId: String              // Firebase Auth UID (String, not UUID)
    var displayName: String?
    var email: String?

    // 프로필 이미지
    var profileImageURL: String?    // 프로필 사진 URL
    var backgroundImageURL: String? // 배경 이미지 URL

    var createdAt: Date
    var lastActiveAt: Date
    var preferences: UserPreferences
    var onboardingState: OnboardingState?
    var initialGoals: [GoalCategory]
    var goals: [String]? // Merged goals from 'goals' table (simple string array for MVP)
    var firstJournalDate: Date?
    
    // Data Collection Settings (Flattened from UserDataCollectionSettings)
    var enabledDataTypes: [String]
    var anonymizationLevel: AnonymizationLevel
    var permissions: DataPermissions?
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var theme: AppTheme
    var notificationsEnabled: Bool
    var language: String
    var timeZone: String
}

enum AppTheme: String, Codable {
    case dark
    case light
    case system
}

// MARK: - Anonymous User Profile
/// 익명화된 사용자 프로필 (분석용)
/// Firestore의 anonymous_users/{anonymousUserId}/profile에 저장
struct AnonymousUserProfile: Codable {
    var anonymousUserId: UUID
    var currentPIPScore: PIPScore?
    var dataCompleteness: Double
    var insights: [String]              // Insight ID 배열
    var lastUpdatedAt: Date
    
    var anonymousUserIdString: String {
        anonymousUserId.uuidString
    }
}

// MARK: - Onboarding State
struct OnboardingState: Codable {
    var isCompleted: Bool
    var completedSteps: [String]        // OnboardingStep.rawValue 배열
    var selectedGoals: [String]          // GoalCategory.rawValue 배열
    var completedAt: Date?
    var skippedSteps: [String]
    // consentedDataTypes removed -> moved to UserProfile.enabledDataTypes
}

enum OnboardingStep: String, Codable {
    case welcome
    case goalSelection
    case programSelection      // 프로그램 선택
    case dataConsent           // 민감 정보 동의
    case dataCollectionIntro
    case insightPreview
    case onboardingComplete
}

// UserDataCollectionSettings & DataTypeSettings removed (Simplified Schema)

enum CollectionFrequency: String, Codable {
    case realTime    // 실시간
    case hourly      // 시간별
    case daily       // 일별
    case manual      // 수동
}

enum AnonymizationLevel: String, Codable {
    case none              // 익명화 없음 (로컬만)
    case pseudonymized    // 가명화 (익명 ID 사용)
    case fullyAnonymized  // 완전 익명화 (집계 데이터만)
}

// MARK: - Data Permissions
struct DataPermissions: Codable {
    var screenTime: PermissionStatus
    var healthKit: PermissionStatus
    var location: PermissionStatus
    var notifications: PermissionStatus
    var camera: PermissionStatus
    var microphone: PermissionStatus
    
    var grantedAt: Date?
    var lastCheckedAt: Date?
}

enum PermissionStatus: String, Codable {
    case notRequested
    case denied
    case granted
    case restricted
}

// MARK: - PIP Score
/// 종합 점수
struct PIPScore: Codable {
    var overall: Double            // 0.0 ~ 1.0 (종합 점수)
    var mind: Double               // 0.0 ~ 1.0 (마음 점수)
    var behavior: Double           // 0.0 ~ 1.0 (행동 점수)
    var physical: Double           // 0.0 ~ 1.0 (신체 점수)
    var calculatedAt: Date
    var confidence: Double         // 0.0 ~ 1.0 (계산 신뢰도)
    var dataCompleteness: Double  // 0.0 ~ 1.0 (데이터 완성도)
    
    // 상세 점수 (0~100)
    var mindDetails: MindScoreDetails?
    var behaviorDetails: BehaviorScoreDetails?
    var physicalDetails: PhysicalScoreDetails?
}

struct MindScoreDetails: Codable {
    var mood: Double?              // 0.0 ~ 1.0
    var stress: Double?            // 0.0 ~ 1.0 (역산)
    var energy: Double?            // 0.0 ~ 1.0
    var focus: Double?             // 0.0 ~ 1.0
}

struct BehaviorScoreDetails: Codable {
    var productivity: Double?      // 0.0 ~ 1.0
    var socialActivity: Double?    // 0.0 ~ 1.0
    var digitalDistraction: Double? // 0.0 ~ 1.0 (역산)
    var exploration: Double?       // 0.0 ~ 1.0
}

struct PhysicalScoreDetails: Codable {
    var sleepScore: Double?        // 0.0 ~ 1.0
    var fatigue: Double?           // 0.0 ~ 1.0 (역산)
    var activityLevel: Double?     // 0.0 ~ 1.0
    var nutrition: Double?         // 0.0 ~ 1.0
}

// MARK: - Goal Category
enum GoalCategory: String, Codable {
    case wellness      // 웰니스
    case productivity  // 생산성
    case emotional     // 감정 관리
    case physical      // 신체 건강
    case social        // 사회적 관계
    case learning      // 학습
    case custom        // 커스텀
}

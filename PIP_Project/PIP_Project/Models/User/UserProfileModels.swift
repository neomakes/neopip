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
    var accountId: UUID
    var displayName: String?
    var email: String?
    var createdAt: Date
    var lastActiveAt: Date
    var preferences: UserPreferences
    var onboardingState: OnboardingState?
    var initialGoals: [GoalCategory]
    var firstJournalDate: Date?
    
    var accountIdString: String {
        accountId.uuidString
    }
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
}

enum OnboardingStep: String, Codable {
    case welcome
    case goalSelection
    case dataCollectionIntro
    case insightPreview
    case onboardingComplete
}

// MARK: - Data Collection Settings
/// 사용자 데이터 수집 설정
/// Firestore의 users/{accountId}/settings/dataCollection에 저장
struct UserDataCollectionSettings: Codable {
    var accountId: UUID
    
    // 활성화된 데이터 타입 (스키마 ID 배열)
    var enabledDataTypes: [String]      // UUID를 String으로 변환
    var typeSettings: [String: DataTypeSettings]  // UUID를 String 키로 사용
    
    // 권한 설정
    var permissions: DataPermissions
    
    // 수집 주기
    var collectionFrequency: CollectionFrequency
    
    // 익명화 옵션
    var anonymizationLevel: AnonymizationLevel
    var allowMLTraining: Bool           // ML 학습 허용 여부
    var allowDataSharing: Bool         // 익명화된 데이터 공유 허용 여부
    
    // 데이터 보관 기간
    var dataRetentionDays: Int?        // nil이면 무기한
    var autoDeleteAfterDays: Int?       // 자동 삭제 기간
    
    var updatedAt: Date
    
    var accountIdString: String {
        accountId.uuidString
    }
}

struct DataTypeSettings: Codable {
    var schemaId: UUID
    var isEnabled: Bool
    var collectionMethod: CollectionMethod
    var sensitivityOverride: SensitivityLevel?  // 사용자가 설정한 민감도
    var customRange: ValueRange?                // 사용자 정의 범위
    var notes: String?
    
    var schemaIdString: String {
        schemaId.uuidString
    }
}

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

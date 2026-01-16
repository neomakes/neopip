//
//  TimeSeriesModels.swift
//  PIP_Project
//
//  Time Series Data Models: 고차원 시계열 데이터 구조
//  Human World Model (Active Inference Agent) Schema
//

import Foundation

// MARK: - Enums & Nested Structures (Human World Model)

// 1. World Context (w)
// 1. World Context (w)
struct WorldContext: Codable {
    let weather: WeatherCondition
    let location: LocationCategory
    
    // Time Context (Merged)
    let dayPhase: DayPhase
    let weekday: Int // 1=Sunday, 2=Monday, ...
    let isHoliday: Bool
    let timeZoneIdentifier: String
}

enum WeatherCondition: String, Codable {
    case clear
    case cloud
    case rain
    case snow
    case atmosphere // fog, mist, etc.
    case unknown
}

enum LocationCategory: String, Codable {
    case home
    case work
    case thirdPlace // cafe, library
    case transit
    case outdoors
    case unknown
}

enum DayPhase: String, Codable {
    case deepNight // 00-05
    case morning   // 05-12
    case afternoon // 12-18
    case night     // 18-24
}

// 2. Action / Intervention (a)
// Using 'Identifiable' to support Lists in UI
struct Intervention: Codable, Identifiable {
    var id: UUID = UUID()
    var type: ActivityType
    var customLabel: String? = nil // For "Other" type or custom overrides
    var customMindsetLabel: String? = nil // For "Other" mindset
    var amount: Double // Intensity (0-100) or specific metric
    var mindset: Mindset
    
    // CodingKeys to exclude 'id' if we don't want to persist it, or keep it.
    // Usually convenient to keep it.
}

enum ActivityType: String, Codable, CaseIterable {
    case work
    case exercise
    case rest
    case sleep
    case social
    case hobby
    case chore
    case transit
    case eat
    case other
}

enum Mindset: String, Codable, CaseIterable {
    case flow       // 몰입
    case duty       // 의무/억지
    case challenge  // 도전
    case relax      // 이완/휴식
    case passive    // 수동적/멍때림
    case anxiety    // 불안/초조
    case other      // 기타
}

// 3. Internal State (s)
struct InternalState: Codable {
    let mood: Double   // Valence: -100 (Negative) ~ 100 (Positive) (Average)
    let energy: Double // Arousal: 0 (Low) ~ 100 (High) (Average)
    
    // Richer Data (7-point curve)
    // Optional for backward compatibility, but ideally required for new format
    let moodValues: [Double]?
    let energyValues: [Double]?
    
    // Persisted Curve Control Times (Hours, e.g. [7.0, 9.5, ...])
    // Shared for both mood and energy ideally, but stored here to persist configuration
    let curveControlHours: [Double]?
}

// 4. Outcome (o)
struct Outcome: Codable {
    let focusLevel: Double    // 0 ~ 100
    let detectedMotion: MotionType?
}

enum MotionType: String, Codable, CaseIterable {
    case stationary
    case walking
    case running
    case automotive
    case cycling
    case unknown
}

// 5. Optimality (O)
struct Optimality: Codable {
    let fulfillment: Double // 1.0 ~ 5.0 (Float precision)
}

// MARK: - Time Series Data Point
/// Human World Model 기반의 시계열 데이터 포인트
/// Firestore의 anonymous_users/{anonymousUserId}/data_points/{dataPointId}에 저장
struct TimeSeriesDataPoint: Identifiable, Codable {
    let id: UUID
    var anonymousUserId: UUID
    
    // 시계열 메타데이터
    var timestamp: Date
    var date: Date // 날짜 (일자 기준)
    
    // Causal Structure
    var world: WorldContext
    var actions: [Intervention]
    var state: InternalState
    var outcome: Outcome
    var optimality: Optimality
    
    // Meta & Utils
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    var anonymousUserIdString: String {
        anonymousUserId.uuidString
    }
    
    var dataPointIdString: String {
        id.uuidString
    }
    
    // Convenience Initializer
    init(
        id: UUID = UUID(),
        anonymousUserId: UUID? = nil,
        timestamp: Date = Date(),
        world: WorldContext,
        actions: [Intervention],
        state: InternalState,
        outcome: Outcome,
        optimality: Optimality,
        notes: String? = nil
    ) {
        let now = Date()
        self.id = id
        self.anonymousUserId = anonymousUserId ?? UUID()
        self.timestamp = timestamp
        self.date = Calendar.current.startOfDay(for: timestamp)
        
        self.world = world
        self.actions = actions
        self.state = state
        self.outcome = outcome
        self.optimality = optimality
        
        self.notes = notes
        self.createdAt = now
        self.updatedAt = now
    }
}

// MARK: - ML Feature Vector
/// ML 모델 입력으로 사용되는 특징 벡터
/// Firestore의 anonymous_users/{anonymousUserId}/ml_features/{featureId}에 저장
struct MLFeatureVector: Codable {
    var id: UUID
    var anonymousUserId: UUID
    var timestamp: Date
    var features: [String: Double]    // 특징값 딕셔너리
    var labels: [String: Double]?     // 레이블 (지도 학습용)
    var metadata: [String: String]?   // 메타데이터
    var createdAt: Date
    
    var anonymousUserIdString: String {
        anonymousUserId.uuidString
    }
}

// MARK: - Time Series Window
/// 시계열 윈도우 (예: 최근 7일 데이터)
/// Firestore에 직접 저장하지 않고, 쿼리로 생성
struct TimeSeriesWindow: Codable {
    var startDate: Date
    var endDate: Date
    var dataPoints: [TimeSeriesDataPoint]
    var aggregatedFeatures: [String: Double]  // 집계된 특징값
    var trendFeatures: [String: Double]       // 트렌드 특징값
    var seasonalityFeatures: [String: Double]? // 계절성 특징값
}

// MARK: - ML Model Output
/// ML 모델 출력 (Orb, Insight, Goal 추천에 사용)
/// Firestore의 anonymous_users/{anonymousUserId}/ml_outputs/{outputId}에 저장
struct MLModelOutput: Codable {
    var id: UUID
    var anonymousUserId: UUID
    var modelId: String
    var timestamp: Date
    var predictions: [String: Double]        // 예측값
    var probabilities: [String: Double]?     // 확률값
    var confidence: Double                    // 0.0 ~ 1.0
    var uncertainty: Double                   // 0.0 ~ 1.0
    var features: [String: Double]            // 사용된 특징값
    var explanation: String?                 // 설명 (XAI)
    var createdAt: Date
    
    var anonymousUserIdString: String {
        anonymousUserId.uuidString
    }
}

// MARK: - ML Training Dataset
/// ML 학습용 데이터셋 (익명화된 ID만 사용)
/// Firestore의 ml_datasets/{datasetId}에 저장
struct MLTrainingDataset: Codable {
    var id: UUID
    var anonymousUserIds: [String]            // ✅ 익명화된 ID만 (String 배열)
    var dataPointIds: [String]                // 사용된 데이터 포인트 ID들
    var features: [String: [Double]]          // 특징값 배열
    var labels: [String: [Double]]?          // 레이블 (지도 학습)
    var anonymizationMethod: String
    var createdAt: Date
    var trainingDate: Date?
}

// MARK: - ML Model Metadata
/// ML 모델 메타데이터
/// Firestore의 ml_models/{modelId}에 저장
struct MLModelMetadata: Codable {
    var modelId: String
    var modelName: String
    var version: String
    var trainingDatasetId: UUID
    var anonymousUserCount: Int              // 학습에 사용된 익명 사용자 수
    var trainingDate: Date
    var performanceMetrics: [String: Double]
    var features: [String]
    var createdAt: Date
    var updatedAt: Date
    
    var trainingDatasetIdString: String {
        trainingDatasetId.uuidString
    }
}

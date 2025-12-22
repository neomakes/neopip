//
//  TimeSeriesModels.swift
//  PIP_Project
//
//  Time Series Data Models: 고차원 시계열 데이터 구조
//  ML/AI 모델 입력으로 사용
//

import Foundation

// MARK: - Time Series Data Point
/// 시계열 데이터 포인트 (익명화된 ID 사용)
/// Firestore의 anonymous_users/{anonymousUserId}/data_points/{dataPointId}에 저장
struct TimeSeriesDataPoint: Identifiable, Codable {
    let id: UUID
    var anonymousUserId: UUID         // ✅ 익명화된 ID만 사용
    
    // 시계열 메타데이터
    var timestamp: Date               // 정확한 시각
    var date: Date                    // 날짜 (일자 기준)
    var timeOfDay: TimeOfDay?
    var dayOfWeek: Int?               // 1=일요일, 7=토요일
    var weekOfYear: Int?
    var month: Int?
    
    // 데이터 값 (동적 구조)
    var values: [String: DataValue]   // "mood": 75, "sleep_score": 80 등
    
    // 데이터 소스 및 품질
    var source: DataSource
    var confidence: Double            // 0.0 ~ 1.0 (데이터 신뢰도)
    var completeness: Double          // 0.0 ~ 1.0 (해당 시점의 데이터 완성도)
    
    // 메타데이터 (PII 제거된)
    var notes: String?                // 사용자 메모 (PII 제거 로직 적용)
    var tags: [String]                // 일반 태그만
    var context: [String: String]?    // PII 없는 컨텍스트
    var category: DataCategory?       // 데이터 카테고리 (메모 분류용)
    
    // ML/AI 관련
    var features: [String: Double]?   // ML 모델용 추출된 특징값
    var predictions: [String: Double]? // 예측값
    var anomalies: [String]?          // 이상 징후
    
    var createdAt: Date
    var updatedAt: Date
    
    var anonymousUserIdString: String {
        anonymousUserId.uuidString
    }
    
    var dataPointIdString: String {
        id.uuidString
    }
    
    // MARK: - Convenience Initializer
    init(
        timestamp: Date,
        category: DataCategory? = nil,
        values: [String: DataValue] = [:],
        source: DataSource = .manual,
        confidence: Double = 1.0,
        completeness: Double = 1.0,
        anonymousUserId: UUID? = nil,
        notes: String? = nil,
        tags: [String] = [],
        context: [String: String]? = nil
    ) {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekday, .weekOfYear, .month], from: timestamp)
        
        self.id = UUID()
        self.anonymousUserId = anonymousUserId ?? UUID()
        self.timestamp = timestamp
        self.date = calendar.startOfDay(for: timestamp)
        self.timeOfDay = Self.calculateTimeOfDay(timestamp)
        self.dayOfWeek = components.weekday
        self.weekOfYear = components.weekOfYear
        self.month = components.month
        self.values = values
        self.source = source
        self.confidence = confidence
        self.completeness = completeness
        self.notes = notes
        self.tags = tags
        self.context = context
        self.category = category
        self.features = nil
        self.predictions = nil
        self.anomalies = nil
        self.createdAt = now
        self.updatedAt = now
    }
    
    private static func calculateTimeOfDay(_ date: Date) -> TimeOfDay? {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        switch hour {
        case 6..<12: return .morning
        case 12..<18: return .afternoon
        case 18..<22: return .evening
        case 22...23, 0..<6: return .night
        default: return nil
        }
    }
}

enum TimeOfDay: String, Codable {
    case morning    // 오전 (6-12)
    case afternoon  // 오후 (12-18)
    case evening    // 저녁 (18-22)
    case night      // 밤 (22-6)
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

//
//  InsightModels.swift
//  PIP_Project
//
//  Insight & Visualization Models
//

import Foundation

// MARK: - Insight
/// 인사이트 (익명화된 ID 사용)
/// Firestore의 anonymous_users/{anonymousUserId}/insights/{insightId}에 저장
struct Insight: Identifiable, Codable {
    let id: UUID
    var anonymousUserId: UUID
    var type: InsightType
    var title: String
    var description: String
    var confidence: Double                // 0.0 ~ 1.0
    var dataCompleteness: Double         // 사용된 데이터의 완성도
    
    // 기반 데이터
    var basedOnDataPoints: [String]        // 사용된 TimeSeriesDataPoint ID들 (String 배열)
    var basedOnTimeRange: DateInterval?    // 분석 기간
    var mlModelOutputId: UUID?            // 사용된 ML 모델 출력 ID
    
    // 인사이트 내용
    var findings: [InsightFinding]
    var recommendations: [String]
    var visualizations: [String]          // 시각화 타입들
    
    var createdAt: Date
    
    var anonymousUserIdString: String {
        anonymousUserId.uuidString
    }
    
    var insightIdString: String {
        id.uuidString
    }
}

enum InsightType: String, Codable {
    case trend          // 트렌드 분석
    case pattern         // 패턴 발견
    case correlation     // 상관관계
    case prediction      // 예측
    case anomaly         // 이상 징후
    case recommendation  // 추천
}

struct InsightFinding: Codable {
    var metric: String                   // "mood", "sleep_score" 등
    var value: Double
    var trend: TrendDirection
    var significance: Double             // 0.0 ~ 1.0 (중요도)
    var explanation: String
}

enum TrendDirection: String, Codable {
    case increasing  // 증가
    case decreasing  // 감소
    case stable      // 유지
}

// MARK: - Insight Generation Criteria
/// 인사이트 생성 조건
struct InsightGenerationCriteria: Codable {
    var minimumDataPoints: Int           // 최소 데이터 포인트 수
    var minimumTimeSpan: TimeInterval    // 최소 시간 범위 (초)
    var minimumCompleteness: Double      // 최소 완성도 (0.0 ~ 1.0)
    var requiredDataTypes: [String]     // 필수 데이터 타입 ID들 (String 배열)
    var minimumConfidence: Double        // 최소 신뢰도 (0.0 ~ 1.0)
}

// MARK: - Orb Visualization
/// Orb 시각화 데이터 (ML 출력 기반)
/// Firestore의 anonymous_users/{anonymousUserId}/orbs/{orbId}에 저장
struct OrbVisualization: Identifiable, Codable {
    let id: UUID
    var anonymousUserId: UUID
    var date: Date
    
    // ML 모델에서 계산된 값
    var brightness: Double              // 데이터 완성도 (0.0 ~ 1.0)
    var complexity: Int                  // 기하학적 복잡도 (1 ~ 10)
    var uncertainty: Double              // AI 모델 불확실성 (0.0 ~ 1.0)
    
    // 시계열 특징값에서 추출
    var timeSeriesFeatures: [String: Double]  // 주기성, 트렌드 등
    var categoryWeights: [String: Double]     // 카테고리별 가중치 (DataCategory.rawValue를 키로)
    
    // 시각화 파라미터
    var gemType: GemType
    var colorTheme: ColorTheme
    var size: Double
    var colorGradient: [String]
    
    // 연결된 데이터
    var dataPointIds: [String]             // 관련 TimeSeriesDataPoint ID들
    var mlModelOutputId: UUID?            // ML 모델 출력 ID
    
    var createdAt: Date
    
    var anonymousUserIdString: String {
        anonymousUserId.uuidString
    }
}

enum GemType: String, Codable {
    case sphere      // 구체
    case diamond     // 다이아몬드
    case crystal     // 수정
    case prism       // 프리즘
    case custom      // 커스텀 형태
}

enum ColorTheme: String, Codable {
    case teal        // 기본 Teal
    case amber       // Amber Flame
    case tiger       // Tiger Flame
    case blue        // French Blue
}

// MARK: - Trend Data
/// 트렌드 데이터
/// Firestore의 anonymous_users/{anonymousUserId}/trends/{trendId}에 저장
struct TrendData: Identifiable, Codable {
    let id: UUID
    var anonymousUserId: UUID
    var period: TimePeriod
    var startDate: Date
    var endDate: Date
    var mindScore: Double          // 0.0 ~ 1.0 (마음 점수)
    var behaviorScore: Double      // 0.0 ~ 1.0 (행동 점수)
    var physicalScore: Double     // 0.0 ~ 1.0 (신체 점수)
    var overallScore: Double      // 0.0 ~ 1.0 (종합 점수)
    var dataCompleteness: Double   // 0.0 ~ 1.0 (데이터 완성도)
    var trendDirection: TrendDirection
    var createdAt: Date
    
    var anonymousUserIdString: String {
        anonymousUserId.uuidString
    }
}

enum TimePeriod: String, Codable {
    case daily    // 일간
    case weekly   // 주간
    case monthly  // 월간
}

// MARK: - Prediction Data
/// 예측 데이터
/// Firestore의 anonymous_users/{anonymousUserId}/predictions/{predictionId}에 저장
struct PredictionData: Identifiable, Codable {
    let id: UUID
    var anonymousUserId: UUID
    var targetDate: Date           // 예측 대상 날짜
    var predictedMindScore: Double  // 0.0 ~ 1.0
    var predictedBehaviorScore: Double
    var predictedPhysicalScore: Double
    var confidence: Double         // 0.0 ~ 1.0 (예측 신뢰도)
    var uncertainty: Double        // 0.0 ~ 1.0 (불확실성)
    var trendContext: String?      // 트렌드 맥락 설명
    var createdAt: Date
    
    var anonymousUserIdString: String {
        anonymousUserId.uuidString
    }
}

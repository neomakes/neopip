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
/// 
/// Orb의 의미:
/// - brightness: 사용자 모델의 재생성 성능 (0.0 ~ 1.0)
///   - 밝을수록 기존 시계열 정보의 재구성 성능이 높음
///   - 어두우면 사용자 모델의 성능이 좋지 않음을 나타냄
/// - borderBrightness: 오늘 예측의 정확도 (0.0 ~ 1.0)
///   - 밝을수록 예측이 정확함
///   - 어두울수록 예측이 부정확할 수 있음을 나타냄
/// - uniqueFeatures: 다른 사용자들과 구분되는 고유 Feature
///   - 내부 색상과 형태를 결정
struct OrbVisualization: Identifiable, Codable {
    let id: UUID
    var anonymousUserId: UUID
    var date: Date
    
    // ML 모델에서 계산된 값
    var brightness: Double              // 사용자 모델의 재생성 성능 (0.0 ~ 1.0)
    var borderBrightness: Double        // 오늘 예측의 정확도 (0.0 ~ 1.0)
    var complexity: Int                  // 기하학적 복잡도 (1 ~ 10)
    var uncertainty: Double              // AI 모델 불확실성 (0.0 ~ 1.0)
    
    // 고유 Feature (다른 사용자들과 구분)
    var uniqueFeatures: [String: Double]  // 고유 특징값 (색상과 형태 결정)
    
    // 시계열 특징값에서 추출
    var timeSeriesFeatures: [String: Double]  // 주기성, 트렌드 등
    var categoryWeights: [String: Double]     // 카테고리별 가중치 (DataCategory.rawValue를 키로)
    
    // 시각화 파라미터
    var gemType: GemType
    var colorTheme: ColorTheme
    var size: Double
    var colorGradient: [String]          // 고유 Feature 기반 색상 그라데이션
    
    // 연결된 데이터
    var dataPointIds: [String]             // 관련 TimeSeriesDataPoint ID들
    var mlModelOutputId: UUID?            // ML 모델 출력 ID
    
    var createdAt: Date
    
    var anonymousUserIdString: String {
        anonymousUserId.uuidString
    }
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

// MARK: - Insight Analysis Card
/// Insight analysis card (card news format)
/// Stored in Firestore at anonymous_users/{anonymousUserId}/insights/{insightId}/analysis_cards/{cardId}
/// Composed of multiple pages like Instagram stories
struct InsightAnalysisCard: Identifiable, Codable {
    let id: UUID
    var insightId: UUID
    var anonymousUserId: UUID
    
    // 카드 내용
    var title: String
    var subtitle: String?
    var cardType: AnalysisCardType
    
    // Multiple pages (Instagram story format)
    var pages: [AnalysisCardPage]
    
    // 행동 제안
    var actionProposals: [ActionProposal]
    
    // 사용자 반응
    var isLiked: Bool              // 하트 버튼 클릭 여부
    var likedAt: Date?
    var acceptedActions: [String]  // 수락한 ActionProposal ID 배열
    
    var createdAt: Date
    
    var insightIdString: String {
        insightId.uuidString
    }
    
    var anonymousUserIdString: String {
        anonymousUserId.uuidString
    }
}

enum AnalysisCardType: String, Codable {
    case explanation   // 설명
    case prediction    // 예측
    case control       // 제어 (행동 제안)
    case correlation   // 상관관계
}

struct AnalysisCardPage: Identifiable, Codable {
    let id: UUID
    var pageNumber: Int
    var contentType: PageContentType
    var content: PageContent
    var visualizations: [PageVisualization]?  // 그래프, 수치 등
}

enum PageContentType: String, Codable {
    case text         // 텍스트
    case graph        // 그래프
    case mantra       // 만트라
    case statistics   // 수치
    case mixed        // 혼합
}

struct PageContent: Codable {
    var text: String?
    var headline: String?
    var body: String?
    var mantra: String?           // 행동 제안 만트라
}

struct PageVisualization: Codable {
    var type: VisualizationType
    var data: [String: AnyCodable]?  // 그래프 데이터
    var chartType: ChartType?
}

enum VisualizationType: String, Codable {
    case lineChart
    case barChart
    case radarChart
    case pieChart
    case number
    case gauge
}

enum ChartType: String, Codable {
    case line
    case bar
    case radar
    case pie
}

struct ActionProposal: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var actionType: ActionType
    var targetDate: Date?
    var calendarEvent: CalendarEvent?
    var alarm: AlarmEvent?
    var isAccepted: Bool
    var acceptedAt: Date?
}

enum ActionType: String, Codable {
    case calendar      // 캘린더 추가
    case alarm         // 알람 설정
    case reminder      // 리마인더
    case habit         // 습관 추가
}

struct CalendarEvent: Codable {
    var title: String
    var description: String?
    var startDate: Date
    var endDate: Date?
    var location: String?
    var notes: String?
}

struct AlarmEvent: Codable {
    var title: String
    var time: Date
    var repeatDays: [Int]?  // 1=일요일, 7=토요일
    var sound: String?
}

// AnyCodable for Firestore compatibility
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}

//
//  DataModels.swift
//  PIP_Project
//
//  Data Models: TimeSeriesDataPoint, DailyGem, DailyStats
//  JournalEntry는 제거되고 TimeSeriesDataPoint.notes로 통합됨
//

import Foundation

// MARK: - Daily Gem
/// 일일 Gem 데이터 (시각화용)
/// Firestore의 users/{accountId}/daily_gems/{gemId}에 저장
struct DailyGem: Identifiable, Codable {
    let id: UUID
    var accountId: UUID
    var date: Date
    var gemType: GemType           // Gem의 기하학적 형태
    var brightness: Double         // 0.0 ~ 1.0 (데이터 완성도)
    var uncertainty: Double        // 0.0 ~ 1.0 (AI 모델 불확실성)
    var dataPointIds: [String]     // 해당 날짜의 TimeSeriesDataPoint ID 배열
    var colorTheme: ColorTheme      // Gem의 색상 테마
    var createdAt: Date
    
    var accountIdString: String {
        accountId.uuidString
    }
    
    var gemIdString: String {
        id.uuidString
    }
}

// MARK: - Daily Stats
/// 일일 통계
/// Firestore의 users/{accountId}/daily_stats/{date}에 저장
struct DailyStats: Codable {
    var accountId: UUID
    var date: Date
    var totalDataPoints: Int        // 해당 날짜의 총 데이터 포인트 수
    var notesCount: Int             // 메모가 있는 데이터 포인트 수
    
    // 마음/행동/신체 점수
    var mindScore: Double?          // 0.0 ~ 1.0 (마음 평균 점수)
    var behaviorScore: Double?     // 0.0 ~ 1.0 (행동 평균 점수)
    var physicalScore: Double?     // 0.0 ~ 1.0 (신체 평균 점수)
    var overallScore: Double?       // 0.0 ~ 1.0 (종합 점수)
    
    // 데이터 완성도
    var mindCompleteness: Double    // 0.0 ~ 1.0 (마음 데이터 완성도)
    var behaviorCompleteness: Double // 0.0 ~ 1.0 (행동 데이터 완성도)
    var physicalCompleteness: Double // 0.0 ~ 1.0 (신체 데이터 완성도)
    var overallCompleteness: Double  // 0.0 ~ 1.0 (전체 데이터 완성도)
    
    // 카테고리별 기록 수 (TimeSeriesDataPoint의 notes 기반)
    var notesByCategory: [String: Int]  // 카테고리별 메모 수
    
    // 데이터 수집 소스별 통계
    var dataSourceCounts: [String: Int]  // DataSource.rawValue를 키로 사용
    
    var accountIdString: String {
        accountId.uuidString
    }
}

// MARK: - Gem Type & Color Theme
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

// MARK: - Gem Record (MVP용 단순화 모델)
/// 기록 데이터를 나타내는 단순한 Gem 레코드
/// - 하나의 기록 = 하나의 Gem
/// - brightness/uncertainty/colorTheme 등 복잡한 속성 없음
/// - Asset에서 gem_0, gem_1, gem_2... 순서대로 표시
struct GemRecord: Identifiable, Codable {
    let id: UUID
    var date: Date
    var gemIndex: Int                   // Asset 이미지 인덱스 (gem_0, gem_1, ...)
    var isCompleted: Bool               // 기록 작성 완료 여부
    var dataPointIds: [String]          // 연결된 TimeSeriesDataPoint ID 배열
    
    // UI 상태
    var opacity: Double {
        isCompleted ? 1.0 : 0.4         // 미완성: 40%, 완성: 100%
    }
}

// MARK: - Dashboard Item
/// Dashboard 카드의 개별 항목 데이터
struct DashboardItem: Codable {
    var icon: String
    let label: String
    let score: Double       // 0-100 점수
    let percentage: Double  // 변화율 (%)
    let uncertainty: Double // 불확실성 (0-100)
}

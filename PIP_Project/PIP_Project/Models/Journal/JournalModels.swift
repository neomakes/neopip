//
//  JournalModels.swift
//  PIP_Project
//
//  Journal Entry Model
//  Created by NEO on 12/18/25.
//

import Foundation

// MARK: - Journal Entry
/// 저널 엔트리
/// Firestore의 users/{accountId}/journal_entries/{entryId}에 저장
struct JournalEntry: Identifiable, Codable {
    let id: UUID
    var accountId: UUID
    var date: Date
    var title: String?
    var content: String
    var emotionScore: Double?     // 0.0 ~ 1.0 (감정 점수, 선택적)
    
    // DailyDataPoint와 연결
    var dataPointId: UUID?        // 연결된 TimeSeriesDataPoint ID
    
    // 추가 필드
    var category: JournalCategory
    var tags: [String]
    var gemId: UUID?              // 생성된 Gem의 고유 ID
    
    var createdAt: Date
    var updatedAt: Date
    
    var accountIdString: String {
        accountId.uuidString
    }
    
    var entryIdString: String {
        id.uuidString
    }
}

enum JournalCategory: String, Codable {
    case emotion    // 감정
    case physical   // 신체
    case behavior   // 행동
    case thought    // 생각
    case general    // 일반
}

// MARK: - Daily Gem
/// 일일 Gem 데이터
/// Firestore의 users/{accountId}/daily_gems/{gemId}에 저장
struct DailyGem: Identifiable, Codable {
    let id: UUID
    var accountId: UUID
    var date: Date
    var gemType: GemType           // Gem의 기하학적 형태
    var brightness: Double         // 0.0 ~ 1.0 (데이터 완성도)
    var uncertainty: Double        // 0.0 ~ 1.0 (AI 모델 불확실성)
    var journalEntries: [String]   // 해당 날짜의 JournalEntry ID 배열 (String)
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
    var totalEntries: Int          // 해당 날짜의 총 기록 수
    var totalDataPoints: Int        // 해당 날짜의 총 데이터 포인트 수
    
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
    
    // 카테고리별 기록 수
    var categories: [String: Int]   // JournalCategory.rawValue를 키로 사용
    
    // 데이터 수집 소스별 통계
    var dataSourceCounts: [String: Int]  // DataSource.rawValue를 키로 사용
    
    var accountIdString: String {
        accountId.uuidString
    }
}

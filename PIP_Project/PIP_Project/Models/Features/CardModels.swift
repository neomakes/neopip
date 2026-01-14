//
//  CardModels.swift
//  PIP_Project
//
//  WriteSheet에서 사용하는 카드 데이터 모델
//  Human World Model Schema ($s, a, o, O$) 대응
//

import Foundation

// MARK: - Card Data
/// 데이터 입력 카드 정보
struct CardData: Identifiable {
    let id: UUID
    var type: CardType
    var title: String
    var subtitle: String? // Added subtitle
    var inputs: [CardInput]
    var textInput: TextInput?
    
    init(id: UUID = UUID(), type: CardType, title: String, subtitle: String? = nil, inputs: [CardInput], textInput: TextInput? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.inputs = inputs
        self.textInput = textInput
    }
}

enum CardType: String {
    case state      // Internal State (s) - Mood, Energy
    case action     // Action / Intervention (a) - Activities
    case outcome    // Outcome (o) & Optimality (O) - Focus, Fulfillment
    case program    // Dynamic Program Cards (Generic fallback)
}

// MARK: - Card Input
/// 카드 내 입력 필드
enum CardInput {
    case slider(key: String, label: String, range: ClosedRange<Double>, defaultValue: Double = 50.0) // Renamed value -> defaultValue for consistency
    case toggle(key: String, label: String, defaultValue: Bool = false) // Renamed value
    case picker(key: String, label: String, options: [String], selectedIndex: Int = 0)
    
    /// 시계열 커브 차트 (Mood, Energy)
    /// Updated for 7-point curve
    case timeSlotChart(key: String, label: String, range: ClosedRange<Double>, values: [Double], times: [Double])
    
    /// 활동 기록 리스트 (Action Card 전용)
    /// Stores array of Interventions
    case activityList(key: String, label: String, limit: Int = 3)
    
    var key: String {
        switch self {
        case .slider(let key, _, _, _): return key
        case .toggle(let key, _, _): return key
        case .picker(let key, _, _, _): return key
        case .timeSlotChart(let key, _, _, _, _): return key
        case .activityList(let key, _, _): return key
        }
    }
}

// MARK: - Text Input
/// 텍스트 입력 필드
enum TextInput {
    case required(key: String, placeholder: String)
    case optional(key: String, placeholder: String)
}

//
//  WriteViewModel.swift
//  PIP_Project
//
//  WriteView의 ViewModel: 카드 입력 및 데이터 저장 관리
//

import Foundation
import Combine
import SwiftUI

@MainActor
class WriteViewModel: ObservableObject {
    // MARK: - Dependencies
    let dataService: DataServiceProtocol
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? MockDataService.shared
    }
    
    // MARK: - Card Generation
    
    /// 데이터 입력 카드 생성 (스키마 기반)
    func generateCards() -> [CardData] {
        var cards: [CardData] = []
        
        // MockDataService에서 스키마 가져오기
        guard let mockService = dataService as? MockDataService else {
            // MockDataService가 아닌 경우 기본 카드 반환
            return generateDefaultCards()
        }
        
        // 카테고리별로 카드 생성
        let categories: [DataCategory] = [.mind, .behavior, .physical]
        
        for category in categories {
            let schemas = mockService.getSchemas(for: category)
            guard !schemas.isEmpty else { continue }
            
            // 카테고리별 입력 필드 생성
            var inputs: [CardInput] = []
            for schema in schemas {
                if let range = schema.range {
                    let minValue = range.min ?? 0
                    let maxValue = range.max ?? 100
                    inputs.append(.slider(
                        key: schema.name,
                        label: schema.displayName,
                        range: minValue...maxValue,
                        value: (minValue + maxValue) / 2
                    ))
                }
            }
            
            // 카드 타입 결정
            let cardType: CardType
            switch category {
            case .mind: cardType = .mind
            case .behavior: cardType = .behavior
            case .physical: cardType = .physical
            default: cardType = .mind
            }
            
            // Card title
            let title: String
            switch category {
            case .mind: title = "How was your mood today?"
            case .behavior: title = "How was your behavior?"
            case .physical: title = "How was your physical state?"
            default: title = "How was your day?"
            }
            
            cards.append(CardData(
                type: cardType,
                title: title,
                inputs: inputs,
                textInput: .optional(key: "notes", placeholder: "Today's note")
            ))
        }
        
        return cards.isEmpty ? generateDefaultCards() : cards
    }
    
    /// Default card generation (when schema is not available)
    private func generateDefaultCards() -> [CardData] {
        return [
            CardData(
                type: .mind,
                title: "How was your mood today?",
                inputs: [
                    .timeSlotChart(key: "mood_timeline", label: "Mood Throughout Day", range: 0...100, values: [50, 50, 50, 50, 50, 50]),
                    .slider(key: "stress", label: "Stress", range: 0...100, value: 50),
                    .slider(key: "energy", label: "Energy", range: 0...100, value: 50)
                ],
                textInput: .optional(key: "notes", placeholder: "Today's note")
            ),
            CardData(
                type: .behavior,
                title: "How was your behavior?",
                inputs: [
                    .slider(key: "productivity", label: "Productivity", range: 0...100, value: 50),
                    .slider(key: "socialActivity", label: "Social Activity", range: 0...100, value: 50),
                    .slider(key: "digitalDistraction", label: "Digital Distraction", range: 0...100, value: 50),
                    .slider(key: "exploration", label: "Exploration", range: 0...100, value: 50)
                ],
                textInput: .optional(key: "notes", placeholder: "Note")
            ),
            CardData(
                type: .physical,
                title: "How was your physical state?",
                inputs: [
                    .slider(key: "sleepScore", label: "Sleep Score", range: 0...100, value: 50),
                    .slider(key: "fatigue", label: "Fatigue", range: 0...100, value: 50),
                    .slider(key: "activityLevel", label: "Activity Level", range: 0...100, value: 50),
                    .slider(key: "nutrition", label: "Nutrition", range: 0...100, value: 50)
                ],
                textInput: .optional(key: "notes", placeholder: "Note")
            )
        ]
    }
    
    // MARK: - Card Data Saving
    
    /// 카드 데이터 저장
    func saveCardData(_ card: CardData, inputs: [String: Any], textInput: String) {
        let now = Date()

        // 입력값을 DataValue로 변환
        var values: [String: DataValue] = [:]

        for (key, value) in inputs {
            if let doubleValue = value as? Double {
                values[key] = .double(doubleValue)
            } else if let intValue = value as? Int {
                values[key] = .integer(intValue)
            } else if let stringValue = value as? String {
                values[key] = .string(stringValue)
            } else if let doubleArray = value as? [Double] {
                // Store full time-slot array as DataValue.array of doubles
                values[key] = .array(doubleArray.map { .double($0) })
            } else if let intArray = value as? [Int] {
                values[key] = .array(intArray.map { .integer($0) })
            }
        }
        
        // 텍스트 입력 추가
        if !textInput.isEmpty {
            values["notes"] = .string(textInput)
        }
        
        // TimeSeriesDataPoint 생성
        let dataPoint = TimeSeriesDataPoint(
            timestamp: now,
            category: card.type.toDataCategory(),
            values: values,
            notes: textInput.isEmpty ? nil : textInput
        )
        
        // DataService를 통해 저장 (기존 동기 wrapper)
        Task {
            do {
                try await dataService.saveData(dataPoint, for: card.type.toDataCategory())
                print("Card data saved successfully")
            } catch {
                print("Error saving card data: \(error)")
            }
        }
    }

    /// 비동기 블록으로 저장 동작을 노출합니다. 오류는 호출자에게 전달됩니다.
    func saveCard(_ card: CardData, inputs: [String: Any], textInput: String) async throws {
        let now = Date()
        var values: [String: DataValue] = [:]

        for (key, value) in inputs {
            if let doubleValue = value as? Double {
                values[key] = .double(doubleValue)
            } else if let intValue = value as? Int {
                values[key] = .integer(intValue)
            } else if let stringValue = value as? String {
                values[key] = .string(stringValue)
            } else if let doubleArray = value as? [Double] {
                values[key] = .array(doubleArray.map { .double($0) })
            } else if let intArray = value as? [Int] {
                values[key] = .array(intArray.map { .integer($0) })
            }
        }

        if !textInput.isEmpty {
            values["notes"] = .string(textInput)
        }

        let dataPoint = TimeSeriesDataPoint(
            timestamp: now,
            category: card.type.toDataCategory(),
            values: values,
            notes: textInput.isEmpty ? nil : textInput
        )

        try await dataService.saveData(dataPoint, for: card.type.toDataCategory())
    }
}

// MARK: - Helper Extensions
extension CardType {
    func toDataCategory() -> DataCategory {
        switch self {
        case .mind: return .mind
        case .behavior: return .behavior
        case .physical: return .physical
        case .program: return .mind  // Default category for program type
        }
    }
}

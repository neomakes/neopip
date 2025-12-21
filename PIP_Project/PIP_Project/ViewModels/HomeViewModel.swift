//
//  HomeViewModel.swift
//  PIP_Project
//
//  HomeView의 ViewModel: 데이터 관리 및 비즈니스 로직
//

import Foundation
import Combine
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var dailyGems: [DailyGem] = []
    @Published var userStats: UserStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    let dataService: DataServiceProtocol
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? MockDataService.shared
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 초기 데이터 로드 (최근 30일)
    func loadInitialData() {
        isLoading = true
        errorMessage = nil
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) else {
            isLoading = false
            return
        }
        
        // DailyGems 로드
        dataService.fetchDailyGems(from: startDate, to: endDate)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] gems in
                    self?.dailyGems = gems
                }
            )
            .store(in: &cancellables)
        
        // UserStats 로드
        dataService.fetchUserStats()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] stats in
                    self?.userStats = stats
                }
            )
            .store(in: &cancellables)
    }
    
    /// 특정 날짜의 데이터 포인트 로드
    func loadDataPoints(for date: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error> {
        return dataService.fetchDataPoints(for: date)
    }
    
    /// 새 데이터 포인트 저장
    func saveDataPoint(_ dataPoint: TimeSeriesDataPoint) {
        dataService.saveDataPoint(dataPoint)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    } else {
                        // 저장 성공 시 데이터 새로고침
                        self?.loadInitialData()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    /// 오늘의 Gem 가져오기
    func getTodayGem() -> DailyGem? {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyGems.first { gem in
            Calendar.current.isDate(gem.date, inSameDayAs: today)
        }
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
                    inputs.append(.slider(
                        key: schema.name,
                        label: schema.displayName,
                        range: ClosedRange(uncheckedBounds: (range.min ?? 0, range.max ?? 100)),
                        value: (range.min ?? 0 + (range.max ?? 100)) / 2
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
                    .slider(key: "mood", label: "Mood", range: 0...100, value: 50),
                    .slider(key: "stress", label: "Stress", range: 0...100, value: 50),
                    .slider(key: "energy", label: "Energy", range: 0...100, value: 50),
                    .slider(key: "focus", label: "Focus", range: 0...100, value: 50)
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
        let calendar = Calendar.current
        
        // 입력값을 DataValue로 변환
        var values: [String: DataValue] = [:]
        
        for (key, value) in inputs {
            if let doubleValue = value as? Double {
                values[key] = .double(doubleValue)
            } else if let intValue = value as? Int {
                values[key] = .integer(intValue)
            } else if let boolValue = value as? Bool {
                values[key] = .boolean(boolValue)
            } else if let stringValue = value as? String {
                values[key] = .string(stringValue)
            }
        }
        
        // 시간대 결정
        let hour = calendar.component(.hour, from: now)
        let timeOfDay: TimeOfDay
        switch hour {
        case 6..<12: timeOfDay = .morning
        case 12..<18: timeOfDay = .afternoon
        case 18..<22: timeOfDay = .evening
        default: timeOfDay = .night
        }
        
        // 카테고리 결정: 각 데이터 필드의 실제 카테고리를 확인
        let category: DataCategory
        if let mockService = dataService as? MockDataService {
            // MockDataService에서 각 필드의 스키마를 조회하여 카테고리 확인
            var categoryCounts: [DataCategory: Int] = [:]
            
            for key in values.keys {
                if let schema = mockService.getAllSchemas().first(where: { $0.name == key }) {
                    categoryCounts[schema.category, default: 0] += 1
                }
            }
            
            // 가장 많은 카테고리 사용, 없으면 card.type 기반
            if let mostCommonCategory = categoryCounts.max(by: { $0.value < $1.value })?.key {
                category = mostCommonCategory
            } else {
                // 폴백: card.type 기반
                switch card.type {
                case .mind: category = .mind
                case .behavior: category = .behavior
                case .physical: category = .physical
                case .program: category = .custom
                }
            }
        } else {
            // MockDataService가 아닌 경우 card.type 기반
            switch card.type {
            case .mind: category = .mind
            case .behavior: category = .behavior
            case .physical: category = .physical
            case .program: category = .custom
            }
        }
        
        // TimeSeriesDataPoint 생성
        let dataPoint = TimeSeriesDataPoint(
            id: UUID(),
            anonymousUserId: UUID(), // 실제로는 사용자 ID 사용
            timestamp: now,
            date: calendar.startOfDay(for: now),
            timeOfDay: timeOfDay,
            dayOfWeek: calendar.component(.weekday, from: now),
            weekOfYear: calendar.component(.weekOfYear, from: now),
            month: calendar.component(.month, from: now),
            values: values,
            source: .manual,
            confidence: 1.0,
            completeness: Double(values.count) / Double(card.inputs.count),
            notes: textInput.isEmpty ? nil : textInput,
            tags: [],
            context: nil,
            category: category,
            features: nil,
            predictions: nil,
            anomalies: nil,
            createdAt: now,
            updatedAt: now
        )
        
        // 저장
        saveDataPoint(dataPoint)
    }
    
    /// 특정 날짜의 데이터 포인트 가져오기
    func fetchDataPoints(for date: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error> {
        return dataService.fetchDataPoints(for: date)
    }
}

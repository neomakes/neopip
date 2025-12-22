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
    
    /// 특정 날짜의 데이터 포인트 가져오기
    func fetchDataPoints(for date: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error> {
        return dataService.fetchDataPoints(for: date)
    }

    
    // MARK: - Icon Name Mapping
    
    /// 데이터 항목명에 해당하는 아이콘 이름을 반환합니다.
    /// Assets에 있는 아이콘 이름과 자동으로 매핑합니다.
    private func iconNameFor(_ schemaName: String) -> String {
        let lowerName = schemaName.lowercased()
        
        // Assets에 실제 존재하는 아이콘 매핑 (02_Insight/00_Insights_icons/)
        let mappings: [String: String] = [
            "mood": "Icon_mood",
            "stress": "Icon_stress",
            "energy": "Icon_energy",
            "focus": "Icon_focus",
            "productivity": "Icon_productivity",
            "social": "Icon_social_activity",
            "socialactivity": "Icon_social_activity",
            "distraction": "Icon_digital_distraction",
            "digitaldistraction": "Icon_digital_distraction",
            "exploration": "Icon_exploration",
            "sleep": "Icon_sleep",
            "sleepscore": "Icon_sleep",
            "fatigue": "Icon_fatigue",
            "activity": "Icon_activity",
            "activitylevel": "Icon_activity",
            "nutrition": "Icon_nutrition"
        ]
        
        // 매핑 테이블에서 먼저 찾기
        if let mapped = mappings[lowerName] {
            return mapped
        }
        
        // 공백 제거 후 다시 시도
        let normalizedName = schemaName.replacingOccurrences(of: " ", with: "").lowercased()
        if let mapped = mappings[normalizedName] {
            return mapped
        }
        
        // 기본값: Icon_${이름} 형식 시도
        return "Icon_\(lowerName.replacingOccurrences(of: " ", with: "_").capitalized)"
    }

    // MARK: - Chart Data Generation

    func createRadarChartDataSets(for date: Date, completion: @escaping (Result<[RadarChartDataSet], Error>) -> Void) {
        // 1. Fetch the single data point for the day
        dataService.fetchDataPoints(for: date)
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                },
                receiveValue: { dataPoints in
                    guard let dataPoint = dataPoints.first else {
                        let error = NSError(domain: "HomeViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "No data point found for the selected date."])
                        completion(.failure(error))
                        return
                    }

                    // 2. Get schemas from the data service
                    guard let mockService = self.dataService as? MockDataService else {
                        let error = NSError(domain: "HomeViewModel", code: 500, userInfo: [NSLocalizedDescriptionKey: "Data service is not a MockDataService."])
                        completion(.failure(error))
                        return
                    }

                    var dataSets: [RadarChartDataSet] = []
                    let categories: [(category: DataCategory, color: Color)] = [
                        (.mind, .red),
                        (.behavior, .blue),
                        (.physical, .orange)
                    ]

                    // 3. Process data for each category
                    for (category, color) in categories {
                        let schemas = mockService.getSchemas(for: category)
                        var chartDataItems: [RadarChartDataItem] = []

                        for schema in schemas {
                            guard let dataValue = dataPoint.values[schema.name] else { continue }
                            
                            let rawValue: Double
                            switch dataValue {
                            case .double(let v): rawValue = v
                            case .integer(let v): rawValue = Double(v)
                            default: continue
                            }
                            
                            // Normalize the value (assuming max is 100)
                            let maxValue = schema.range?.max ?? 100.0
                            let normalizedValue = rawValue / maxValue
                            
                            let displayValue = String(format: "%.0f", rawValue)
                            let iconName = self.iconNameFor(schema.name)
                            chartDataItems.append(
                                RadarChartDataItem(iconName: iconName, value: normalizedValue, displayValue: displayValue)
                            )
                        }

                        if !chartDataItems.isEmpty {
                            let title: String
                            switch category {
                            case .mind: title = "Mind"
                            case .behavior: title = "Behavior"
                            case .physical: title = "Physical"
                            default: title = "Data"
                            }
                            dataSets.append(
                                RadarChartDataSet(title: title, data: chartDataItems, dataColor: color)
                            )
                        }
                    }

                    completion(.success(dataSets))
                }
            )
            .store(in: &self.cancellables)
    }

}

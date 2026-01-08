//
//  HomeViewModel.swift
//  PIP_Project
//
//  HomeView's ViewModel: Data management and business logic
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
    @Published var last7Days: [GemRecord] = []
    @Published var userName: String?

    // MARK: - Computed stats (derived from `dailyGems`)
    /// Total number of unique days with gems (derived from `dailyGems`). Use set of startOfDay to avoid duplicates.
    var totalGemsCreated: Int {
        let calendar = Calendar.current
        let days = Set(dailyGems.map { calendar.startOfDay(for: $0.date) })
        return days.count
    }

    /// Current streak computed from `dailyGems`.
    /// Streak counts consecutive days with data ending at yesterday (today excluded unless you prefer otherwise).
    var currentStreak: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard !dailyGems.isEmpty else { return 0 }

        // Build a set of days that have data
        let presentDays = Set(dailyGems.map { calendar.startOfDay(for: $0.date) })

        // Start counting from yesterday
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
        var streak = 0
        var dayToCheck = yesterday

        while presentDays.contains(dayToCheck) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: dayToCheck) else { break }
            dayToCheck = prev
        }

        return streak
    }    
    // MARK: - Dependencies
    let dataService: DataServiceProtocol
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        // Use injected service if provided, otherwise use currently active service from DataServiceManager
        self.dataService = dataService ?? DataServiceManager.shared.currentService

        // default name is nil until we fetch profile
        self.userName = nil
        loadInitialData()

        // 매일 자정에 데이터 새로고침 (Streak 업데이트를 위함)
        setupDailyRefresh()
    }
    
    // MARK: - Public Methods
    
    /// 자정마다 데이터 새로고침 설정
    private func setupDailyRefresh() {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 0
        components.minute = 0
        components.second = 1
        
        guard let midnightToday = calendar.date(from: components),
              let midnightTomorrow = calendar.date(byAdding: .day, value: 1, to: midnightToday) else {
            return
        }
        
        let timeUntilMidnight = midnightTomorrow.timeIntervalSince(Date())
        
        // 자정 시점에 첫 번째 새로고침 실행
        DispatchQueue.main.asyncAfter(deadline: .now() + timeUntilMidnight) { [weak self] in
            self?.loadInitialData()
            
            // 이후 매일 자정마다 새로고침 (24시간 간격)
            Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
                self?.loadInitialData()
            }
        }
    }
    
    /// 초기 데이터 로드 (최근 30일)
    func loadInitialData() {
        print("📥 [HomeViewModel] loadInitialData() called")
        isLoading = true
        errorMessage = nil
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) else {
            isLoading = false
            return
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        print("📥 [HomeViewModel] Fetching daily gems from \(formatter.string(from: startDate)) to \(formatter.string(from: endDate))")
        
        // DailyGems 로드
        dataService.fetchDailyGems(from: startDate, to: endDate)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        print("❌ [HomeViewModel] Error fetching gems: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] gems in
                    print("✅ [HomeViewModel] Received \(gems.count) daily gems")
                    self?.dailyGems = gems
                    self?.updateLast7Days()
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

        // UserProfile 로드 (displayName를 헤더에 사용)
        dataService.fetchUserProfile()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ [HomeViewModel] Failed to fetch user profile: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] profile in
                    // prefer explicit displayName, fallback to existing userName or 'User'
                    let name = profile.displayName ?? self?.userName ?? "User"
                    self?.userName = name
                    print("✅ [HomeViewModel] Fetched user profile, displayName: \(name)")
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
    
    /// last7Days 업데이트 (과거 6일 + 오늘 = 7개)
    private func updateLast7Days() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var gemRecords: [GemRecord] = []
        
        print("📅 [HomeViewModel.updateLast7Days] Processing dailyGems: \(dailyGems.count) total gems")
        print("📅 [HomeViewModel.updateLast7Days] Today's date: \(today)")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        // 과거 6일 + 오늘 = 7일
        for i in (0...6).reversed() {
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? Date()
            
            // dailyGems에서 해당 날짜의 gem을 찾기
            let dailyGem = dailyGems.first { gem in
                calendar.isDate(gem.date, inSameDayAs: date)
            }
            
            let dateStr = formatter.string(from: date)
            let gemIndex = 7 - i  // 오늘: 7, 1일전: 6, 2일전: 5, ..., 6일전: 1 ✨
            
            // 오늘(i=0)은 데이터 유무 상관없이 항상 생성
            // 과거(i>0)는 데이터가 있을 때만 생성
            if i == 0 {
                // 오늘: 무조건 생성 (데이터 유무에 따라 isCompleted 결정)
                let isCompleted = dailyGem != nil
                let gemRecord = GemRecord(
                    id: UUID(),
                    date: date,
                    gemIndex: gemIndex,
                    isCompleted: isCompleted,
                    dataPointIds: dailyGem?.dataPointIds ?? []
                )
                gemRecords.append(gemRecord)
                print("📅 [HomeViewModel.updateLast7Days] \(dateStr): Today's gem created (isCompleted=\(isCompleted))")
            } else if let dailyGem = dailyGem {
                // 과거: 데이터가 있을 때만 생성
                let gemRecord = GemRecord(
                    id: UUID(),
                    date: date,
                    gemIndex: gemIndex,
                    isCompleted: true,
                    dataPointIds: dailyGem.dataPointIds
                )
                gemRecords.append(gemRecord)
                print("📅 [HomeViewModel.updateLast7Days] \(dateStr): Created gem with \(dailyGem.dataPointIds.count) dataPoints")
            } else {
                print("📅 [HomeViewModel.updateLast7Days] \(dateStr): No data, skipping")
            }
        }
        
        self.last7Days = gemRecords
        print("✅ [HomeViewModel.updateLast7Days] Updated last7Days: \(gemRecords.count) records")
        print("🔥 [HomeViewModel] Current streak: \(currentStreak)")
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
        
        // First look in mapping table
        if let mapped = mappings[lowerName] {
            return mapped
        }
        
        // 공백 제거 후 다시 시도
        let normalizedName = schemaName.replacingOccurrences(of: " ", with: "").lowercased()
        if let mapped = mappings[normalizedName] {
            return mapped
        }
        
        // Default: Try Icon_${name} format
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


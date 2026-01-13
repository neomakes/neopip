//
//  HomeViewModel.swift
//  PIP_Project
//
//  HomeView's ViewModel: Data management and business logic
//

import Foundation
import Combine
import SwiftUI
import FirebaseAuth

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var dailyGems: [DailyGem] = []
    @Published var userStats: UserStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var last7Days: [GemRecord] = []
    @Published var userName: String?
    
    // Internal state to prevent premature syncing
    private var hasFetchedGems = false

    // MARK: - Computed stats (derived from `dailyGems`)
    /// Total number of unique days with gems (derived from `dailyGems`). Use set of startOfDay to avoid duplicates.
    var totalGemsCreated: Int {
        let calendar = Calendar.current
        let days = Set(dailyGems.map { calendar.startOfDay(for: $0.date) })
        return days.count
    }

    /// Current streak calculated from dailyGems (Local Source of Truth for immediate UI update)
    /// UserStats.streakDays is used as fallback; local calculation takes precedence for responsiveness
    var currentStreak: Int {
        // dailyGems가 있으면 로컬에서 직접 계산 (즉시 반영)
        if !dailyGems.isEmpty {
            return calculateStreakFromGems()
        }
        // fallback: UserStats에서 가져오기
        return userStats?.streakDays ?? 0
    }

    /// dailyGems 배열에서 오늘부터 역순으로 연속 streak 계산
    private func calculateStreakFromGems() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // dailyGems의 날짜들을 Set으로 변환 (빠른 조회)
        let gemDates = Set(dailyGems.map { calendar.startOfDay(for: $0.date) })

        // 오늘부터 역순으로 연속 날짜 카운트
        var streak = 0
        var checkDate = today

        while gemDates.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        return streak
    }    
    // MARK: - Dependencies
    let dataService: DataServiceProtocol
    var cancellables = Set<AnyCancellable>()
    
    // Auth Listener
    private var authListenerHandle: NSObjectProtocol?

    // Date state tracking
    private var lastRefreshedDate: Date = Date()
    private var dayCheckTimer: Timer?

    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        // Use injected service if provided, otherwise use currently active service from DataServiceManager
        self.dataService = dataService ?? DataServiceManager.shared.currentService
 
        // default name is nil until we fetch profile
        self.userName = nil
        
        // Load data immediately (best effort)
        Task {
            await MainActor.run { [weak self] in
                self?.loadInitialData()
            }
        }
 
        // Setup robust date change detection
        setupDateChangeObservers()
 
        // Listen for card save notifications to refresh today's gem
        NotificationCenter.default.publisher(for: .didSaveCardData)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("📥 [HomeViewModel] Received didSaveCardData notification, refreshing...")
                self?.loadInitialData(showLoading: false)
            }
            .store(in: &cancellables)
            
        // Listen for Auth changes to reload data (Crucial for app restarts/reinstalls)
        authListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] (auth: Auth, user: User?) in
            if let user = user {
                print("👤 [HomeViewModel] User authenticated: \(user.uid). Reloading data.")
                Task {
                    await MainActor.run { [weak self] in
                        self?.loadInitialData()
                    }
                }
            }
        }
    }
    
    deinit {
        if let handle = authListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
        dayCheckTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Setup observers for app lifecycle and time changes
    private func setupDateChangeObservers() {
        // 1. App enters foreground
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("📱 [HomeViewModel] App entered foreground, checking day change...")
                self?.checkDayChange()
            }
            .store(in: &cancellables)
            
        // 2. Significant time change (e.g. midnight, time zone change)
        NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("⏰ [HomeViewModel] Significant time change detected, checking day change...")
                self?.checkDayChange()
            }
            .store(in: &cancellables)
            
        // 3. Periodic timer (every 60s) to catch midnight while app is active
        // invalidate existing timer if any
        dayCheckTimer?.invalidate()
        dayCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkDayChange()
        }
    }
    
    /// Check if the day has changed since the last refresh.
    /// If so, reloads the data.
    private func checkDayChange() {
        let calendar = Calendar.current
        let now = Date()
        
        if !calendar.isDate(now, inSameDayAs: lastRefreshedDate) {
            print("📆 [HomeViewModel] Day changed from \(lastRefreshedDate) to \(now). Reloading data.")
            loadInitialData(showLoading: false) // Don't show full loading screen for seamless update
        }
    }
    
    /// 초기 데이터 로드 (최근 30일)
    func loadInitialData(showLoading: Bool = true) {
        print("📥 [HomeViewModel] loadInitialData(showLoading: \(showLoading)) called")
        if showLoading {
            isLoading = true
        }
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
        
        // Update lastRefreshedDate to now
        self.lastRefreshedDate = Date()
        
        // DailyGems 로드
        dataService.fetchDailyGems(from: startDate, to: endDate)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if showLoading {
                        self?.isLoading = false
                    }
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        print("❌ [HomeViewModel] Error fetching gems: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] gems in
                    print("✅ [HomeViewModel] Received \(gems.count) daily gems")
                    self?.dailyGems = gems
                    self?.hasFetchedGems = true
                    self?.updateLast7Days()
                    self?.syncStatsWithServer()
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
                    // Stats 로드 후, 현재 Gems 기반으로 동기화 필요 여부 확인
                    if let self = self {
                        self.syncStatsWithServer()
                    }
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
    
    /// 서버와 로컬 통계 동기화
    /// dailyGems(로컬 계산)와 fetch된 UserStats가 다르면 업데이트
    private func syncStatsWithServer() {
        guard let currentStats = userStats else { return }
        guard hasFetchedGems else {
            print("⏳ [HomeViewModel] Skipping stats sync: Gems not yet fetched")
            return
        }
        
        let calculatedStreak = calculateStreakFromGems()
        let calculatedTotalGems = totalGemsCreated // Computed property usage
        
        // 변경 사항이 있는지 확인
        if currentStats.streakDays != calculatedStreak || currentStats.totalGems != calculatedTotalGems {
            print("🔄 [HomeViewModel] Syncing stats with server...")
            print("   L Streak: \(currentStats.streakDays) -> \(calculatedStreak)")
            print("   L Total: \(currentStats.totalGems) -> \(calculatedTotalGems)")
            
            var newStats = currentStats
            newStats.streakDays = calculatedStreak
            newStats.totalGems = calculatedTotalGems
            newStats.lastRecordedAt = Date() // 업데이트 시점 갱신
            // updated_at은 DataService나 서버에서 처리하는게 좋지만, 여기서 명시적으로 변경 가능
             newStats.updatedAt = Date()
            
            // Optimistic update
            self.userStats = newStats
            
            dataService.updateUserStats(newStats)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ [HomeViewModel] Failed to sync stats: \(error)")
                            // 실패 시 롤백 로직이 필요할 수 있으나, 다음 fetch에서 보정되므로 생략
                        }
                    },
                    receiveValue: { updatedStats in
                        print("✅ [HomeViewModel] Stats synced successfully")
                        NotificationCenter.default.post(name: .didSaveCardData, object: nil)
                    }
                )
                .store(in: &cancellables)
        } else {
            print("✅ [HomeViewModel] Stats are in sync")
        }
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
                        // 저장 성공 시 데이터 새로고침 및 노티피케이션 발송
                        self?.loadInitialData()
                        NotificationCenter.default.post(name: .didSaveCardData, object: nil)
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
        // 1. Fetch the data points for the day
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

                    print("📊 [HomeViewModel] Processing dataPoint: \(dataPoint.id)")
                    print("   → Category: \(dataPoint.category?.rawValue ?? "nil")")
                    print("   → Values keys: \(dataPoint.values.keys.joined(separator: ", "))")

                    var dataSets: [RadarChartDataSet] = []
                    let categories: [(category: DataCategory, categoryKey: String, color: Color)] = [
                        (.mind, "mind", .red),
                        (.behavior, "behavior", .blue),
                        (.physical, "physical", .orange)
                    ]

                    // 2. Process data for each category
                    // 데이터 구조: { "mind": { "stress": 50, ... }, "behavior": { ... } }
                    for (category, categoryKey, color) in categories {
                        let schemas = self.dataService.getSchemas(for: category)
                        var chartDataItems: [RadarChartDataItem] = []

                        // 카테고리별 중첩 데이터 추출
                        var categoryValues: [String: DataValue] = [:]

                        // Case 1: 중첩 구조 (dailyLog 형식)
                        if case .object(let nestedValues) = dataPoint.values[categoryKey] {
                            categoryValues = nestedValues
                            print("   → Found nested \(categoryKey) with \(nestedValues.count) values")
                        }
                        // Case 2: 평탄화 구조 (레거시 또는 단일 카테고리)
                        else {
                            categoryValues = dataPoint.values
                        }

                        for schema in schemas {
                            guard let dataValue = categoryValues[schema.name] else { continue }

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
                            print("   ✅ Created \(title) chart with \(chartDataItems.count) items")
                        }
                    }

                    print("📊 [HomeViewModel] Total dataSets created: \(dataSets.count)")
                    completion(.success(dataSets))
                }
            )
            .store(in: &self.cancellables)
    }

}


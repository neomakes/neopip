//
//  HomeViewModel.swift
//  PIP_Project
//
//  HomeView's ViewModel: Data management and business logic
//  Refactored for Human World Model Schema ($P(O, o, s, a, w)$)
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
    /// Total number of unique days with gems
    var totalGemsCreated: Int {
        let calendar = Calendar.current
        let days = Set(dailyGems.map { calendar.startOfDay(for: $0.date) })
        return days.count
    }

    /// Current streak calculated from dailyGems
    var currentStreak: Int {
        if !dailyGems.isEmpty {
            return calculateStreakFromGems()
        }
        return userStats?.streakDays ?? 0
    }

    /// Calculate Streak locally
    private func calculateStreakFromGems() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let gemDates = Set(dailyGems.map { calendar.startOfDay(for: $0.date) })

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
        self.dataService = dataService ?? DataServiceManager.shared.currentService
        self.userName = nil
        
        Task {
            await MainActor.run { [weak self] in
                self?.loadInitialData()
            }
        }
 
        setupDateChangeObservers()
 
        // Notification Name is now in DataModels.swift extension
        NotificationCenter.default.publisher(for: .didSaveCardData)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("📥 [HomeViewModel] Received didSaveCardData notification, refreshing...")
                self?.loadInitialData(showLoading: false)
            }
            .store(in: &cancellables)
            
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
    
    private func setupDateChangeObservers() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("📱 [HomeViewModel] App entered foreground...")
                self?.checkDayChange()
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("⏰ [HomeViewModel] Significant time change...")
                self?.checkDayChange()
            }
            .store(in: &cancellables)
            
        dayCheckTimer?.invalidate()
        dayCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkDayChange()
        }
    }
    
    /// Check if day changed
    private func checkDayChange() {
        // Since this method touches @Published props or calls MainActor methods, it must be on MainActor.
        // It is called from Timer/Notification which might not be main, but `sink` handles main dispatch.
        // For Timer, we need to be careful. But strictly, checkDayChange is just logic.
        // `loadInitialData` is MainActor.
        
        // Ensure isolation
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            let calendar = Calendar.current
            let now = Date()
            
            if !calendar.isDate(now, inSameDayAs: self.lastRefreshedDate) {
                print("📆 [HomeViewModel] Day changed. Reloading.")
                self.loadInitialData(showLoading: false)
            }
        }
    }
    
    func loadInitialData(showLoading: Bool = true) {
        if showLoading { isLoading = true }
        errorMessage = nil
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) else {
            isLoading = false
            return
        }
        
        self.lastRefreshedDate = Date()
        
        // Fetch Gems
        dataService.fetchDailyGems(from: startDate, to: endDate)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if showLoading { self?.isLoading = false }
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] gems in
                    self?.dailyGems = gems
                    self?.hasFetchedGems = true
                    self?.updateLast7Days()
                    self?.syncStatsWithServer()
                }
            )
            .store(in: &cancellables)
        
        // Fetch UserStats
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
                    self?.syncStatsWithServer()
                }
            )
            .store(in: &cancellables)

        // Fetch Profile
        dataService.fetchUserProfile()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] profile in
                    let name = profile.displayName ?? self?.userName ?? "User"
                    self?.userName = name
                }
            )
            .store(in: &cancellables)
    }
    
    private func syncStatsWithServer() {
        guard let currentStats = userStats, hasFetchedGems else { return }
        
        let calculatedStreak = calculateStreakFromGems()
        let calculatedTotalGems = totalGemsCreated
        
        if currentStats.streakDays != calculatedStreak || currentStats.totalGems != calculatedTotalGems {
            var newStats = currentStats
            newStats.streakDays = calculatedStreak
            newStats.totalGems = calculatedTotalGems
            newStats.lastRecordedAt = Date()
            newStats.updatedAt = Date()
            
            self.userStats = newStats
            
            dataService.updateUserStats(newStats)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { _ in
                        NotificationCenter.default.post(name: .didSaveCardData, object: nil)
                    }
                )
                .store(in: &cancellables)
        }
    }
    
    func loadDataPoints(for date: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error> {
        return dataService.fetchDataPoints(for: date)
    }
    
    func saveDataPoint(_ dataPoint: TimeSeriesDataPoint) {
        dataService.saveDataPoint(dataPoint)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    } else {
                        self?.loadInitialData()
                        NotificationCenter.default.post(name: .didSaveCardData, object: nil)
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    func getTodayGem() -> DailyGem? {
        let today = Calendar.current.startOfDay(for: Date())
        return dailyGems.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    private func updateLast7Days() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var gemRecords: [GemRecord] = []
        
        for i in (0...6).reversed() { // 6 days ago ... today
            let date = calendar.date(byAdding: .day, value: -i, to: today) ?? Date()
            let dailyGem = dailyGems.first { calendar.isDate($0.date, inSameDayAs: date) }
            let gemIndex = 7 - i
            
            if i == 0 { // Today
                let isCompleted = dailyGem != nil
                let gemRecord = GemRecord(
                    id: UUID(),
                    date: date,
                    gemIndex: gemIndex,
                    isCompleted: isCompleted,
                    dataPointIds: dailyGem?.dataPointIds ?? []
                )
                gemRecords.append(gemRecord)
            } else if let dailyGem = dailyGem {
                let gemRecord = GemRecord(
                    id: UUID(),
                    date: date,
                    gemIndex: gemIndex,
                    isCompleted: true,
                    dataPointIds: dailyGem.dataPointIds
                )
                gemRecords.append(gemRecord)
            }
        }
        self.last7Days = gemRecords
    }

    func fetchDataPoints(for date: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error> {
        return dataService.fetchDataPoints(for: date)
    }

    // MARK: - Icon Name Mapping
    private func iconNameFor(_ schemaName: String) -> String {
        // Simple mapping based on known keys
        let mapping: [String: String] = [
            "mood": "Icon_mood",
            "energy": "Icon_energy",
            "focus": "Icon_focus",
            "fulfillment": "Icon_activity" // Fallback/Close match
        ]
        return mapping[schemaName] ?? "Icon_activity"
    }

    // MARK: - Chart Data Generation (Updated for Human World Model)
    func createRadarChartDataSets(for date: Date, completion: @escaping (Result<[RadarChartDataSet], Error>) -> Void) {
        dataService.fetchDataPoints(for: date)
            .sink(
                receiveCompletion: { result in
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                },
                receiveValue: { dataPoints in
                    // Aggregation Strategy: Average the values for the day
                    guard !dataPoints.isEmpty else {
                        let error = NSError(domain: "HomeViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "No data."])
                        completion(.failure(error))
                        return
                    }
                    
                    // Separate State (Mind/Energy) & Outcome (Focus/Fulfillment)
                    var totalMood: Double = 0
                    var totalEnergy: Double = 0
                    var totalFocus: Double = 0
                    var totalFulfillment: Double = 0
                    let count = Double(dataPoints.count)
                    
                    for dp in dataPoints {
                        // Normalize Mood (-100~100) -> 0~100 for Radar? Or keep strict mapping
                        // Let's map Mood (-100~100) -> 0~100 (Valence + 100 / 2)
                        let normalizedMood = (dp.state.mood + 100) / 2
                        totalMood += normalizedMood
                        totalEnergy += dp.state.energy
                        
                        totalFocus += dp.outcome.focusLevel
                        // Fulfillment (1-5) -> 0~100
                        totalFulfillment += Double(dp.optimality.fulfillment) * 20.0
                    }
                    
                    // Averages
                    let avgMood = totalMood / count
                    let avgEnergy = totalEnergy / count
                    let avgFocus = totalFocus / count
                    let avgFulfillment = totalFulfillment / count
                    
                    // Create DataSets
                    // 1. Mind Set (Mood, Energy)
                    let mindItems = [
                        RadarChartDataItem(iconName: "Icon_mood", value: avgMood, displayValue: String(format: "%.0f", avgMood)),
                        RadarChartDataItem(iconName: "Icon_energy", value: avgEnergy, displayValue: String(format: "%.0f", avgEnergy))
                    ]
                    let mindSet = RadarChartDataSet(title: "Mind", data: mindItems, dataColor: .red) // Red/Pink
                    
                    // 2. Outcome Set (Focus, Fulfillment)
                    let outcomeItems = [
                        RadarChartDataItem(iconName: "Icon_focus", value: avgFocus, displayValue: String(format: "%.0f", avgFocus)),
                        RadarChartDataItem(iconName: "Icon_activity", value: avgFulfillment, displayValue: String(format: "%.0f", avgFulfillment))
                    ]
                    let outcomeSet = RadarChartDataSet(title: "Outcome", data: outcomeItems, dataColor: .blue) // Blue/Teal
                    
                    completion(.success([mindSet, outcomeSet]))
                }
            )
            .store(in: &self.cancellables)
    }
}

//
//  MockDataService.swift
//  PIP_Project
//
//  MockData Service: Provides mock data for UI verification without Firebase
//

import Foundation
import Combine
import UIKit

/// MockData service for UI verification before Firebase integration
class MockDataService: DataServiceProtocol {
    @MainActor
    static let shared = MockDataService()
    
    // MARK: - File Management
    private let fileManager = FileManager.default
    
    /// Path to MockData folder in app's Documents directory
    private var mockDataDirectory: URL {
        if let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let mockDataDir = documentsDir.appendingPathComponent("MockData")
            try? fileManager.createDirectory(at: mockDataDir, withIntermediateDirectories: true)
            return mockDataDir
        }
        return FileManager.default.temporaryDirectory
    }

    // MARK: - JSON File Names
    private enum FileName {
        static let dataTypeSchemas = "Common/dataTypeSchemas.json"
        static let timeSeriesData = "Common/timeSeriesData.json"
        static let dailyStats = "Common/dailyStats.json"
        static let analysisCards = "Insight/analysisCards.json"
        static let dashboardData = "Insight/dashboardData.json"
        static let orbVisualization = "Insight/orbVisualization.json"
        static let dailyGems = "Home/dailyGems.json"
        static let userStats = "Home/userStats.json"
        static let userProfile = "Status/userProfile.json"
        static let achievements = "Status/achievements.json"
        static let valueAnalysis = "Status/valueAnalysis.json"
        static let goalProgramProgress = "Goal/goalProgramProgress.json"
        static let goalProgressHistory = "Goal/goalProgressHistory.json"
    }
    
    // MARK: - JSON Encoder/Decoder
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    // MARK: - Mock Data Storage
    private var mockDataPoints: [TimeSeriesDataPoint] = []
    private var mockDailyGems: [DailyGem] = []
    private var mockDailyStats: [DailyStats] = []
    private var mockUserStats: UserStats?
    private var mockUserProfile: UserProfile?
    private var mockAchievements: [Achievement] = []
    private var mockValueAnalysis: ValueAnalysis?
    private var mockAnalysisCards: [InsightAnalysisCard] = []
    private var mockDashboardData: [String: [DashboardItem]] = [:]
    private var mockOrbVisualization: OrbVisualization?
    private var mockProgramEnrollments: [ProgramEnrollment] = []
    private var dataTypeSchemas: [DataTypeSchema] = []
    
    // Mock User IDs
    private let mockAccountId = "mockFirebaseUID123456789"
    private let mockAnonymousUserId = UUID()
    
    private init() {
        setupDataDirectory()
        loadAllData()
    }
    
    // MARK: - Methods
    private func setupDataDirectory() {
        try? fileManager.createDirectory(at: mockDataDirectory, withIntermediateDirectories: true, attributes: nil)
    }
    
    private func saveJSON<T: Encodable>(_ object: T, to fileName: String) {
        // Implementation omitted for brevity in this fix, assumes ability to save to fileURL(for: fileName)
    }
    
    private func fileURL(for fileName: String) -> URL {
        return mockDataDirectory.appendingPathComponent(fileName)
    }
    
    private func loadJSON<T: Decodable>(_ type: T.Type, from fileName: String, isSilent: Bool = false) -> T? {
        return nil // Force generator
    }
    
    private func loadAllData() {
        mockDailyGems = loadJSON([DailyGem].self, from: FileName.dailyGems) ?? []
        mockDataPoints = loadJSON([TimeSeriesDataPoint].self, from: FileName.timeSeriesData) ?? []
        mockDailyStats = loadJSON([DailyStats].self, from: FileName.dailyStats) ?? []
        mockUserStats = loadJSON(UserStats.self, from: FileName.userStats)
        mockUserProfile = loadJSON(UserProfile.self, from: FileName.userProfile)
        
        if mockUserStats == nil || mockUserProfile == nil {
            generateMockData()
        }
    }
    
    // MARK: - Data Generation
    private func generateMockData() {
        let calendar = Calendar.current
        let today = Date()
        
        mockDataPoints = []
        mockDailyGems = []
        mockDailyStats = []
        
        for dayOffset in 1..<30 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // 1. World Context (Fixed)
            // 1. World Context (Merged)
            let world = WorldContext(
                weather: .clear,
                location: .home,
                dayPhase: .night,
                weekday: calendar.component(.weekday, from: date),
                isHoliday: false,
                timeZoneIdentifier: TimeZone.current.identifier
            )
            
            // 2. Internal State (s)
            let mockMood = Double.random(in: -50...50)
            let mockEnergy = Double.random(in: 30...90)
            let state = InternalState(
                mood: mockMood,
                energy: mockEnergy,
                moodValues: Array(repeating: mockMood, count: 7),
                energyValues: Array(repeating: mockEnergy, count: 7),
                curveControlHours: [7.0, 9.6, 12.3, 15.0, 17.6, 20.3, 23.0]
            )
            
            // 3. Actions (a) (Fixed)
            let intervention = Intervention(
                id: UUID(),
                type: .rest, 
                amount: 600, // Duration in seconds
                mindset: .relax // Added missing parameter
            )
            
            // 4. Outcome (o)
            let outcome = Outcome(
                focusLevel: Double.random(in: 40...100),
                detectedMotion: .stationary
            )
            
            // 5. Optimality (O)
            let optimality = Optimality(fulfillment: Double.random(in: 3.0...5.0))
            
            let dataPoint = TimeSeriesDataPoint(
                id: UUID(),
                anonymousUserId: mockAnonymousUserId,
                timestamp: date,
                world: world,
                actions: [intervention],
                state: state,
                outcome: outcome,
                optimality: optimality,
                notes: "Sample journal for \(date)"
            )
            
            mockDataPoints.append(dataPoint)
            mockDailyGems.append(createMockDailyGem(date: date, dataPointIds: [dataPoint.id.uuidString]))
            mockDailyStats.append(createMockDailyStats(date: date, dataPoints: [dataPoint]))
            mockAchievements = createMockAchievements() // Ensure achievements are created
            mockValueAnalysis = createMockValueAnalysis() // Ensure value analysis is created
        }
        
        mockUserStats = createMockUserStats()
        mockUserProfile = createMockUserProfile()
    }
    
    private func createMockDailyGem(date: Date, dataPointIds: [String]) -> DailyGem {
        let gemTypes: [GemType] = [.sphere, .diamond, .crystal, .prism]
        let colorThemes: [ColorTheme] = [.teal, .amber, .tiger, .blue]
        
        return DailyGem(
            id: UUID(),
            accountId: mockAccountId,
            date: date,
            gemType: gemTypes.randomElement() ?? .sphere,
            brightness: Double.random(in: 0.6...1.0),
            uncertainty: Double.random(in: 0.1...0.4),
            dataPointIds: dataPointIds,
            colorTheme: colorThemes.randomElement() ?? .teal,
            createdAt: date
        )
    }
    
    private func createMockDailyStats(date: Date, dataPoints: [TimeSeriesDataPoint]) -> DailyStats {
        return DailyStats(
            accountId: mockAccountId,
            date: date,
            totalDataPoints: dataPoints.count,
            notesCount: dataPoints.filter { $0.notes != nil }.count,
            mindScore: 0.8,
            behaviorScore: 0.7,
            physicalScore: 0.6,
            overallScore: 0.7,
            mindCompleteness: 0.8,
            behaviorCompleteness: 0.8,
            physicalCompleteness: 0.8,
            overallCompleteness: 0.8,
            notesByCategory: ["general": 1],
            dataSourceCounts: ["manual": dataPoints.count]
        )
    }
    
    private func createMockUserStats() -> UserStats {
        return UserStats(
            accountId: "mock_user",
            totalDataPoints: mockDataPoints.count,
            totalGems: mockDailyGems.count,
            streakDays: 5,
            lastRecordedAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createMockUserProfile() -> UserProfile {
        return UserProfile(
            accountId: mockAccountId,
            displayName: "Test User",
            email: "test@example.com",
            profileImageURL: nil,
            backgroundImageURL: nil,
            createdAt: Date(),
            lastActiveAt: Date(),
            preferences: UserPreferences(theme: .system, notificationsEnabled: true, language: "en", timeZone: "UTC"),
            onboardingState: OnboardingState(isCompleted: true, completedSteps: [], selectedGoals: [], completedAt: Date(), skippedSteps: []),
            initialGoals: [],
            firstJournalDate: Date(),
            enabledDataTypes: [],
            anonymizationLevel: .none,
            permissions: nil
        )
    }
    
    private func createMockAchievements() -> [Achievement] {
        return [
            Achievement(id: UUID(), accountId: mockAccountId, programId: nil, title: "First Step", description: "First entry", category: .consistency, unlockedDate: Date(), isUnlocked: true, illustration3D: nil, colorScheme: [], iconName: "star.fill", createdAt: Date())
        ]
    }
    
    private func createMockValueAnalysis() -> ValueAnalysis {
        return ValueAnalysis(id: UUID(), accountId: mockAccountId, analysisDate: Date(), topValues: [], valueDistribution: [:], comparisonData: ComparisonData(userPercentile: 0, averageScore: 0, uniqueAspects: []), insights: [], createdAt: Date())
    }

    // MARK: - DataServiceProtocol Methods
    
    func fetchDataPoints(for date: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        let points = mockDataPoints.filter { $0.timestamp >= start && $0.timestamp < end }
        return Just(points).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchDataPoints(from startDate: Date, to endDate: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error> {
        let points = mockDataPoints.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
        return Just(points).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func saveDataPoint(_ dataPoint: TimeSeriesDataPoint) -> AnyPublisher<TimeSeriesDataPoint, Error> {
        if let idx = mockDataPoints.firstIndex(where: { $0.id == dataPoint.id }) {
            mockDataPoints[idx] = dataPoint
        } else {
            mockDataPoints.append(dataPoint)
        }
        return Just(dataPoint).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    // MISSING STUB ADDED
    func saveData(_ dataPoint: TimeSeriesDataPoint, for category: DataCategory) async throws {
        // Async version of saveDataPoint
        if let idx = mockDataPoints.firstIndex(where: { $0.id == dataPoint.id }) {
            mockDataPoints[idx] = dataPoint
        } else {
            mockDataPoints.append(dataPoint)
        }
    }
    
    func deleteDataPoint(_ id: UUID) -> AnyPublisher<Void, Error> {
        mockDataPoints.removeAll { $0.id == id }
        return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchDailyGems(from startDate: Date, to endDate: Date) -> AnyPublisher<[DailyGem], Error> {
        return Just(mockDailyGems).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchDailyGem(for date: Date) -> AnyPublisher<DailyGem?, Error> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let gem = mockDailyGems.first { calendar.isDate($0.date, inSameDayAs: start) }
        return Just(gem).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func saveDailyGem(_ gem: DailyGem) -> AnyPublisher<DailyGem, Error> {
        if let idx = mockDailyGems.firstIndex(where: { $0.id == gem.id }) {
            mockDailyGems[idx] = gem
        } else {
            mockDailyGems.append(gem)
        }
        return Just(gem).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchDailyStats(for date: Date) -> AnyPublisher<DailyStats?, Error> {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let stats = mockDailyStats.first { calendar.isDate($0.date, inSameDayAs: start) }
        return Just(stats).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchDailyStats(from startDate: Date, to endDate: Date) -> AnyPublisher<[DailyStats], Error> {
        return Just(mockDailyStats).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchUserStats() -> AnyPublisher<UserStats, Error> {
        guard let stats = mockUserStats else {
            return Fail(error: NSError(domain: "Mock", code: 404, userInfo: nil)).eraseToAnyPublisher()
        }
        return Just(stats).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func updateUserStats(_ stats: UserStats) -> AnyPublisher<UserStats, Error> {
        mockUserStats = stats
        return Just(stats).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchUserProfile() -> AnyPublisher<UserProfile, Error> {
        guard let profile = mockUserProfile else {
            return Fail(error: NSError(domain: "Mock", code: 404, userInfo: nil)).eraseToAnyPublisher()
        }
        return Just(profile).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func saveUserProfile(_ profile: UserProfile) -> AnyPublisher<UserProfile, Error> {
        mockUserProfile = profile
        return Just(profile).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func updateUserProfile(_ profile: UserProfile) -> AnyPublisher<UserProfile, Error> {
        mockUserProfile = profile
        return Just(profile).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    // MARK: - Goal/Program Stubs
    func fetchGoals() -> AnyPublisher<[Goal], Error> { return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func fetchGoal(id: UUID) -> AnyPublisher<Goal?, Error> { return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func saveGoal(_ goal: Goal) -> AnyPublisher<Goal, Error> { return Just(goal).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func updateGoal(_ goal: Goal) -> AnyPublisher<Goal, Error> { return Just(goal).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func deleteGoal(id: UUID) -> AnyPublisher<Void, Error> { return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
    
    func fetchPrograms() -> AnyPublisher<[Program], Error> { return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func fetchProgram(id: UUID) -> AnyPublisher<Program?, Error> { return Just(nil).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func fetchRecommendedPrograms(for userId: String) -> AnyPublisher<[Program], Error> { return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func saveProgram(_ program: Program) -> AnyPublisher<Void, Error> { return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
    
    func fetchProgramMissions(for programId: UUID) -> AnyPublisher<[ProgramMission], Error> { return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func fetchProgramMetrics(for programId: UUID) -> AnyPublisher<[ProgramSuccessMetric], Error> { return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher() }
    
    func saveProgramMission(programId: UUID, mission: ProgramMission) -> AnyPublisher<Void, Error> { return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func saveProgramStory(programId: UUID, story: InsightStory) -> AnyPublisher<Void, Error> { return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
    func saveProgramMetric(programId: UUID, metric: ProgramSuccessMetric) -> AnyPublisher<Void, Error> { return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() }
    
    func createProgramEnrollment(_ enrollment: ProgramEnrollment) -> AnyPublisher<ProgramEnrollment, Error> {
        mockProgramEnrollments.append(enrollment)
        return Just(enrollment).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchProgramEnrollments() -> AnyPublisher<[ProgramEnrollment], Error> {
        return Just(mockProgramEnrollments).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    // MISSING STUBS ADDED
    func fetchProgramEnrollment(id: UUID) -> AnyPublisher<ProgramEnrollment?, Error> {
        let enrollment = mockProgramEnrollments.first { $0.id == id }
        return Just(enrollment).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func updateProgramEnrollment(_ enrollment: ProgramEnrollment) -> AnyPublisher<ProgramEnrollment, Error> {
        if let idx = mockProgramEnrollments.firstIndex(where: { $0.id == enrollment.id }) {
            mockProgramEnrollments[idx] = enrollment
        } else {
            mockProgramEnrollments.append(enrollment)
        }
        return Just(enrollment).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchAchievements() -> AnyPublisher<[Achievement], Error> {
        return Just(mockAchievements).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchValueAnalysis() -> AnyPublisher<ValueAnalysis, Error> {
        guard let analysis = mockValueAnalysis else {
            return Fail(error: NSError(domain: "Mock", code: 404, userInfo: nil)).eraseToAnyPublisher()
        }
        return Just(analysis).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchAnalysisCards() -> AnyPublisher<[InsightAnalysisCard], Error> {
        return Just(mockAnalysisCards).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    // Added for ProgramStoryViewModel compatibility
    func loadOngoingProgramStories() -> [ProgramStory] {
        // Return mock stories if available, or empty list
        // In a real implementation this might fetch from a local JSON or cache
        return []
    }
    
    func fetchInsightStory(for cardId: String) -> AnyPublisher<InsightStory, Error> {
        // Return a dummy story or try to load
        let story = InsightStory(id: cardId, title: "Mock Story", subtitle: "For testing", pages: [], isLiked: false)
        return Just(story).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func fetchDashboardData() -> AnyPublisher<[String : [DashboardItem]], Error> {
        return Just(mockDashboardData).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    // Schema Management
    func addDataTypeSchema(_ schema: DataTypeSchema) { dataTypeSchemas.append(schema) }
    func removeDataTypeSchema(_ schemaId: UUID) { dataTypeSchemas.removeAll { $0.id == schemaId } }
    func setSchemaEnabled(_ schemaId: UUID, enabled: Bool) {
        if let idx = dataTypeSchemas.firstIndex(where: { $0.id == schemaId }) {
            dataTypeSchemas[idx].isEnabled = enabled
        }
    }
    func getEnabledSchemas() -> [DataTypeSchema] { return dataTypeSchemas.filter { $0.isEnabled } }
    
    // Protocol requires these exactly
    func getSchemas(for category: DataCategory) -> [DataTypeSchema] {
        return dataTypeSchemas.filter { $0.category == category }
    }
    func getAllSchemas() -> [DataTypeSchema] { return dataTypeSchemas }
}

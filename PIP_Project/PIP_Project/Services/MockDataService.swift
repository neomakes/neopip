//
//  MockDataService.swift
//  PIP_Project
//
//  MockData Service: Provides mock data for UI verification without Firebase
//

import Foundation
import Combine

/// MockData service for UI verification before Firebase integration
@MainActor
class MockDataService: DataServiceProtocol {
    static let shared = MockDataService()
    
    // MARK: - File Management
    private let fileManager = FileManager.default
    private lazy var mockDataDirectory: URL = {
        // 프로젝트 루트의 MockData 폴더 사용
        let projectRoot = URL(fileURLWithPath: #file)
            .deletingLastPathComponent() // Services
            .deletingLastPathComponent() // PIP_Project
            .deletingLastPathComponent() // PIP_Project
        return projectRoot.appendingPathComponent("MockData")
    }()
    
    // MARK: - JSON File Names (Subdirectory Structure)
    private enum FileName {
        // Insight 페이지 데이터
        static let analysisCards = "Insight/analysisCards.json"
        
        // Home 페이지 데이터
        static let dailyGems = "Home/dailyGems.json"
        static let userStats = "Home/userStats.json"
        
        // Status 페이지 데이터
        static let userProfile = "Status/userProfile.json"
        static let achievements = "Status/achievements.json"
        static let valueAnalysis = "Status/valueAnalysis.json"
        
        // Write 페이지 데이터
        static let dataTypeSchemas = "Write/dataTypeSchemas.json"
        
        // 공통 데이터
        static let timeSeriesData = "Common/timeSeriesData.json"
        static let dailyStats = "Common/dailyStats.json"
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
    
    // MARK: - Data Type Schema Registry
    /// Dynamic data type definition registry
    /// In the actual app, loaded from Firebase or determined by user settings
    private var dataTypeSchemas: [DataTypeSchema] = []
    
    // Mock User IDs
    private let mockAccountId = UUID()
    private let mockAnonymousUserId = UUID()
    
    private init() {
        setupDataDirectory()
        loadAllData()
    }
    
    // MARK: - File Management Helpers
    private func setupDataDirectory() {
        do {
            try fileManager.createDirectory(at: mockDataDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create mock data directory: \(error)")
        }
    }
    
    private func fileURL(for fileName: String) -> URL {
        let fileURL = mockDataDirectory.appendingPathComponent(fileName)
        
        // 서브디렉토리가 있는 경우 디렉토리 생성
        let directoryURL = fileURL.deletingLastPathComponent()
        if directoryURL != mockDataDirectory {
            do {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create subdirectory: \(error)")
            }
        }
        
        return fileURL
    }
    
    private func saveJSON<T: Encodable>(_ object: T, to fileName: String) {
        let fileURL = fileURL(for: fileName)
        do {
            let data = try jsonEncoder.encode(object)
            try data.write(to: fileURL, options: .atomic)
            print("✅ Saved \(fileName)")
        } catch {
            print("❌ Failed to save \(fileName): \(error)")
        }
    }
    
    private func loadJSON<T: Decodable>(_ type: T.Type, from fileName: String) -> T? {
        let fileURL = fileURL(for: fileName)
        do {
            let data = try Data(contentsOf: fileURL)
            let object = try jsonDecoder.decode(type, from: data)
            print("✅ Loaded \(fileName)")
            return object
        } catch {
            print("❌ Failed to load \(fileName): \(error)")
            return nil
        }
    }
    
    private func loadAllData() {
        // Load data type schemas first
        if let schemas = loadJSON([DataTypeSchema].self, from: FileName.dataTypeSchemas) {
            dataTypeSchemas = schemas
        } else {
            initializeDataTypeSchemas()
            saveJSON(dataTypeSchemas, to: FileName.dataTypeSchemas)
        }
        
        // Load mock data
        mockAnalysisCards = loadJSON([InsightAnalysisCard].self, from: FileName.analysisCards) ?? []
        mockUserStats = loadJSON(UserStats.self, from: FileName.userStats)
        mockUserProfile = loadJSON(UserProfile.self, from: FileName.userProfile)
        mockAchievements = loadJSON([Achievement].self, from: FileName.achievements) ?? []
        mockValueAnalysis = loadJSON(ValueAnalysis.self, from: FileName.valueAnalysis)
        mockDailyGems = loadJSON([DailyGem].self, from: FileName.dailyGems) ?? []
        mockDataPoints = loadJSON([TimeSeriesDataPoint].self, from: FileName.timeSeriesData) ?? []
        mockDailyStats = loadJSON([DailyStats].self, from: FileName.dailyStats) ?? []
        
        // Generate missing data
        if mockAnalysisCards.isEmpty || mockUserStats == nil || mockUserProfile == nil {
            generateMockData()
            saveAllData()
        }
    }
    
    private func saveAllData() {
        saveJSON(mockAnalysisCards, to: FileName.analysisCards)
        if let stats = mockUserStats { saveJSON(stats, to: FileName.userStats) }
        if let profile = mockUserProfile { saveJSON(profile, to: FileName.userProfile) }
        saveJSON(mockAchievements, to: FileName.achievements)
        if let analysis = mockValueAnalysis { saveJSON(analysis, to: FileName.valueAnalysis) }
        saveJSON(mockDailyGems, to: FileName.dailyGems)
        saveJSON(mockDataPoints, to: FileName.timeSeriesData)
        saveJSON(mockDailyStats, to: FileName.dailyStats)
        saveJSON(dataTypeSchemas, to: FileName.dataTypeSchemas)
    }
    
    // MARK: - Data Type Schema Initialization
    /// Initialize basic data type schemas
    /// Can be dynamically added/removed as needed
    private func initializeDataTypeSchemas() {
        let now = Date()
        
        // Mind Category
        // - mood: Overall emotional state
        // - stress: Stress level
        // - energy: Energy level
        // - focus: Focus/concentration level
        dataTypeSchemas.append(DataTypeSchema(
            id: UUID(),
            name: "mood",
            displayName: "Mood",
            category: .mind,
            dataType: .double,
            unit: "pts",
            range: ValueRange(min: 0, max: 100, step: 1),
            sensitivity: .medium,
            collectionMethod: .manual,
            isRequired: true,
            isEnabled: true,
            description: "Overall mood state (0-100)",
            createdAt: now,
            updatedAt: now
        ))
        
        dataTypeSchemas.append(DataTypeSchema(
            id: UUID(),
            name: "stress",
            displayName: "Stress",
            category: .mind,
            dataType: .double,
            unit: "pts",
            range: ValueRange(min: 0, max: 100, step: 1),
            sensitivity: .medium,
            collectionMethod: .manual,
            isRequired: false,
            isEnabled: true,
            description: "Stress level (0-100)",
            createdAt: now,
            updatedAt: now
        ))
        
        dataTypeSchemas.append(DataTypeSchema(
            id: UUID(),
            name: "energy",
            displayName: "Energy",
            category: .mind,
            dataType: .double,
            unit: "pts",
            range: ValueRange(min: 0, max: 100, step: 1),
            sensitivity: .low,
            collectionMethod: .manual,
            isRequired: false,
            isEnabled: true,
            description: "Energy level (0-100)",
            createdAt: now,
            updatedAt: now
        ))
        
        dataTypeSchemas.append(DataTypeSchema(
            id: UUID(),
            name: "focus",
            displayName: "Focus",
            category: .mind,
            dataType: .double,
            unit: "pts",
            range: ValueRange(min: 0, max: 100, step: 1),
            sensitivity: .low,
            collectionMethod: .manual,
            isRequired: false,
            isEnabled: true,
            description: "Focus/concentration level (0-100)",
            createdAt: now,
            updatedAt: now
        ))
        
        // Behavior Category
        // - productivity: Work/task productivity
        // - socialActivity: Social interaction level
        // - digitalDistraction: Digital device distraction
        // - exploration: New experience exploration
        dataTypeSchemas.append(DataTypeSchema(
            id: UUID(),
            name: "productivity",
            displayName: "Productivity",
            category: .behavior,
            dataType: .double,
            unit: "pts",
            range: ValueRange(min: 0, max: 100, step: 1),
            sensitivity: .low,
            collectionMethod: .manual,
            isRequired: false,
            isEnabled: true,
            description: "Productivity level (0-100)",
            createdAt: now,
            updatedAt: now
        ))
        
        dataTypeSchemas.append(DataTypeSchema(
            id: UUID(),
            name: "socialActivity",
            displayName: "Social Activity",
            category: .behavior,
            dataType: .double,
            unit: "pts",
            range: ValueRange(min: 0, max: 100, step: 1),
            sensitivity: .medium,
            collectionMethod: .manual,
            isRequired: false,
            isEnabled: true,
            description: "Social activity level (0-100)",
            createdAt: now,
            updatedAt: now
        ))
        
        dataTypeSchemas.append(DataTypeSchema(
            id: UUID(),
            name: "digitalDistraction",
            displayName: "Digital Distraction",
            category: .behavior,
            dataType: .double,
            unit: "pts",
            range: ValueRange(min: 0, max: 100, step: 1),
            sensitivity: .medium,
            collectionMethod: .screenTime,
            isRequired: false,
            isEnabled: true,
            description: "Digital device distraction level (0-100)",
            createdAt: now,
            updatedAt: now
        ))
        
        dataTypeSchemas.append(DataTypeSchema(
            id: UUID(),
            name: "exploration",
            displayName: "Exploration",
            category: .behavior,
            dataType: .double,
            unit: "pts",
            range: ValueRange(min: 0, max: 100, step: 1),
            sensitivity: .low,
            collectionMethod: .manual,
            isRequired: false,
            isEnabled: true,
            description: "New experience exploration level (0-100)",
            createdAt: now,
            updatedAt: now
        ))
        
        // Physical Category
        // - sleepScore: Sleep quality score
        // - fatigue: Fatigue level
        // - activityLevel: Physical activity level
        // - nutrition: Nutrition quality score
        dataTypeSchemas.append(DataTypeSchema(
            id: UUID(),
            name: "sleepScore",
            displayName: "Sleep Score",
            category: .physical,
            dataType: .double,
            unit: "pts",
            range: ValueRange(min: 0, max: 100, step: 1),
            sensitivity: .medium,
            collectionMethod: .healthKit,
            isRequired: false,
            isEnabled: true,
            description: "Sleep quality score (0-100)",
            createdAt: now,
            updatedAt: now
        ))
        
        dataTypeSchemas.append(DataTypeSchema(
            id: UUID(),
            name: "fatigue",
            displayName: "Fatigue",
            category: .physical,
            dataType: .double,
            unit: "pts",
            range: ValueRange(min: 0, max: 100, step: 1),
            sensitivity: .low,
            collectionMethod: .manual,
            isRequired: false,
            isEnabled: true,
            description: "Fatigue level (0-100)",
            createdAt: now,
            updatedAt: now
        ))
        
        dataTypeSchemas.append(DataTypeSchema(
            id: UUID(),
            name: "activityLevel",
            displayName: "Activity Level",
            category: .physical,
            dataType: .double,
            unit: "pts",
            range: ValueRange(min: 0, max: 100, step: 1),
            sensitivity: .low,
            collectionMethod: .healthKit,
            isRequired: false,
            isEnabled: true,
            description: "Physical activity level (0-100)",
            createdAt: now,
            updatedAt: now
        ))
        
        dataTypeSchemas.append(DataTypeSchema(
            id: UUID(),
            name: "nutrition",
            displayName: "Nutrition",
            category: .physical,
            dataType: .double,
            unit: "pts",
            range: ValueRange(min: 0, max: 100, step: 1),
            sensitivity: .medium,
            collectionMethod: .manual,
            isRequired: false,
            isEnabled: true,
            description: "Nutrition quality score (0-100)",
            createdAt: now,
            updatedAt: now
        ))
    }
    
    // MARK: - Public Methods for Schema Management
    /// 데이터 타입 스키마 추가 (동적 확장용)
    /// 새로운 데이터 타입을 추가하려면 이 메서드를 사용하세요.
    /// 
    /// 예시:
    /// ```swift
    /// let newSchema = DataTypeSchema(
    ///     id: UUID(),
    ///     name: "creativity",
    ///     displayName: "창의성",
    ///     category: .cognitive,
    ///     dataType: .double,
    ///     unit: "점",
    ///     range: ValueRange(min: 0, max: 100, step: 1),
    ///     sensitivity: .low,
    ///     collectionMethod: .manual,
    ///     isRequired: false,
    ///     isEnabled: true,
    ///     description: "창의성 수준 (0-100)",
    ///     createdAt: Date(),
    ///     updatedAt: Date()
    /// )
    /// MockDataService.shared.addDataTypeSchema(newSchema)
    /// ```
    func addDataTypeSchema(_ schema: DataTypeSchema) {
        if !dataTypeSchemas.contains(where: { $0.id == schema.id }) {
            dataTypeSchemas.append(schema)
            // 스키마 추가 후 데이터 재생성 (선택사항)
            // generateMockData()
        }
    }
    
    /// 데이터 타입 스키마 제거
    func removeDataTypeSchema(_ schemaId: UUID) {
        dataTypeSchemas.removeAll { $0.id == schemaId }
    }
    
    /// 데이터 타입 스키마 활성화/비활성화
    func setSchemaEnabled(_ schemaId: UUID, enabled: Bool) {
        if let index = dataTypeSchemas.firstIndex(where: { $0.id == schemaId }) {
            dataTypeSchemas[index].isEnabled = enabled
        }
    }
    
    /// 활성화된 데이터 타입 스키마 가져오기
    func getEnabledSchemas() -> [DataTypeSchema] {
        return dataTypeSchemas.filter { $0.isEnabled }
    }
    
    /// 특정 카테고리의 데이터 타입 스키마 가져오기
    func getSchemas(for category: DataCategory) -> [DataTypeSchema] {
        return dataTypeSchemas.filter { $0.category == category && $0.isEnabled }
    }
    
    /// 모든 데이터 타입 스키마 가져오기 (활성화 여부 무관)
    func getAllSchemas() -> [DataTypeSchema] {
        return dataTypeSchemas
    }
    
    // MARK: - Data Generation
    private func generateMockData() {
        let calendar = Calendar.current
        let today = Date()
        
        // 최근 30일간의 데이터 생성 (오늘 제외 - dayOffset 1부터 시작)
        for dayOffset in 1..<30 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            
            // 하루에 하나의 '통합 데이터 포인트' 생성
            // 시간은 저녁 시간대로 설정
            let hour = Int.random(in: 20...22)
            guard let timestamp = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date) else { continue }
            
            // 모든 카테고리의 활성화된 스키마 가져오기
            let allEnabledSchemas = getEnabledSchemas()
            var combinedValues: [String: DataValue] = [:]
            
            // 모든 스키마에 대해 값 생성
            for schema in allEnabledSchemas {
                let min = schema.range?.min ?? 0.0
                let max = schema.range?.max ?? 100.0
                
                switch schema.dataType {
                case .double:
                    let value = Double.random(in: min...max)
                    combinedValues[schema.name] = .double(value)
                case .integer:
                    let value = Int.random(in: Int(min)...Int(max))
                    combinedValues[schema.name] = .integer(value)
                case .boolean:
                    combinedValues[schema.name] = .boolean(Bool.random())
                case .string:
                    let examples = ["Good", "Normal", "Bad"]
                    combinedValues[schema.name] = .string(examples.randomElement() ?? "Normal")
                default:
                    break
                }
            }
            
            let journalTemplates = [
                "A productive day overall. Managed to finish the main tasks.",
                "Felt a bit low on energy, but pushed through. Social interaction was nice.",
                "Slept well and felt refreshed. A good day for physical activity.",
                "A fairly normal day. Nothing special to report.",
                "Feeling stressed from work, but managed to relax in the evening."
            ]

            let dataPoint = TimeSeriesDataPoint(
                timestamp: timestamp,
                category: nil, // 특정 카테고리에 속하지 않는 통합 데이터
                values: combinedValues,
                source: .manual,
                confidence: Double.random(in: 0.8...1.0),
                completeness: Double.random(in: 0.8...1.0),
                anonymousUserId: mockAnonymousUserId,
                notes: journalTemplates.randomElement(),
                tags: ["daily-summary", "journal"],
                context: nil
            )
            
            mockDataPoints.append(dataPoint)
            
            // DailyGem 생성
            let gem = createMockDailyGem(
                date: date,
                dataPointIds: [dataPoint.id.uuidString] // 단일 데이터 포인트 ID
            )
            mockDailyGems.append(gem)
            
            // DailyStats 생성
            let stats = createMockDailyStats(
                date: date,
                dataPoints: [dataPoint] // 단일 데이터 포인트
            )
            mockDailyStats.append(stats)
        }
        
        // UserStats 생성
        mockUserStats = createMockUserStats()
        
        // UserProfile 생성
        mockUserProfile = createMockUserProfile()
        
        // Achievement 생성
        mockAchievements = createMockAchievements()
        
        // ValueAnalysis 생성
        mockValueAnalysis = createMockValueAnalysis()
        
        // AnalysisCards 생성
        mockAnalysisCards = createMockAnalysisCards()
    }
    
    // MARK: - Helper Methods
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
        // 스키마 기반으로 카테고리별 점수 계산
        var mindScores: [Double] = []
        var behaviorScores: [Double] = []
        var physicalScores: [Double] = []
        
        // 각 카테고리의 스키마 가져오기
        let mindSchemas = getSchemas(for: .mind)
        let behaviorSchemas = getSchemas(for: .behavior)
        let physicalSchemas = getSchemas(for: .physical)
        
        // 데이터 포인트에서 각 카테고리별 점수 추출
        for point in dataPoints {
            // 마음 카테고리 점수
            for schema in mindSchemas {
                if let value = point.values[schema.name],
                   case .double(let doubleValue) = value {
                    mindScores.append(doubleValue / 100.0)
                } else if let value = point.values[schema.name],
                          case .integer(let intValue) = value {
                    mindScores.append(Double(intValue) / 100.0)
                }
            }
            
            // 행동 카테고리 점수
            for schema in behaviorSchemas {
                if let value = point.values[schema.name],
                   case .double(let doubleValue) = value {
                    behaviorScores.append(doubleValue / 100.0)
                } else if let value = point.values[schema.name],
                          case .integer(let intValue) = value {
                    behaviorScores.append(Double(intValue) / 100.0)
                }
            }
            
            // 신체 카테고리 점수
            for schema in physicalSchemas {
                if let value = point.values[schema.name],
                   case .double(let doubleValue) = value {
                    physicalScores.append(doubleValue / 100.0)
                } else if let value = point.values[schema.name],
                          case .integer(let intValue) = value {
                    physicalScores.append(Double(intValue) / 100.0)
                }
            }
        }
        
        // 평균 계산
        let mindScore = mindScores.isEmpty ? nil : mindScores.reduce(0, +) / Double(mindScores.count)
        let behaviorScore = behaviorScores.isEmpty ? nil : behaviorScores.reduce(0, +) / Double(behaviorScores.count)
        let physicalScore = physicalScores.isEmpty ? nil : physicalScores.reduce(0, +) / Double(physicalScores.count)
        
        let overallScore = [mindScore, behaviorScore, physicalScore]
            .compactMap { $0 }
            .reduce(0, +) / 3.0
        
        return DailyStats(
            accountId: mockAccountId,
            date: date,
            totalDataPoints: dataPoints.count,
            notesCount: dataPoints.filter { $0.notes != nil }.count,
            mindScore: mindScore,
            behaviorScore: behaviorScore,
            physicalScore: physicalScore,
            overallScore: overallScore,
            mindCompleteness: Double.random(in: 0.7...1.0),
            behaviorCompleteness: Double.random(in: 0.6...1.0),
            physicalCompleteness: Double.random(in: 0.5...1.0),
            overallCompleteness: Double.random(in: 0.6...1.0),
            notesByCategory: ["mind": dataPoints.filter { $0.category == .mind && $0.notes != nil }.count],
            dataSourceCounts: ["manual": dataPoints.count]
        )
    }
    
    private func createMockUserStats() -> UserStats {
        let totalDataPoints = mockDataPoints.count
        let totalDaysActive = Set(mockDataPoints.map { Calendar.current.startOfDay(for: $0.date) }).count
        
        // 연속 기록 일수 계산
        let sortedDates = Set(mockDataPoints.map { Calendar.current.startOfDay(for: $0.date) })
            .sorted(by: >)  // 내림차순: 최신 날짜부터
        
        var currentStreak = 0
        
        // 가장 최신 기록부터 역순으로 연속된 날짜 세기
        if !sortedDates.isEmpty {
            let mostRecentDate = sortedDates[0]
            
            for (index, date) in sortedDates.enumerated() {
                let expectedDate = Calendar.current.date(byAdding: .day, value: -index, to: mostRecentDate)!
                if Calendar.current.isDate(date, inSameDayAs: expectedDate) {
                    currentStreak += 1
                } else {
                    break
                }
            }
        }
        
        return UserStats(
            accountId: mockAccountId,
            totalDataPoints: totalDataPoints,
            totalDaysActive: totalDaysActive,
            currentStreak: currentStreak,
            longestStreak: currentStreak,
            totalGoalsCompleted: 2,
            totalProgramsCompleted: 1,
            averageEmotionScore: 0.72,
            totalGemsCreated: mockDailyGems.count,
            lastUpdated: Date()
        )
    }
    
    private func createMockUserProfile() -> UserProfile {
        return UserProfile(
            accountId: mockAccountId,
            displayName: "NEO",
            email: "neo@pip.app",
            profileImageURL: "profile_example",
            backgroundImageURL: nil,
            createdAt: Date(timeIntervalSinceNow: -30 * 86400), // 30일 전
            lastActiveAt: Date(),
            preferences: UserPreferences(
                theme: .dark,
                notificationsEnabled: true,
                language: "ko",
                timeZone: "Asia/Seoul"
            ),
            onboardingState: OnboardingState(
                isCompleted: true,
                completedSteps: ["welcome", "goalSelection", "dataCollectionIntro"],
                selectedGoals: ["wellness", "productivity"],
                completedAt: Date(timeIntervalSinceNow: -25 * 86400),
                skippedSteps: []
            ),
            initialGoals: [.wellness, .productivity],
            firstJournalDate: Date(timeIntervalSinceNow: -25 * 86400)
        )
    }
    
    private func createMockAchievements() -> [Achievement] {
        let achievementData = [
            (title: "First Steps", category: AchievementCategory.consistency, colorScheme: ["#3B82F6", "#1E40AF"]),
            (title: "Weekly Warrior", category: AchievementCategory.growth, colorScheme: ["#8B5CF6", "#6D28D9"]),
            (title: "Mind Master", category: AchievementCategory.mastery, colorScheme: ["#EC4899", "#BE185D"]),
            (title: "Insight Seeker", category: AchievementCategory.exploration, colorScheme: ["#F59E0B", "#B45309"]),
            (title: "30 Days Strong", category: AchievementCategory.consistency, colorScheme: ["#10B981", "#047857"]),
        ]
        
        return achievementData.enumerated().map { index, data in
            Achievement(
                id: UUID(),
                accountId: mockAccountId,
                programId: UUID(),
                title: data.title,
                description: "Unlocked on \(Date().formatted(date: .abbreviated, time: .omitted))",
                category: data.category,
                unlockedDate: Date(timeIntervalSinceNow: -Double(index * 3) * 86400),
                isUnlocked: true,
                illustration3D: AchievementIllustration3D(
                    modelId: "achievement_model_\(index)",
                    modelURL: nil,
                    previewImageURL: "achievement_\(index)",
                    colorScheme: data.colorScheme
                ),
                colorScheme: data.colorScheme,
                iconName: "star.fill",
                createdAt: Date(timeIntervalSinceNow: -Double(index * 3) * 86400)
            )
        }
    }
    
    private func createMockValueAnalysis() -> ValueAnalysis {
        let valueItems = [
            ValueItem(id: UUID(), name: "Health", score: 0.85, description: "Physical and mental wellbeing", trend: .increasing),
            ValueItem(id: UUID(), name: "Growth", score: 0.72, description: "Personal development", trend: .increasing),
            ValueItem(id: UUID(), name: "Connection", score: 0.68, description: "Relationships and community", trend: .stable),
            ValueItem(id: UUID(), name: "Achievement", score: 0.78, description: "Goals and accomplishments", trend: .increasing),
            ValueItem(id: UUID(), name: "Balance", score: 0.65, description: "Work-life harmony", trend: .stable),
            ValueItem(id: UUID(), name: "Creativity", score: 0.70, description: "Self-expression and innovation", trend: .increasing),
        ]
        
        let valueDistribution: [String: Double] = [
            "health": 0.85,
            "growth": 0.72,
            "connection": 0.68,
            "achievement": 0.78,
            "balance": 0.65,
            "creativity": 0.70
        ]
        
        return ValueAnalysis(
            id: UUID(),
            accountId: mockAccountId,
            analysisDate: Date(),
            topValues: valueItems,
            valueDistribution: valueDistribution,
            comparisonData: ComparisonData(
                userPercentile: 75.5,
                averageScore: 0.68,
                uniqueAspects: ["Strong focus on health and wellbeing", "Consistent growth mindset", "Values balance in life"]
            ),
            insights: [
                "You prioritize health more than average users",
                "Your value scores are well-balanced across all dimensions",
                "Growth is increasingly important to you"
            ],
            createdAt: Date()
        )
    }
    
    // MARK: - DataServiceProtocol Implementation
    
    func fetchDataPoints(for date: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let filtered = mockDataPoints.filter { dataPoint in
            dataPoint.date >= startOfDay && dataPoint.date < endOfDay
        }
        
        return Just(filtered)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchDataPoints(from startDate: Date, to endDate: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error> {
        let filtered = mockDataPoints.filter { dataPoint in
            dataPoint.date >= startDate && dataPoint.date <= endDate
        }
        
        return Just(filtered)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func saveDataPoint(_ dataPoint: TimeSeriesDataPoint) -> AnyPublisher<TimeSeriesDataPoint, Error> {
        // Mock에서는 기존 항목 업데이트 또는 새로 추가
        if let index = mockDataPoints.firstIndex(where: { $0.id == dataPoint.id }) {
            mockDataPoints[index] = dataPoint
        } else {
            mockDataPoints.append(dataPoint)
        }
        
        // Save to file
        saveJSON(mockDataPoints, to: FileName.timeSeriesData)
        
        return Just(dataPoint)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func deleteDataPoint(_ id: UUID) -> AnyPublisher<Void, Error> {
        mockDataPoints.removeAll { $0.id == id }
        
        // Save to file
        saveJSON(mockDataPoints, to: FileName.timeSeriesData)
        
        return Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchDailyGems(from startDate: Date, to endDate: Date) -> AnyPublisher<[DailyGem], Error> {
        let filtered = mockDailyGems.filter { gem in
            gem.date >= startDate && gem.date <= endDate
        }
        
        return Just(filtered.sorted { $0.date > $1.date })
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchDailyGem(for date: Date) -> AnyPublisher<DailyGem?, Error> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let gem = mockDailyGems.first { gem in
            calendar.isDate(gem.date, inSameDayAs: startOfDay)
        }
        
        return Just(gem)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func saveDailyGem(_ gem: DailyGem) -> AnyPublisher<DailyGem, Error> {
        if let index = mockDailyGems.firstIndex(where: { $0.id == gem.id }) {
            mockDailyGems[index] = gem
        } else {
            mockDailyGems.append(gem)
        }
        
        // Save to file
        saveJSON(mockDailyGems, to: FileName.dailyGems)
        
        return Just(gem)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchDailyStats(for date: Date) -> AnyPublisher<DailyStats?, Error> {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        let stats = mockDailyStats.first { stats in
            calendar.isDate(stats.date, inSameDayAs: startOfDay)
        }
        
        return Just(stats)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchDailyStats(from startDate: Date, to endDate: Date) -> AnyPublisher<[DailyStats], Error> {
        let filtered = mockDailyStats.filter { stats in
            stats.date >= startDate && stats.date <= endDate
        }
        
        return Just(filtered.sorted { $0.date > $1.date })
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchUserStats() -> AnyPublisher<UserStats, Error> {
        guard let stats = mockUserStats else {
            return Fail(error: NSError(domain: "MockDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "UserStats not found"]))
                .eraseToAnyPublisher()
        }
        
        return Just(stats)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func updateUserStats(_ stats: UserStats) -> AnyPublisher<UserStats, Error> {
        mockUserStats = stats
        return Just(stats)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchUserProfile() -> AnyPublisher<UserProfile, Error> {
        guard let profile = mockUserProfile else {
            return Fail(error: NSError(domain: "MockDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "UserProfile not found"]))
                .eraseToAnyPublisher()
        }
        
        return Just(profile)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchAchievements() -> AnyPublisher<[Achievement], Error> {
        return Just(mockAchievements)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func fetchValueAnalysis() -> AnyPublisher<ValueAnalysis, Error> {
        guard let analysis = mockValueAnalysis else {
            return Fail(error: NSError(domain: "MockDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "ValueAnalysis not found"]))
                .eraseToAnyPublisher()
        }
        
        return Just(analysis)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Save Data (async method)
    func saveData(_ dataPoint: TimeSeriesDataPoint, for category: DataCategory) async throws {
        var updatedDataPoint = dataPoint
        updatedDataPoint.category = category
        
        if let index = mockDataPoints.firstIndex(where: { $0.id == dataPoint.id }) {
            mockDataPoints[index] = updatedDataPoint
        } else {
            mockDataPoints.append(updatedDataPoint)
        }
        
        // Save to file
        saveJSON(mockDataPoints, to: FileName.timeSeriesData)
    }
    
    // MARK: - Analysis Cards
    func fetchAnalysisCards() -> AnyPublisher<[InsightAnalysisCard], Error> {
        return Just(mockAnalysisCards)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func createMockAnalysisCards() -> [InsightAnalysisCard] {
        let mockInsightId = UUID()
        let mockUserId = UUID()
        
        return [
            InsightAnalysisCard(
                id: UUID(),
                insightId: mockInsightId,
                anonymousUserId: mockUserId,
                title: "Weekly Mood Pattern Analysis",
                subtitle: "Your mood score averaged 0.72, up 5% from last week",
                cardType: .explanation,
                pages: [
                    AnalysisCardPage(
                        id: UUID(),
                        pageNumber: 1,
                        contentType: .text,
                        content: PageContent(
                            text: "Weekly Mood Pattern Analysis",
                            headline: "Positive changes are visible",
                            body: "Analysis of the last 7 days of data shows your mood score steadily increasing.",
                            mantra: nil
                        ),
                        visualizations: nil
                    )
                ],
                actionProposals: [
                    ActionProposal(
                        id: UUID(),
                        title: "Increase Meditation Time",
                        description: "Try 10 minutes of daily meditation to improve emotional stability",
                        actionType: .reminder,
                        targetDate: Date().addingTimeInterval(86400),
                        calendarEvent: nil,
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Add Walking Routine",
                        description: "Increase physical activity with 30-minute walks 3 times a week",
                        actionType: .calendar,
                        targetDate: Date().addingTimeInterval(172800),
                        calendarEvent: CalendarEvent(
                            title: "Walking",
                            description: "Walking for emotional health",
                            startDate: Date().addingTimeInterval(172800),
                            endDate: Date().addingTimeInterval(172800 + 1800),
                            location: "Nearby park",
                            notes: nil
                        ),
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Improve Sleep Pattern",
                        description: "Aim for 11 PM bedtime to improve sleep quality",
                        actionType: .alarm,
                        targetDate: nil,
                        calendarEvent: nil,
                        alarm: AlarmEvent(
                            title: "Bedtime Reminder",
                            time: Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!,
                            repeatDays: [1,2,3,4,5,6,7],
                            sound: "default"
                        ),
                        isAccepted: false,
                        acceptedAt: nil
                    )
                ],
                isLiked: false,
                likedAt: nil,
                acceptedActions: [],
                createdAt: Date()
            ),
            InsightAnalysisCard(
                id: UUID(),
                insightId: mockInsightId,
                anonymousUserId: mockUserId,
                title: "Behavior Pattern Prediction",
                subtitle: "Next week behavior score expected at 0.78 with increased consistency",
                cardType: .prediction,
                pages: [
                    AnalysisCardPage(
                        id: UUID(),
                        pageNumber: 1,
                        contentType: .graph,
                        content: PageContent(
                            text: "Behavior Pattern Prediction",
                            headline: "Stable upward trend",
                            body: "AI model predicts behavior scores will rise next week.",
                            mantra: nil
                        ),
                        visualizations: [
                            PageVisualization(
                                type: .lineChart,
                                data: ["points": AnyCodable(["0.65", "0.68", "0.72", "0.75", "0.78"])],
                                chartType: .line
                            )
                        ]
                    )
                ],
                actionProposals: [
                    ActionProposal(
                        id: UUID(),
                        title: "Use Habit Tracking App",
                        description: "Record and analyze your behavior patterns",
                        actionType: .habit,
                        targetDate: Date().addingTimeInterval(86400),
                        calendarEvent: nil,
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Set Weekly Goals",
                        description: "Set specific goals for next week",
                        actionType: .reminder,
                        targetDate: Date().addingTimeInterval(604800),
                        calendarEvent: nil,
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Performance Review Time",
                        description: "Take time on weekends to review this week's achievements",
                        actionType: .calendar,
                        targetDate: Date().addingTimeInterval(518400),
                        calendarEvent: CalendarEvent(
                            title: "Weekly Review",
                            description: "Review this week's performance and plan for next week",
                            startDate: Date().addingTimeInterval(518400),
                            endDate: Date().addingTimeInterval(518400 + 3600),
                            location: nil,
                            notes: "Performance review and goal setting"
                        ),
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    )
                ],
                isLiked: false,
                likedAt: nil,
                acceptedActions: [],
                createdAt: Date()
            ),
            InsightAnalysisCard(
                id: UUID(),
                insightId: mockInsightId,
                anonymousUserId: mockUserId,
                title: "Physical Health Control",
                subtitle: "Physical score is 0.70, exercise increase needed",
                cardType: .control,
                pages: [
                    AnalysisCardPage(
                        id: UUID(),
                        pageNumber: 1,
                        contentType: .statistics,
                        content: PageContent(
                            text: "Physical Health Control",
                            headline: "Exercise increase needed",
                            body: "Current physical score is below target. Regular exercise is recommended.",
                            mantra: nil
                        ),
                        visualizations: [
                            PageVisualization(
                                type: .gauge,
                                data: ["current": AnyCodable("0.70"), "target": AnyCodable("0.85")],
                                chartType: nil
                            )
                        ]
                    )
                ],
                actionProposals: [
                    ActionProposal(
                        id: UUID(),
                        title: "Gym Registration",
                        description: "Improve physical health with 3 gym visits per week",
                        actionType: .calendar,
                        targetDate: Date().addingTimeInterval(86400),
                        calendarEvent: CalendarEvent(
                            title: "Gym Workout",
                            description: "Strength training and cardio exercise",
                            startDate: Date().addingTimeInterval(86400),
                            endDate: Date().addingTimeInterval(86400 + 3600),
                            location: "Gym",
                            notes: "45 minutes strength + 15 minutes cardio"
                        ),
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Daily Step Goal",
                        description: "Set a goal of 10,000 steps per day",
                        actionType: .reminder,
                        targetDate: Date(),
                        calendarEvent: nil,
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Nutrition Supplement",
                        description: "Increase protein intake and maintain a healthy diet",
                        actionType: .habit,
                        targetDate: Date().addingTimeInterval(172800),
                        calendarEvent: nil,
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    )
                ],
                isLiked: false,
                likedAt: nil,
                acceptedActions: [],
                createdAt: Date()
            ),
            InsightAnalysisCard(
                id: UUID(),
                insightId: mockInsightId,
                anonymousUserId: mockUserId,
                title: "Correlation Between Mood and Sleep",
                subtitle: "Mood scores increase by 15% when sleep quality is good",
                cardType: .correlation,
                pages: [
                    AnalysisCardPage(
                        id: UUID(),
                        pageNumber: 1,
                        contentType: .graph,
                        content: PageContent(
                            text: "Correlation Between Mood and Sleep",
                            headline: "Impact of Sleep on Mood",
                            body: "Data analysis shows a strong correlation between sleep quality and mood scores.",
                            mantra: nil
                        ),
                        visualizations: [
                            PageVisualization(
                                type: .radarChart,
                                data: ["sleep_quality": AnyCodable("0.8"), "mood_score": AnyCodable("0.75"), "correlation": AnyCodable("0.85")],
                                chartType: .radar
                            )
                        ]
                    )
                ],
                actionProposals: [
                    ActionProposal(
                        id: UUID(),
                        title: "Create Bedtime Routine",
                        description: "Start bedtime preparation at the same time every day",
                        actionType: .alarm,
                        targetDate: nil,
                        calendarEvent: nil,
                        alarm: AlarmEvent(
                            title: "Bedtime Preparation",
                            time: Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date())!,
                            repeatDays: [1,2,3,4,5,6,7],
                            sound: "gentle"
                        ),
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Limit Caffeine Intake",
                        description: "Avoid caffeine after 2 PM",
                        actionType: .reminder,
                        targetDate: Date(),
                        calendarEvent: nil,
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Improve Sleep Environment",
                        description: "Make your room dark and quiet to improve sleep quality",
                        actionType: .habit,
                        targetDate: Date().addingTimeInterval(86400),
                        calendarEvent: nil,
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    )
                ],
                isLiked: false,
                likedAt: nil,
                acceptedActions: [],
                createdAt: Date()
            ),
            InsightAnalysisCard(
                id: UUID(),
                insightId: mockInsightId,
                anonymousUserId: mockUserId,
                title: "Weekly Activity Summary",
                subtitle: "This week total activity time was 25 hours, achieving 80% of goal",
                cardType: .explanation,
                pages: [
                    AnalysisCardPage(
                        id: UUID(),
                        pageNumber: 1,
                        contentType: .statistics,
                        content: PageContent(
                            text: "Weekly Activity Summary",
                            headline: "Good Performance",
                            body: "You achieved 80% of your weekly activity goal this week. Your consistent efforts are paying off.",
                            mantra: nil
                        ),
                        visualizations: [
                            PageVisualization(
                                type: .barChart,
                                data: ["mon": AnyCodable("4"), "tue": AnyCodable("3.5"), "wed": AnyCodable("5"), "thu": AnyCodable("4.5"), "fri": AnyCodable("3"), "sat": AnyCodable("2.5"), "sun": AnyCodable("2.5")],
                                chartType: .bar
                            )
                        ]
                    )
                ],
                actionProposals: [
                    ActionProposal(
                        id: UUID(),
                        title: "Increase Activity Time",
                        description: "Set next week goal to 30 hours",
                        actionType: .reminder,
                        targetDate: Date().addingTimeInterval(604800),
                        calendarEvent: nil,
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Ensure Rest Time",
                        description: "Take adequate rest time between activities",
                        actionType: .calendar,
                        targetDate: Date().addingTimeInterval(86400),
                        calendarEvent: CalendarEvent(
                            title: "Rest Time",
                            description: "Rest after activity",
                            startDate: Date().addingTimeInterval(86400 + 1800),
                            endDate: Date().addingTimeInterval(86400 + 3600),
                            location: nil,
                            notes: "Meditation or light walk"
                        ),
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Share Achievements",
                        description: "Share this week's achievements with people around you",
                        actionType: .habit,
                        targetDate: Date().addingTimeInterval(172800),
                        calendarEvent: nil,
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    )
                ],
                isLiked: false,
                likedAt: nil,
                acceptedActions: [],
                createdAt: Date()
            ),
            InsightAnalysisCard(
                id: UUID(),
                insightId: mockInsightId,
                anonymousUserId: mockUserId,
                title: "Future Health Prediction",
                subtitle: "Health score expected to rise to 0.82 in 3 months",
                cardType: .prediction,
                pages: [
                    AnalysisCardPage(
                        id: UUID(),
                        pageNumber: 1,
                        contentType: .graph,
                        content: PageContent(
                            text: "Future Health Prediction",
                            headline: "Positive Outlook",
                            body: "If current trends continue, health scores will steadily increase.",
                            mantra: nil
                        ),
                        visualizations: [
                            PageVisualization(
                                type: .lineChart,
                                data: ["week1": AnyCodable("0.72"), "week2": AnyCodable("0.74"), "week3": AnyCodable("0.76"), "month2": AnyCodable("0.78"), "month3": AnyCodable("0.82")],
                                chartType: .line
                            )
                        ]
                    )
                ],
                actionProposals: [
                    ActionProposal(
                        id: UUID(),
                        title: "Set Long-term Goals",
                        description: "Set specific health goals for 3 months from now",
                        actionType: .calendar,
                        targetDate: Date().addingTimeInterval(604800),
                        calendarEvent: CalendarEvent(
                            title: "Set Long-term Goals",
                            description: "Establish 3-month health goals",
                            startDate: Date().addingTimeInterval(604800),
                            endDate: Date().addingTimeInterval(604800 + 3600),
                            location: nil,
                            notes: "Aim to achieve health score of 0.85"
                        ),
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Regular Health Checkups",
                        description: "Get health checkups once every 3 months",
                        actionType: .reminder,
                        targetDate: Date().addingTimeInterval(2592000 * 3),
                        calendarEvent: nil,
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Monitor Health Data",
                        description: "Regularly check and record health data",
                        actionType: .habit,
                        targetDate: Date().addingTimeInterval(86400),
                        calendarEvent: nil,
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    )
                ],
                isLiked: false,
                likedAt: nil,
                acceptedActions: [],
                createdAt: Date()
            ),
            InsightAnalysisCard(
                id: UUID(),
                insightId: mockInsightId,
                anonymousUserId: mockUserId,
                title: "Stress Management",
                subtitle: "Stress index is 0.65, meditation and rest needed",
                cardType: .control,
                pages: [
                    AnalysisCardPage(
                        id: UUID(),
                        pageNumber: 1,
                        contentType: .statistics,
                        content: PageContent(
                            text: "Stress Management",
                            headline: "Rest Needed",
                            body: "Current stress index is high. Find ways to relieve stress.",
                            mantra: nil
                        ),
                        visualizations: [
                            PageVisualization(
                                type: .gauge,
                                data: ["current": AnyCodable("0.65"), "target": AnyCodable("0.4")],
                                chartType: nil
                            )
                        ]
                    )
                ],
                actionProposals: [
                    ActionProposal(
                        id: UUID(),
                        title: "Stress Relief Meditation",
                        description: "Practice 15 minutes of stress relief meditation daily",
                        actionType: .alarm,
                        targetDate: nil,
                        calendarEvent: nil,
                        alarm: AlarmEvent(
                            title: "Meditation Time",
                            time: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!,
                            repeatDays: [1,2,3,4,5,6,7],
                            sound: "calm"
                        ),
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Hobby Activity Time",
                        description: "Reduce stress with 2 hobby activities per week",
                        actionType: .calendar,
                        targetDate: Date().addingTimeInterval(172800),
                        calendarEvent: CalendarEvent(
                            title: "Hobby Activity",
                            description: "Hobby for stress relief",
                            startDate: Date().addingTimeInterval(172800),
                            endDate: Date().addingTimeInterval(172800 + 3600),
                            location: nil,
                            notes: "Drawing, listening to music, etc."
                        ),
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    ),
                    ActionProposal(
                        id: UUID(),
                        title: "Forest Walk",
                        description: "Relieve stress by walking in nature",
                        actionType: .reminder,
                        targetDate: Date().addingTimeInterval(345600),
                        calendarEvent: nil,
                        alarm: nil,
                        isAccepted: false,
                        acceptedAt: nil
                    )
                ],
                isLiked: false,
                likedAt: nil,
                acceptedActions: [],
                createdAt: Date()
            )
        ]
    }
    
    // MARK: - Persistence
    private func loadAnalysisCards() -> [InsightAnalysisCard]? {
        return loadJSON([InsightAnalysisCard].self, from: FileName.analysisCards)
    }
    
    private func saveAnalysisCards() {
        saveJSON(mockAnalysisCards, to: FileName.analysisCards)
    }
    
    private func loadUserStats() -> UserStats? {
        return loadJSON(UserStats.self, from: FileName.userStats)
    }
    
    private func saveUserStats() {
        if let stats = mockUserStats {
            saveJSON(stats, to: FileName.userStats)
        }
    }
    
    private func loadUserProfile() -> UserProfile? {
        return loadJSON(UserProfile.self, from: FileName.userProfile)
    }
    
    private func saveUserProfile() {
        if let profile = mockUserProfile {
            saveJSON(profile, to: FileName.userProfile)
        }
    }
    
    private func loadAchievements() -> [Achievement]? {
        return loadJSON([Achievement].self, from: FileName.achievements)
    }
    
    private func saveAchievements() {
        saveJSON(mockAchievements, to: FileName.achievements)
    }
    
    private func loadValueAnalysis() -> ValueAnalysis? {
        return loadJSON(ValueAnalysis.self, from: FileName.valueAnalysis)
    }
    
    private func saveValueAnalysis() {
        if let analysis = mockValueAnalysis {
            saveJSON(analysis, to: FileName.valueAnalysis)
        }
    }
    
    private func loadDailyGems() -> [DailyGem]? {
        return loadJSON([DailyGem].self, from: FileName.dailyGems)
    }
    
    private func saveDailyGems() {
        saveJSON(mockDailyGems, to: FileName.dailyGems)
    }
}

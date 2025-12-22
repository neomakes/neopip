//
//  MockDataService.swift
//  PIP_Project
//
//  MockData Service: Firebase 없이 UI 검증을 위한 Mock 데이터 제공
//

import Foundation
import Combine

/// MockData 서비스 (Firebase 연동 전 UI 검증용)
@MainActor
class MockDataService: DataServiceProtocol {
    static let shared = MockDataService()
    
    // MARK: - Mock Data Storage
    private var mockDataPoints: [TimeSeriesDataPoint] = []
    private var mockDailyGems: [DailyGem] = []
    private var mockDailyStats: [DailyStats] = []
    private var mockUserStats: UserStats?
    
    // MARK: - Data Type Schema Registry
    /// 동적 데이터 타입 정의 레지스트리
    /// 실제 앱에서는 Firebase에서 로드하거나 사용자 설정에 따라 결정됨
    private var dataTypeSchemas: [DataTypeSchema] = []
    
    // Mock User IDs
    private let mockAccountId = UUID()
    private let mockAnonymousUserId = UUID()
    
    private init() {
        initializeDataTypeSchemas()
        generateMockData()
    }
    
    // MARK: - Data Type Schema Initialization
    /// 기본 데이터 타입 스키마 초기화
    /// 필요에 따라 동적으로 추가/제거 가능
    private func initializeDataTypeSchemas() {
        let now = Date()
        
        // Mind Category (마음)
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
        
        // Behavior Category (행동)
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
        
        // Physical Category (신체)
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
        
        // 최근 30일간의 데이터 생성
        for dayOffset in 0..<30 {
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
            .sorted(by: >)
        
        var currentStreak = 0
        let today = Calendar.current.startOfDay(for: Date())
        
        for (index, date) in sortedDates.enumerated() {
            let expectedDate = Calendar.current.date(byAdding: .day, value: -index, to: today)!
            if Calendar.current.isDate(date, inSameDayAs: expectedDate) {
                currentStreak += 1
            } else {
                break
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
        
        return Just(dataPoint)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    func deleteDataPoint(_ id: UUID) -> AnyPublisher<Void, Error> {
        mockDataPoints.removeAll { $0.id == id }
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
    
    // MARK: - Save Data (async method)
    func saveData(_ dataPoint: TimeSeriesDataPoint, for category: DataCategory) async throws {
        var updatedDataPoint = dataPoint
        updatedDataPoint.category = category
        
        if let index = mockDataPoints.firstIndex(where: { $0.id == dataPoint.id }) {
            mockDataPoints[index] = updatedDataPoint
        } else {
            mockDataPoints.append(updatedDataPoint)
        }
    }
}

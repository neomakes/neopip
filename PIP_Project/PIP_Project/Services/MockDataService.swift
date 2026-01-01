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
    /// Bundle's MockData is read-only, so Documents is used for runtime data storage
    private var mockDataDirectory: URL {
        if let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let mockDataDir = documentsDir.appendingPathComponent("MockData")
            // Create folder if it doesn't exist
            try? fileManager.createDirectory(at: mockDataDir, withIntermediateDirectories: true)
            return mockDataDir
        }
        
        return FileManager.default.temporaryDirectory
    }


    
    // MARK: - JSON File Names (Subdirectory Structure)
    private enum FileName {
        // Common data
        static let dataTypeSchemas = "Common/dataTypeSchemas.json"
        static let timeSeriesData = "Common/timeSeriesData.json"
        static let dailyStats = "Common/dailyStats.json"
        
        // Insight page data
        static let analysisCards = "Insight/analysisCards.json"
        static let dashboardData = "Insight/dashboardData.json"
        static let orbVisualization = "Insight/orbVisualization.json"
        
        // Home page data
        static let dailyGems = "Home/dailyGems.json"
        static let userStats = "Home/userStats.json"
        
        // Status page data
        static let userProfile = "Status/userProfile.json"
        static let achievements = "Status/achievements.json"
        static let valueAnalysis = "Status/valueAnalysis.json"
        
        // Goal page data
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
    
    // MARK: - Data Type Schema Registry
    /// Dynamic data type definition registry
    /// In the actual app, loaded from Firebase or determined by user settings
    private var dataTypeSchemas: [DataTypeSchema] = []
    
    // Mock User IDs
    private let mockAccountId = UUID()
    private let mockAnonymousUserId = UUID()
    
    private init() {
        setupDataDirectory()
        copyInsightStoryJSONFilesIfNeeded()
        copyGoalJSONFilesIfNeeded()
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
    
    /// Copy InsightStory JSON files to app's Documents directory and validate/auto-fix format
    private func copyInsightStoryJSONFilesIfNeeded() {
        let cardIds = [
            "332A2000-CCC0-4B01-8B02-0B3EBA7152A0",
            "492AED2A-7C96-439A-B6F3-B9C3F9E3A843",
            "8C525668-20D7-4499-A4AC-7942B07996F9",
            "EE2BF404-8BF7-4950-A5AE-97FB23972728",
            "BF336B37-A4CC-498B-AE9B-97709318953A",
            "14854C55-B2B4-481D-AF40-3E6B3886F111",
            "1B3788C6-D81B-4813-BF15-A2BF53D58C36"
        ]
        
        // Create analysis card folder
        let analysisFolderURL = mockDataDirectory.appendingPathComponent("Insight/analysis")
        try? fileManager.createDirectory(at: analysisFolderURL, withIntermediateDirectories: true)
        
        print("📁 MockData Directory: \(mockDataDirectory.path)")
        
        for cardId in cardIds {
            let destinationPath = analysisFolderURL.appendingPathComponent("\(cardId).json")
            
            // Skip if already exists in valid format
            if fileManager.fileExists(atPath: destinationPath.path) {
                // Format validation
                if validateInsightStoryJSON(at: destinationPath) {
                    print("✅ Already valid: \(cardId).json")
                    continue
                }
                // Regenerate if format is invalid
            }
            
            // Find original JSON file in Bundle
            if let bundleUrl = Bundle.main.url(forResource: cardId, withExtension: "json") {
                do {
                    // Load original file
                    let bundleData = try Data(contentsOf: bundleUrl)
                    
                    // Try parsing original format
                    if let correctedData = convertToInsightStoryFormat(bundleData, cardId: cardId) {
                        // Save converted data
                        try correctedData.write(to: destinationPath, options: .atomic)
                        print("✅ Saved \(cardId).json to: \(destinationPath.path)")
                    } else {
                        print("⚠️ Could not convert \(cardId).json to InsightStory format")
                    }
                } catch {
                    print("⚠️ Failed to process \(cardId).json: \(error)")
                }
            }
        }
    }
    
    /// Validate if JSON is valid InsightStory format
    private func validateInsightStoryJSON(at url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let _ = try jsonDecoder.decode(InsightStory.self, from: data)
            return true
        } catch {
            return false
        }
    }
    
    /// Convert original JSON format to InsightStory format
    private func convertToInsightStoryFormat(_ data: Data, cardId: String) -> Data? {
        do {
            // First parse as Dictionary
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }
            
            // Convert to InsightStory format
            let id = (json["id"] as? String) ?? cardId
            let title = (json["title"] as? String) ?? "Untitled Story"
            let subtitle = (json["subtitle"] as? String) ?? ""
            let isLiked = (json["isLiked"] as? Bool) ?? false
            
            // Process pages array
            var pages: [[String: Any]] = []
            if let rawPages = json["pages"] as? [[String: Any]] {
                pages = rawPages.map { page in
                    var processedPage = page
                    // If pageNumber doesn't exist, generate based on index
                    if processedPage["pageNumber"] == nil, let index = rawPages.firstIndex(where: { $0["pageNumber"] as? Int ?? -1 == page["pageNumber"] as? Int ?? -1 }) {
                        processedPage["pageNumber"] = index + 1
                    }
                    return processedPage
                }
                // Sort by pageNumber order
                pages.sort { 
                    let p1 = ($0["pageNumber"] as? Int) ?? 0
                    let p2 = ($1["pageNumber"] as? Int) ?? 0
                    return p1 < p2
                }
            }
            
            // Construct new InsightStory format Dictionary
            let correctedStory: [String: Any] = [
                "id": id,
                "title": title,
                "subtitle": subtitle,
                "pages": pages,
                "isLiked": isLiked
            ]
            
            // Re-encode as JSON data
            let correctedData = try JSONSerialization.data(withJSONObject: correctedStory, options: [.prettyPrinted, .sortedKeys])
            
            // Final validation
            if let _ = try? jsonDecoder.decode(InsightStory.self, from: correctedData) {
                print("✅ Successfully converted \(cardId) to InsightStory format")
                return correctedData
            }
            
            return nil
        } catch {
            print("⚠️ Conversion error for \(cardId): \(error)")
            return nil
        }
    }
    
    private func fileURL(for fileName: String) -> URL {
        let fileURL = mockDataDirectory.appendingPathComponent(fileName)
        
        // Create directory if subdirectories exist
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
    
    private func loadJSON<T: Decodable>(_ type: T.Type, from fileName: String, isSilent: Bool = false) -> T? {
        // Separate filename and subdirectory (e.g., "Home/dailyGems.json" -> subdirectory: "MockData/Home", resourceName: "dailyGems")
        let components = fileName.split(separator: "/").map { String($0) }
        let resourceName = String(components.last?.split(separator: ".").first ?? "")
        let resourceExtension = String(components.last?.split(separator: ".").last ?? "json")
        
        // Construct subdirectory (e.g., "Home/dailyGems.json" -> "MockData/Home")
        var subdirectory = "MockData"
        if components.count > 1 {
            let subpaths = components.dropLast()
            subdirectory = "MockData/" + subpaths.joined(separator: "/")
        }
        
        if !isSilent {
            print("📂 Trying to load from Bundle: \(subdirectory)/\(resourceName).\(resourceExtension)")
        }
        
        // Search in Bundle with subdirectory
        if let bundleUrl = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension, subdirectory: subdirectory) {
            do {
                let data = try Data(contentsOf: bundleUrl)
                let object = try jsonDecoder.decode(type, from: data)
                if !isSilent {
                    print("✅ Loaded \(fileName) from Bundle: \(bundleUrl.path)")
                }
                return object
            } catch {
                if !isSilent {
                    print("⚠️ Failed to decode from Bundle: \(error.localizedDescription)")
                }
                return nil
            }
        }
        
        if !isSilent {
            print("⚠️ File not found in Bundle: \(subdirectory)/\(resourceName).\(resourceExtension)")
        }
        
        // Second attempt: Load from mockDataDirectory path (Legacy support)
        let filePath = mockDataDirectory.appendingPathComponent(fileName)
        
        do {
            let data = try Data(contentsOf: filePath)
            let object = try jsonDecoder.decode(type, from: data)
            if !isSilent {
                print("✅ Loaded \(fileName) from mockDataDirectory: \(filePath.path)")
            }
            return object
        } catch {
            if !isSilent {
                print("⚠️ Failed to load from mockDataDirectory: \(error.localizedDescription)")
            }
        }
        
        if !isSilent {
            print("❌ Failed to load \(fileName) from any source")
        }
        return nil
    }
    
    /// Function that specially processes InsightStory JSON files
    private func loadInsightStoryJSON(_ cardId: String) -> InsightStory? {
        // First search in Bundle resources (MockData/Insight/analysis subdirectory)
        if let bundleUrl = Bundle.main.url(forResource: cardId, withExtension: "json", subdirectory: "MockData/Insight/analysis") {
            do {
                let data = try Data(contentsOf: bundleUrl)
                let story = try jsonDecoder.decode(InsightStory.self, from: data)
                print("✅ Loaded InsightStory from Bundle: \(bundleUrl.path)")
                return story
            } catch {
                print("⚠️ Failed to decode from Bundle: \(bundleUrl.path) - \(error.localizedDescription)")
            }
        } else {
            print("⚠️ InsightStory JSON not found in Bundle at: MockData/Insight/analysis/\(cardId).json")
        }
        
        // Fallback 1: Search in Bundle root
        if let bundleUrl = Bundle.main.url(forResource: cardId, withExtension: "json") {
            do {
                let data = try Data(contentsOf: bundleUrl)
                let story = try jsonDecoder.decode(InsightStory.self, from: data)
                print("✅ Loaded InsightStory from Bundle root: \(bundleUrl.path)")
                return story
            } catch {
                print("⚠️ Failed to decode from Bundle root: \(bundleUrl.path) - \(error.localizedDescription)")
            }
        }
        
        // Fallback 2: Search in Documents directory
        let fileName = "\(cardId).json"
        let documentsPath = mockDataDirectory.appendingPathComponent("Insight/analysis/\(fileName)").path
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: documentsPath))
            let story = try jsonDecoder.decode(InsightStory.self, from: data)
            print("✅ Loaded InsightStory from Documents: \(documentsPath)")
            return story
        } catch {
            print("⚠️ Failed to load from Documents: \(documentsPath) - \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Copy Goal JSON files to app's Documents directory
    private func copyGoalJSONFilesIfNeeded() {
        let programIds = [
            "P001-UUID-0001-0001",
            "P002-UUID-0002-0002", 
            "P003-UUID-0003-0003"
        ]
        
        // Create ongoing_programs folder
        let ongoingProgramsFolderURL = mockDataDirectory.appendingPathComponent("Goal/ongoing_programs")
        try? fileManager.createDirectory(at: ongoingProgramsFolderURL, withIntermediateDirectories: true)
        
        print("📁 Goal MockData Directory: \(ongoingProgramsFolderURL.path)")
        
        for programId in programIds {
            let destinationPath = ongoingProgramsFolderURL.appendingPathComponent("\(programId).json")
            
            // Skip if already exists
            if fileManager.fileExists(atPath: destinationPath.path) {
                print("✅ Already exists: \(programId).json")
                continue
            }
            
            // Try to find original JSON file in Bundle first (subdirectory then root)
            let subdirectory = "MockData/Goal/ongoing_programs"
            if let bundleUrl = Bundle.main.url(forResource: programId, withExtension: "json", subdirectory: subdirectory) ?? Bundle.main.url(forResource: programId, withExtension: "json") {
                do {
                    let bundleData = try Data(contentsOf: bundleUrl)
                    try bundleData.write(to: destinationPath, options: .atomic)
                    print("✅ Copied \(programId).json from Bundle to: \(destinationPath.path)")
                } catch {
                    print("⚠️ Failed to copy \(programId).json from Bundle: \(error)")
                }
            } else {
                // Fallback to project path if available (dev only)
                let projectMockDataPath = "/Users/neo/ACCEL/PIP_Project/PIP_Project/PIP_Project/MockData/Goal/ongoing_programs/\(programId).json"
                let projectURL = URL(fileURLWithPath: projectMockDataPath)
                if fileManager.fileExists(atPath: projectURL.path) {
                    do {
                        let bundleData = try Data(contentsOf: projectURL)
                        try bundleData.write(to: destinationPath, options: .atomic)
                        print("✅ Copied \(programId).json from project to: \(destinationPath.path)")
                    } catch {
                        print("⚠️ Failed to copy \(programId).json from project: \(error)")
                    }
                } else {
                    print("⚠️ Original \(programId).json not found in Bundle or project: \(programId)")
                }
            }
        }
        
        // Create new_programs folder and copy if available in Bundle or project
        let newProgramsFolderURL = mockDataDirectory.appendingPathComponent("Goal/new_programs")
        try? fileManager.createDirectory(at: newProgramsFolderURL, withIntermediateDirectories: true)
        
        print("📁 New Programs MockData Directory: \(newProgramsFolderURL.path)")
        
        let newProgramIds = [
            "P004-UUID-0004-0004",
            "P005-UUID-0005-0005",
            "P006-UUID-0006-0006",
            "P007-UUID-0007-0007",
            "P008-UUID-0008-0008"
        ]
        
        for programId in newProgramIds {
            let destinationPath = newProgramsFolderURL.appendingPathComponent("\(programId).json")
            
            // Skip if already exists
            if fileManager.fileExists(atPath: destinationPath.path) {
                print("✅ Already valid: \(programId).json")
                continue
            }
            
            // Prefer to copy from Bundle
            let subdirectory = "MockData/Goal/new_programs"
            if let bundleUrl = Bundle.main.url(forResource: programId, withExtension: "json", subdirectory: subdirectory) ?? Bundle.main.url(forResource: programId, withExtension: "json") {
                do {
                    let bundleData = try Data(contentsOf: bundleUrl)
                    try bundleData.write(to: destinationPath, options: .atomic)
                    print("✅ Copied \(programId).json from Bundle to: \(destinationPath.path)")
                } catch {
                    print("⚠️ Failed to copy \(programId).json from Bundle: \(error)")
                }
            } else {
                // Fallback to project path if available (dev only)
                let projectMockDataPath = "/Users/neo/ACCEL/PIP_Project/PIP_Project/PIP_Project/MockData/Goal/new_programs/\(programId).json"
                let projectURL = URL(fileURLWithPath: projectMockDataPath)
                if fileManager.fileExists(atPath: projectURL.path) {
                    do {
                        let bundleData = try Data(contentsOf: projectURL)
                        try bundleData.write(to: destinationPath, options: .atomic)
                        print("✅ Copied \(programId).json from project to: \(destinationPath.path)")
                    } catch {
                        print("⚠️ Failed to copy \(programId).json from project: \(error)")
                    }
                } else {
                    print("⚠️ Original \(programId).json not found in Bundle or project: \(programId)")
                }
            }
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
        
        // Load individual analysis card JSON files
        mockAnalysisCards = loadAnalysisCardsFromIndividualFiles()
        
        // If no cards loaded, create default mock cards as fallback
        if mockAnalysisCards.isEmpty {
            print("⚠️ No analysis cards found in files, creating default mock cards...")
            mockAnalysisCards = createDefaultMockAnalysisCards()
            print("✅ Created \(mockAnalysisCards.count) default mock analysis cards")
        } else {
            print("✅ Loaded \(mockAnalysisCards.count) analysis cards")
        }
        
        mockDashboardData = loadJSON([String: [DashboardItem]].self, from: FileName.dashboardData) ?? createMockDashboardData()

        // Normalize dashboard icons so runtime asset lookups are consistent
        for (category, items) in mockDashboardData {
            mockDashboardData[category] = items.map { item in
                var copy = item
                copy.icon = normalizeAssetName(copy.icon)
                return copy
            }
        }

        mockOrbVisualization = loadJSON(OrbVisualization.self, from: FileName.orbVisualization, isSilent: true)
        mockUserStats = loadJSON(UserStats.self, from: FileName.userStats)
        mockUserProfile = loadJSON(UserProfile.self, from: FileName.userProfile)
        mockAchievements = loadJSON([Achievement].self, from: FileName.achievements) ?? []
        mockValueAnalysis = loadJSON(ValueAnalysis.self, from: FileName.valueAnalysis)
        mockDailyGems = loadJSON([DailyGem].self, from: FileName.dailyGems) ?? []
        mockDataPoints = loadJSON([TimeSeriesDataPoint].self, from: FileName.timeSeriesData) ?? []
        mockDailyStats = loadJSON([DailyStats].self, from: FileName.dailyStats) ?? []
        
        // Generate missing data (only if essential data is missing)
        if mockUserStats == nil || mockUserProfile == nil {
            generateMockData()
            saveAllData()
        }
    }
    
    private func saveAllData() {
        saveJSON(mockAnalysisCards, to: FileName.analysisCards)
        saveJSON(mockDashboardData, to: FileName.dashboardData)
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
    /// Add data type schema (for dynamic expansion)
    /// Use this method to add new data types.
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
            // Regenerate data after schema addition (optional)
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
        
        // Note: AnalysisCards는 JSON 파일에서만 로드됨 (generateMockData에서 생성하지 않음)
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
    
    // MARK: - Load Analysis Cards from Individual JSON Files
    private func loadAnalysisCardsFromIndividualFiles() -> [InsightAnalysisCard] {
        let cardIds = [
            "332A2000-CCC0-4B01-8B02-0B3EBA7152A0",
            "492AED2A-7C96-439A-B6F3-B9C3F9E3A843",
            "8C525668-20D7-4499-A4AC-7942B07996F9",
            "EE2BF404-8BF7-4950-A5AE-97FB23972728",
            "BF336B37-A4CC-498B-AE9B-97709318953A",
            "14854C55-B2B4-481D-AF40-3E6B3886F111",
            "1B3788C6-D81B-4813-BF15-A2BF53D58C36"
        ]
        
        var cards: [InsightAnalysisCard] = []
        
        for cardId in cardIds {
            var loaded = false
            
            // 방법 1: Bundle에서 MockData/Insight/analysis 서브디렉토리에서 찾기
            if let bundleUrl = Bundle.main.url(forResource: cardId, withExtension: "json", subdirectory: "MockData/Insight/analysis") {
                if let card = loadCardFromUrl(bundleUrl, cardId: cardId) {
                    cards.append(card)
                    loaded = true
                }
            }
            
            // 방법 2: 실패하면 Bundle root에서 찾기
            if !loaded, let bundleUrl = Bundle.main.url(forResource: cardId, withExtension: "json") {
                if let card = loadCardFromUrl(bundleUrl, cardId: cardId) {
                    cards.append(card)
                    loaded = true
                }
            }
            
            // 방법 3: 실패하면 Documents 디렉토리에서 찾기 (런타임 캐시)
            if !loaded {
                let docPath = mockDataDirectory.appendingPathComponent("Insight/analysis/\(cardId).json")
                if fileManager.fileExists(atPath: docPath.path) {
                    if let card = loadCardFromUrl(docPath, cardId: cardId) {
                        cards.append(card)
                        loaded = true
                    }
                }
            }
            
            if !loaded {
                print("⚠️ Card file not found: \(cardId).json")
            }
        }
        
        print("📊 Successfully loaded \(cards.count) / \(cardIds.count) analysis cards")
        return cards
    }
    
    private func loadCardFromUrl(_ url: URL, cardId: String) -> InsightAnalysisCard? {
        do {
            let data = try Data(contentsOf: url)
            let card = try jsonDecoder.decode(InsightAnalysisCard.self, from: data)
            print("✅ Loaded card: \(card.title)")
            return card
        } catch {
            print("⚠️ Failed to load card \(cardId) from \(url.path): \(error.localizedDescription)")
            return nil
        }
    }
    
    private func createDefaultMockAnalysisCards() -> [InsightAnalysisCard] {
        let cardData = [
            (id: "332A2000-CCC0-4B01-8B02-0B3EBA7152A0", title: "Weekly Mood Pattern Analysis", subtitle: "Your mood patterns over the past week", type: AnalysisCardType.explanation),
            (id: "492AED2A-7C96-439A-B6F3-B9C3F9E3A843", title: "Behavior Pattern Prediction", subtitle: "Your behavior is projected to improve", type: AnalysisCardType.prediction),
            (id: "8C525668-20D7-4499-A4AC-7942B07996F9", title: "Stress Management Strategies", subtitle: "Your stress level is higher than optimal", type: AnalysisCardType.control),
            (id: "EE2BF404-8BF7-4950-A5AE-97FB23972728", title: "Physical Health Control", subtitle: "Take control of your physical health", type: AnalysisCardType.control),
            (id: "BF336B37-A4CC-498B-AE9B-97709318953A", title: "Future Health Prediction", subtitle: "Your health is projected to reach 85+", type: AnalysisCardType.prediction),
            (id: "14854C55-B2B4-481D-AF40-3E6B3886F111", title: "Weekly Activity Summary", subtitle: "You completed 85% of your goals", type: AnalysisCardType.explanation),
            (id: "1B3788C6-D81B-4813-BF15-A2BF53D58C36", title: "Correlation Between Mood and Sleep", subtitle: "When you sleep well, mood improves", type: AnalysisCardType.correlation)
        ]
        
        return cardData.map { data in
            let pages = (1...4).map { pageNum in
                AnalysisCardPage(
                    id: UUID(),
                    pageNumber: pageNum,
                    contentType: .text,
                    content: PageContent(
                        text: "Page \(pageNum) of \(data.title)",
                        headline: "\(data.title) - Page \(pageNum)",
                        body: "Content for page \(pageNum). This is a default mock card because JSON files weren't found. Please add the actual JSON files to the project.",
                        mantra: "Data-driven insights"
                    ),
                    visualizations: nil
                )
            }
            
            return InsightAnalysisCard(
                id: UUID(uuidString: data.id) ?? UUID(),
                insightId: UUID(),
                anonymousUserId: UUID(),
                title: data.title,
                subtitle: data.subtitle,
                cardType: data.type,
                pages: pages,
                actionProposals: [],
                isLiked: false,
                likedAt: nil,
                acceptedActions: [],
                createdAt: Date()
            )
        }
    }
    
    // MARK: - Generate Analysis Cards from InsightStories
    private func generateAnalysisCardsFromInsightStories() -> [InsightAnalysisCard] {
        let cardIds = [
            "332A2000-CCC0-4B01-8B02-0B3EBA7152A0",
            "492AED2A-7C96-439A-B6F3-B9C3F9E3A843",
            "8C525668-20D7-4499-A4AC-7942B07996F9",
            "EE2BF404-8BF7-4950-A5AE-97FB23972728",
            "BF336B37-A4CC-498B-AE9B-97709318953A",
            "14854C55-B2B4-481D-AF40-3E6B3886F111",
            "1B3788C6-D81B-4813-BF15-A2BF53D58C36"
        ]
        
        var cards: [InsightAnalysisCard] = []
        let cardTypes: [AnalysisCardType] = [.explanation, .prediction, .control, .correlation, .prediction, .explanation, .correlation]
        
        for (index, cardId) in cardIds.enumerated() {
            // Load InsightStory from JSON to extract metadata and pages
            if let story = loadInsightStoryJSON(cardId) {
                let cardType = cardTypes[index % cardTypes.count]
                
                // StoryPage를 AnalysisCardPage로 변환
                let analysisPages: [AnalysisCardPage] = story.pages.map { storyPage in
                    // StoryPage의 내용을 PageContent로 변환
                    let pageContent = PageContent(
                        text: "\(storyPage.headline)\n\n\(storyPage.body)",
                        headline: storyPage.headline,
                        body: storyPage.body,
                        mantra: nil
                    )
                    
                    return AnalysisCardPage(
                        id: storyPage.id,
                        pageNumber: storyPage.pageNumber,
                        contentType: .text,
                        content: pageContent,
                        visualizations: nil
                    )
                }
                
                // Create InsightAnalysisCard from InsightStory with full pages
                let card = InsightAnalysisCard(
                    id: UUID(uuidString: cardId) ?? UUID(),
                    insightId: UUID(),
                    anonymousUserId: UUID(),
                    title: story.title,
                    subtitle: story.subtitle,
                    cardType: cardType,
                    pages: analysisPages, // 4개 페이지 모두 포함
                    actionProposals: [],
                    isLiked: story.isLiked,
                    likedAt: nil,
                    acceptedActions: [],
                    createdAt: Date()
                )
                cards.append(card)
                print("✅ Card \(cardId): title='\(story.title)', pages=\(analysisPages.count)")
            }
        }
        
        print("✅ Generated \(cards.count) analysis cards with full pages from InsightStory files")
        return cards
    }
    
    // MARK: - Insight Story
    func fetchInsightStory(for cardId: String) -> AnyPublisher<InsightStory, Error> {
        // 1단계: mockAnalysisCards 상태 로깅
        print("🔍 [fetchInsightStory] Request for cardId: \(cardId)")
        print("📊 [fetchInsightStory] mockAnalysisCards count: \(mockAnalysisCards.count)")
        
        if mockAnalysisCards.isEmpty {
            print("⚠️ [fetchInsightStory] WARNING: mockAnalysisCards is empty!")
            print("📁 [fetchInsightStory] Attempting to reload from files...")
            mockAnalysisCards = loadAnalysisCardsFromIndividualFiles()
            print("📊 [fetchInsightStory] After reload: \(mockAnalysisCards.count) cards")
        }
        
        // 2단계: 사용 가능한 cardId 목록 로깅
        let availableIds = mockAnalysisCards.map { $0.id.uuidString }
        print("📋 [fetchInsightStory] Available cardIds: \(availableIds)")
        
        // 3단계: 카드 조회
        if let card = mockAnalysisCards.first(where: { $0.id.uuidString == cardId }) {
            print("✅ [fetchInsightStory] Found card: \(card.title)")
            print("📄 [fetchInsightStory] Card has \(card.pages.count) pages")
            
            let storyPages: [StoryPage] = card.pages.map { analysisPage in
                StoryPage(
                    pageNumber: analysisPage.pageNumber,
                    headline: analysisPage.content.headline ?? "",
                    body: analysisPage.content.body ?? "",
                    imageName: ""
                )
            }
            
            print("🔄 [fetchInsightStory] Converted \(storyPages.count) story pages")
            
            // 각 페이지 내용 샘플 로깅
            for (idx, page) in storyPages.enumerated() {
                print("   Page \(idx + 1): headline='\(page.headline.prefix(50))...', body='\(page.body.prefix(50))...'")
            }
            
            let story = InsightStory(
                id: cardId,
                title: card.title,
                subtitle: card.subtitle ?? "",
                pages: storyPages,
                isLiked: card.isLiked
            )
            
            print("✅ [fetchInsightStory] Successfully created InsightStory with \(story.pages.count) pages")
            
            return Just(story)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        // 4단계: 카드 미발견 시 상세 에러
        print("❌ [fetchInsightStory] Card not found!")
        print("   Requested: \(cardId)")
        print("   Available IDs: \(availableIds)")
        
        let errorMsg = "InsightStory not found for cardId: \(cardId). Available: \(availableIds.joined(separator: ", "))"
        
        return Fail(error: NSError(domain: "MockDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: errorMsg]))
            .eraseToAnyPublisher()
    }

    // MARK: - Analysis Cards
    func fetchAnalysisCards() -> AnyPublisher<[InsightAnalysisCard], Error> {
        return Just(mockAnalysisCards)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Dashboard Data
    func fetchDashboardData() -> AnyPublisher<[String: [DashboardItem]], Error> {
        return Just(mockDashboardData)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Orb Visualization
    func fetchOrbVisualization() -> AnyPublisher<OrbVisualization?, Error> {
        return Just(mockOrbVisualization)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    private func createMockDashboardData() -> [String: [DashboardItem]] {
        return [
            "mind": [
                DashboardItem(icon: "Icon_mood", label: "Mood", score: 72.5, percentage: 5.2, uncertainty: 12.3),
                DashboardItem(icon: "Icon_stress", label: "Stress", score: 45.8, percentage: -8.1, uncertainty: 18.7),
                DashboardItem(icon: "Icon_energy", label: "Energy", score: 68.3, percentage: 12.4, uncertainty: 9.5),
                DashboardItem(icon: "Icon_focus", label: "Focus", score: 61.9, percentage: 3.7, uncertainty: 15.2)
            ],
            "behavior": [
                DashboardItem(icon: "Icon_productivity", label: "Productivity", score: 78.4, percentage: 9.3, uncertainty: 11.8),
                DashboardItem(icon: "Icon_social_activity", label: "Social", score: 55.6, percentage: -4.2, uncertainty: 22.1),
                DashboardItem(icon: "Icon_digital_distraction", label: "Digital", score: 42.1, percentage: -15.8, uncertainty: 25.4),
                DashboardItem(icon: "Icon_exploration", label: "Explore", score: 83.7, percentage: 18.6, uncertainty: 8.9)
            ],
            "physical": [
                DashboardItem(icon: "Icon_sleep", label: "Sleep", score: 67.2, percentage: 7.1, uncertainty: 14.6),
                DashboardItem(icon: "Icon_fatigue", label: "Fatigue", score: 38.9, percentage: -11.3, uncertainty: 19.8),
                DashboardItem(icon: "Icon_activity", label: "Activity", score: 74.5, percentage: 14.2, uncertainty: 10.7),
                DashboardItem(icon: "Icon_nutrition", label: "Nutrition", score: 59.8, percentage: 2.9, uncertainty: 16.4)
            ]
        ]
    }
    
    /// Normalize an asset name to an actual asset present in the app bundle.
    /// Tries several common variants (capitalization, stripped prefixes) and returns
    /// the first matching asset name. If none found, returns the original name.
    private func normalizeAssetName(_ name: String) -> String {
        // Exact match
        if UIImage(named: name) != nil { return name }

        // Capitalize first character: icon_mood -> Icon_mood
        if name.count > 0 {
            let alt = name.prefix(1).uppercased() + name.dropFirst()
            if UIImage(named: String(alt)) != nil { return String(alt) }
        }

        // Lower/upper variants
        let lower = name.lowercased()
        if UIImage(named: lower) != nil { return lower }
        let upper = name.uppercased()
        if UIImage(named: upper) != nil { return upper }

        // Try stripping common prefixes like 'icon_'
        if lower.hasPrefix("icon_") {
            let stripped = String(lower.dropFirst("icon_".count))
            if UIImage(named: stripped) != nil { return stripped }
            let strippedCapital = stripped.prefix(1).uppercased() + stripped.dropFirst()
            if UIImage(named: strippedCapital) != nil { return String(strippedCapital) }
            // Try with Icon_ + strippedCapital
            let withIconCap = "Icon_" + strippedCapital
            if UIImage(named: withIconCap) != nil { return withIconCap }
        }

        #if DEBUG
        print("⚠️ normalizeAssetName: no matching asset for \(name), returning original")
        #endif

        return name
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
    
    // MARK: - OrbVisualization Helper
    
    /// OrbVisualization을 생성합니다 (uniqueFeatures 기반 색상 생성).
    /// - Returns: 새로운 OrbVisualization 인스턴스
    private func generateOrbVisualization() -> OrbVisualization {
        // uniqueFeatures 생성
        let uniqueFeatures: [String: Double] = [
            "mood_variance": Double.random(in: 0.3...0.7),
            "energy_consistency": Double.random(in: 0.5...0.9),
            "sleep_pattern": Double.random(in: 0.4...0.8)
        ]
        
        // uniqueFeatures로부터 색상 그라데이션 생성
        let colorGradient = ColorUtility.generateColorGradient(from: uniqueFeatures)
        
        return OrbVisualization(
            id: UUID(),
            anonymousUserId: mockAnonymousUserId,
            date: Date(),
            brightness: Double.random(in: 0.6...0.9),          // 사용자 모델 재생성 성능
            borderBrightness: Double.random(in: 0.7...0.95),   // 오늘 예측 정확도
            complexity: Int.random(in: 3...8),
            uncertainty: Double.random(in: 0.1...0.3),
            uniqueFeatures: uniqueFeatures,
            timeSeriesFeatures: [:],
            categoryWeights: [
                "mind": Double.random(in: 0.3...0.5),
                "behavior": Double.random(in: 0.2...0.4),
                "physical": Double.random(in: 0.2...0.4)
            ],
            gemType: .sphere,
            colorTheme: .teal,
            size: 1.0,
            colorGradient: colorGradient,  // ✅ uniqueFeatures 기반 생성된 색상
            dataPointIds: [],
            mlModelOutputId: nil,
            createdAt: Date()
        )
    }
}

// MARK: - Goal Data Methods
extension MockDataService {
    /// Load ongoing program stories from MockData/Goal/ongoing_programs/
    func loadOngoingProgramStories() -> [ProgramStory] {
        let ongoingProgramsDir = mockDataDirectory.appendingPathComponent("Goal/ongoing_programs")
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: ongoingProgramsDir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
            
            var stories: [ProgramStory] = []
            for fileURL in fileURLs {
                if let data = try? Data(contentsOf: fileURL),
                   let story = try? jsonDecoder.decode(ProgramStory.self, from: data) {
                    stories.append(story)
                }
            }
            return stories.sorted { $0.createdAt < $1.createdAt }
        } catch {
            print("Error loading ongoing program stories: \(error)")
            return []
        }
    }
    
    /// Load new program recommendations from MockData/Goal/new_programs/
    func loadNewProgramRecommendations() -> [Program] {
        let newProgramsDir = mockDataDirectory.appendingPathComponent("Goal/new_programs")
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: newProgramsDir, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "json" }
            
            var programs: [Program] = []
            for fileURL in fileURLs {
                if let data = try? Data(contentsOf: fileURL),
                   let program = try? jsonDecoder.decode(Program.self, from: data) {
                    programs.append(program)
                }
            }
            return programs
        } catch {
            print("Error loading new program recommendations: \(error)")
            return []
        }
    }
}

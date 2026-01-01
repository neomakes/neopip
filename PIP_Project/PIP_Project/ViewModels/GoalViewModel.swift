//
//  GoalViewModel.swift
//  PIP_Project
//
//  ViewModel for GoalView
//

import Foundation
import Combine
import SwiftUI

@MainActor
class GoalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var activeGoals: [Goal] = []
    @Published var availablePrograms: [Program] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Newly added properties
    @Published var selectedGoal: Goal?
    @Published var ongoingPrograms: [Program] = []              // 최대 3개
    @Published var currentProgramIndex: Int = 0
    @Published var programProgress: [String: ProgramProgress] = [:]  // programId -> ProgramProgress
    @Published var selectedProgram: Program?                    // For Sheet display
    @Published var newPrograms: [Program] = []                  // 새로운 추천 프로그램들
    
    // MARK: - Dependencies
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// Load initial data
    func loadInitialData() {
        print("🚀 [GoalViewModel] loadInitialData() called")
        isLoading = true
        createMockGoals()
        createMockPrograms()
        createMockNewPrograms()
        createMockProgramProgress()
        selectFirstGoal()
        isLoading = false
        print("✅ [GoalViewModel] loadInitialData() completed. newPrograms count: \(newPrograms.count)")
    }
    
    /// Select first active goal
    func selectFirstGoal() {
        if let firstGoal = activeGoals.first {
            selectedGoal = firstGoal
            // Filter ongoing programs for the goal (max 3)
            ongoingPrograms = availablePrograms
                .filter { $0.category == firstGoal.category }
                .prefix(3)
                .map { $0 }
            currentProgramIndex = 0
        }
    }
    
    /// Select program (tab navigation)
    func selectProgram(at index: Int) {
        guard index < ongoingPrograms.count else { return }
        currentProgramIndex = index
        selectedProgram = ongoingPrograms[index]
    }
    
    /// Move to next program
    func selectNextProgram() {
        if currentProgramIndex < ongoingPrograms.count - 1 {
            selectProgram(at: currentProgramIndex + 1)
        }
    }
    
    /// Move to previous program
    func selectPreviousProgram() {
        if currentProgramIndex > 0 {
            selectProgram(at: currentProgramIndex - 1)
        }
    }

    /// Adopt a program into ongoing programs (e.g., user selects a new recommended program)
    func adoptProgram(_ program: Program) {
        // No-op in reverted state; original behavior wasn't present
    }
    
    /// Return progress of currently selected program
    func currentProgramProgress() -> ProgramProgress? {
        guard currentProgramIndex < ongoingPrograms.count else { return nil }
        let program = ongoingPrograms[currentProgramIndex]
        return programProgress[program.id.uuidString]
    }
    
    // MARK: - Private Methods
    
    private func createMockGoals() {
        activeGoals = [
            Goal(
                id: UUID(),
                accountId: UUID(),
                title: "Improve Emotional Management",
                description: "Effectively manage daily stress",
                category: .emotional,
                targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
                startDate: Date(),
                status: .active,
                progress: 0.45,
                gemVisualization: GemVisualization(
                    gemType: .crystal,
                    colorTheme: .teal,
                    brightness: 0.7,
                    size: 1.0,
                    customShape: nil
                ),
                milestones: [],
                relatedDataPointIds: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
    
    private func createMockPrograms() {
        let programStory1 = loadProgramStory(from: "P001-UUID-0001-0001")
        let programStory2 = loadProgramStory(from: "P002-UUID-0002-0002")
        let programStory3 = loadProgramStory(from: "P003-UUID-0003-0003")

        availablePrograms = [
            Program(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                name: "21-Day Emotional Journal Program",
                description: "A program to understand and manage your emotional patterns through consistent emotional recording for 21 days",
                category: .emotional,
                duration: 21,
                difficulty: .beginner,
                gemVisualization: GemVisualization(
                    gemType: .diamond,
                    colorTheme: programStory1?.colorTheme ?? .amber,
                    gradientColors: programStory1?.gradientColors?.map { $0.rawValue },
                    brightness: 0.8,
                    size: 1.0,
                    customShape: nil
                ),
                illustration3D: ProgramIllustration3D(
                    modelId: "emotion_program_3d",
                    modelURL: nil,
                    previewImageURL: nil,
                    colorScheme: ["#82EBEB", "#FFA500"]
                ),
                popularity: 0.85,
                rating: 4.5,
                reviewCount: 234,
                userCount: 1234,
                steps: [],
                prerequisites: nil,
                tags: ["emotion", "journal", "21-day"],
                expectedEffects: [
                    "Improve emotional awareness",
                    "Enhance stress management",
                    "Increase self-understanding"
                ],
                requiredDataTypes: ["mood", "stress", "energy"],
                userReviews: nil,
                isRecommended: true,
                createdAt: Date()
            ),
            Program(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                name: "Morning Meditation Habit",
                description: "Build a consistent meditation practice with guided sessions",
                category: .emotional,
                duration: 30,
                difficulty: .beginner,
                gemVisualization: GemVisualization(
                    gemType: .sphere,
                    colorTheme: programStory2?.colorTheme ?? .blue,
                    gradientColors: programStory2?.gradientColors?.map { $0.rawValue },
                    brightness: 0.75,
                    size: 0.95,
                    customShape: nil
                ),
                illustration3D: ProgramIllustration3D(
                    modelId: "meditation_program_3d",
                    modelURL: nil,
                    previewImageURL: nil,
                    colorScheme: ["#87CEEB", "#4169E1"]
                ),
                popularity: 0.92,
                rating: 4.7,
                reviewCount: 512,
                userCount: 3456,
                steps: [],
                prerequisites: nil,
                tags: ["meditation", "mindfulness", "wellness"],
                expectedEffects: [
                    "Reduced stress and anxiety",
                    "Improved focus",
                    "Better emotional regulation"
                ],
                requiredDataTypes: ["mood", "stress"],
                userReviews: nil,
                isRecommended: true,
                createdAt: Date()
            ),
            Program(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                name: "Weekly Reading Goal",
                description: "Complete one book per week with reflection notes",
                category: .emotional,
                duration: 70,
                difficulty: .intermediate,
                gemVisualization: GemVisualization(
                    gemType: .diamond,
                    colorTheme: programStory3?.colorTheme ?? .amber,
                    gradientColors: programStory3?.gradientColors?.map { $0.rawValue },
                    brightness: 0.80,
                    size: 1.0,
                    customShape: nil
                ),
                illustration3D: ProgramIllustration3D(
                    modelId: "reading_program_3d",
                    modelURL: nil,
                    previewImageURL: nil,
                    colorScheme: ["#DA70D6", "#BA55D3"]
                ),
                popularity: 0.76,
                rating: 4.2,
                reviewCount: 189,
                userCount: 876,
                steps: [],
                prerequisites: nil,
                tags: ["reading", "learning", "personal-growth"],
                expectedEffects: [
                    "Enhanced knowledge retention",
                    "Improved critical thinking",
                    "Increased motivation"
                ],
                requiredDataTypes: ["focus", "energy"],
                userReviews: nil,
                isRecommended: false,
                createdAt: Date()
            )
        ]
    }

    private func loadProgramStory(from fileName: String) -> ProgramStory? {
        // Try to load from Documents directory first (copied by MockDataService)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MockData/Goal/ongoing_programs/\(fileName).json")
        
        if let documentsURL = documentsPath, FileManager.default.fileExists(atPath: documentsURL.path) {
            do {
                let data = try Data(contentsOf: documentsURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let story = try decoder.decode(ProgramStory.self, from: data)
                return story
            } catch {
                print("Error loading program story from Documents: \(error)")
            }
        }
        
        // Fallback to Bundle
        let resourceName = fileName
        let resourceExtension = "json"
        let subdirectory = "MockData/Goal/ongoing_programs"

        guard let bundleUrl = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension, subdirectory: subdirectory) else {
            print("⚠️ File not found in Bundle: \(subdirectory)/\(resourceName).\(resourceExtension)")
            return nil
        }

        do {
            let data = try Data(contentsOf: bundleUrl)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let story = try decoder.decode(ProgramStory.self, from: data)
            return story
        } catch {
            print("Error loading or decoding program story from \(fileName).json: \(error)")
            return nil
        }
    }

    private func createMockNewPrograms() {
        // Load new programs from new_programs folder
        let fileNames = ["P004-UUID-0004-0004", "P005-UUID-0005-0005", "P006-UUID-0006-0006", "P007-UUID-0007-0007", "P008-UUID-0008-0008"]

        var loadedPrograms: [Program] = []
        print("🔍 [GoalViewModel] Starting to load new programs...")

        for fileName in fileNames {
            print("📁 [GoalViewModel] Loading program: \(fileName)")
            if let program = loadNewProgram(from: fileName) {
                loadedPrograms.append(program)
                print("✅ [GoalViewModel] Successfully loaded program: \(program.name)")
            } else {
                print("❌ [GoalViewModel] Failed to load program: \(fileName)")
            }
        }

        newPrograms = loadedPrograms
        print("📊 [GoalViewModel] Total new programs loaded: \(newPrograms.count)")
    }

    private func loadNewProgram(from fileName: String) -> Program? {
        // Try to load from Documents directory first (copied by MockDataService)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MockData/Goal/new_programs/\(fileName).json")
        
        print("📂 [loadNewProgram] Checking Documents path: \(documentsPath?.path ?? "nil")")
        if let documentsURL = documentsPath, FileManager.default.fileExists(atPath: documentsURL.path) {
            print("📂 [loadNewProgram] File exists in Documents: \(documentsURL.path)")
            do {
                let data = try Data(contentsOf: documentsURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let program = try decoder.decode(Program.self, from: data)
                return program
            } catch {
                print("❌ [loadNewProgram] Error loading new program from Documents: \(error)")
            }
        } else {
            print("📂 [loadNewProgram] File not found in Documents; falling back to Bundle")
        }
        
        // Fallback: try to load from Bundle's MockData/Goal/new_programs, then root
        let subdirectory = "MockData/Goal/new_programs"
        if let bundleUrl = Bundle.main.url(forResource: fileName, withExtension: "json", subdirectory: subdirectory) {
            do {
                let data = try Data(contentsOf: bundleUrl)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let program = try decoder.decode(Program.self, from: data)
                print("📂 [loadNewProgram] Loaded program from Bundle (subdirectory): \(bundleUrl.path)")
                return program
            } catch {
                print("❌ [loadNewProgram] Error loading new program from Bundle (subdirectory): \(error)")
                return nil
            }
        } else if let bundleUrlRoot = Bundle.main.url(forResource: fileName, withExtension: "json") {
            // Try root of Bundle
            do {
                let data = try Data(contentsOf: bundleUrlRoot)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let program = try decoder.decode(Program.self, from: data)
                print("📂 [loadNewProgram] Loaded program from Bundle (root): \(bundleUrlRoot.path)")
                return program
            } catch {
                print("❌ [loadNewProgram] Error loading new program from Bundle (root): \(error)")
                return nil
            }
        } else {
            // Debug: list files in subdirectory if present
            if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: subdirectory) {
                print("📂 [loadNewProgram] Bundle contains \(urls.count) files in \(subdirectory)")
            } else {
                print("📂 [loadNewProgram] Bundle has no files in subdirectory \(subdirectory)")
            }

            print("⚠️ [loadNewProgram] File not found in Bundle: \(subdirectory)/\(fileName).json or root")
        }
        
        return nil
    }
    
    private func createMockProgramProgress() {
        for program in availablePrograms {
            let beforeMetrics: [String: Double] = [
                "mood": Double.random(in: 0.3...0.5),
                "stress": Double.random(in: 0.6...0.8),
                "energy": Double.random(in: 0.4...0.6),
                "focus": Double.random(in: 0.5...0.7)
            ]
            
            let currentMetrics: [String: Double] = [
                "mood": Double.random(in: 0.6...0.8),
                "stress": Double.random(in: 0.3...0.5),
                "energy": Double.random(in: 0.7...0.9),
                "focus": Double.random(in: 0.7...0.9)
            ]
            
            let improvementRate = (currentMetrics.values.reduce(0, +) - beforeMetrics.values.reduce(0, +)) / Double(beforeMetrics.count)
            
            // Generate progress history (30 days)
            var progressHistory: [ProgressPoint] = []
            for day in 0..<30 {
                let date = Calendar.current.date(byAdding: .day, value: -day, to: Date()) ?? Date()
                progressHistory.append(ProgressPoint(
                    date: date,
                    goalProgress: Double(day) / 30.0 + Double.random(in: -0.05...0.05),
                    presentProgress: Double(day) / 35.0 + Double.random(in: -0.05...0.05),
                    sessionsCompleted: day,
                    sessionsPlanned: 30
                ))
            }
            
            // Radar chart data
            let radarData: [RadarDataPoint] = [
                RadarDataPoint(label: "Mood", beforeValue: beforeMetrics["mood"] ?? 0.4, afterValue: currentMetrics["mood"] ?? 0.7),
                RadarDataPoint(label: "Stress", beforeValue: beforeMetrics["stress"] ?? 0.7, afterValue: currentMetrics["stress"] ?? 0.4),
                RadarDataPoint(label: "Energy", beforeValue: beforeMetrics["energy"] ?? 0.5, afterValue: currentMetrics["energy"] ?? 0.8),
                RadarDataPoint(label: "Focus", beforeValue: beforeMetrics["focus"] ?? 0.6, afterValue: currentMetrics["focus"] ?? 0.8)
            ]
            
            // Generate stories (3 pages)
            let stories: [ProgramStory] = [
                ProgramStory(
                    id: UUID(),
                    programId: program.id,
                    title: "Day 1: Getting Started",
                    subtitle: "Your first step to transformation",
                    pages: [
                        ProgramStoryPage(
                            pageNumber: 1,
                            contentType: ProgramStoryPageContentType.text,
                            content: ProgramStoryPageContent(headline: "Welcome", body: "Start your journey today with commitment and enthusiasm.")
                        ),
                        ProgramStoryPage(
                            pageNumber: 2,
                            contentType: ProgramStoryPageContentType.tip,
                            content: ProgramStoryPageContent(headline: "Pro Tip", body: "Set a specific time each day for this program.", mantra: "Consistency is key")
                        ),
                        ProgramStoryPage(
                            pageNumber: 3,
                            contentType: ProgramStoryPageContentType.motivation,
                            content: ProgramStoryPageContent(mantra: "Every small step leads to great progress!")
                        )
                    ],
                    isViewed: false,
                    createdAt: Date()
                )
            ]
            
            let progress = ProgramProgress(
                id: UUID(),
                programId: program.id,
                goalId: selectedGoal?.id ?? UUID(),
                accountId: UUID(),
                beforeMetrics: beforeMetrics,
                currentMetrics: currentMetrics,
                improvementRate: max(0, improvementRate),
                progressHistory: progressHistory,
                stories: stories,
                radarChartData: radarData,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            programProgress[program.id.uuidString] = progress
        }
    }
}

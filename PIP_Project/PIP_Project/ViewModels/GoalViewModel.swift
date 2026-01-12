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
    @Published var activeEnrollments: [ProgramEnrollment] = []   // Active enrollments from DB
    @Published var ongoingPrograms: [Program] = []              // Programs corresponding to active enrollments
    @Published var currentProgramIndex: Int = 0
    @Published var programProgress: [String: ProgramProgress] = [:]  // programId -> ProgramProgress
    @Published var selectedProgram: Program?                    // For Sheet display
    @Published var newPrograms: [Program] = []                  // New/Recommended programs
    
    // MARK: - Dependencies
    private let dataService: DataServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        if let service = dataService {
            self.dataService = service
        } else {
            // Use active DataService by default (consistent with Onboarding)
            self.dataService = DataServiceManager.shared.currentService
        }
        loadInitialData()
    }

    // MARK: - Public Methods

    /// Load initial data from Firebase
    func loadInitialData() {
        print("📥 [GoalViewModel] Loading initial data...")
        isLoading = true
        errorMessage = nil

        // Fetch Goals from Firebase
        dataService.fetchGoals()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ [GoalViewModel] Error fetching goals: \(error)")
                        self?.errorMessage = error.localizedDescription
                        // Fallback to mock data if Firebase fails
                        self?.createMockGoals()
                    }
                },
                receiveValue: { [weak self] goals in
                    print("✅ [GoalViewModel] Fetched \(goals.count) goals from Firebase")
                    self?.activeGoals = goals.filter { $0.status == .active }
                    if self?.activeGoals.isEmpty == true {
                        // If no goals exist, create mock data for demo
                        self?.createMockGoals()
                    }
                    self?.selectFirstGoal()
                }
            )
            .store(in: &cancellables)

        // Fetch Programs from Firebase
        dataService.fetchPrograms()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ [GoalViewModel] Error fetching programs: \(error)")
                        self?.errorMessage = error.localizedDescription
                        // Fallback to mock data
                        self?.createMockPrograms()
                        self?.createMockNewPrograms()
                    }
                },
                receiveValue: { [weak self] programs in
                    print("✅ [GoalViewModel] Fetched \(programs.count) programs from Firebase")
                    self?.availablePrograms = programs
                    self?.newPrograms = programs.filter { $0.isRecommended }.prefix(5).map { $0 }
                    if self?.availablePrograms.isEmpty == true {
                        // If no programs exist, create mock data for demo
                        self?.createMockPrograms()
                        self?.createMockNewPrograms()
                    }
                    // self?.createMockProgramProgress() // Removed mock progress generation, now driven by enrollments
                    self?.updateOngoingPrograms() // Update again in case programs loaded after enrollments
                }
            )
            .store(in: &cancellables)
            
        // Fetch Active Program Enrollments
        dataService.fetchProgramEnrollments()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ [GoalViewModel] Error fetching enrollments: \(error)")
                    }
                },
                receiveValue: { [weak self] enrollments in
                    print("✅ [GoalViewModel] Fetched \(enrollments.count) enrollments")
                    self?.activeEnrollments = enrollments
                    self?.updateOngoingPrograms()
                }
            )
            .store(in: &cancellables)
    }

    /// Save a new goal to Firebase
    func saveGoal(_ goal: Goal) {
        print("💾 [GoalViewModel] Saving goal: \(goal.title)")
        dataService.saveGoal(goal)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ [GoalViewModel] Error saving goal: \(error)")
                        self?.errorMessage = "Failed to save goal: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] savedGoal in
                    print("✅ [GoalViewModel] Goal saved successfully")
                    // Add to local array if not already present
                    if let index = self?.activeGoals.firstIndex(where: { $0.id == savedGoal.id }) {
                        self?.activeGoals[index] = savedGoal
                    } else {
                        self?.activeGoals.append(savedGoal)
                    }
                }
            )
            .store(in: &cancellables)
    }

    /// Update existing goal in Firebase
    func updateGoal(_ goal: Goal) {
        print("🔄 [GoalViewModel] Updating goal: \(goal.title)")
        dataService.updateGoal(goal)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ [GoalViewModel] Error updating goal: \(error)")
                        self?.errorMessage = "Failed to update goal: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] updatedGoal in
                    print("✅ [GoalViewModel] Goal updated successfully")
                    if let index = self?.activeGoals.firstIndex(where: { $0.id == updatedGoal.id }) {
                        self?.activeGoals[index] = updatedGoal
                    }
                }
            )
            .store(in: &cancellables)
    }

    /// Delete goal from Firebase
    func deleteGoal(_ goalId: UUID) {
        print("🗑️ [GoalViewModel] Deleting goal: \(goalId)")
        dataService.deleteGoal(id: goalId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ [GoalViewModel] Error deleting goal: \(error)")
                        self?.errorMessage = "Failed to delete goal: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] _ in
                    print("✅ [GoalViewModel] Goal deleted successfully")
                    self?.activeGoals.removeAll { $0.id == goalId }
                    self?.selectFirstGoal()
                }
            )
            .store(in: &cancellables)
    }
    
    /// Select first active goal
    func selectFirstGoal() {
        if let firstGoal = activeGoals.first {
            selectedGoal = firstGoal
            selectedGoal = firstGoal
            // Note: ongoingPrograms is now driven by activeEnrollments, not Goal category
            // If we wanted to filter enrolled programs by the selected Goal, we could do it here
            // But per new design, Programs are independent.
            // keeping ongoingPrograms as is (all active enrollments)
            
            // If ongoingPrograms is empty, UI handles fallback.
            currentProgramIndex = 0
        }
    }
    
    /// Update ongoingPrograms based on activeEnrollments and availablePrograms
    private func updateOngoingPrograms() {
        ongoingPrograms = availablePrograms.filter { program in
            activeEnrollments.contains { $0.programId == program.id }
        }
        
        // Fetch missions for these programs if needed
        fetchMissionsForOngoingPrograms()
        
        // Generate progress objects for enrolled programs
        generateProgramProgressData()
    }
    
    private func fetchMissionsForOngoingPrograms() {
        for program in ongoingPrograms {
            // Only fetch if missions are missing
            if program.missions == nil || program.missions!.isEmpty {
                print("📥 [GoalViewModel] Fetching missions for enrolled program: \(program.name)")
                dataService.fetchProgramMissions(for: program.id)
                    .receive(on: DispatchQueue.main)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                print("❌ [GoalViewModel] Error fetching missions for \(program.name): \(error)")
                            }
                        },
                        receiveValue: { [weak self] missions in
                            print("✅ [GoalViewModel] Fetched \(missions.count) missions for \(program.name)")
                            
                            // Update availablePrograms with new missions
                            if let index = self?.availablePrograms.firstIndex(where: { $0.id == program.id }) {
                                var updatedProgram = self?.availablePrograms[index]
                                updatedProgram?.missions = missions
                                self?.availablePrograms[index] = updatedProgram!
                                
                                // Refresh ongoingPrograms
                                self?.ongoingPrograms = self?.availablePrograms.filter { p in
                                    self?.activeEnrollments.contains { $0.programId == p.id } ?? false
                                } ?? []
                                
                                // Ensure UI updates
                                self?.objectWillChange.send()
                            }
                        }
                    )
                    .store(in: &cancellables)
            }
        }
    }
    
    private func generateProgramProgressData() {
        var newProgress: [String: ProgramProgress] = [:]
        
        for enrollment in activeEnrollments {
            guard let program = availablePrograms.first(where: { $0.id == enrollment.programId }) else { continue }
            
            // Generate ProgramProgress from Enrollment
            // Using logic similar to createMockProgramProgress but based on real enrollment data
            
            let beforeMetrics = enrollment.initialMetrics ?? [:]
            // Current metrics: in real app, fetch latest. For now, assume same or simulate change?
            // Let's just use beforeMetrics for now to avoid showing broken data
            let currentMetrics = beforeMetrics 
            
            let improvementRate = 0.0 // Calculate if we had current metrics
            
            // Progress History from completedDays
            // We can map completed days to ProgressPoints
            var progressHistory: [ProgressPoint] = []
            // This is a simplification; ideally we store dates of completion.
            // Enrollment has completedDays (Set<Int>).
            
            let radarData: [RadarDataPoint] = beforeMetrics.map { key, value in
                RadarDataPoint(label: key.capitalized, beforeValue: value, afterValue: value) // No change shown yet
            }
            
            // Stories - reusing program stories if available
            let stories = program.stories ?? []
            
            let progress = ProgramProgress(
                id: UUID(), // ephemeral ID for view model
                programId: program.id,
                goalId: UUID(), // Legacy: Goal ID. Programs are independent now. Use dummy or first goal.
                accountId: enrollment.accountId,
                beforeMetrics: beforeMetrics,
                currentMetrics: currentMetrics,
                improvementRate: improvementRate,
                progressHistory: progressHistory,
                stories: stories,
                radarChartData: radarData,
                createdAt: enrollment.createdAt,
                updatedAt: enrollment.updatedAt
            )
            
            newProgress[program.id.uuidString] = progress
        }
        
        self.programProgress = newProgress
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
                accountId: String(),
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
                missionCount: 21,
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
                missionCount: 30,
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
                missionCount: 70,
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

        for fileName in fileNames {
            if let program = loadNewProgram(from: fileName) {
                loadedPrograms.append(program)
            }
        }

        newPrograms = loadedPrograms
    }

    private func loadNewProgram(from fileName: String) -> Program? {
        // Try to load from Documents directory first (copied by MockDataService)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("MockData/Goal/new_programs/\(fileName).json")

        if let documentsURL = documentsPath, FileManager.default.fileExists(atPath: documentsURL.path) {
            do {
                let data = try Data(contentsOf: documentsURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let program = try decoder.decode(Program.self, from: data)
                return program
            } catch {
                // Failed to load from Documents, will try Bundle next
            }
        }

        // Fallback: try to load from Bundle's MockData/Goal/new_programs, then root
        let subdirectory = "MockData/Goal/new_programs"
        if let bundleUrl = Bundle.main.url(forResource: fileName, withExtension: "json", subdirectory: subdirectory) {
            do {
                let data = try Data(contentsOf: bundleUrl)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let program = try decoder.decode(Program.self, from: data)
                return program
            } catch {
                // Failed to load from Bundle subdirectory, will try root
            }
        } else if let bundleUrlRoot = Bundle.main.url(forResource: fileName, withExtension: "json") {
            // Try root of Bundle
            do {
                let data = try Data(contentsOf: bundleUrlRoot)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let program = try decoder.decode(Program.self, from: data)
                return program
            } catch {
                // Failed to load program from all locations
                return nil
            }
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
                accountId: String(),  // Empty string for mock data
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

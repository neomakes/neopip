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
    
    // MARK: - Dependencies
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// Load initial data
    func loadInitialData() {
        isLoading = true
        createMockGoals()
        createMockPrograms()
        createMockProgramProgress()
        selectFirstGoal()
        isLoading = false
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
                    colorTheme: .amber,
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
                    colorTheme: .blue,
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
                    colorTheme: .amber,
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

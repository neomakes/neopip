//
//  OnboardingViewModel.swift
//  PIP_Project
//
//  ViewModel for onboarding flow
//  Follows ONBOARDING_FLOW_DESIGN.md specification
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class OnboardingViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var currentStep: OnboardingStep = .welcome
    @Published var selectedGoals: [GoalCategory] = []
    @Published var selectedPrograms: [UUID] = []
    @Published var consentedDataTypes: [String] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let authStateManager = AuthStateManager.shared
    private let authService = AuthService.shared
    private let dataService: DataServiceProtocol
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        if let service = dataService {
            self.dataService = service
        } else {
            // Use the active DataService by default (e.g., Firebase in DEV/PROD)
            // This ensures onboarding writes go to the real backend instead of the mock store.
            self.dataService = DataServiceManager.shared.currentService
        }
    }

    // MARK: - Onboarding Steps

    enum OnboardingStep: String, CaseIterable {
        case welcome
        case goalSelection
        case programSelection
        case dataConsent
        case insightPreview
        case complete
    }

    // MARK: - Progress

    var progress: Double {
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep) else { return 0 }
        return Double(currentIndex + 1) / Double(allSteps.count)
    }

    var stepNumber: Int {
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep) else { return 0 }
        return currentIndex + 1
    }

    var totalSteps: Int {
        return OnboardingStep.allCases.count
    }

    // MARK: - Navigation

    /// Move to next step
    func nextStep() {
        withAnimation(.easeInOut) {
            switch currentStep {
            case .welcome:
                currentStep = .goalSelection
            case .goalSelection:
                if !selectedGoals.isEmpty {
                    currentStep = .programSelection
                }
            case .programSelection:
                currentStep = .dataConsent
            case .dataConsent:
                if !consentedDataTypes.isEmpty {
                    currentStep = .insightPreview
                }
            case .insightPreview:
                currentStep = .complete
            case .complete:
                break
            }
        }
    }

    /// Move to previous step
    func previousStep() {
        withAnimation(.easeInOut) {
            switch currentStep {
            case .welcome:
                break
            case .goalSelection:
                currentStep = .welcome
            case .programSelection:
                currentStep = .goalSelection
            case .dataConsent:
                currentStep = .programSelection
            case .insightPreview:
                currentStep = .dataConsent
            case .complete:
                currentStep = .insightPreview
            }
        }
    }

    /// Skip current step
    func skipStep() {
        nextStep()
    }

    // MARK: - Goal Selection

    /// Toggle goal selection
    func toggleGoal(_ goal: GoalCategory) {
        if selectedGoals.contains(goal) {
            selectedGoals.removeAll { $0 == goal }
        } else {
            // Limit to 2 goals as per design
            if selectedGoals.count < 2 {
                selectedGoals.append(goal)
            }
        }
    }

    /// Check if goal is selected
    func isGoalSelected(_ goal: GoalCategory) -> Bool {
        return selectedGoals.contains(goal)
    }

    // MARK: - Program Selection

    /// Toggle program selection
    func toggleProgram(_ programId: UUID) {
        if selectedPrograms.contains(programId) {
            selectedPrograms.removeAll { $0 == programId }
        } else {
            selectedPrograms.append(programId)
        }
    }

    /// Check if program is selected
    func isProgramSelected(_ programId: UUID) -> Bool {
        return selectedPrograms.contains(programId)
    }

    // MARK: - Data Consent

    /// Toggle data type consent
    func toggleDataConsent(_ dataType: String) {
        if consentedDataTypes.contains(dataType) {
            consentedDataTypes.removeAll { $0 == dataType }
        } else {
            consentedDataTypes.append(dataType)
        }
    }

    /// Check if data type is consented
    func isDataConsented(_ dataType: String) -> Bool {
        return consentedDataTypes.contains(dataType)
    }

    /// Consent to all data types
    func consentToAll() {
        consentedDataTypes = [
            "mood", "stress", "energy", "focus",
            "weather", "location", "screenTime",
            "heartRate", "steps", "sleep",
            "productivity", "social", "distraction", "exploration",
            "fatigue", "activity", "nutrition"
        ]
    }

    // MARK: - Complete Onboarding

    /// Complete onboarding and save state
    func completeOnboarding() async {
        isLoading = true
        errorMessage = nil

        // Create anonymous user if not authenticated
        if !authService.isAuthenticated {
            // User can use app without account (anonymous mode)
            // Identity will be created when needed
        }

        // Save onboarding state
        let onboardingState = OnboardingState(
            isCompleted: true,
            completedSteps: OnboardingStep.allCases.map { $0.rawValue },
            selectedGoals: selectedGoals.map { $0.rawValue },
            completedAt: Date(),
            skippedSteps: []
        )

        // Create and save UserProfile to Firebase
        if authService.isAuthenticated {
            let userProfile = UserProfile(
                accountId: authService.currentUser?.uid ?? "",
                displayName: authService.currentUser?.displayName,
                email: authService.currentUser?.email,
                profileImageURL: authService.currentUser?.photoURL?.absoluteString,
                backgroundImageURL: nil,
                createdAt: Date(),
                lastActiveAt: Date(),
                preferences: UserPreferences(
                    theme: .system,
                    notificationsEnabled: true,
                    language: "en",
                    timeZone: TimeZone.current.identifier
                ),
                onboardingState: onboardingState,
                initialGoals: selectedGoals,
                firstJournalDate: nil,
                enabledDataTypes: consentedDataTypes,
                anonymizationLevel: .none, // Default to none aka internal use only
                permissions: nil // Permissions managed by device system currently
            )

            // Ensure Identity Mapping exists
            print("🔑 [Onboarding] Ensuring identity mapping exists...")
            do {
                let mappingId = try await IdentityMappingService.shared.getAnonymousUserId()
                print("✅ [Onboarding] Identity mapping verified: \(mappingId)")
            } catch {
                print("❌ [Onboarding] Failed to create/verify identity mapping: \(error)")
                self.errorMessage = "Failed to setup identity. Please try again."
                isLoading = false
                return
            }

            // Save profile to Firebase
            print("💾 [Onboarding] Saving user profile to Firebase...")
            await saveUserProfile(userProfile)

            // Create initial UserStats
            let initialStats = UserStats(
                accountId: authService.currentUser?.uid ?? "",
                totalDataPoints: 0,
                totalGems: 0,
                streakDays: 0,
                lastRecordedAt: nil,
                updatedAt: Date()
            )

            // Save initial stats to Firebase
            print("💾 [Onboarding] Saving initial user stats to Firebase...")
            await saveUserStats(initialStats)

            // Create Goal documents for each selected goal
            print("💾 [Onboarding] Creating Goal documents...")
            for goalCategory in selectedGoals {
                await createGoal(for: goalCategory)
            }

            // Create ProgramEnrollment documents for each selected program
            print("💾 [Onboarding] Creating ProgramEnrollment documents...")
            for programId in selectedPrograms {
                await createProgramEnrollment(for: programId)
            }
        }

        // Mark as completed locally
        authStateManager.completeOnboarding()

        // Save selected goals and programs locally (backup)
        UserDefaults.standard.set(selectedGoals.map { $0.rawValue }, forKey: "initialGoals")
        UserDefaults.standard.set(selectedPrograms.map { $0.uuidString }, forKey: "selectedPrograms")
        UserDefaults.standard.set(consentedDataTypes, forKey: "consentedDataTypes")

        print("✅ [Onboarding] Completed successfully")

        isLoading = false
    }

    // MARK: - Private Helpers

    /// Create a Goal document for a selected category
    private func createGoal(for category: GoalCategory) async {
        let goal = Goal(
            id: UUID(),
            accountId: authService.currentUser?.uid ?? "",
            title: category.rawValue.capitalized,
            description: "Goal created during onboarding",
            category: category,
            targetDate: Calendar.current.date(byAdding: .month, value: 3, to: Date()),
            startDate: Date(),
            status: .active,
            progress: 0.0,
            gemVisualization: GemVisualization(
                gemType: .sphere,
                colorTheme: .teal,
                brightness: 0.5,
                size: 100.0
            ),
            milestones: [],
            relatedDataPointIds: [],
            createdAt: Date(),
            updatedAt: Date()
        )

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            dataService.saveGoal(goal)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        print("✅ [Onboarding] Goal created: \(goal.title)")
                    case .failure(let error):
                        print("❌ [Onboarding] Failed to create goal: \(error)")
                        self.errorMessage = "Failed to create goal: \(error.localizedDescription)"
                    }
                    continuation.resume()
                } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }

    /// Create a ProgramEnrollment document for a selected program
    private func createProgramEnrollment(for programId: UUID) async {
        let enrollment = ProgramEnrollment(
            id: UUID(),
            accountId: authService.currentUser?.uid ?? "",
            anonymousUserId: nil, // Will be set later by backend
            programId: programId,
            status: .active,
            startDate: Date(),
            targetCompletionDate: Calendar.current.date(byAdding: .day, value: 21, to: Date()),
            actualCompletionDate: nil,
            initialMetrics: [:],
            successProgress: 0.0,
            successRate: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            dataService.createProgramEnrollment(enrollment)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        print("✅ [Onboarding] Program enrollment created: \(enrollment.programIdString)")
                    case .failure(let error):
                        print("❌ [Onboarding] Failed to create program enrollment: \(error)")
                        self.errorMessage = "Failed to create program enrollment: \(error.localizedDescription)"
                    }
                    continuation.resume()
                } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }

    /// Save user profile to Firebase
    private func saveUserProfile(_ profile: UserProfile) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            dataService.saveUserProfile(profile)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        print("✅ [Onboarding] User profile saved successfully")
                    case .failure(let error):
                        print("❌ [Onboarding] Failed to save user profile: \(error)")
                        self.errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    }
                    continuation.resume()
                } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }

    /// Save user stats to Firebase
    private func saveUserStats(_ stats: UserStats) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            dataService.updateUserStats(stats)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        print("✅ [Onboarding] User stats saved successfully")
                    case .failure(let error):
                        print("❌ [Onboarding] Failed to save user stats: \(error)")
                        self.errorMessage = "Failed to save stats: \(error.localizedDescription)"
                    }
                    continuation.resume()
                } receiveValue: { _ in }
                .store(in: &cancellables)
        }
    }

    /// Check if can proceed to next step
    func canProceed() -> Bool {
        switch currentStep {
        case .welcome:
            return true
        case .goalSelection:
            return !selectedGoals.isEmpty
        case .programSelection:
            return true // Programs are optional
        case .dataConsent:
            return !consentedDataTypes.isEmpty
        case .insightPreview:
            return true
        case .complete:
            return true
        }
    }
}

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
    private let db = Firestore.firestore()

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
            "heartRate", "steps", "sleep"
        ]
    }

    // MARK: - Complete Onboarding

    /// Complete onboarding and save state
    func completeOnboarding() async {
        isLoading = true
        errorMessage = nil

        do {
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

            // Mark as completed locally
            authStateManager.completeOnboarding()

            // Save selected goals and programs
            UserDefaults.standard.set(selectedGoals.map { $0.rawValue }, forKey: "initialGoals")
            UserDefaults.standard.set(selectedPrograms.map { $0.uuidString }, forKey: "selectedPrograms")
            UserDefaults.standard.set(consentedDataTypes, forKey: "consentedDataTypes")

        } catch {
            errorMessage = "Failed to complete onboarding: \(error.localizedDescription)"
        }

        isLoading = false
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

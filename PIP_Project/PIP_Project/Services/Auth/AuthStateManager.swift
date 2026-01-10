//
//  AuthStateManager.swift
//  PIP_Project
//
//  Manages authentication state and app routing logic
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

/// Manages authentication state for the app
@MainActor
class AuthStateManager: ObservableObject {

    static let shared = AuthStateManager()

    // MARK: - Published Properties
    @Published var authState: AuthState = .loading

    // MARK: - Dependencies
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // 🧟 Check for "Zombie Session" (Authenticated in Keychain but no local data)
        // This happens on fresh install after deleting app without explicit logout
        if Auth.auth().currentUser != nil && !hasCompletedOnboarding() {
            print("🧟 [AuthStateManager] Zombie session detected! Cleaning up...")
            try? Auth.auth().signOut()
        }
        
        observeAuthChanges()
    }

    // MARK: - Auth State

    enum AuthState: Equatable {
        case loading
        case unauthenticated
        case authenticated
    }

    // MARK: - Public Methods

    /// Determine initial route based on auth state
    func determineInitialRoute() -> AppRoute {
        print("🧭 [AuthStateManager] Determining route...")

        // Step 1: Check authentication first
        let isAuth = authService.isAuthenticated
        print("   → isAuthenticated: \(isAuth)")

        if !isAuth {
            print("   ✅ Route: .login (not authenticated)")
            return .login
        }

        // Step 2: If authenticated, check onboarding status
        let hasOnboarded = hasCompletedOnboarding()
        print("   → hasCompletedOnboarding: \(hasOnboarded)")

        if !hasOnboarded {
            print("   ✅ Route: .onboarding (authenticated but not onboarded)")
            return .onboarding
        }

        // Step 3: Both authenticated and onboarded → go to home
        print("   ✅ Route: .home (authenticated and onboarded)")
        return .home
    }

    /// Handle auth state changes
    func handleAuthStateChange() {
        if authService.isAuthenticated {
            authState = .authenticated
        } else {
            authState = .unauthenticated
        }
    }

    /// Mark onboarding as completed
    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    /// Check if user has completed onboarding
    func hasCompletedOnboarding() -> Bool {
        let status = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        print("🔍 [AuthStateManager] hasCompletedOnboarding check: \(status)")
        return status
    }

    /// Reset onboarding state (for new users or testing)
    func resetOnboarding() {
        print("🔄 [AuthStateManager] Resetting onboarding state...")
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        print("✅ [AuthStateManager] Onboarding state reset to: false")
    }

    // MARK: - Private Methods

    /// Observe authentication changes
    private func observeAuthChanges() {
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                self?.handleAuthStateChange()
            }
            .store(in: &cancellables)
    }
}

// MARK: - App Route
enum AppRoute: Equatable {
    case onboarding
    case login
    case home
}

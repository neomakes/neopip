//
//  AuthStateManager.swift
//  PIP_Project
//
//  Manages authentication state and app routing logic
//

import Foundation
import SwiftUI
import Combine

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
        if authService.isAuthenticated {
            return .home
        } else {
            // Check if user has completed onboarding
            if hasCompletedOnboarding() {
                return .login
            } else {
                return .onboarding
            }
        }
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
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    /// Reset onboarding state (for testing)
    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
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

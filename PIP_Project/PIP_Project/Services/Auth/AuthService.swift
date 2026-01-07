//
//  AuthService.swift
//  PIP_Project
//
//  Firebase Authentication Service
//  Handles email/password authentication and user account management
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Service for managing Firebase Authentication
@MainActor
class AuthService: ObservableObject {

    static let shared = AuthService()

    // MARK: - Published Properties
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let identityMapping = IdentityMappingService.shared

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        self.currentUser = auth.currentUser
        self.isAuthenticated = auth.currentUser != nil
    }

    // MARK: - Auth State Listener

    /// Start listening to auth state changes
    func startAuthStateListener() {
        authStateHandle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
        }
    }

    /// Stop listening to auth state changes
    func stopAuthStateListener() {
        if let handle = authStateHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Email Authentication

    /// Sign up with email and password
    func signUpWithEmail(email: String, password: String, displayName: String?) async throws -> User {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            // Create Firebase Auth user
            let authResult = try await auth.createUser(withEmail: email, password: password)
            let user = authResult.user

            // Update display name if provided
            if let displayName = displayName {
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }

            // Create user account and profile in Firestore
            try await createUserAccount(user: user, displayName: displayName)

            // Create identity mapping
            let anonymousUserId = try await identityMapping.getAnonymousUserId()

            currentUser = user
            isAuthenticated = true

            return user
        } catch let error as NSError {
            errorMessage = mapAuthError(error)
            throw error
        }
    }

    /// Sign in with email and password
    func signInWithEmail(email: String, password: String) async throws -> User {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            let authResult = try await auth.signIn(withEmail: email, password: password)
            let user = authResult.user

            // Load or create identity mapping
            let anonymousUserId = try await identityMapping.getAnonymousUserId()

            currentUser = user
            isAuthenticated = true

            return user
        } catch let error as NSError {
            errorMessage = mapAuthError(error)
            throw error
        }
    }

    // MARK: - Sign Out & Delete

    /// Sign out current user
    func signOut() throws {
        try auth.signOut()
        try identityMapping.clearCache()

        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
    }

    /// Delete current user account
    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw AuthServiceError.userNotFound
        }

        isLoading = true
        defer { isLoading = false }

        // Request data deletion through IdentityMappingService
        try await identityMapping.requestDataDeletion(type: .account)

        // Delete Firebase Auth account
        try await user.delete()

        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Password Reset

    /// Send password reset email
    func sendPasswordResetEmail(email: String) async throws {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            errorMessage = mapAuthError(error)
            throw error
        }
    }

    // MARK: - Private Methods

    /// Create user account and profile in Firestore
    private func createUserAccount(user: User, displayName: String?) async throws {
        let accountId = UUID(uuidString: user.uid) ?? UUID()

        // Create UserAccount document
        let userAccount = UserAccount(
            id: accountId,
            email: user.email,
            displayName: displayName,
            createdAt: Date(),
            lastLoginAt: Date()
        )

        try db.collection("users")
            .document(user.uid)
            .collection("account")
            .document("info")
            .setData(from: userAccount)

        // Create UserProfile document
        let userProfile = UserProfile(
            accountId: accountId,
            displayName: displayName,
            email: user.email,
            profileImageURL: nil,
            backgroundImageURL: nil,
            createdAt: Date(),
            lastActiveAt: Date(),
            preferences: UserPreferences(
                theme: .dark,
                notificationsEnabled: true,
                language: "en",
                timeZone: TimeZone.current.identifier
            ),
            onboardingState: OnboardingState(
                isCompleted: false,
                completedSteps: [],
                selectedGoals: [],
                completedAt: nil,
                skippedSteps: []
            ),
            initialGoals: [],
            firstJournalDate: nil
        )

        try db.collection("users")
            .document(user.uid)
            .collection("profile")
            .document("info")
            .setData(from: userProfile)
    }

    /// Map Firebase Auth errors to user-friendly messages
    private func mapAuthError(_ error: NSError) -> String {
        guard let errorCode = AuthErrorCode.Code(rawValue: error.code) else {
            return "An unknown error occurred. Please try again."
        }

        switch errorCode {
        case .invalidEmail:
            return "The email address is invalid."
        case .emailAlreadyInUse:
            return "This email address is already in use."
        case .weakPassword:
            return "The password is too weak. Please use at least 8 characters."
        case .wrongPassword:
            return "The password is incorrect."
        case .userNotFound:
            return "No account found with this email."
        case .networkError:
            return "Network error. Please check your connection."
        case .tooManyRequests:
            return "Too many attempts. Please try again later."
        case .userDisabled:
            return "This account has been disabled."
        default:
            return "Authentication failed. Please try again."
        }
    }
}

// MARK: - Auth Service Errors
enum AuthServiceError: Error {
    case userNotFound
    case invalidCredentials
    case networkError
    case unknownError

    var localizedDescription: String {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidCredentials:
            return "Invalid credentials"
        case .networkError:
            return "Network error"
        case .unknownError:
            return "Unknown error"
        }
    }
}

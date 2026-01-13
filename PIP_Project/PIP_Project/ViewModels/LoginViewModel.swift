//
//  LoginViewModel.swift
//  PIP_Project
//
//  ViewModel for login and signup flows
//

import Foundation
import SwiftUI
import PhotosUI
import Combine
import FirebaseAuth

@MainActor
class LoginViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var displayName: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isSignUpMode: Bool = false

    // MARK: - Dependencies
    private let authService = AuthService.shared
    private let storageService = FirebaseStorageService.shared

    // MARK: - Image Selection
    @Published var selectedImageItem: PhotosPickerItem? = nil {
        didSet {
            Task {
                await loadSelectedImage()
            }
        }
    }
    @Published var selectedUIImage: UIImage? = nil


    // MARK: - Validation

    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    var isPasswordValid: Bool {
        return password.count >= 8
    }

    var doPasswordsMatch: Bool {
        return password == confirmPassword
    }

    var canSubmit: Bool {
        if isSignUpMode {
            return isEmailValid && isPasswordValid && doPasswordsMatch && !displayName.isEmpty
        } else {
            return isEmailValid && !password.isEmpty
        }
    }

    // MARK: - Public Methods

    /// Toggle between sign in and sign up modes
    func toggleMode() {
        isSignUpMode.toggle()
        errorMessage = nil
    }

    /// Sign in with email and password
    func signIn() async {
        guard canSubmit else {
            errorMessage = "Please fill in all fields correctly."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await authService.signInWithEmail(email: email, password: password)
            // Navigation will be handled by AuthStateManager
        } catch let error as NSError {
            if let authError = AuthErrorCode(_bridgedNSError: error) {
                errorMessage = mapAuthErrorToMessage(authError)
            } else {
                errorMessage = authService.errorMessage ?? "Sign in failed. Please try again."
            }
        }

        isLoading = false
    }

    /// Sign up with email and password
    func signUp() async {
        guard canSubmit else {
            errorMessage = "Please fill in all fields correctly."
            return
        }

        guard doPasswordsMatch else {
            errorMessage = "Passwords do not match."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            _ = try await authService.signUpWithEmail(
                email: email,
                password: password,
                displayName: displayName
                // profileImage: selectedUIImage // FEATURE DISABLED: Storage Billing Issue
            )
            // Navigation will be handled by AuthStateManager
        } catch let error as NSError {
            if let authError = AuthErrorCode(_bridgedNSError: error) {
                errorMessage = mapSignUpErrorToMessage(authError)
            } else {
                errorMessage = authService.errorMessage ?? "Sign up failed. Please try again."
            }
        }

        isLoading = false
    }

    /// Send password reset email
    func resetPassword() async {
        guard isEmailValid else {
            errorMessage = "Please enter a valid email address."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.sendPasswordResetEmail(email: email)
            errorMessage = "Password reset email sent. Please check your inbox."
        } catch {
            errorMessage = authService.errorMessage ?? "Failed to send reset email."
        }

        isLoading = false
    }

    /// Clear all fields
    func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        errorMessage = nil
    }

    // MARK: - Private Methods
    
    private func loadSelectedImage() async {
        guard let item = selectedImageItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            await MainActor.run {
                self.selectedUIImage = uiImage
            }
        }
    }

    /// Map Firebase Auth errors to user-friendly messages for sign in
    private func mapAuthErrorToMessage(_ errorCode: AuthErrorCode) -> String {
        switch errorCode.code {
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email."
        case .invalidEmail:
            return "Invalid email format."
        case .networkError:
            return "Network error. Please check your connection."
        case .tooManyRequests:
            return "Too many failed attempts. Please try again later."
        case .userDisabled:
            return "This account has been disabled."
        default:
            return authService.errorMessage ?? "Sign in failed. Please try again."
        }
    }

    /// Map Firebase Auth errors to user-friendly messages for sign up
    private func mapSignUpErrorToMessage(_ errorCode: AuthErrorCode) -> String {
        switch errorCode.code {
        case .emailAlreadyInUse:
            return "This email is already registered. Please sign in instead."
        case .weakPassword:
            return "Password is too weak. Use at least 8 characters with mixed case and numbers."
        case .invalidEmail:
            return "Invalid email format."
        case .networkError:
            return "Network error. Please check your connection."
        case .tooManyRequests:
            return "Too many attempts. Please try again later."
        default:
            return authService.errorMessage ?? "Sign up failed. Please try again."
        }
    }
}

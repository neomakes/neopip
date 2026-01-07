//
//  LoginView.swift
//  PIP_Project
//
//  Login and signup view with email/password authentication
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var authStateManager: AuthStateManager
    @Environment(\.dismiss) private var dismiss
    @State private var showNextScreen = false
    @State private var nextRoute: AppRoute = .onboarding

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color(hex: "#202020")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 60)

                    // Logo or app name
                    VStack(spacing: 12) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.pip.home.buttonAddGrad1, Color.pip.home.buttonAddGrad2],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text("PIP")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            )

                        Text(viewModel.isSignUpMode ? "Create Account" : "Welcome Back")
                            .font(.pip.hero)
                            .foregroundColor(.white)

                        Text(viewModel.isSignUpMode ? "Sign up to get started" : "Sign in to continue")
                            .font(.pip.body)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 20)

                    // Input fields
                    VStack(spacing: 16) {
                        // Display Name (Sign Up only)
                        if viewModel.isSignUpMode {
                            CustomTextField(
                                placeholder: "Display Name",
                                text: $viewModel.displayName,
                                isSecure: false
                            )
                        }

                        // Email
                        CustomTextField(
                            placeholder: "Email",
                            text: $viewModel.email,
                            isSecure: false,
                            keyboardType: .emailAddress
                        )

                        // Password
                        CustomTextField(
                            placeholder: "Password",
                            text: $viewModel.password,
                            isSecure: true
                        )

                        // Confirm Password (Sign Up only)
                        if viewModel.isSignUpMode {
                            CustomTextField(
                                placeholder: "Confirm Password",
                                text: $viewModel.confirmPassword,
                                isSecure: true
                            )
                        }
                    }
                    .padding(.horizontal, 32)

                    // Error message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.pip.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Submit button
                    Button(action: {
                        Task {
                            if viewModel.isSignUpMode {
                                await viewModel.signUp()
                            } else {
                                await viewModel.signIn()
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(viewModel.isSignUpMode ? "Sign Up" : "Sign In")
                                    .font(.pip.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.pip.home.buttonAddGrad1,
                                    Color.pip.home.buttonAddGrad2
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .opacity(viewModel.canSubmit ? 1.0 : 0.5)
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isLoading)
                    .padding(.horizontal, 32)

                    // Toggle mode button
                    Button(action: {
                        viewModel.toggleMode()
                    }) {
                        HStack(spacing: 4) {
                            Text(viewModel.isSignUpMode ? "Already have an account?" : "Don't have an account?")
                                .font(.pip.body)
                                .foregroundColor(.gray)
                            Text(viewModel.isSignUpMode ? "Sign In" : "Sign Up")
                                .font(.pip.body)
                                .foregroundColor(Color.pip.home.buttonAddGrad1)
                        }
                    }

                    // Forgot password (Sign In only)
                    if !viewModel.isSignUpMode {
                        Button(action: {
                            Task {
                                await viewModel.resetPassword()
                            }
                        }) {
                            Text("Forgot Password?")
                                .font(.pip.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Spacer()
                }
            }
        }
        .onChange(of: authService.isAuthenticated) { oldValue, newValue in
            if newValue {
                // User just logged in successfully
                // Determine next route based on onboarding status
                nextRoute = authStateManager.hasCompletedOnboarding() ? .home : .onboarding
                showNextScreen = true
            }
        }
        .fullScreenCover(isPresented: $showNextScreen) {
            if nextRoute == .onboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textInputAutocapitalization(.never)
            }
        }
        .font(.pip.body)
        .foregroundColor(.white)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.pip.home.buttonAddGrad1.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    LoginView()
}

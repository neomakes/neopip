// PIP_Project/PIP_Project/Views/Shared/SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @Binding var path: NavigationPath
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var authStateManager: AuthStateManager

    @State private var isLoggingOut = false
    @State private var showLogoutAlert = false

    var body: some View {
        List {
            Section(header: Text("Account").foregroundColor(.gray)) {
                Button(action: {
                    showLogoutAlert = true
                }) {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                }
                .listRowBackground(Color.white.opacity(0.05))
                .disabled(isLoggingOut)
            }

            #if DEBUG
            Section(header: Text("Debug").foregroundColor(.gray)) {
                Button(action: {
                    resetOnboardingAndLogout()
                }) {
                    Label("Reset Onboarding & Sign Out", systemImage: "arrow.counterclockwise")
                        .foregroundColor(.orange)
                }
                .listRowBackground(Color.white.opacity(0.05))
                .disabled(isLoggingOut)
            }
            #endif

            Section(header: Text("Legal").foregroundColor(.gray)) {
                Button(action: {
                    path.append(StatusRoute.licenses)
                }) {
                    Label("Open Source Licenses", systemImage: "text.book.closed.fill")
                }
                .listRowBackground(Color.white.opacity(0.05))
            }

            Section(header: Text("Device Info").foregroundColor(.gray)) {
                LabeledContent("Version", value: "1.0.0 (Build 2025)")
                    .listRowBackground(Color.white.opacity(0.05))
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                performLogout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .overlay {
            if isLoggingOut {
                ProgressView("Signing out...")
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }
        }
    }

    private func performLogout() {
        isLoggingOut = true
        do {
            // 📝 WriteViewModel 캐시 정리 (Firebase는 계정별로 자동 격리)
            WriteViewModel().clearDraftDataForLogout()
            
            try authService.signOut()
            print("✅ Logged out successfully")
        } catch {
            print("❌ Logout failed: \(error)")
        }
        isLoggingOut = false
    }

    private func resetOnboardingAndLogout() {
        isLoggingOut = true
        authStateManager.resetOnboarding()
        print("🔄 Onboarding reset")
        do {
            // 📝 WriteViewModel 캐시 정리 (Firebase는 계정별로 자동 격리)
            WriteViewModel().clearDraftDataForLogout()
            
            try authService.signOut()
            print("✅ Logged out successfully with onboarding reset")
        } catch {
            print("❌ Logout failed: \(error)")
        }
        isLoggingOut = false
    }
}
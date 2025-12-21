import SwiftUI

@main
struct PIP_ProjectApp: App {
    var body: some Scene {
        WindowGroup {
            // Entry point for the application
            LaunchScreenWrapper()
        }
    }
}

// MARK: - Launch Screen Wrapper
// Manages the transition from LaunchView to MainTabView
struct LaunchScreenWrapper: View {
    @State private var isLoading: Bool = true

    var body: some View {
        ZStack {
            if isLoading {
                // Initial Launch View (Views/LaunchView.swift)
                LaunchView()
                    .transition(.opacity) // Smooth fade transition
            } else {
                // Main Application Content (Views/MainTabView.swift)
                MainTabView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            startLoadingProcess()
        }
    }

    private func startLoadingProcess() {
        // Delay for 1.0 second then switch view
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.8)) {
                isLoading = false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LaunchScreenWrapper()
}

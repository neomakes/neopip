import SwiftUI
import Firebase

// MARK: - App Delegate
// Manages application-level events, including Firebase setup
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase
        // Note: Make sure the `GoogleService-Info.plist` file is added to the project target.
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully!")
        
        return true
    }
}

@main
struct PIP_ProjectApp: App {
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // MARK: - Environment Configuration
    // Set to `true` to use the real FirebaseDataService, `false` to use MockDataService.
    // This allows for easy switching between development/testing and production environments.
    private let useFirebase = false 

    var body: some Scene {
        WindowGroup {
            // Entry point for the application, passing the data service choice
            LaunchScreenWrapper(useFirebase: useFirebase)
        }
    }
}

// MARK: - Launch Screen Wrapper
// Manages the transition from LaunchView to MainTabView
struct LaunchScreenWrapper: View {
    @State private var isLoading: Bool = true
    let useFirebase: Bool // Receive the data service choice

    var body: some View {
        ZStack {
            if isLoading {
                // Initial Launch View (Views/LaunchView.swift)
                LaunchView()
                    .transition(.opacity) // Smooth fade transition
            } else {
                // Main Application Content, now configured with the selected data service
                MainTabView(useFirebase: useFirebase)
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
    LaunchScreenWrapper(useFirebase: false)
}

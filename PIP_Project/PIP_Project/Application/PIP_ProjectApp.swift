import SwiftUI
import Firebase

// MARK: - App Delegate
// Manages application-level events, including Firebase setup
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Determine current environment
        let environment = getCurrentEnvironment()

        // Configure Firebase for non-mock environments
        if let configFileName = environment.firebaseConfigFileName {
            configureFirebase(configFileName: configFileName, environment: environment)
        } else {
            print("📦 Mock environment - Firebase not configured")
        }

        return true
    }

    private func getCurrentEnvironment() -> AppEnvironment {
        #if USE_MOCK_DATA
        return .mock
        #elseif DEV
        return .development
        #else
        return .production
        #endif
    }

    private func configureFirebase(configFileName: String, environment: AppEnvironment) {
        // Try to load custom config file (for future prod/dev separation)
        if let filePath = Bundle.main.path(forResource: configFileName, ofType: "plist"),
           let options = FirebaseOptions(contentsOfFile: filePath) {
            FirebaseApp.configure(options: options)
            print("🔥 Firebase configured successfully! Environment: \(environment.displayName)")
            print("🔥 Project ID: \(options.projectID ?? "Unknown")")
        } else {
            // Fallback to default GoogleService-Info.plist
            FirebaseApp.configure()
            print("🔥 Firebase configured with default plist! Environment: \(environment.displayName)")
        }
    }
}

@main
struct PIP_ProjectApp: App {
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // MARK: - State Management
    @StateObject private var authStateManager = AuthStateManager.shared
    @StateObject private var authService = AuthService.shared

    // MARK: - Environment Configuration
    // This determines which data service to use based on build configuration
    // - USE_MOCK_DATA: Uses MockDataService (UI testing)
    // - DEV: Uses FirebaseDataService with DEV project
    // - Production: Uses FirebaseDataService with PROD project (future)
    #if USE_MOCK_DATA
    @StateObject private var dataServiceManager = DataServiceManager(environment: .mock)
    #elseif DEV
    @StateObject private var dataServiceManager = DataServiceManager(environment: .development)
    #else
    @StateObject private var dataServiceManager = DataServiceManager(environment: .production)
    #endif

    var body: some Scene {
        WindowGroup {
            // Entry point for the application, passing the data service choice
            LaunchScreenWrapper()
                .environmentObject(dataServiceManager)
                .environmentObject(authStateManager)
                .environmentObject(authService)
        }
    }
}

// MARK: - Launch Screen Wrapper
// Manages the transition from LaunchView to Onboarding, Login, or MainTabView
struct LaunchScreenWrapper: View {
    @EnvironmentObject var dataServiceManager: DataServiceManager
    @EnvironmentObject var authStateManager: AuthStateManager
    @EnvironmentObject var authService: AuthService

    @State private var isLoading: Bool = true
    @State private var currentRoute: AppRoute = .onboarding

    var body: some View {
        ZStack {
            if isLoading {
                // Initial Launch View (Views/LaunchView.swift)
                LaunchView()
                    .transition(.opacity) // Smooth fade transition
            } else {
                // Route based on onboarding and auth status
                switch currentRoute {
                case .onboarding:
                    OnboardingView()
                        .transition(.opacity)
                case .login:
                    LoginView()
                        .transition(.opacity)
                case .home:
                    MainTabView()
                        .transition(.opacity)
                }
            }
        }
        .onAppear {
            startLoadingProcess()
        }
    }

    private func startLoadingProcess() {
        // Start auth listener
        authService.startAuthStateListener()

        // Delay for 1.0 second then determine route
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            // Determine routing based on onboarding and auth status
            let route = authStateManager.determineInitialRoute()

            withAnimation(.easeInOut(duration: 0.8)) {
                currentRoute = route
                isLoading = false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LaunchScreenWrapper()
        .environmentObject(DataServiceManager(environment: .mock))
        .environmentObject(AuthStateManager.shared)
        .environmentObject(AuthService.shared)
}

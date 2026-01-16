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
    func applicationWillTerminate(_ application: UIApplication) {
        // Ensure analytics are flushed on forced termination
        print("⚠️ [AppDelegate] App terminating, flushing navigation session...")
        // We still attempt to flush here just in case, but MainTabView should have handled it if it was active
        AnalyticsService.shared.endNavigationSession()
    }
}

@main
struct PIP_ProjectApp: App {
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // MARK: - State Management
    @Environment(\.scenePhase) private var scenePhase
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
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    // Removed global analytics session management to avoid race conditions with MainTabView
                    // MainTabView now handles its own session lifecycle
                }
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
        .onChange(of: authStateManager.authState) { oldValue, newValue in
            // React to auth state changes (e.g., sign out)
            handleAuthStateChange(newValue)
        }
    }

    private func startLoadingProcess() {
        // Start auth listener
        authService.startAuthStateListener()

        // Delay for 1.0 second then determine route
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            // Determine routing based on onboarding and auth status
            print("📱 [PIP_ProjectApp] Initial route determination...")
            let route = authStateManager.determineInitialRoute()
            print("✅ [PIP_ProjectApp] Initial route: \(route)")

            withAnimation(.easeInOut(duration: 0.8)) {
                currentRoute = route
                isLoading = false
            }
        }
    }

    private func handleAuthStateChange(_ newState: AuthStateManager.AuthState) {
        // Skip if still in loading phase
        guard !isLoading else {
            print("⏸️ [PIP_ProjectApp] Still loading, skipping auth state change")
            return
        }

        // Determine new route based on auth state
        print("📱 [PIP_ProjectApp] Auth state changed to: \(newState)")
        let newRoute = authStateManager.determineInitialRoute()
        print("🎯 [PIP_ProjectApp] New route determined: \(newRoute) (current: \(currentRoute))")

        // Only update if route actually changed
        guard newRoute != currentRoute else {
            print("✋ [PIP_ProjectApp] Route unchanged, no navigation needed")
            return
        }

        print("🔄 [PIP_ProjectApp] Navigating to: \(newRoute)")

        withAnimation(.easeInOut(duration: 0.5)) {
            currentRoute = newRoute
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

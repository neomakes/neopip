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
    // This flag determines which data service to use.
    // - In "Debug" mode (with USE_MOCK_DATA flag), it defaults to `false`, using `MockDataService`.
    // - In "Release" mode (or any configuration without the flag), it becomes `true`, using `FirebaseDataService`.
    #if USE_MOCK_DATA
    @StateObject private var dataServiceManager = DataServiceManager(useFirebase: false)
    #else
    @StateObject private var dataServiceManager = DataServiceManager(useFirebase: true)
    #endif 

    var body: some Scene {
        WindowGroup {
            // Entry point for the application, passing the data service choice
            LaunchScreenWrapper()
                .environmentObject(dataServiceManager)
        }
    }
}

// MARK: - Data Service Manager
// Manages the data service lifecycle and provides it to the app
@MainActor
class DataServiceManager: ObservableObject {
    @Published private(set) var dataService: DataServiceProtocol
    let useFirebase: Bool
    
    init(useFirebase: Bool) {
        self.useFirebase = useFirebase
        
        if useFirebase {
            print("🔥 Using Firebase Data Service")
            self.dataService = FirebaseDataService()
        } else {
            print("📦 Using Mock Data Service")
            self.dataService = MockDataService.shared
        }
    }
    
    // For switching data services at runtime (useful for testing)
    func switchToMock() {
        print("📦 Switching to Mock Data Service")
        dataService = MockDataService.shared
    }
    
    func switchToFirebase() {
        print("🔥 Switching to Firebase Data Service")
        dataService = FirebaseDataService()
    }
}

// MARK: - Launch Screen Wrapper
// Manages the transition from LaunchView to MainTabView
struct LaunchScreenWrapper: View {
    @EnvironmentObject var dataServiceManager: DataServiceManager
    @State private var isLoading: Bool = true

    var body: some View {
        ZStack {
            if isLoading {
                // Initial Launch View (Views/LaunchView.swift)
                LaunchView()
                    .transition(.opacity) // Smooth fade transition
            } else {
                // Main Application Content, now configured with the selected data service
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
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            withAnimation(.easeInOut(duration: 0.8)) {
                isLoading = false
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LaunchScreenWrapper()
        .environmentObject(DataServiceManager(useFirebase: false))
}

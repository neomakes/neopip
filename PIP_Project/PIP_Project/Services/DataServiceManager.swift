//
//  DataServiceManager.swift
//  PIP_Project
//
//  Manages the data service lifecycle and provides it to the app
//

import Foundation
import SwiftUI
import Combine

// MARK: - Data Service Manager
/// Manages the data service lifecycle and provides it to the app
@MainActor
class DataServiceManager: ObservableObject {
    static let shared = DataServiceManager(environment: AppEnvironment.current)

    @Published private(set) var dataService: DataServiceProtocol
    let environment: AppEnvironment

    /// Convenience property to access current service
    var currentService: DataServiceProtocol {
        return dataService
    }

    init(environment: AppEnvironment) {
        self.environment = environment

        switch environment {
        case .mock:
            print("📦 Using Mock Data Service")
            self.dataService = MockDataService.shared
        case .development, .production:
            print("\(environment.displayName) Using Firebase Data Service")
            self.dataService = FirebaseDataService(environment: environment)
        }
    }

    // For switching data services at runtime (useful for testing)
    func switchToMock() {
        print("📦 Switching to Mock Data Service")
        dataService = MockDataService.shared
    }

    func switchToFirebase(environment: AppEnvironment = .development) {
        print("\(environment.displayName) Switching to Firebase Data Service")
        dataService = FirebaseDataService(environment: environment)
    }
}

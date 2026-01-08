//
//  AppEnvironment.swift
//  PIP_Project
//
//  App environment configuration
//

import Foundation

// MARK: - App Environment
/// Defines the app's runtime environment
enum AppEnvironment {
    case mock        // Mock data for UI testing
    case development // Firebase DEV environment
    case production  // Firebase PROD environment

    /// Current environment based on compile flags
    static var current: AppEnvironment {
        #if USE_MOCK_DATA
        return .mock
        #elseif DEV
        return .development
        #else
        return .production
        #endif
    }

    var displayName: String {
        switch self {
        case .mock: return "📦 Mock"
        case .development: return "🔧 DEV"
        case .production: return "🚀 PROD"
        }
    }

    var firebaseConfigFileName: String? {
        switch self {
        case .mock:
            return nil
        case .development:
            return "GoogleService-Info" // For now, using single config
        case .production:
            return "GoogleService-Info-Prod" // Future: separate prod config
        }
    }
}

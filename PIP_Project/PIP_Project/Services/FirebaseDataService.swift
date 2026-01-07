//
//  FirebaseDataService.swift
//  PIP_Project
//
//  Created by Gemini on 2026/01/06.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

// Firebase implementation of DataServiceProtocol
@MainActor
class FirebaseDataService: DataServiceProtocol {

    private let db = Firestore.firestore()
    private let environment: AppEnvironment
    private let identityMapping = IdentityMappingService.shared

    // MARK: - Initialization
    init(environment: AppEnvironment = .development) {
        self.environment = environment
        print("🔥 FirebaseDataService initialized for \(environment.displayName)")
    }

    // MARK: - Helper Methods

    private func getAnonymousUserId() async throws -> UUID {
        return try await identityMapping.getAnonymousUserId()
    }
    
    // MARK: - TimeSeriesDataPoint

    func fetchDataPoints(for date: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    let anonymousUserId = try await self.getAnonymousUserId()
                    let calendar = Calendar.current
                    let startOfDay = calendar.startOfDay(for: date)
                    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

                    print("📥 [Firebase] Fetching data points for date: \(date)")

                    let snapshot = try await self.db
                        .collection("anonymous_users")
                        .document(anonymousUserId.uuidString)
                        .collection("data_points")
                        .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                        .whereField("date", isLessThan: Timestamp(date: endOfDay))
                        .order(by: "timestamp", descending: true)
                        .getDocuments()

                    let dataPoints = try snapshot.documents.compactMap { doc in
                        try doc.data(as: TimeSeriesDataPoint.self)
                    }

                    print("✅ [Firebase] Fetched \(dataPoints.count) data points for \(date)")
                    promise(.success(dataPoints))
                } catch {
                    print("❌ [Firebase] Error fetching data points: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchDataPoints(from startDate: Date, to endDate: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    let anonymousUserId = try await self.getAnonymousUserId()
                    let calendar = Calendar.current
                    let start = calendar.startOfDay(for: startDate)
                    let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!

                    print("📥 [Firebase] Fetching data points from \(startDate) to \(endDate)")

                    let snapshot = try await self.db
                        .collection("anonymous_users")
                        .document(anonymousUserId.uuidString)
                        .collection("data_points")
                        .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
                        .whereField("date", isLessThan: Timestamp(date: end))
                        .order(by: "timestamp", descending: true)
                        .getDocuments()

                    let dataPoints = try snapshot.documents.compactMap { doc in
                        try doc.data(as: TimeSeriesDataPoint.self)
                    }

                    print("✅ [Firebase] Fetched \(dataPoints.count) data points")
                    promise(.success(dataPoints))
                } catch {
                    print("❌ [Firebase] Error fetching data points: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func saveDataPoint(_ dataPoint: TimeSeriesDataPoint) -> AnyPublisher<TimeSeriesDataPoint, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    let anonymousUserId = try await self.getAnonymousUserId()

                    // Create a new data point with the anonymous user ID
                    var updatedDataPoint = dataPoint
                    updatedDataPoint.anonymousUserId = anonymousUserId

                    print("💾 [Firebase] Saving data point: \(updatedDataPoint.id)")

                    try self.db
                        .collection("anonymous_users")
                        .document(anonymousUserId.uuidString)
                        .collection("data_points")
                        .document(updatedDataPoint.id.uuidString)
                        .setData(from: updatedDataPoint)

                    print("✅ [Firebase] Saved data point successfully")
                    promise(.success(updatedDataPoint))
                } catch {
                    print("❌ [Firebase] Error saving data point: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveData(_ dataPoint: TimeSeriesDataPoint, for category: DataCategory) async throws {
        // TODO: Implement Firebase logic
        print("saveData for category not implemented in FirebaseDataService")
    }
    
    func deleteDataPoint(_ id: UUID) -> AnyPublisher<Void, Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    // MARK: - DailyGem
    func fetchDailyGems(from startDate: Date, to endDate: Date) -> AnyPublisher<[DailyGem], Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    func fetchDailyGem(for date: Date) -> AnyPublisher<DailyGem?, Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    func saveDailyGem(_ gem: DailyGem) -> AnyPublisher<DailyGem, Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    // MARK: - DailyStats
    func fetchDailyStats(for date: Date) -> AnyPublisher<DailyStats?, Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    func fetchDailyStats(from startDate: Date, to endDate: Date) -> AnyPublisher<[DailyStats], Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    // MARK: - UserStats
    func fetchUserStats() -> AnyPublisher<UserStats, Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    func updateUserStats(_ stats: UserStats) -> AnyPublisher<UserStats, Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    // MARK: - UserProfile
    func fetchUserProfile() -> AnyPublisher<UserProfile, Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    // MARK: - Achievements
    func fetchAchievements() -> AnyPublisher<[Achievement], Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    // MARK: - Value Analysis
    func fetchValueAnalysis() -> AnyPublisher<ValueAnalysis, Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    // MARK: - Analysis Cards
    func fetchAnalysisCards() -> AnyPublisher<[InsightAnalysisCard], Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    // MARK: - Insight Story
    func fetchInsightStory(for cardId: String) -> AnyPublisher<InsightStory, Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    // MARK: - Dashboard Data
    func fetchDashboardData() -> AnyPublisher<[String: [DashboardItem]], Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }

    // MARK: - Schemas
    func getSchemas(for category: DataCategory) -> [DataTypeSchema] {
        // TODO: Implement Firebase logic to fetch schemas
        return []
    }
}

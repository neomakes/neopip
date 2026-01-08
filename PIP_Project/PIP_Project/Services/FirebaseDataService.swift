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
        let anonymousUserId = try await getAnonymousUserId()

        // Create a new data point with the anonymous user ID and category
        var updatedDataPoint = dataPoint
        updatedDataPoint.anonymousUserId = anonymousUserId
        updatedDataPoint.category = category

        print("💾 [Firebase] Saving data for category \(category): \(updatedDataPoint.id)")

        try db
            .collection("anonymous_users")
            .document(anonymousUserId.uuidString)
            .collection("time_series_data")
            .document(updatedDataPoint.id.uuidString)
            .setData(from: updatedDataPoint)

        print("✅ [Firebase] Saved data for category \(category) successfully")
    }
    
    func deleteDataPoint(_ id: UUID) -> AnyPublisher<Void, Error> {
        // TODO: Implement Firebase logic
        return Fail(error: NSError(domain: "FirebaseDataService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not implemented"]))
            .eraseToAnyPublisher()
    }
    
    // MARK: - DailyGem
    func fetchDailyGems(from startDate: Date, to endDate: Date) -> AnyPublisher<[DailyGem], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    let calendar = Calendar.current
                    let start = calendar.startOfDay(for: startDate)
                    let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!

                    print("📥 [Firebase] Fetching daily gems from \(startDate) to \(endDate)")

                    let snapshot = try await self.db
                        .collection("users")
                        .document(accountId)
                        .collection("daily_gems")
                        .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
                        .whereField("date", isLessThan: Timestamp(date: end))
                        .order(by: "date", descending: false)
                        .getDocuments()

                    let gems = try snapshot.documents.compactMap { doc in
                        try doc.data(as: DailyGem.self)
                    }

                    print("✅ [Firebase] Fetched \(gems.count) daily gems")
                    promise(.success(gems))
                } catch {
                    print("❌ [Firebase] Error fetching daily gems: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchDailyGem(for date: Date) -> AnyPublisher<DailyGem?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    let calendar = Calendar.current
                    let startOfDay = calendar.startOfDay(for: date)
                    let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

                    print("📥 [Firebase] Fetching daily gem for date: \(date)")

                    let snapshot = try await self.db
                        .collection("users")
                        .document(accountId)
                        .collection("daily_gems")
                        .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
                        .whereField("date", isLessThan: Timestamp(date: endOfDay))
                        .limit(to: 1)
                        .getDocuments()

                    if let document = snapshot.documents.first {
                        let gem = try document.data(as: DailyGem.self)
                        print("✅ [Firebase] Fetched daily gem for \(date)")
                        promise(.success(gem))
                    } else {
                        print("⚠️ [Firebase] No gem found for \(date)")
                        promise(.success(nil))
                    }
                } catch {
                    print("❌ [Firebase] Error fetching daily gem: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func saveDailyGem(_ gem: DailyGem) -> AnyPublisher<DailyGem, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    var updatedGem = gem
                    updatedGem.accountId = accountId

                    print("💾 [Firebase] Saving daily gem: \(updatedGem.id)")

                    try self.db
                        .collection("users")
                        .document(accountId)
                        .collection("daily_gems")
                        .document(updatedGem.id.uuidString)
                        .setData(from: updatedGem)

                    print("✅ [Firebase] Saved daily gem successfully")
                    promise(.success(updatedGem))
                } catch {
                    print("❌ [Firebase] Error saving daily gem: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - DailyStats
    func fetchDailyStats(for date: Date) -> AnyPublisher<DailyStats?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    let calendar = Calendar.current
                    let startOfDay = calendar.startOfDay(for: date)
                    let dateString = ISO8601DateFormatter().string(from: startOfDay)

                    print("📥 [Firebase] Fetching daily stats for date: \(date)")

                    let document = try await self.db
                        .collection("users")
                        .document(accountId)
                        .collection("daily_stats")
                        .document(dateString)
                        .getDocument()

                    if document.exists {
                        let stats = try document.data(as: DailyStats.self)
                        print("✅ [Firebase] Fetched daily stats for \(date)")
                        promise(.success(stats))
                    } else {
                        print("⚠️ [Firebase] No stats found for \(date)")
                        promise(.success(nil))
                    }
                } catch {
                    print("❌ [Firebase] Error fetching daily stats: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchDailyStats(from startDate: Date, to endDate: Date) -> AnyPublisher<[DailyStats], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    let calendar = Calendar.current
                    let start = calendar.startOfDay(for: startDate)
                    let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!

                    print("📥 [Firebase] Fetching daily stats from \(startDate) to \(endDate)")

                    let snapshot = try await self.db
                        .collection("users")
                        .document(accountId)
                        .collection("daily_stats")
                        .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: start))
                        .whereField("date", isLessThan: Timestamp(date: end))
                        .order(by: "date", descending: false)
                        .getDocuments()

                    let stats = try snapshot.documents.compactMap { doc in
                        try doc.data(as: DailyStats.self)
                    }

                    print("✅ [Firebase] Fetched \(stats.count) daily stats")
                    promise(.success(stats))
                } catch {
                    print("❌ [Firebase] Error fetching daily stats: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - UserStats
    func fetchUserStats() -> AnyPublisher<UserStats, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    print("📥 [Firebase] Fetching user stats for accountId: \(accountId)")

                    let document = try await self.db
                        .collection("users")
                        .document(accountId)
                        .collection("stats")
                        .document("summary")
                        .getDocument()

                    if document.exists {
                        let stats = try document.data(as: UserStats.self)
                        print("✅ [Firebase] Fetched user stats successfully")
                        promise(.success(stats))
                    } else {
                        throw NSError(domain: "FirebaseDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User stats not found"])
                    }
                } catch {
                    print("❌ [Firebase] Error fetching user stats: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func updateUserStats(_ stats: UserStats) -> AnyPublisher<UserStats, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    print("🔄 [Firebase] Updating user stats for accountId: \(accountId)")

                    try self.db
                        .collection("users")
                        .document(accountId)
                        .collection("stats")
                        .document("summary")
                        .setData(from: stats, merge: true)

                    print("✅ [Firebase] Updated user stats successfully")
                    promise(.success(stats))
                } catch {
                    print("❌ [Firebase] Error updating user stats: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - UserProfile
    func fetchUserProfile() -> AnyPublisher<UserProfile, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    print("📥 [Firebase] Fetching user profile for accountId: \(accountId)")

                    let document = try await self.db
                        .collection("users")
                        .document(accountId)
                        .collection("profile")
                        .document("data")
                        .getDocument()

                    if document.exists {
                        let profile = try document.data(as: UserProfile.self)
                        print("✅ [Firebase] Fetched user profile successfully")
                        promise(.success(profile))
                    } else {
                        throw NSError(domain: "FirebaseDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
                    }
                } catch {
                    print("❌ [Firebase] Error fetching user profile: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func saveUserProfile(_ profile: UserProfile) -> AnyPublisher<UserProfile, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    var updatedProfile = profile
                    updatedProfile.accountId = accountId

                    print("💾 [Firebase] Saving user profile for accountId: \(accountId)")

                    try self.db
                        .collection("users")
                        .document(accountId)
                        .collection("profile")
                        .document("data")
                        .setData(from: updatedProfile)

                    print("✅ [Firebase] Saved user profile successfully")
                    promise(.success(updatedProfile))
                } catch {
                    print("❌ [Firebase] Error saving user profile: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func updateUserProfile(_ profile: UserProfile) -> AnyPublisher<UserProfile, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    print("🔄 [Firebase] Updating user profile for accountId: \(accountId)")

                    try self.db
                        .collection("users")
                        .document(accountId)
                        .collection("profile")
                        .document("data")
                        .setData(from: profile, merge: true)

                    print("✅ [Firebase] Updated user profile successfully")
                    promise(.success(profile))
                } catch {
                    print("❌ [Firebase] Error updating user profile: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Goals
    func fetchGoals() -> AnyPublisher<[Goal], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    print("📥 [Firebase] Fetching goals for accountId: \(accountId)")

                    let snapshot = try await self.db
                        .collection("users")
                        .document(accountId)
                        .collection("goals")
                        .order(by: "createdAt", descending: true)
                        .getDocuments()

                    let goals = try snapshot.documents.compactMap { doc in
                        try doc.data(as: Goal.self)
                    }

                    print("✅ [Firebase] Fetched \(goals.count) goals")
                    promise(.success(goals))
                } catch {
                    print("❌ [Firebase] Error fetching goals: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchGoal(id: UUID) -> AnyPublisher<Goal?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    print("📥 [Firebase] Fetching goal with id: \(id)")

                    let document = try await self.db
                        .collection("users")
                        .document(accountId)
                        .collection("goals")
                        .document(id.uuidString)
                        .getDocument()

                    if document.exists {
                        let goal = try document.data(as: Goal.self)
                        print("✅ [Firebase] Fetched goal successfully")
                        promise(.success(goal))
                    } else {
                        print("⚠️ [Firebase] Goal not found")
                        promise(.success(nil))
                    }
                } catch {
                    print("❌ [Firebase] Error fetching goal: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func saveGoal(_ goal: Goal) -> AnyPublisher<Goal, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    var updatedGoal = goal
                    updatedGoal.accountId = accountId

                    print("💾 [Firebase] Saving goal: \(updatedGoal.id)")

                    try self.db
                        .collection("users")
                        .document(accountId)
                        .collection("goals")
                        .document(updatedGoal.id.uuidString)
                        .setData(from: updatedGoal)

                    print("✅ [Firebase] Saved goal successfully")
                    promise(.success(updatedGoal))
                } catch {
                    print("❌ [Firebase] Error saving goal: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func updateGoal(_ goal: Goal) -> AnyPublisher<Goal, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    print("🔄 [Firebase] Updating goal: \(goal.id)")

                    try self.db
                        .collection("users")
                        .document(accountId)
                        .collection("goals")
                        .document(goal.id.uuidString)
                        .setData(from: goal, merge: true)

                    print("✅ [Firebase] Updated goal successfully")
                    promise(.success(goal))
                } catch {
                    print("❌ [Firebase] Error updating goal: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func deleteGoal(id: UUID) -> AnyPublisher<Void, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    let accountId = currentUser.uid
                    print("🗑️ [Firebase] Deleting goal: \(id)")

                    try await self.db
                        .collection("users")
                        .document(accountId)
                        .collection("goals")
                        .document(id.uuidString)
                        .delete()

                    print("✅ [Firebase] Deleted goal successfully")
                    promise(.success(()))
                } catch {
                    print("❌ [Firebase] Error deleting goal: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    // MARK: - Programs
    func fetchPrograms() -> AnyPublisher<[Program], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    print("📥 [Firebase] Fetching all programs")

                    let snapshot = try await self.db
                        .collection("programs")
                        .order(by: "popularity", descending: true)
                        .getDocuments()

                    let programs = try snapshot.documents.compactMap { doc in
                        try doc.data(as: Program.self)
                    }

                    print("✅ [Firebase] Fetched \(programs.count) programs")
                    promise(.success(programs))
                } catch {
                    print("❌ [Firebase] Error fetching programs: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchProgram(id: UUID) -> AnyPublisher<Program?, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    print("📥 [Firebase] Fetching program with id: \(id)")

                    let document = try await self.db
                        .collection("programs")
                        .document(id.uuidString)
                        .getDocument()

                    if document.exists {
                        let program = try document.data(as: Program.self)
                        print("✅ [Firebase] Fetched program successfully")
                        promise(.success(program))
                    } else {
                        print("⚠️ [Firebase] Program not found")
                        promise(.success(nil))
                    }
                } catch {
                    print("❌ [Firebase] Error fetching program: \(error)")
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func fetchRecommendedPrograms(for userId: String) -> AnyPublisher<[Program], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Service deallocated"])))
                return
            }

            Task {
                do {
                    print("📥 [Firebase] Fetching recommended programs for user: \(userId)")

                    // For now, fetch all programs with isRecommended = true
                    // In the future, this could use ML/AI recommendations based on user data
                    let snapshot = try await self.db
                        .collection("programs")
                        .whereField("isRecommended", isEqualTo: true)
                        .order(by: "popularity", descending: true)
                        .limit(to: 10)
                        .getDocuments()

                    let programs = try snapshot.documents.compactMap { doc in
                        try doc.data(as: Program.self)
                    }

                    print("✅ [Firebase] Fetched \(programs.count) recommended programs")
                    promise(.success(programs))
                } catch {
                    print("❌ [Firebase] Error fetching recommended programs: \(error)")
                    promise(.failure(error))
                }
            }
        }
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

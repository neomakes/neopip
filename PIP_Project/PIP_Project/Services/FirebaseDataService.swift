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
                var accountId: String = "<unknown>"
                do {
                    guard let currentUser = Auth.auth().currentUser else {
                        throw NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
                    }

                    accountId = currentUser.uid
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

                    // If no stats found (404), build initial stats and try to persist (best-effort), then return it so UI can show defaults.
                    if (error as NSError).code == 404 {
                        print("🔧 [Firebase] User stats missing; building initial stats and attempting to persist")
                        let initialStats = UserStats(
                            accountId: accountId,
                            totalDataPoints: 0,
                            totalDaysActive: 0,
                            currentStreak: 0,
                            longestStreak: 0,
                            totalGoalsCompleted: 0,
                            totalProgramsCompleted: 0,
                            averageEmotionScore: 0.0,
                            totalGemsCreated: 0,
                            lastUpdated: Date()
                        )

                        do {
                            try self.db
                                .collection("users")
                                .document(accountId)
                                .collection("stats")
                                .document("summary")
                                .setData(from: initialStats)
                            print("✅ [Firebase] Persisted initial user stats")
                        } catch {
                            print("⚠️ [Firebase] Failed to persist initial user stats: \(error) (might be rules permission)")
                        }

                        promise(.success(initialStats))
                    } else {
                        promise(.failure(error))
                    }
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

                    // Try the canonical 'data' document first, fall back to legacy 'info' if missing
                    print("🔍 [Firebase] Attempting to read users/\(accountId)/profile/data")
                    var document: DocumentSnapshot
                    do {
                        document = try await self.db
                            .collection("users")
                            .document(accountId)
                            .collection("profile")
                            .document("data")
                            .getDocument()
                    } catch let err as NSError {
                        print("❌ [Firebase] Error reading users/\(accountId)/profile/data: Domain:\(err.domain) Code:\(err.code) Desc:\(err.localizedDescription) UserInfo: \(err.userInfo)")
                        throw err
                    }

                    if !document.exists {
                        print("⚠️ [Firebase] 'data' profile doc not found, falling back to 'info'")
                        print("🔍 [Firebase] Attempting to read users/\(accountId)/profile/info")
                        do {
                            document = try await self.db
                                .collection("users")
                                .document(accountId)
                                .collection("profile")
                                .document("info")
                                .getDocument()
                            print("🔎 [Firebase] 'info' doc exists: \(document.exists)")
                        } catch let err as NSError {
                            print("❌ [Firebase] Error reading users/\(accountId)/profile/info: Domain:\(err.domain) Code:\(err.code) Desc:\(err.localizedDescription) UserInfo: \(err.userInfo)")
                            throw err
                        }
                    } else {
                        print("🔎 [Firebase] 'data' doc exists: \(document.exists)")
                    }

                    if document.exists {
                        do {
                            let profile = try document.data(as: UserProfile.self)
                            print("✅ [Firebase] Fetched user profile successfully from profile doc")
                            promise(.success(profile))
                            return
                        } catch {
                            // Legacy/partial profile fallback: attempt to construct a minimal UserProfile
                            print("⚠️ [Firebase] Failed decoding user profile document: \(error). Attempting fallback using document fields.")
                            let raw = document.data() ?? [:]
                            let displayName = raw["displayName"] as? String
                            let email = raw["email"] as? String
                            let now = Date()
                            let fallbackProfile = UserProfile(
                                accountId: accountId,
                                displayName: displayName,
                                email: email,
                                profileImageURL: nil,
                                backgroundImageURL: nil,
                                createdAt: now,
                                lastActiveAt: now,
                                preferences: UserPreferences(theme: .system, notificationsEnabled: true, language: Locale.current.languageCode ?? "en", timeZone: TimeZone.current.identifier),
                                onboardingState: nil,
                                initialGoals: [],
                                firstJournalDate: nil
                            )
                            print("✅ [Firebase] Built partial UserProfile from profile doc fields")
                            promise(.success(fallbackProfile))
                            return
                        }
                    }

                    // Last-resort: maybe legacy data was stored inside the parent user document (users/{uid}.profile or users/{uid}.profile.info)
                    print("🔍 [Firebase] No profile doc found; checking embedded 'profile' map on users/\(accountId) document")
                    let userDoc = try await self.db.collection("users").document(accountId).getDocument()
                    if userDoc.exists, let userData = userDoc.data() {
                        if let profileMap = userData["profile"] as? [String: Any] {
                            print("🔎 [Firebase] Found embedded 'profile' map on user document")
                            // prefer 'data' or 'info' keys inside profileMap
                            if let dataMap = profileMap["data"] as? [String: Any] ?? profileMap["info"] as? [String: Any] {
                                let displayName = dataMap["displayName"] as? String
                                let email = dataMap["email"] as? String
                                let now = Date()
                                let fallbackProfile = UserProfile(
                                    accountId: accountId,
                                    displayName: displayName,
                                    email: email,
                                    profileImageURL: nil,
                                    backgroundImageURL: nil,
                                    createdAt: now,
                                    lastActiveAt: now,
                                    preferences: UserPreferences(theme: .system, notificationsEnabled: true, language: Locale.current.languageCode ?? "en", timeZone: TimeZone.current.identifier),
                                    onboardingState: nil,
                                    initialGoals: [],
                                    firstJournalDate: nil
                                )
                                print("✅ [Firebase] Built partial UserProfile from embedded 'profile' map")
                                promise(.success(fallbackProfile))
                                return
                            }

                            // maybe displayName is stored directly on the user doc under 'profile.displayName' path
                            if let display = profileMap["displayName"] as? String {
                                let now = Date()
                                let fallbackProfile = UserProfile(
                                    accountId: accountId,
                                    displayName: display,
                                    email: userData["email"] as? String,
                                    profileImageURL: nil,
                                    backgroundImageURL: nil,
                                    createdAt: now,
                                    lastActiveAt: now,
                                    preferences: UserPreferences(theme: .system, notificationsEnabled: true, language: Locale.current.languageCode ?? "en", timeZone: TimeZone.current.identifier),
                                    onboardingState: nil,
                                    initialGoals: [],
                                    firstJournalDate: nil
                                )
                                print("✅ [Firebase] Built partial UserProfile from user doc 'profile.displayName'")
                                promise(.success(fallbackProfile))
                                return
                            }
                        }
                    }

                    // If we reach here, no usable profile data exists in Firestore docs.
                    // As a last-resort, construct a minimal UserProfile from Firebase Auth user info
                    if let authUser = Auth.auth().currentUser {
                        print("🔧 [Firebase] No profile doc found; building fallback profile from Auth user info")
                        let fallbackProfile = UserProfile(
                            accountId: accountId,
                            displayName: authUser.displayName,
                            email: authUser.email,
                            profileImageURL: authUser.photoURL?.absoluteString,
                            backgroundImageURL: nil,
                            createdAt: Date(),
                            lastActiveAt: Date(),
                            preferences: UserPreferences(theme: .system, notificationsEnabled: true, language: Locale.current.languageCode ?? "en", timeZone: TimeZone.current.identifier),
                            onboardingState: nil,
                            initialGoals: [],
                            firstJournalDate: nil
                        )

                        // Try to persist fallback profile to Firestore (best-effort). If it fails due to permissions, we still return the fallback so UI can show the display name.
                        do {
                            try self.db
                                .collection("users")
                                .document(accountId)
                                .collection("profile")
                                .document("data")
                                .setData(from: fallbackProfile)
                            print("✅ [Firebase] Persisted fallback profile to users/\(accountId)/profile/data")
                        } catch let err as NSError {
                            print("⚠️ [Firebase] Failed to persist fallback profile: Domain:\(err.domain) Code:\(err.code) Desc:\(err.localizedDescription) UserInfo: \(err.userInfo) (possibly rules permission issue)")
                        }

                        promise(.success(fallbackProfile))
                        return
                    }

                    throw NSError(domain: "FirebaseDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
                } catch {
                    let ns = error as NSError
                    print("❌ [Firebase] Error fetching user profile: Domain:\(ns.domain) Code:\(ns.code) Desc:\(ns.localizedDescription) UserInfo: \(ns.userInfo)")
                    // For DEV builds, dump raw profile documents to help debug missing docs / rules issues
                    #if DEBUG
                    if ns.domain == "FIRFirestoreErrorDomain" || ns.code == 7 {
                        print("🔬 [Firebase] Triggering DEV debug dump for user: \(accountId)")
                        self.debugDumpUserProfile(accountId: accountId)
                    }
                    #endif
                }
            }
        }
        .eraseToAnyPublisher()
    }

    /// DEV-only helper: dump raw profile docs for a specific account to the console (useful for debugging rules and missing docs)
    func debugDumpUserProfile(accountId: String) {
        Task {
            #if DEBUG
            do {
                print("🔬 [Firebase DebugDump] Reading users/\(accountId)/profile/data")
                let dataDoc = try await self.db.collection("users").document(accountId).collection("profile").document("data").getDocument()
                print("🔬 [Firebase DebugDump] data.exists: \(dataDoc.exists), data: \(dataDoc.data() ?? [:])")
            } catch let err as NSError {
                print("🔬 [Firebase DebugDump] Error reading profile/data: Domain:\(err.domain) Code:\(err.code) Desc:\(err.localizedDescription) UserInfo: \(err.userInfo)")
            }

            do {
                print("🔬 [Firebase DebugDump] Reading users/\(accountId)/profile/info")
                let infoDoc = try await self.db.collection("users").document(accountId).collection("profile").document("info").getDocument()
                print("🔬 [Firebase DebugDump] info.exists: \(infoDoc.exists), data: \(infoDoc.data() ?? [:])")
            } catch let err as NSError {
                print("🔬 [Firebase DebugDump] Error reading profile/info: Domain:\(err.domain) Code:\(err.code) Desc:\(err.localizedDescription) UserInfo: \(err.userInfo)")
            }

            do {
                print("🔬 [Firebase DebugDump] Reading users/\(accountId) parent document")
                let userDoc = try await self.db.collection("users").document(accountId).getDocument()
                print("🔬 [Firebase DebugDump] user.exists: \(userDoc.exists), data: \(userDoc.data() ?? [:])")
            } catch let err as NSError {
                print("🔬 [Firebase DebugDump] Error reading user document: Domain:\(err.domain) Code:\(err.code) Desc:\(err.localizedDescription) UserInfo: \(err.userInfo)")
            }
            #else
            print("🔬 [Firebase DebugDump] Debug dump is available only in DEBUG builds")
            #endif
        }
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
                    let ns = error as NSError
                    print("❌ [Firebase] Error fetching programs: Domain:\(ns.domain) Code:\(ns.code) Desc:\(ns.localizedDescription) UserInfo: \(ns.userInfo)")

                    // If we hit permission errors, return an empty array to keep UI functional and log a clear guidance message.
                    if ns.domain == "FIRFirestoreErrorDomain" && ns.code == 7 {
                        print("⚠️ [Firebase] Permission denied reading 'programs'. Check Firestore rules to allow authenticated reads for 'programs' in DEV.")
                        promise(.success([]))
                    } else {
                        promise(.failure(error))
                    }
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

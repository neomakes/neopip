//
//  FirebaseDataService+Profile.swift
//  PIP_Project
//
//  Created by Gemini on 2026/01/10.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

// MARK: - UserProfile
extension FirebaseDataService {
    
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

                    // Try the canonical 'data' document first
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

                    if document.exists {
                        do {
                            let profile = try document.data(as: UserProfile.self)
                            print("✅ [Firebase] Fetched user profile successfully from profile doc")
                            promise(.success(profile))
                            return
                        } catch {
                            print("⚠️ [Firebase] Failed decoding user profile document: \(error). Using fallback.")
                        }
                    }

                    // Fallback: Build minimal profile from Auth info
                    print("🔧 [Firebase] No valid profile doc found; building fallback profile from Auth user info")
                    let fallbackProfile = UserProfile(
                        accountId: accountId,
                        displayName: currentUser.displayName,
                        email: currentUser.email,
                        profileImageURL: currentUser.photoURL?.absoluteString,
                        backgroundImageURL: nil,
                        createdAt: Date(),
                        lastActiveAt: Date(),
                        preferences: UserPreferences(theme: .system, notificationsEnabled: true, language: Locale.current.languageCode ?? "en", timeZone: TimeZone.current.identifier),
                        onboardingState: nil,
                        initialGoals: [],
                        goals: [], // Initialize empty goals
                        firstJournalDate: nil,
                        
                        // New flattened fields (Defaulting for fallback)
                        enabledDataTypes: [], // No consent given yet in fallback
                        anonymizationLevel: .none,
                        permissions: nil
                    )
                    
                    // Try to persist fallback profile
                    do {
                        try self.db
                            .collection("users")
                            .document(accountId)
                            .collection("profile")
                            .document("data")
                            .setData(from: fallbackProfile)
                        print("✅ [Firebase] Persisted fallback profile")
                    } catch {
                        print("⚠️ [Firebase] Failed to persist fallback: \(error)")
                    }

                    promise(.success(fallbackProfile))
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
}

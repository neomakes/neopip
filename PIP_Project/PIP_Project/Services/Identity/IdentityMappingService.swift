//
//  IdentityMappingService.swift
//  PIP_Project
//
//  Manages identity mapping between user accounts and anonymous IDs
//  Implements privacy-first architecture with encryption
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

/// Service for managing identity mapping with encryption and secure storage
@MainActor
class IdentityMappingService: ObservableObject {

    static let shared = IdentityMappingService()

    private let db = Firestore.firestore()
    private let encryption = EncryptionService.shared
    private let keychain = KeychainService.shared

    @Published private(set) var currentMapping: IdentityMapping?
    @Published private(set) var isLoading = false

    private init() {}

    // MARK: - Public Methods

    /// Get anonymous user ID for the currently logged-in user
    /// Returns cached ID if available, otherwise fetches from Firestore or creates new
    /// Get anonymous user ID for the currently logged-in user
    /// Server-First Strategy: DB 확인 -> 없으면 생성. (캐시는 오프라인 Fallback용)
    /// 이를 통해 DB 데이터가 삭제되더라도 자동으로 복구(재생성)됨.
    func getAnonymousUserId() async throws -> UUID {
        guard let currentUser = Auth.auth().currentUser else {
            throw IdentityMappingError.userNotAuthenticated
        }

        let accountId = currentUser.uid
        print("🔍 [IdentityMapping] Getting anonymous ID for account: \(accountId)")

        // 1. Try Fetch from Firestore (Source of Truth)
        isLoading = true
        defer { isLoading = false }

        do {
            if let mapping = try await fetchMappingFromFirestore(accountId: accountId) {
                // DB에 존재함 -> 캐시 업데이트 및 리턴
                try? saveAnonymousIdToCache(mapping.anonymousUserId)
                currentMapping = mapping
                print("✅ [IdentityMapping] Resolved ID from Firestore: \(mapping.anonymousUserId)")
                return mapping.anonymousUserId
            } else {
                print("⚠️ [IdentityMapping] Mapping not found in Firestore. Creating new one.")
            }
        } catch {
            print("⚠️ [IdentityMapping] Network/Fetch error: \(error). Falling back to cache.")
            // 2. Fallback to Cache (Offline Support)
            if let cachedId = try? loadAnonymousIdFromCache() {
                print("✅ [IdentityMapping] Using cached ID (Offline Mode): \(cachedId)")
                return cachedId
            }
            // 캐시도 없음 -> 에러 전파 혹은 재생성 시도 (아래로 진행)
        }

        // 3. Create new mapping (DB에 없거나, 최초 생성)
        print("🆕 [IdentityMapping] Creating new identity mapping...")
        let newMapping = try await createNewMapping(accountId: accountId)
        try? saveAnonymousIdToCache(newMapping.anonymousUserId)
        currentMapping = newMapping
        print("✅ [IdentityMapping] Created new anonymous ID: \(newMapping.anonymousUserId)")
        return newMapping.anonymousUserId
    }

    /// Clear cached identity mapping (for logout)
    func clearCache() throws {
        try keychain.delete(for: .anonymousUserId)
        try keychain.delete(for: .identityMapping)
        currentMapping = nil
        print("🧹 [IdentityMapping] Cleared cache")
    }

    // MARK: - Private Methods - Caching

    private func loadAnonymousIdFromCache() throws -> UUID {
        let data = try keychain.load(for: .anonymousUserId)
        guard let uuidString = String(data: data, encoding: .utf8),
              let uuid = UUID(uuidString: uuidString) else {
            throw IdentityMappingError.invalidCachedData
        }
        return uuid
    }

    private func saveAnonymousIdToCache(_ uuid: UUID) throws {
        let data = Data(uuid.uuidString.utf8)
        try keychain.save(data, for: .anonymousUserId)
    }

    // MARK: - Private Methods - Firestore

    private func fetchMappingFromFirestore(accountId: String) async throws -> IdentityMapping? {
        // Query identity_mappings collection by accountId
        let query = db.collection("identity_mappings")
            .whereField("accountId", isEqualTo: accountId)
            .whereField("isActive", isEqualTo: true)
            .limit(to: 1)

        let snapshot = try await query.getDocuments()

        guard let document = snapshot.documents.first else {
            return nil
        }

        return try document.data(as: IdentityMapping.self)
    }

    private func createNewMapping(accountId: String) async throws -> IdentityMapping {
        // Generate new anonymous user ID
        let anonymousUserId = UUID()
        let mappingId = UUID()

        // Create encrypted key using the accountId string
        let encryptedKey = try encryption.encrypt(accountId)

        let mapping = IdentityMapping(
            id: mappingId,
            accountId: accountId,  // Use Firebase UID directly as String
            anonymousUserId: anonymousUserId,
            encryptedKey: encryptedKey,
            createdAt: Date(),
            isActive: true,
            deletionRequestedAt: nil
        )

        // Save to Firestore
        try await saveMapping(mapping)

        // Create anonymous_user_identities document
        try await createAnonymousUserIdentity(anonymousUserId: anonymousUserId)

        return mapping
    }

    private func saveMapping(_ mapping: IdentityMapping) async throws {
        try db.collection("identity_mappings")
            .document(mapping.id.uuidString)
            .setData(from: mapping)

        print("💾 [IdentityMapping] Saved mapping to Firestore: \(mapping.id)")
    }

    private func createAnonymousUserIdentity(anonymousUserId: UUID) async throws {
        let identity = AnonymousUserIdentity(
            id: anonymousUserId,
            accountId: nil as String?, // No reference to account ID for privacy (String?, not UUID?)
            createdAt: Date()
        )

        try db.collection("anonymous_users")
            .document(anonymousUserId.uuidString)
            .setData(from: identity)

        print("💾 [IdentityMapping] Created anonymous user identity: \(anonymousUserId)")
    }

    // MARK: - Privacy Methods

    /// Request data deletion (GDPR compliance)
    func requestDataDeletion(type: DeletionType) async throws {
        guard let currentUser = Auth.auth().currentUser else {
            throw IdentityMappingError.userNotAuthenticated
        }

        let accountId = currentUser.uid  // Use Firebase UID directly as String
        let requestId = UUID()

        let deletionRequest = DataDeletionRequest(
            id: requestId,
            accountId: accountId,
            requestType: type,
            requestedAt: Date(),
            status: .pending,
            completedAt: nil,
            errorMessage: nil
        )

        // Save deletion request
        try db.collection("users")
            .document(currentUser.uid)
            .collection("deletion_requests")
            .document(requestId.uuidString)
            .setData(from: deletionRequest)

        print("🗑️ [IdentityMapping] Created deletion request: \(requestId)")

        // Mark mapping as inactive
        if let mapping = currentMapping {
            var updatedMapping = mapping
            updatedMapping.isActive = false
            updatedMapping.deletionRequestedAt = Date()
            try await saveMapping(updatedMapping)
        }

        // Clear cache
        try clearCache()
    }
}

// MARK: - Identity Mapping Errors
enum IdentityMappingError: Error {
    case userNotAuthenticated
    case mappingNotFound
    case invalidCachedData
    case firestoreError(Error)
    case encryptionError(Error)

    var localizedDescription: String {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .mappingNotFound:
            return "Identity mapping not found"
        case .invalidCachedData:
            return "Invalid cached data"
        case .firestoreError(let error):
            return "Firestore error: \(error.localizedDescription)"
        case .encryptionError(let error):
            return "Encryption error: \(error.localizedDescription)"
        }
    }
}

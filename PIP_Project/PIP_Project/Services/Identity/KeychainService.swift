//
//  KeychainService.swift
//  PIP_Project
//
//  Secure keychain storage for sensitive data
//

import Foundation
import Security

/// Keychain service for secure storage of encryption keys and identity mappings
class KeychainService {

    static let shared = KeychainService()

    private init() {}

    // MARK: - Service Identifiers
    private let service = "com.neomakes.PIP-Project"

    enum KeychainKey: String {
        case encryptionKey = "encryption_key"
        case anonymousUserId = "anonymous_user_id"
        case identityMapping = "identity_mapping"
    }

    // MARK: - Public Methods

    /// Save data to keychain
    func save(_ data: Data, for key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }

        print("🔐 [Keychain] Saved data for key: \(key.rawValue)")
    }

    /// Retrieve data from keychain
    func load(for key: KeychainKey) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            throw KeychainError.loadFailed(status: status)
        }

        print("🔓 [Keychain] Loaded data for key: \(key.rawValue)")
        return data
    }

    /// Delete data from keychain
    func delete(for key: KeychainKey) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }

        print("🗑️ [Keychain] Deleted data for key: \(key.rawValue)")
    }

    /// Clear all keychain data for this app
    func clearAll() throws {
        for key in [KeychainKey.encryptionKey, .anonymousUserId, .identityMapping] {
            try? delete(for: key)
        }
        print("🧹 [Keychain] Cleared all data")
    }
}

// MARK: - Keychain Errors
enum KeychainError: Error {
    case saveFailed(status: OSStatus)
    case loadFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)

    var localizedDescription: String {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .loadFailed(let status):
            return "Failed to load from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        }
    }
}

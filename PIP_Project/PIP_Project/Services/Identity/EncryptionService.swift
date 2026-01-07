//
//  EncryptionService.swift
//  PIP_Project
//
//  AES-256-GCM encryption for identity mapping
//

import Foundation
import CryptoKit

/// Encryption service using AES-256-GCM for securing identity mappings
class EncryptionService {

    static let shared = EncryptionService()

    private init() {}

    // MARK: - Encryption Key Management

    /// Get or generate encryption key
    func getEncryptionKey() throws -> SymmetricKey {
        // Try to load existing key from keychain
        if let existingKey = try? loadKeyFromKeychain() {
            print("🔑 [Encryption] Loaded existing encryption key")
            return existingKey
        }

        // Generate new key
        let newKey = SymmetricKey(size: .bits256)
        try saveKeyToKeychain(newKey)
        print("🔑 [Encryption] Generated new encryption key")
        return newKey
    }

    private func saveKeyToKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        try KeychainService.shared.save(keyData, for: .encryptionKey)
    }

    private func loadKeyFromKeychain() throws -> SymmetricKey {
        let keyData = try KeychainService.shared.load(for: .encryptionKey)
        return SymmetricKey(data: keyData)
    }

    // MARK: - Encryption Methods

    /// Encrypt string using AES-256-GCM
    func encrypt(_ string: String) throws -> String {
        let key = try getEncryptionKey()
        let data = Data(string.utf8)

        let sealedBox = try AES.GCM.seal(data, using: key)

        // Combine nonce + ciphertext + tag
        guard let combined = sealedBox.combined else {
            throw EncryptionError.encryptionFailed
        }

        // Return base64 encoded
        return combined.base64EncodedString()
    }

    /// Decrypt string using AES-256-GCM
    func decrypt(_ encrypted: String) throws -> String {
        let key = try getEncryptionKey()

        // Decode base64
        guard let combined = Data(base64Encoded: encrypted) else {
            throw EncryptionError.invalidEncryptedData
        }

        // Create sealed box from combined data
        let sealedBox = try AES.GCM.SealedBox(combined: combined)

        // Decrypt
        let decryptedData = try AES.GCM.open(sealedBox, using: key)

        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }

        return decryptedString
    }

    // MARK: - UUID Encryption

    /// Encrypt UUID for identity mapping
    func encryptUUID(_ uuid: UUID) throws -> String {
        return try encrypt(uuid.uuidString)
    }

    /// Decrypt UUID from encrypted string
    func decryptUUID(_ encrypted: String) throws -> UUID {
        let uuidString = try decrypt(encrypted)
        guard let uuid = UUID(uuidString: uuidString) else {
            throw EncryptionError.invalidUUID
        }
        return uuid
    }

    // MARK: - Hash Generation

    /// Generate SHA-256 hash for verification
    func generateHash(for data: String) -> String {
        let inputData = Data(data.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Encryption Errors
enum EncryptionError: Error {
    case encryptionFailed
    case decryptionFailed
    case invalidEncryptedData
    case invalidUUID
    case keyGenerationFailed

    var localizedDescription: String {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidEncryptedData:
            return "Invalid encrypted data format"
        case .invalidUUID:
            return "Invalid UUID format"
        case .keyGenerationFailed:
            return "Failed to generate encryption key"
        }
    }
}

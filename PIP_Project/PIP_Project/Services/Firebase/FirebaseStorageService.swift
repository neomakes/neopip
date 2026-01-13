//
//  FirebaseStorageService.swift
//  PIP_Project
//
//  Service for managing Firebase Storage uploads and downloads
//

import Foundation
import FirebaseStorage
import UIKit
import Combine

enum StorageError: Error {
    case imageConversionFailed
    case uploadFailed(Error)
    case urlRetrievalFailed(Error)
    case deletionFailed(Error)
}

class FirebaseStorageService {
    static let shared = FirebaseStorageService()
    
    private let storage = Storage.storage()
    private lazy var storageRef = storage.reference()
    
    private init() {}
    
    /// Compresses and uploads a profile image to 'profile_images/{userId}.jpg'
    /// Returns the download URL string
    func uploadProfileImage(_ image: UIImage, userId: String) async throws -> String {
        // 1. Convert UIImage to JPEG data with compression
        guard let imageData = image.jpegData(compressionQuality: 0.5) else {
            throw StorageError.imageConversionFailed
        }
        
        let imageRef = storageRef.child("profile_images/\(userId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // 2. Upload data
        do {
            _ = try await imageRef.putDataAsync(imageData, metadata: metadata)
        } catch {
            throw StorageError.uploadFailed(error)
        }
        
        // 3. Get download URL
        do {
            let downloadURL = try await imageRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
            throw StorageError.urlRetrievalFailed(error)
        }
    }
    
    /// Deletes the profile image for a user
    func deleteProfileImage(userId: String) async throws {
        let imageRef = storageRef.child("profile_images/\(userId).jpg")
        do {
            try await imageRef.delete()
        } catch {
            // Ignore "object not found" errors, as it means it's already gone
            let nsError = error as NSError
            if nsError.domain == StorageErrorDomain && nsError.code == StorageErrorCode.objectNotFound.rawValue {
                return
            }
            throw StorageError.deletionFailed(error)
        }
    }
}

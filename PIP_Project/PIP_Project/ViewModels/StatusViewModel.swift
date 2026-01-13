//
//  StatusViewModel.swift
//  PIP_Project
//
//  StatusView의 ViewModel
//

import Foundation
import Combine
import SwiftUI
import PhotosUI

@MainActor
class StatusViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userProfile: UserProfile?
    @Published var userStats: UserStats?
    @Published var achievements: [Achievement] = []
    @Published var valueAnalysis: ValueAnalysis?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let dataService: DataServiceProtocol
    private let storageService = FirebaseStorageService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Image Selection
    @Published var selectedImageItem: PhotosPickerItem? = nil {
        didSet {
            Task {
                await updateProfileImage()
            }
        }
    }
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        // Use injected service if provided, otherwise use currently active service from DataServiceManager
        self.dataService = dataService ?? DataServiceManager.shared.currentService
        loadInitialData()
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .didSaveCardData)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("📥 [StatusViewModel] Received didSaveCardData notification, refreshing...")
                self?.loadInitialData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    /// Update profile image when selection changes
    func updateProfileImage() async {
        guard let item = selectedImageItem else { return }
        guard let userProfile = userProfile else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else {
                print("⚠️ [StatusViewModel] Failed to load image data")
                return
            }
            
            // Upload to Storage
            let url = try await storageService.uploadProfileImage(uiImage, userId: userProfile.accountId)
            print("✅ [StatusViewModel] Uploaded new profile image: \(url)")
            
            // Update Firestore Profile
            var updatedProfile = userProfile
            updatedProfile.profileImageURL = url
            
            _ = try await dataService.updateUserProfile(updatedProfile).async()
            
            await MainActor.run {
                self.userProfile = updatedProfile
            }
            
        } catch {
            print("❌ [StatusViewModel] Failed to update profile image: \(error)")
            errorMessage = "Failed to update profile image. Please try again."
        }
    }
    
    /// 초기 데이터 로드
    func loadInitialData() {
        isLoading = true
        errorMessage = nil
        
        // UserProfile 로드
        // Identity Verification (Debug)
        if let uuidData = try? KeychainService.shared.load(for: .anonymousUserId),
           let uuidStr = String(data: uuidData, encoding: .utf8) {
            print("🔍 [StatusViewModel] Current Anonymous ID (Keychain): \(uuidStr)")
        } else {
            print("⚠️ [StatusViewModel] No Anonymous ID found in Keychain")
        }
        
        dataService.fetchUserProfile()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] profile in
                    self?.userProfile = profile
                }
            )
            .store(in: &cancellables)
        
        // UserStats 로드
        dataService.fetchUserStats()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] stats in
                    self?.userStats = stats
                }
            )
            .store(in: &cancellables)
        
        // Achievements 로드
        dataService.fetchAchievements()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] achievements in
                    self?.achievements = achievements
                }
            )
            .store(in: &cancellables)
        
        // ValueAnalysis 로드
        dataService.fetchValueAnalysis()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] analysis in
                    self?.valueAnalysis = analysis
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Combine Async Extension
extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                },
                receiveValue: { value in
                    continuation.resume(returning: value)
                }
            )
        }
    }
}

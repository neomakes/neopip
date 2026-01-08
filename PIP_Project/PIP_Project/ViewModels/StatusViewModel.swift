//
//  StatusViewModel.swift
//  PIP_Project
//
//  StatusView의 ViewModel
//

import Foundation
import Combine
import SwiftUI

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
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        // Use injected service if provided, otherwise use currently active service from DataServiceManager
        self.dataService = dataService ?? DataServiceManager.shared.currentService
        loadInitialData()
    }
    
    // MARK: - Public Methods
    
    /// 초기 데이터 로드
    func loadInitialData() {
        isLoading = true
        errorMessage = nil
        
        // UserProfile 로드
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

//
//  DataServiceProtocol.swift
//  PIP_Project
//
//  Data Service Protocol: Abstract MockData and Firebase
//

import Foundation
import Combine

/// Data service protocol (common interface for MockData and Firebase)
protocol DataServiceProtocol {
    // MARK: - TimeSeriesDataPoint
    func fetchDataPoints(for date: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error>
    func fetchDataPoints(from startDate: Date, to endDate: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error>
    func saveDataPoint(_ dataPoint: TimeSeriesDataPoint) -> AnyPublisher<TimeSeriesDataPoint, Error>
    func saveData(_ dataPoint: TimeSeriesDataPoint, for category: DataCategory) async throws
    func deleteDataPoint(_ id: UUID) -> AnyPublisher<Void, Error>
    
    // MARK: - DailyGem
    func fetchDailyGems(from startDate: Date, to endDate: Date) -> AnyPublisher<[DailyGem], Error>
    func fetchDailyGem(for date: Date) -> AnyPublisher<DailyGem?, Error>
    func saveDailyGem(_ gem: DailyGem) -> AnyPublisher<DailyGem, Error>
    
    // MARK: - DailyStats
    func fetchDailyStats(for date: Date) -> AnyPublisher<DailyStats?, Error>
    func fetchDailyStats(from startDate: Date, to endDate: Date) -> AnyPublisher<[DailyStats], Error>
    
    // MARK: - UserStats
    func fetchUserStats() -> AnyPublisher<UserStats, Error>
    func updateUserStats(_ stats: UserStats) -> AnyPublisher<UserStats, Error>
    
    // MARK: - UserProfile
    func fetchUserProfile() -> AnyPublisher<UserProfile, Error>
    func saveUserProfile(_ profile: UserProfile) -> AnyPublisher<UserProfile, Error>
    func updateUserProfile(_ profile: UserProfile) -> AnyPublisher<UserProfile, Error>

    // MARK: - Goals
    func fetchGoals() -> AnyPublisher<[Goal], Error>
    func fetchGoal(id: UUID) -> AnyPublisher<Goal?, Error>
    func saveGoal(_ goal: Goal) -> AnyPublisher<Goal, Error>
    func updateGoal(_ goal: Goal) -> AnyPublisher<Goal, Error>
    func deleteGoal(id: UUID) -> AnyPublisher<Void, Error>

    // MARK: - Programs
    func fetchPrograms() -> AnyPublisher<[Program], Error>
    func fetchProgram(id: UUID) -> AnyPublisher<Program?, Error>
    func fetchRecommendedPrograms(for userId: String) -> AnyPublisher<[Program], Error>

    // MARK: - Program Enrollments
    func createProgramEnrollment(_ enrollment: ProgramEnrollment) -> AnyPublisher<ProgramEnrollment, Error>
    func fetchProgramEnrollments() -> AnyPublisher<[ProgramEnrollment], Error>
    func fetchProgramEnrollment(id: UUID) -> AnyPublisher<ProgramEnrollment?, Error>
    func updateProgramEnrollment(_ enrollment: ProgramEnrollment) -> AnyPublisher<ProgramEnrollment, Error>

    // MARK: - Achievements
    func fetchAchievements() -> AnyPublisher<[Achievement], Error>
    
    // MARK: - Value Analysis
    func fetchValueAnalysis() -> AnyPublisher<ValueAnalysis, Error>
    
    // MARK: - Analysis Cards
    func fetchAnalysisCards() -> AnyPublisher<[InsightAnalysisCard], Error>
    
    // MARK: - Insight Story
    func fetchInsightStory(for cardId: String) -> AnyPublisher<InsightStory, Error>
    
    // MARK: - Dashboard Data
    func fetchDashboardData() -> AnyPublisher<[String: [DashboardItem]], Error>
    
    // MARK: - Schemas
    func getSchemas(for category: DataCategory) -> [DataTypeSchema]
}

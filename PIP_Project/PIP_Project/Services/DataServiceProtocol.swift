//
//  DataServiceProtocol.swift
//  PIP_Project
//
//  Data Service Protocol: MockData와 Firebase를 추상화
//

import Foundation
import Combine

/// 데이터 서비스 프로토콜 (MockData와 Firebase 공통 인터페이스)
protocol DataServiceProtocol {
    // MARK: - TimeSeriesDataPoint
    func fetchDataPoints(for date: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error>
    func fetchDataPoints(from startDate: Date, to endDate: Date) -> AnyPublisher<[TimeSeriesDataPoint], Error>
    func saveDataPoint(_ dataPoint: TimeSeriesDataPoint) -> AnyPublisher<TimeSeriesDataPoint, Error>
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
}

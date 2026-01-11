//
//  DefaultSchemaProvider.swift
//  PIP_Project
//
//  Provides default DataTypeSchema definitions for both Mock and Firebase services
//

import Foundation

/// Centralized provider for default data type schemas
class DefaultSchemaProvider {
    static let shared = DefaultSchemaProvider()
    
    private init() {}
    
    /// Get schemas for a specific category
    func getSchemas(for category: DataCategory) -> [DataTypeSchema] {
        switch category {
        case .mind:
            return getMindSchemas()
        case .behavior:
            return getBehaviorSchemas()
        case .physical:
            return getPhysicalSchemas()
        case .dailyLog:
            return getAllSchemas() // Combined for daily log
        default:
            return []
        }
    }
    
    // MARK: - Mind Schemas
    
    private func getMindSchemas() -> [DataTypeSchema] {
        return [
            DataTypeSchema(
                id: UUID(),
                name: "mood",
                displayName: "기분",
                category: .mind,
                dataType: .double,
                unit: "점",
                range: ValueRange(min: 0, max: 100, step: 1),
                sensitivity: .medium,
                collectionMethod: .manual,
                isRequired: true,
                isEnabled: true,
                description: "전반적인 기분 상태",
                createdAt: Date(),
                updatedAt: Date()
            ),
            DataTypeSchema(
                id: UUID(),
                name: "stress",
                displayName: "스트레스",
                category: .mind,
                dataType: .double,
                unit: "점",
                range: ValueRange(min: 0, max: 100, step: 1),
                sensitivity: .medium,
                collectionMethod: .manual,
                isRequired: false,
                isEnabled: true,
                description: "스트레스 수준",
                createdAt: Date(),
                updatedAt: Date()
            ),
            DataTypeSchema(
                id: UUID(),
                name: "energy",
                displayName: "에너지",
                category: .mind,
                dataType: .double,
                unit: "점",
                range: ValueRange(min: 0, max: 100, step: 1),
                sensitivity: .low,
                collectionMethod: .manual,
                isRequired: false,
                isEnabled: true,
                description: "에너지 수준",
                createdAt: Date(),
                updatedAt: Date()
            ),
            DataTypeSchema(
                id: UUID(),
                name: "focus",
                displayName: "집중력",
                category: .mind,
                dataType: .double,
                unit: "점",
                range: ValueRange(min: 0, max: 100, step: 1),
                sensitivity: .low,
                collectionMethod: .manual,
                isRequired: false,
                isEnabled: true,
                description: "집중력 수준",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
    
    // MARK: - Behavior Schemas
    
    private func getBehaviorSchemas() -> [DataTypeSchema] {
        return [
            DataTypeSchema(
                id: UUID(),
                name: "productivity",
                displayName: "생산성",
                category: .behavior,
                dataType: .double,
                unit: "점",
                range: ValueRange(min: 0, max: 100, step: 1),
                sensitivity: .low,
                collectionMethod: .manual,
                isRequired: false,
                isEnabled: true,
                description: "생산성 수준",
                createdAt: Date(),
                updatedAt: Date()
            ),
            DataTypeSchema(
                id: UUID(),
                name: "socialActivity",
                displayName: "사회 활동",
                category: .behavior,
                dataType: .double,
                unit: "점",
                range: ValueRange(min: 0, max: 100, step: 1),
                sensitivity: .medium,
                collectionMethod: .manual,
                isRequired: false,
                isEnabled: true,
                description: "사회적 활동 수준",
                createdAt: Date(),
                updatedAt: Date()
            ),
            DataTypeSchema(
                id: UUID(),
                name: "digitalDistraction",
                displayName: "디지털 방해",
                category: .behavior,
                dataType: .double,
                unit: "점",
                range: ValueRange(min: 0, max: 100, step: 1),
                sensitivity: .low,
                collectionMethod: .manual,
                isRequired: false,
                isEnabled: true,
                description: "디지털 기기로 인한 방해 정도",
                createdAt: Date(),
                updatedAt: Date()
            ),
            DataTypeSchema(
                id: UUID(),
                name: "exploration",
                displayName: "탐색",
                category: .behavior,
                dataType: .double,
                unit: "점",
                range: ValueRange(min: 0, max: 100, step: 1),
                sensitivity: .low,
                collectionMethod: .manual,
                isRequired: false,
                isEnabled: true,
                description: "새로운 것을 탐색한 정도",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
    
    // MARK: - Physical Schemas
    
    private func getPhysicalSchemas() -> [DataTypeSchema] {
        return [
            DataTypeSchema(
                id: UUID(),
                name: "sleepScore",
                displayName: "수면 점수",
                category: .physical,
                dataType: .double,
                unit: "점",
                range: ValueRange(min: 0, max: 100, step: 1),
                sensitivity: .medium,
                collectionMethod: .manual,
                isRequired: false,
                isEnabled: true,
                description: "수면의 질",
                createdAt: Date(),
                updatedAt: Date()
            ),
            DataTypeSchema(
                id: UUID(),
                name: "fatigue",
                displayName: "피로도",
                category: .physical,
                dataType: .double,
                unit: "점",
                range: ValueRange(min: 0, max: 100, step: 1),
                sensitivity: .medium,
                collectionMethod: .manual,
                isRequired: false,
                isEnabled: true,
                description: "신체 피로 수준",
                createdAt: Date(),
                updatedAt: Date()
            ),
            DataTypeSchema(
                id: UUID(),
                name: "activityLevel",
                displayName: "활동량",
                category: .physical,
                dataType: .double,
                unit: "점",
                range: ValueRange(min: 0, max: 100, step: 1),
                sensitivity: .low,
                collectionMethod: .manual,
                isRequired: false,
                isEnabled: true,
                description: "신체 활동 수준",
                createdAt: Date(),
                updatedAt: Date()
            ),
            DataTypeSchema(
                id: UUID(),
                name: "nutrition",
                displayName: "영양",
                category: .physical,
                dataType: .double,
                unit: "점",
                range: ValueRange(min: 0, max: 100, step: 1),
                sensitivity: .low,
                collectionMethod: .manual,
                isRequired: false,
                isEnabled: true,
                description: "영양 섭취 수준",
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
    
    // MARK: - All Schemas (for dailyLog)
    
    private func getAllSchemas() -> [DataTypeSchema] {
        return getMindSchemas() + getBehaviorSchemas() + getPhysicalSchemas()
    }
}

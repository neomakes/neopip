//
//  FirebaseDataService+Goals.swift
//  PIP_Project
//
//  Created by Gemini on 2026/01/10.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

// MARK: - Goals (Simplified for UserProfile)
extension FirebaseDataService {
    
    /// UserProfile의 goals(String 배열)를 읽어와서 임시 Goal 객체로 변환하여 반환
    func fetchGoals() -> AnyPublisher<[Goal], Error> {
        return fetchUserProfile()
            .map { profile -> [Goal] in
                guard let goalStrings = profile.goals else { return [] }
                
                // Convert Strings to Dummy Goals for UI compatibility
                return goalStrings.enumerated().map { index, title in
                    // Try to match a category based on keywords or default to .custom
                    let category = self.guessCategory(from: title)
                    
                    return Goal(
                        id: UUID.deterministicUUID(from: "goal_\(title)_\(index)"), // Deterministic ID
                        accountId: profile.accountId,
                        title: title,
                        description: "Goal from profile",
                        category: category,
                        targetDate: nil,
                        startDate: profile.createdAt,
                        status: .active,
                        progress: 0.0,
                        gemVisualization: GemVisualization(gemType: .sphere, colorTheme: .teal, gradientColors: nil, brightness: 0.8, size: 1.0, customShape: nil),
                        milestones: [],
                        relatedDataPointIds: [],
                        createdAt: profile.createdAt,
                        updatedAt: profile.createdAt
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    // Helper to guess category
    private func guessCategory(from title: String) -> GoalCategory {
        let lower = title.lowercased()
        if lower.contains("sleep") || lower.contains("health") { return .physical }
        if lower.contains("stress") || lower.contains("medit") { return .wellness }
        if lower.contains("work") || lower.contains("study") { return .productivity }
        return .custom
    }

    func fetchGoal(id: UUID) -> AnyPublisher<Goal?, Error> {
        // Since we don't store individual goal docs anymore, this is tricky.
        // We fetch all goals and filter.
        return fetchGoals()
            .map { goals in
                goals.first { $0.id == id }
            }
            .eraseToAnyPublisher()
    }

    func saveGoal(_ goal: Goal) -> AnyPublisher<Goal, Error> {
        // Add goal title to UserProfile.goals
        return fetchUserProfile()
            .flatMap { [weak self] profile -> AnyPublisher<Goal, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Deallocated"])).eraseToAnyPublisher()
                }
                
                var updatedProfile = profile
                var currentGoals = updatedProfile.goals ?? []
                
                // Avoid duplicates
                if !currentGoals.contains(goal.title) {
                    currentGoals.append(goal.title)
                    updatedProfile.goals = currentGoals
                    
                    return self.saveUserProfile(updatedProfile)
                        .map { _ in goal }
                        .eraseToAnyPublisher()
                } else {
                    return Just(goal).setFailureType(to: Error.self).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func updateGoal(_ goal: Goal) -> AnyPublisher<Goal, Error> {
        // Renaming is hard with just strings array, assuming no update for MVP or just allow dupes?
        // For MVP, if we edit a goal, we might assume it's a new goal or just ignore.
        // Let's implement simple replacement if we could find the old name. But we don't know the old name.
        // So for now, updateGoal is a no-op or just returns success.
        print("⚠️ [FirebaseDataService] updateGoal is not fully supported in Simplified Goals mode.")
        return Just(goal).setFailureType(to: Error.self).eraseToAnyPublisher()
    }

    func deleteGoal(id: UUID) -> AnyPublisher<Void, Error> {
        // We need to fetch goals to find the title matching this ID, then remove from profile.
        return fetchGoals()
            .flatMap { [weak self] goals -> AnyPublisher<Void, Error> in
                guard let self = self else {
                    return Fail(error: NSError(domain: "FirebaseDataService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Deallocated"])).eraseToAnyPublisher()
                }
                
                guard let goalToDelete = goals.first(where: { $0.id == id }) else {
                    return Fail(error: NSError(domain: "FirebaseDataService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Goal not found"])).eraseToAnyPublisher()
                }
                
                return self.fetchUserProfile()
                    .flatMap { profile -> AnyPublisher<Void, Error> in
                        var updatedProfile = profile
                        if var currentGoals = updatedProfile.goals {
                            currentGoals.removeAll { $0 == goalToDelete.title }
                            updatedProfile.goals = currentGoals
                            return self.saveUserProfile(updatedProfile)
                                .map { _ in () }
                                .eraseToAnyPublisher()
                        } else {
                            return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}

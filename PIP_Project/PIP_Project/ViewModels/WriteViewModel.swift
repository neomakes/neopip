//
//  WriteViewModel.swift
//  PIP_Project
//
//  WriteView의 ViewModel: 카드 입력 및 데이터 저장 관리
//

import Foundation
import Combine
import SwiftUI

@MainActor
class WriteViewModel: ObservableObject {
    // MARK: - Dependencies
    let dataService: DataServiceProtocol
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Local Cache
    @Published var cachedInputs: [[String: Any]] = []
    var localDataPoints: [TimeSeriesDataPoint] = []
    
    // User Profile for Dynamic Cards
    @Published var userProfile: UserProfile?
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DataServiceManager.shared.currentService
        loadCachedInputs()
        loadLocalDataPoints()
        checkAndSyncIfNeeded()
        
        // Fetch profile for card customization
        Task {
            await fetchUserProfile()
        }
    }
    
    private func fetchUserProfile() async {
        // If we can get it from HomeViewModel/Environment that would be better, but fetching here is safe fallback
        if let service = dataService as? FirebaseDataService {
             do {
                 for try await profile in service.fetchUserProfile().values {
                     self.userProfile = profile
                     break
                 }
             } catch {
                 print("⚠️ [WriteViewModel] Failed to fetch profile: \(error)")
             }
        }
    }
    
    // MARK: - Local Cache Management
    
    func loadCachedInputs() {
        if let data = UserDefaults.standard.data(forKey: "cachedCardInputs"),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
            cachedInputs = json
            print("WriteViewModel: Loaded cached inputs with \(cachedInputs.count) cards")
        } else {
            print("WriteViewModel: No cached inputs found")
        }
    }
    
    func saveCachedInputs() {
        if let data = try? JSONSerialization.data(withJSONObject: cachedInputs, options: []) {
            UserDefaults.standard.set(data, forKey: "cachedCardInputs")
            print("WriteViewModel: Saved cached inputs with \(cachedInputs.count) cards")
        } else {
            print("WriteViewModel: Failed to save cached inputs")
        }
    }
    
    func updateLocalCache(inputs: [String: Any], for index: Int) {
        if index < cachedInputs.count {
            cachedInputs[index] = inputs
            saveCachedInputs()
            print("WriteViewModel: Updated local cache for card \(index)")
        } else {
            print("WriteViewModel: Failed to update local cache for card \(index), cachedInputs.count = \(cachedInputs.count)")
        }
    }
    
    func loadLocalDataPoints() {
        if let data = UserDefaults.standard.data(forKey: "localTimeSeriesData"),
           let points = try? JSONDecoder().decode([TimeSeriesDataPoint].self, from: data) {
            localDataPoints = points
        }
    }
    
    func saveLocalDataPoints() {
        if let data = try? JSONEncoder().encode(localDataPoints) {
            UserDefaults.standard.set(data, forKey: "localTimeSeriesData")
        }
    }
    
    func checkAndSyncIfNeeded() {
        let lastSync = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date ?? Date.distantPast
        if !Calendar.current.isDate(lastSync, inSameDayAs: Date()) {
            // 날짜 바뀜, 전송
            Task {
                await syncLocalDataToServer()
                UserDefaults.standard.set(Date(), forKey: "lastSyncDate")
            }
        }
    }
    
    func syncLocalDataToServer() async {
        for point in localDataPoints {
            do {
                try await dataService.saveData(point, for: point.category ?? .mind)
            } catch {
                print("Error syncing: \(error)")
            }
        }
        localDataPoints.removeAll()
        saveLocalDataPoints()
    }
    
    // MARK: - Logout Data Cleanup
    
    /// 로그아웃 시 호출: 계정별 로컬 캐시 정리
    /// Firebase는 accountId/anonymousUserId로 자동 격리되므로 서버 정리 불필요
    func clearDraftDataForLogout() {
        print("🗑️ WriteViewModel: Clearing draft data on logout")
        
        // 로컬 캐시 제거 (UserDefaults)
        UserDefaults.standard.removeObject(forKey: "cachedCardInputs")
        UserDefaults.standard.removeObject(forKey: "localTimeSeriesData")
        UserDefaults.standard.removeObject(forKey: "lastSyncDate")
        
        // 인메모리 캐시 초기화
        cachedInputs.removeAll()
        localDataPoints.removeAll()
        
        print("✅ WriteViewModel: Draft data cleared")
    }
    
    // MARK: - Card Generation
    
    /// 데이터 입력 카드 생성 (스키마 기반)
    func generateCards() -> [CardData] {
        // 1. If we have UserProfile with consentedDataTypes, use those to filter/build cards
        if let profile = userProfile {
            return generateCardsBasedOnConsent(profile.enabledDataTypes)
        }
        
        // 2. Fallback to existing logic (MockDataService or Default)
        
        // MockDataService에서 스키마 가져오기
        guard dataService is MockDataService else {
            // MockDataService가 아닌 경우 기본 카드 반환
            return generateDefaultCards()
        }
        
        // ... (MockService logic omitted for brevity as it was unreachable in Prod) ...
        return generateDefaultCards()
    }
    
    private func generateCardsBasedOnConsent(_ consentedTypes: [String]) -> [CardData] {
        // Map consented strings to inputs
        // "mood", "stress", "energy", "focus" -> Mind Input
        // "productivity", "social", "distraction", "exploration" -> Behavior Input
        // "sleep", "fatigue", "activity", "nutrition" -> Physical Input
        
        var cards: [CardData] = []
        
        // Mind Category
        var mindInputs: [CardInput] = []
        // Always include mood timeline if mood is consented or by default? Let's include it if 'mood' is present.
        if consentedTypes.contains("mood") {
             mindInputs.append(.timeSlotChart(key: "mood_timeline", label: "Mood Throughout Day", range: 0...100, values: Array(repeating: 50.0, count: 5)))
        }
        if consentedTypes.contains("stress") { mindInputs.append(.slider(key: "stress", label: "Stress", range: 0...100, value: 50)) }
        if consentedTypes.contains("energy") { mindInputs.append(.slider(key: "energy", label: "Energy", range: 0...100, value: 50)) }
        if consentedTypes.contains("focus") { mindInputs.append(.slider(key: "focus", label: "Focus", range: 0...100, value: 50)) }
        
        if !mindInputs.isEmpty {
            cards.append(CardData(type: .mind, title: "How was your mood?", inputs: mindInputs, textInput: .optional(key: "notes", placeholder: "Today's note")))
        }
        
        // Behavior Category
        var behaviorInputs: [CardInput] = []
        if consentedTypes.contains("productivity") { behaviorInputs.append(.slider(key: "productivity", label: "Productivity", range: 0...100, value: 50)) }
        if consentedTypes.contains("social") { behaviorInputs.append(.slider(key: "socialActivity", label: "Social Activity", range: 0...100, value: 50)) }
        if consentedTypes.contains("distraction") { behaviorInputs.append(.slider(key: "digitalDistraction", label: "Digital Distraction", range: 0...100, value: 50)) }
        if consentedTypes.contains("exploration") { behaviorInputs.append(.slider(key: "exploration", label: "Exploration", range: 0...100, value: 50)) }
        
        if !behaviorInputs.isEmpty {
            cards.append(CardData(type: .behavior, title: "How was your behavior?", inputs: behaviorInputs, textInput: .optional(key: "behavior_notes", placeholder: "Any thoughts?")))
        }

        // Physical Category
        var physicalInputs: [CardInput] = []
        if consentedTypes.contains("sleep") { physicalInputs.append(.slider(key: "sleepScore", label: "Sleep Score", range: 0...100, value: 50)) }
        if consentedTypes.contains("fatigue") { physicalInputs.append(.slider(key: "fatigue", label: "Fatigue", range: 0...100, value: 50)) }
        if consentedTypes.contains("activity") { physicalInputs.append(.slider(key: "activityLevel", label: "Activity Level", range: 0...100, value: 50)) }
        if consentedTypes.contains("nutrition") { physicalInputs.append(.slider(key: "nutrition", label: "Nutrition", range: 0...100, value: 50)) }

        if !physicalInputs.isEmpty {
            cards.append(CardData(type: .physical, title: "Physical State", inputs: physicalInputs, textInput: .optional(key: "physical_notes", placeholder: "Body check-in")))
        }
        
        return cards.isEmpty ? generateDefaultCards() : cards
    }

    /// Default card generation (when schema is not available)
    private func generateDefaultCards() -> [CardData] {
        return [
            CardData(
                type: .mind,
                title: "How was your mood today?",
                inputs: [
                    .timeSlotChart(key: "mood_timeline", label: "Mood Throughout Day", range: 0...100, values: Array(repeating: 50.0, count: 5)),
                    .slider(key: "stress", label: "Stress", range: 0...100, value: 50),
                    .slider(key: "energy", label: "Energy", range: 0...100, value: 50)
                ],
                textInput: .optional(key: "notes", placeholder: "Today's note")
            ),
            CardData(
                type: .behavior,
                title: "How was your behavior?",
                inputs: [
                    .slider(key: "productivity", label: "Productivity", range: 0...100, value: 50),
                    .slider(key: "socialActivity", label: "Social Activity", range: 0...100, value: 50),
                    .slider(key: "digitalDistraction", label: "Digital Distraction", range: 0...100, value: 50),
                    .slider(key: "exploration", label: "Exploration", range: 0...100, value: 50)
                ],
                textInput: .optional(key: "notes", placeholder: "Note")
            ),
            CardData(
                type: .physical,
                title: "How was your physical state?",
                inputs: [
                    .slider(key: "sleepScore", label: "Sleep Score", range: 0...100, value: 50),
                    .slider(key: "fatigue", label: "Fatigue", range: 0...100, value: 50),
                    .slider(key: "activityLevel", label: "Activity Level", range: 0...100, value: 50),
                    .slider(key: "nutrition", label: "Nutrition", range: 0...100, value: 50)
                ],
                textInput: .optional(key: "notes", placeholder: "Note")
            )
        ]
    }
    
    // MARK: - Card Data Saving
    
    /// 카드 데이터 저장
    func saveCardData(_ card: CardData, inputs: [String: Any], textInput: String) {
        let now = Date()

        // 입력값을 DataValue로 변환
        var values: [String: DataValue] = [:]

        for (key, value) in inputs {
            if let doubleValue = value as? Double {
                values[key] = .double(doubleValue)
            } else if let intValue = value as? Int {
                values[key] = .integer(intValue)
            } else if let stringValue = value as? String {
                values[key] = .string(stringValue)
            } else if let doubleArray = value as? [Double] {
                // Store full time-slot array as DataValue.array of doubles
                values[key] = .array(doubleArray.map { .double($0) })
            } else if let intArray = value as? [Int] {
                values[key] = .array(intArray.map { .integer($0) })
            }
        }
        
        // 텍스트 입력 추가
        if !textInput.isEmpty {
            values["notes"] = .string(textInput)
        }
        
        // TimeSeriesDataPoint 생성
        let dataPoint = TimeSeriesDataPoint(
            timestamp: now,
            category: card.type.toDataCategory(),
            values: values,
            notes: textInput.isEmpty ? nil : textInput
        )
        
        // 로컬에 저장
        localDataPoints.append(dataPoint)
        saveLocalDataPoints()
        
        // 서버로 바로 보내지 않음, 하루 끝날 때 전송
    }

    /// 비동기 블록으로 저장 동작을 노출합니다. 오류는 호출자에게 전달됩니다.
    /// Firebase에 isDraft=true로 저장하여 나중에 수정/삭제 가능하도록 함
    func saveCard(_ card: CardData, inputs: [String: Any], textInput: String) async throws {
        let now = Date()
        var values: [String: DataValue] = [:]

        for (key, value) in inputs {
            if let doubleValue = value as? Double {
                values[key] = .double(doubleValue)
            } else if let intValue = value as? Int {
                values[key] = .integer(intValue)
            } else if let stringValue = value as? String {
                values[key] = .string(stringValue)
            } else if let doubleArray = value as? [Double] {
                values[key] = .array(doubleArray.map { .double($0) })
            } else if let intArray = value as? [Int] {
                values[key] = .array(intArray.map { .integer($0) })
            }
        }

        if !textInput.isEmpty {
            values["notes"] = .string(textInput)
        }

        // ✅ isDraft=true로 Firebase에 직접 저장 (계정별 격리됨)
        let dataPoint = TimeSeriesDataPoint(
            timestamp: now,
            category: card.type.toDataCategory(),
            values: values,
            notes: textInput.isEmpty ? nil : textInput,
            isDraft: true  // ← Draft 표시 (미완성 상태)
        )

        // 1️⃣ Firebase TimeSeriesDataPoint 저장 (계정별로 자동 격리)
        try await dataService.saveData(dataPoint, for: card.type.toDataCategory())
        
        // 2️⃣ 로컬 캐시에도 추가 (오프라인 지원)
        localDataPoints.append(dataPoint)
        saveLocalDataPoints()

        // 3️⃣ DailyGem 생성/수정 (오늘의 Gem이 활성화되어 불투명해짐)
        let (savedGem, isNewGem) = await createOrUpdateDailyGem(for: now, dataPointId: dataPoint.id.uuidString)

        // 4️⃣ UserStats 업데이트 (totalDataPoints, totalGemsCreated, streak 등)
        await updateUserStats(for: now, savedGem: savedGem, isNewGem: isNewGem)

        // HomeViewModel에 새로고침 알림 (UI 반영)
        NotificationCenter.default.post(name: .didSaveCardData, object: nil)
    }

    /// 오늘 날짜에 대한 DailyGem을 생성하거나 업데이트합니다.
    /// - 반환값: (DailyGem, isNew) -> 저장된 DailyGem과 새로 생성되었는지 여부
    private func createOrUpdateDailyGem(for date: Date, dataPointId: String) async -> (DailyGem?, Bool) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        // 기존 DailyGem 확인
        var existingGem: DailyGem?
        var cancellable: AnyCancellable?

        await withCheckedContinuation { continuation in
            cancellable = dataService.fetchDailyGem(for: startOfDay)
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { gem in
                        existingGem = gem
                        continuation.resume()
                    }
                )
        }
        _ = cancellable  // Keep reference until completion

        let gemToSave: DailyGem
        var isNew = false
        
        if var existing = existingGem {
            // 기존 gem에 dataPointId 추가
            if !existing.dataPointIds.contains(dataPointId) {
                existing.dataPointIds.append(dataPointId)
            }
            // brightness 업데이트 (데이터가 추가될수록 밝아짐)
            existing.brightness = min(1.0, existing.brightness + 0.2)
             // Uncertainty 감소 (데이터가 쌓일수록 확실해짐)
            existing.uncertainty = max(0.1, existing.uncertainty - 0.1)
            gemToSave = existing
        } else {
            // 새로운 DailyGem 생성
            isNew = true
            gemToSave = DailyGem(
                id: UUID(),
                accountId: "",  // FirebaseDataService에서 실제 accountId로 교체됨
                date: startOfDay,
                gemType: .diamond,
                brightness: 0.6,
                uncertainty: 0.3,
                dataPointIds: [dataPointId],
                colorTheme: .teal,
                createdAt: Date()
            )
        }

        // DailyGem 저장
        var savedGem: DailyGem?
        var saveCancellable: AnyCancellable?
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            saveCancellable = dataService.saveDailyGem(gemToSave)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ [WriteViewModel] Failed to save DailyGem: \(error)")
                        }
                        continuation.resume()
                    },
                    receiveValue: { gem in
                        savedGem = gem
                        print("✅ [WriteViewModel] DailyGem saved for \(startOfDay)")
                    }
                )
        }
        _ = saveCancellable  // Keep reference until completion
        return (savedGem, isNew)
    }

    /// UserStats를 업데이트하여 사용자 통계 반영
    /// - Parameters:
    ///   - date: 저장 날짜
    ///   - savedGem: 저장된 DailyGem (새 gem 판별용)
    ///   - isNewGem: 새로운 Gem이 생성되었는지 여부
    /// - 업데이트 내용:
    ///   - totalDataPoints += 1 (항상 증가)
    ///   - totalGemsCreated += 1 (isNewGem일 때만)
    ///   - totalDaysActive += 1 (isNewGem일 때만)
    ///   - currentStreak & longestStreak (로컬 데이터 기반 재계산)
    ///   - lastUpdated = 현재 시간
    private func updateUserStats(for date: Date, savedGem: DailyGem?, isNewGem: Bool) async {
        print("🔄 [WriteViewModel] Updating UserStats...")
        
        var cancellable: AnyCancellable?
        
        await withCheckedContinuation { continuation in
            cancellable = dataService.fetchUserStats()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ [WriteViewModel] Failed to fetch UserStats: \(error)")
                        }
                        continuation.resume()
                    },
                    receiveValue: { [weak self] stats in
                        var updatedStats = stats
                        
                        // 1️⃣ totalDataPoints 증가 (모든 저장마다)
                        updatedStats.totalDataPoints += 1
                        print("   📊 totalDataPoints: \(stats.totalDataPoints) → \(updatedStats.totalDataPoints)")
                        
                        // 2️⃣ 새로운 Gem인 경우만 카운트 증가 (기존 gem 수정 시 제외)
                        if isNewGem {
                            updatedStats.totalGemsCreated += 1
                            updatedStats.totalDaysActive += 1
                            print("   💎 totalGemsCreated: \(stats.totalGemsCreated) → \(updatedStats.totalGemsCreated)")
                            print("   📅 totalDaysActive: \(stats.totalDaysActive) → \(updatedStats.totalDaysActive)")
                        } else {
                            print("   📝 Existing gem modified, not incrementing gem counts")
                        }
                        
                        // 3️⃣ Streak 재계산 (로컬 데이터 기반)
                        self?.calculateAndUpdateStreak(stats: &updatedStats)
                        
                        // 4️⃣ lastUpdated 갱신
                        updatedStats.lastUpdated = Date()
                        
                        // 5️⃣ Firebase에 업데이트
                        var updateCancellable: AnyCancellable?
                        updateCancellable = self?.dataService.updateUserStats(updatedStats)
                            .sink(
                                receiveCompletion: { completion in
                                    if case .failure(let error) = completion {
                                        print("❌ [WriteViewModel] Failed to update UserStats: \(error)")
                                    }
                                    _ = updateCancellable
                                },
                                receiveValue: { stats in
                                    print("✅ [WriteViewModel] UserStats 저장 완료:")
                                    print("   📊 totalDataPoints: \(stats.totalDataPoints)")
                                    print("   💎 totalGemsCreated: \(stats.totalGemsCreated)")
                                    print("   🔥 currentStreak: \(stats.currentStreak)")
                                    print("   📅 totalDaysActive: \(stats.totalDaysActive)")
                                }
                            )
                    }
                )
        }
        _ = cancellable
    }

    /// Streak을 계산하고 UserStats에 반영합니다.
    /// - currentStreak: 어제부터 연속 기록된 일수 (오늘은 제외)
    /// - longestStreak: 현재 streak이 이전 최장 streak을 넘으면 업데이트
    private func calculateAndUpdateStreak(stats: inout UserStats) {
        print("🔥 [WriteViewModel] Calculating streak from local data...")
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 로컬 데이터 포인트에서 날짜 집합 구성
        var datePresentDays = Set<Date>()
        for dataPoint in localDataPoints {
            let day = calendar.startOfDay(for: dataPoint.timestamp)
            datePresentDays.insert(day)
        }
        
        print("   📊 Data points: \(localDataPoints.count) across \(datePresentDays.count) unique days")
        
        // 어제부터 거슬러 올라가며 streak 계산
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
            stats.currentStreak = 0
            return
        }
        
        var streak = 0
        var dayToCheck = yesterday
        
        while datePresentDays.contains(dayToCheck) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: dayToCheck) else { break }
            dayToCheck = prev
        }
        
        stats.currentStreak = streak
        print("   🔥 currentStreak: \(streak)")
        
        // longestStreak 업데이트
        if streak > stats.longestStreak {
            stats.longestStreak = streak
            print("   🏆 longestStreak updated: \(stats.longestStreak)")
        }
    }
}

// MARK: - Notification Name
extension Notification.Name {
    static let didSaveCardData = Notification.Name("didSaveCardData")
}

// MARK: - Helper Extensions
extension CardType {
    func toDataCategory() -> DataCategory {
        switch self {
        case .mind: return .mind
        case .behavior: return .behavior
        case .physical: return .physical
        case .program: return .mind  // Default category for program type
        }
    }
}

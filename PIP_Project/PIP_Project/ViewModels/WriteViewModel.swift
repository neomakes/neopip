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
    @Published var isRestoring: Bool = false

    // Enrolled Programs for dynamic program cards
    @Published var enrolledPrograms: [EnrolledProgramInfo] = []

    /// 프로그램 카드 생성을 위한 간단한 정보 구조체
    struct EnrolledProgramInfo: Identifiable {
        let id: String
        let name: String
        let inputs: [CardInput]
    }
    
    // 수정 모드 여부 (기존 DataPoint ID가 있으면 true)
    var isEditMode: Bool { existingDataPointId != nil }
    private var existingDataPointId: UUID?
    
    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DataServiceManager.shared.currentService
        loadCachedInputs()
        loadLocalDataPoints()
        loadDraftAccumulation() // Load draft state
        checkAndSyncIfNeeded()
        
        // Fetch profile and restore data
        Task {
            await fetchUserProfile()
            await restoreTodayData()
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
            // 날짜 바뀜: 이전 날짜의 캐시 정리 및 동기화
            print("📅 [WriteViewModel] Day changed. Clearing previous day's cache...")
            clearDraftAccumulation()  // 이전 날짜 데이터 정리
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
        
        // Draft Accumulation 제거
        UserDefaults.standard.removeObject(forKey: "draftAccumulatedValues")
        UserDefaults.standard.removeObject(forKey: "draftAccumulatedNotes")
        
        // 인메모리 캐시 초기화
        cachedInputs.removeAll()
        localDataPoints.removeAll()
        accumulatedValues.removeAll()
        accumulatedNotes.removeAll()
        
        print("✅ WriteViewModel: Draft data cleared")
    }

    // MARK: - Data Restoration

    /// 오늘 날짜의 데이터를 DB(또는 로컬)에서 복원합니다.
    /// DB를 Source of Truth로 사용하여 항상 최신 데이터를 가져옵니다.
    /// 오늘 날짜의 데이터를 복원합니다.
    /// Local-First Strategy: 로컬 캐시를 우선 표시하고, 백그라운드에서 서버 데이터를 병합합니다.
    func restoreTodayData() async {
        print("🔄 [WriteViewModel] Restoring today's data (Local-First Strategy)...")

        let hasLocalDraft = !accumulatedValues.isEmpty

        // 1. 로컬 데이터가 있으면 즉시 복원 (딜레이 제거, isRestoring = false 유지)
        if hasLocalDraft {
            print("   ⚡️ Local draft exists (\(accumulatedValues.count) categories). Restoring immediately.")
            restoreInputsFromAccumulation()
            // 로컬 데이터가 있으면 isRestoring을 절대 true로 설정하지 않음
            // UI가 즉시 표시되도록 함
        } else {
            // 로컬 데이터가 없을 때만 로딩 표시
            print("   ⏳ No local draft. Setting isRestoring = true")
            await MainActor.run { isRestoring = true }
        }

        // 2. 백그라운드 DB 동기화 (Source of Truth 확인 및 병합)
        let today = Date()
        let dbDataPoint = await fetchDailyLogDataPoint(for: today)

        await MainActor.run {
            if let dataPoint = dbDataPoint {
                print("   ✅ Found saved data point in DB: \(dataPoint.id)")

                // Safe Merge: 로컬 데이터 우선, DB 데이터 병합
                self.existingDataPointId = dataPoint.id

                if self.accumulatedValues.isEmpty {
                    // Case 1: 로컬이 비어있으면 DB 데이터로 전면 교체
                    self.accumulatedValues = dataPoint.values
                    if let notes = dataPoint.notes {
                        self.accumulatedNotes = notes.components(separatedBy: "\n\n")
                    } else {
                         self.accumulatedNotes = []
                    }
                    print("   📥 Remote data applied (Local was empty).")
                    // DB 데이터가 적용되었으므로 캐시 복원
                    self.restoreInputsFromAccumulation()
                } else {
                    // Case 2: 로컬이 있으면 'Safe Merge' 수행 (누락된 데이터만 채움)
                    print("   🐢 Local data exists. Performing safe merge...")
                    self.mergeServerData(serverValues: dataPoint.values)
                }

                // 저장 (Merge된 상태 저장)
                self.saveDraftAccumulation()
            } else {
                print("   → No saved data in DB.")
            }

            self.isRestoring = false
            self.objectWillChange.send()
        }
    }
    
    /// 서버 데이터를 로컬 데이터에 안전하게 병합 (로컬 우선)
    private func mergeServerData(serverValues: [String: DataValue]) {
        for (category, val) in serverValues {
            if accumulatedValues[category] == nil {
                // 로컬에 해당 카테고리가 없으면 서버 데이터 추가
                accumulatedValues[category] = val
            } else {
                // 카테고리가 있으면 내부 필드 병합 (Shallow Merge for Object)
                if case .object(let serverObj) = val,
                   case .object(var localObj) = accumulatedValues[category] {
                    var isModified = false
                    for (k, v) in serverObj {
                        // 로컬에 없는 키만 추가 (로컬 값 유지)
                        if localObj[k] == nil {
                            localObj[k] = v
                            isModified = true
                        }
                    }
                    if isModified {
                        accumulatedValues[category] = .object(localObj)
                    }
                }
            }
        }
    }
    
    private func fetchDailyLogDataPoint(for date: Date) async -> TimeSeriesDataPoint? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        return await withCheckedContinuation { continuation in
            var hasResumed = false  // 중복 resume 방지

            dataService.fetchDataPoints(for: startOfDay)
                .sink(
                    receiveCompletion: { completion in
                        // 에러 발생 시 또는 값을 받지 못한 경우 nil 반환
                        if !hasResumed {
                            hasResumed = true
                            if case .failure(let error) = completion {
                                print("❌ [WriteViewModel] fetchDailyLogDataPoint error: \(error)")
                            }
                            continuation.resume(returning: nil)
                        }
                    },
                    receiveValue: { points in
                        guard !hasResumed else { return }
                        hasResumed = true
                        // .dailyLog 카테고리이면서 가장 최신 것
                        let dailyLog = points.first { $0.category == .dailyLog }
                        continuation.resume(returning: dailyLog)
                    }
                )
                .store(in: &cancellables)
        }
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

        // Program Cards (등록된 프로그램에 따라 동적 생성)
        for program in enrolledPrograms {
            let programCard = CardData(
                id: UUID(uuidString: program.id) ?? UUID(),
                type: .program,
                title: program.name,
                inputs: program.inputs,
                textInput: .optional(key: "program_notes", placeholder: "Program reflection")
            )
            cards.append(programCard)
        }

        return cards.isEmpty ? generateDefaultCards() : cards
    }

    /// 프로그램 등록 시 호출하여 프로그램 카드 추가
    func registerProgram(id: String, name: String, inputs: [CardInput]) {
        let programInfo = EnrolledProgramInfo(id: id, name: name, inputs: inputs)
        enrolledPrograms.append(programInfo)
        print("📋 [WriteViewModel] Registered program card: \(name)")
    }

    /// 프로그램 해제 시 호출하여 프로그램 카드 제거
    func unregisterProgram(id: String) {
        enrolledPrograms.removeAll { $0.id == id }
        print("🗑️ [WriteViewModel] Unregistered program card: \(id)")
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
    // MARK: - Accumulation State (카테고리별 구조)
    /// 카테고리별로 그룹화된 값 저장
    /// 구조: { "mind": { "mood_timeline": [...], "stress": 50, "notes": "..." }, "behavior": {...}, "program_meditation": {...} }
    private var accumulatedValues: [String: DataValue] = [:]
    private var accumulatedNotes: [String] = []  // 레거시 호환용 (전체 노트 합본)

    // MARK: - Saving Logic (Batch)

    /// 카드의 데이터를 임시 저장하고, 마지막 카드일 경우 서버에 전송합니다.
    /// - Parameters:
    ///   - card: 현재 저장하는 카드 (카테고리 정보 포함)
    ///   - inputs: 카드의 입력값들
    ///   - textInput: 카드의 노트 입력
    ///   - isLast: 마지막 카드인지 여부
    func saveCard(_ card: CardData, inputs: [String: Any], textInput: String, isLast: Bool) async throws {
        // 1. Accumulate Data (카테고리별로 병합)
        accumulate(card: card, inputs: inputs, textInput: textInput)

        // 2. 마지막 카드라면 커밋 (서버 저장)
        if isLast {
            try await commitSession()
        }
    }

    /// 카테고리별로 값과 노트를 저장합니다.
    private func accumulate(card: CardData, inputs: [String: Any], textInput: String) {
        // 카테고리 키 결정 (mind, behavior, physical, program_xxx)
        let categoryKey = getCategoryKey(for: card)

        // 기존 카테고리 데이터 가져오기 또는 새로 생성
        var categoryValues: [String: DataValue] = [:]
        if case .object(let existing) = accumulatedValues[categoryKey] {
            categoryValues = existing
        }

        // Input 값을 DataValue로 변환하여 카테고리 내에 병합
        for (key, value) in inputs {
            if let doubleValue = value as? Double {
                categoryValues[key] = .double(doubleValue)
            } else if let intValue = value as? Int {
                categoryValues[key] = .integer(intValue)
            } else if let stringValue = value as? String {
                categoryValues[key] = .string(stringValue)
            } else if let doubleArray = value as? [Double] {
                categoryValues[key] = .array(doubleArray.map { .double($0) })
            } else if let intArray = value as? [Int] {
                categoryValues[key] = .array(intArray.map { .integer($0) })
            }
        }

        // 노트를 카테고리 내에 저장
        if !textInput.isEmpty {
            categoryValues["notes"] = .string(textInput)
            // 레거시 호환용 전체 노트 배열에도 추가
            accumulatedNotes.append(textInput)
        }

        // 카테고리 값 업데이트
        accumulatedValues[categoryKey] = .object(categoryValues)

        print("📦 [WriteViewModel] Accumulated data for '\(categoryKey)'. Total categories: \(accumulatedValues.count)")

        // Draft 저장 (Persistence)
        saveDraftAccumulation()
    }

    /// 카드 타입에 따른 카테고리 키 반환
    private func getCategoryKey(for card: CardData) -> String {
        switch card.type {
        case .mind:
            return "mind"
        case .behavior:
            return "behavior"
        case .physical:
            return "physical"
        case .program:
            // 프로그램 카드의 경우 enrolledPrograms에서 매칭되는 프로그램 ID 사용
            // 카드 ID로 프로그램을 찾아 일관된 키 생성
            if let program = enrolledPrograms.first(where: { UUID(uuidString: $0.id) == card.id }) {
                return "program_\(program.id)"
            }
            // fallback: 카드 ID 기반
            return "program_\(card.id.uuidString.prefix(8))"
        }
    }

    private func commitSession() async throws {
        print("💾 [WriteViewModel] Committing session...")
        let now = Date()

        // 전체 노트 병합 (레거시 호환 - 선택적)
        let combinedNotes = accumulatedNotes.isEmpty ? nil : accumulatedNotes.joined(separator: "\n\n")

        // 1️⃣ 통합 TimeSeriesDataPoint 생성 (.dailyLog)
        // 기존 ID가 있으면 재사용 (수정 모드), 아니면 새로 생성
        let dataPointId = existingDataPointId ?? UUID()
        let dataPoint = TimeSeriesDataPoint(
            id: dataPointId,
            timestamp: now,
            category: .dailyLog,
            values: accumulatedValues,  // 이미 카테고리별로 구조화된 값
            notes: combinedNotes  // 레거시 호환용 전체 노트
        )

        print("   → Values structure:")
        for (category, value) in accumulatedValues {
            if case .object(let obj) = value {
                print("      \(category): \(obj.keys.joined(separator: ", "))")
            }
        }

        // 2️⃣ Firebase TimeSeriesDataPoint 저장
        do {
            try await dataService.saveData(dataPoint, for: .dailyLog)
        } catch {
            print("❌ [WriteViewModel] Critical Error: Failed to save TimeSeriesDataPoint: \(error)")
            throw error
        }

        // 3️⃣ 로컬 캐시에도 추가
        localDataPoints.append(dataPoint)
        saveLocalDataPoints()

        // 4️⃣ DailyGem 생성/수정
        print("   → Creating/Updating DailyGem...")
        let (savedGem, isNewGem) = await createOrUpdateDailyGem(for: now, dataPointId: dataPoint.id.uuidString)

        // 5️⃣ UserStats 업데이트 (통합 1회)
        print("   → Updating UserStats...")
        // 수정인 경우(existingDataPointId가 있었던 경우) totalDataPoints 증가 방지
        let isUpdate = (existingDataPointId != nil)
        await updateUserStats(for: now, savedGem: savedGem, isNewGem: isNewGem, isUpdate: isUpdate)

        // 6️⃣ 저장 완료 후 캐시 유지 (다음 접근 시 즉시 표시를 위해)
        // accumulatedValues와 cachedInputs는 유지하고, existingDataPointId만 설정
        // 이렇게 하면 다음에 WriteView를 열 때 저장된 데이터가 즉시 표시됨
        self.existingDataPointId = dataPointId
        saveDraftAccumulation()  // 캐시 저장 (다음 세션에서 즉시 로드)
        print("   → Cache preserved with existingDataPointId: \(dataPointId)")

        // HomeViewModel 새로고침 알림
        NotificationCenter.default.post(name: .didSaveCardData, object: nil)
        print("✅ [WriteViewModel] Session committed successfully")
    }
    
    // MARK: - Draft Persistence
    
    private func saveDraftAccumulation() {
        // DataValue는 Codable이므로 JSON 인코딩 가능 (DataValue 정의 확인 필요, 만약 아니라면 변환 로직 필요)
        // DataValue가 Codable이라고 가정 (DataModels.swift 확인)
        // 안타깝게도 DataValue Enum에 대한 Codable conformance를 확인하지 못했으므로, 
        // 안전하게 Dictionary<String, Any>로 변환해서 저장하거나, DataValue가 Codable인지 확인해야 함.
        // DataModels.swift를 보면 DataValue는 Codable임.
        
        if let valuesData = try? JSONEncoder().encode(accumulatedValues),
           let notesData = try? JSONEncoder().encode(accumulatedNotes) {
            UserDefaults.standard.set(valuesData, forKey: "draftAccumulatedValues")
            UserDefaults.standard.set(notesData, forKey: "draftAccumulatedNotes")
            
            // 기존 DataPoint ID 저장 (수정 모드 유지를 위해)
            if let id = existingDataPointId {
                UserDefaults.standard.set(id.uuidString, forKey: "draftExistingDataPointId")
            }
            
            print("💾 [WriteViewModel] Draft accumulation saved")
        }
    }
    
    private func loadDraftAccumulation() {
        if let valuesData = UserDefaults.standard.data(forKey: "draftAccumulatedValues"),
           let loadedValues = try? JSONDecoder().decode([String: DataValue].self, from: valuesData) {
            self.accumulatedValues = loadedValues
            print("📂 [WriteViewModel] Loaded accumulatedValues: \(loadedValues.keys.joined(separator: ", "))")
        } else {
            print("📂 [WriteViewModel] No accumulatedValues in UserDefaults")
        }

        if let notesData = UserDefaults.standard.data(forKey: "draftAccumulatedNotes"),
           let loadedNotes = try? JSONDecoder().decode([String].self, from: notesData) {
            self.accumulatedNotes = loadedNotes
        }

        if let idString = UserDefaults.standard.string(forKey: "draftExistingDataPointId"),
           let id = UUID(uuidString: idString) {
            self.existingDataPointId = id
            print("📂 [WriteViewModel] Loaded existingDataPointId: \(id)")
        }

        print("📂 [WriteViewModel] Draft accumulation loaded: keys=\(accumulatedValues.count), notes=\(accumulatedNotes.count), existingId=\(existingDataPointId?.uuidString ?? "nil")")

        // accumulatedValues가 있으면 cachedInputs 복원 (UI 반영)
        if !accumulatedValues.isEmpty {
            restoreInputsFromAccumulation()
        }
    }
    
    private func clearDraftAccumulation() {
        UserDefaults.standard.removeObject(forKey: "draftAccumulatedValues")
        UserDefaults.standard.removeObject(forKey: "draftAccumulatedNotes")
        UserDefaults.standard.removeObject(forKey: "draftExistingDataPointId")
        UserDefaults.standard.removeObject(forKey: "cachedCardInputs") // 카드 캐시도 함께 날림 (세션 완료되었으므로)
        cachedInputs = []
    }
    
    // MARK: - Restoration Helper
    /// 이미 입력된(accumulated) 데이터를 기반으로 필터링된 카드를 반환합니다.
    func getRemainingCards() -> [CardData] {
        let allCards = generateCards()

        // 수정 모드(이미 DB 저장된 데이터 복원)라면 모든 카드를 보여줌 (수정 가능하도록)
        if isEditMode {
            print("📝 [WriteViewModel] Edit mode active: Returning all cards for editing.")
            return allCards
        }

        let remaining = allCards.filter { card in
            // 카테고리 키로 이미 저장된 데이터가 있는지 확인
            let categoryKey = getCategoryKey(for: card)
            return accumulatedValues[categoryKey] == nil
        }

        return remaining
    }

    // MARK: - Input Restoration Logic

    /// accumulatedValues(카테고리별 구조)를 cachedInputs([String: Any])로 변환
    private func restoreInputsFromAccumulation() {
        print("🔄 [WriteViewModel] Restoring cachedInputs from accumulation...")
        let cards = generateCards()
        var newInputs: [[String: Any]] = []

        for card in cards {
            var cardInput: [String: Any] = [:]
            let categoryKey = getCategoryKey(for: card)

            // 해당 카테고리의 저장된 값 가져오기
            var categoryValues: [String: DataValue] = [:]
            if case .object(let obj) = accumulatedValues[categoryKey] {
                categoryValues = obj
            }

            for input in card.inputs {
                let key = keyForInput(input)
                // 카테고리 내에서 저장된 값이 있으면 변환, 없으면 기본값 사용
                if let dataValue = categoryValues[key], let value = extractAnyValue(from: dataValue) {
                    cardInput[key] = value
                } else {
                    cardInput[key] = defaultValueForInput(input)
                }
            }
            newInputs.append(cardInput)
        }

        self.cachedInputs = newInputs
        print("   ✅ Restored \(newInputs.count) card inputs from categorized data")
    }

    /// 특정 카테고리의 노트를 가져옵니다.
    func getNotes(for card: CardData) -> String {
        let categoryKey = getCategoryKey(for: card)
        if case .object(let obj) = accumulatedValues[categoryKey],
           case .string(let notes) = obj["notes"] {
            return notes
        }
        return ""
    }
    
    private func keyForInput(_ input: CardInput) -> String {
        switch input {
        case .slider(let key, _, _, _): return key
        case .toggle(let key, _, _): return key
        case .picker(let key, _, _, _): return key
        case .timeSlotChart(let key, _, _, _): return key
        }
    }
    
    private func defaultValueForInput(_ input: CardInput) -> Any {
        switch input {
        case .slider(_, _, _, let def): return def
        case .toggle(_, _, let def): return def
        case .picker(_, _, _, let idx): return idx
        case .timeSlotChart(_, _, _, let def): return def
        }
    }
    
    private func extractAnyValue(from dataValue: DataValue) -> Any? {
        switch dataValue {
        case .integer(let v): return v
        case .double(let v): return v
        case .boolean(let v): return v
        case .string(let v): return v
        case .array(let arr): return arr.compactMap { extractAnyValue(from: $0) }
        case .object(_): return nil
        }
    }

    
    func getTotalCardsCount() -> Int {
        return generateCards().count
    }

    /// accumulatedValues에 실제 데이터가 있는지 확인합니다.
    /// WriteView에서 캐시 존재 여부를 판단할 때 사용됩니다.
    func hasAccumulatedData() -> Bool {
        return !accumulatedValues.isEmpty
    }

    /// accumulatedValues가 있지만 cachedInputs가 비어있는 경우 캐시를 재생성합니다.
    /// DB에서 데이터를 복원한 후 WriteView에서 호출됩니다.
    func refreshCachedInputsIfNeeded() {
        // accumulatedValues가 있고 cachedInputs가 비어있으면 캐시 재생성
        if !accumulatedValues.isEmpty && cachedInputs.isEmpty {
            print("🔄 [WriteViewModel] Refreshing cachedInputs from accumulatedValues...")
            restoreInputsFromAccumulation()
        }
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
    ///   - isUpdate: 기존 DataPoint 수정 여부 (true면 totalDataPoints 증가 안함)
    /// - 업데이트 내용:
    ///   - totalDataPoints += 1 (isNewGem이고 !isUpdate일 때만 - 새 날짜의 첫 저장)
    ///   - totalGems += 1 (isNewGem일 때만)
    ///   - streakDays (DB 기반 재계산)
    ///   - updatedAt = 현재 시간
    private func updateUserStats(for date: Date, savedGem: DailyGem?, isNewGem: Bool, isUpdate: Bool) async {
        print("🔄 [WriteViewModel] Updating UserStats (isNewGem: \(isNewGem), isUpdate: \(isUpdate))...")

        // 1. 먼저 DB에서 최근 30일 DailyGem을 가져와 streak 계산
        let streakDays = await calculateStreakFromDB()
        print("🔍 [WriteViewModel] Calculated streak from DB: \(streakDays)")

        var cancellable: AnyCancellable?

        await withCheckedContinuation { continuation in
            var hasResumed = false
            cancellable = dataService.fetchUserStats()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            print("❌ [WriteViewModel] Failed to fetch UserStats: \(error)")
                            // 에러 발생 시에도 계속 진행해야 함 (continuation resume)
                        }
                        if !hasResumed {
                             hasResumed = true
                             continuation.resume()
                        }
                    },
                    receiveValue: { [weak self] stats in
                        print("📥 [WriteViewModel] Fetched current UserStats: \(stats)")
                        var updatedStats = stats

                        // 1️⃣ totalDataPoints: 새 날짜의 첫 저장일 때만 증가
                        // isNewGem = 오늘 처음 저장, isUpdate = 기존 DataPoint 수정
                        // 새 Gem이고 수정이 아닐 때만 증가 (오늘 처음 저장할 때)
                        if isNewGem && !isUpdate {
                            updatedStats.totalDataPoints += 1
                            print("   📊 totalDataPoints: \(stats.totalDataPoints) → \(updatedStats.totalDataPoints) (new day)")
                        } else {
                            print("   📊 totalDataPoints: \(stats.totalDataPoints) (unchanged - same day update)")
                        }

                        // 2️⃣ 새로운 Gem인 경우만 totalGems 증가
                        if isNewGem {
                            updatedStats.totalGems += 1
                            print("   💎 totalGems: \(stats.totalGems) → \(updatedStats.totalGems)")
                        } else {
                            print("   💎 totalGems: \(stats.totalGems) (unchanged - existing gem)")
                        }

                        // 3️⃣ Streak 적용 (DB 기반으로 미리 계산됨)
                        print("   🔥 Updating streakDays: \(stats.streakDays) → \(streakDays)")
                        updatedStats.streakDays = streakDays
                        
                        // 4️⃣ updatedAt 갱신
                        updatedStats.updatedAt = Date()

                        // 5️⃣ Firebase에 업데이트
                        print("🚀 [WriteViewModel] Attempting to save UserStats...")
                        var updateCancellable: AnyCancellable?
                        updateCancellable = self?.dataService.updateUserStats(updatedStats)
                            .sink(
                                receiveCompletion: { completion in
                                    if case .failure(let error) = completion {
                                        print("❌ [WriteViewModel] Failed to update UserStats: \(error)")
                                    } else {
                                        print("✅ [WriteViewModel] UserStats update completion received")
                                    }
                                    _ = updateCancellable
                                },
                                receiveValue: { savedStats in
                                    print("✅ [WriteViewModel] UserStats saved successfully!")
                                    print("   📊 Stats: \(savedStats)")
                                }
                            )
                        
                        if !hasResumed {
                             hasResumed = true
                             continuation.resume()
                        }
                    }
                )
        }
        _ = cancellable
    }

    /// DB에서 DailyGem 데이터를 가져와 streak을 계산합니다.
    private func calculateStreakFromDB() async -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: today) else {
            return 1 // 오늘 저장했으므로 최소 1
        }

        // DB에서 최근 30일 DailyGem 가져오기
        var gemDates = Set<Date>()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            var fetchCancellable: AnyCancellable?
            fetchCancellable = dataService.fetchDailyGems(from: startDate, to: today)
                .sink(
                    receiveCompletion: { _ in
                        continuation.resume()
                    },
                    receiveValue: { gems in
                        for gem in gems {
                            let day = calendar.startOfDay(for: gem.date)
                            gemDates.insert(day)
                        }
                        _ = fetchCancellable
                    }
                )
        }

        // 오늘 저장했으므로 오늘 날짜 추가
        gemDates.insert(today)

        print("🔥 [WriteViewModel] Calculating streak from DB: \(gemDates.count) days with gems")

        // 오늘부터 역순으로 연속 streak 계산
        var streak = 0
        var checkDate = today

        while gemDates.contains(checkDate) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        return streak
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

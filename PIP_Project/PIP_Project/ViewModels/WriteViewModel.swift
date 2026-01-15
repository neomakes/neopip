//
//  WriteViewModel.swift
//  PIP_Project
//
//  WriteView의 ViewModel: Human World Model ($w, s, a, o, O$) 데이터 수집
//  Refactored for Causal Schema
//  Fixed Build Errors: Async/Await & Initializers
//

import Foundation
import Combine
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class WriteViewModel: ObservableObject {
    // MARK: - Dependencies
    let dataService: DataServiceProtocol
    private let worldService = WorldContextService.shared
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Local Draft State
    // Strongly typed draft session for the new schema
    struct DraftSession {
        var state: InternalState?
        var actions: [Intervention] = []
        var outcome: Outcome?
        var optimality: Optimality?
        var notes: String?
        
        // Raw inputs for UI restoration
        var rawInputs: [[String: Any]] = []
    }
    
    @Published var draftSession = DraftSession()
    @Published var isRestoring: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    
    // Legacy support for WriteView binding (maps card index to input dictionary)
    @Published var cachedInputs: [[String: Any]] = [] 
    @Published var cachedTextInputs: [String] = []
    
    // MARK: - State Properties
    @Published var editingDataPointId: UUID? = nil

    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DataServiceManager.shared.currentService
        // Restore previous session if needed (TODO: Persistence)
        restoreCachedInputs()
    }
    
    // MARK: - Card Generation
    /// Human World Model 데이터 수집을 위한 정적 카드 생성
    func generateCards() -> [CardData] {
        var cards: [CardData] = []
        
        // Card 1: Internal State (s) - Mood & Energy (7-Point Curve)
        let defaultTimes: [Double] = [7.0, 9.6, 12.3, 15.0, 17.6, 20.3, 23.0]
        
        cards.append(CardData(type: .state, title: "How do you feel?", subtitle: "Track your flow state throughout the day", inputs: [
            // Valence: -100 to 100
            .timeSlotChart(key: "mood", label: "Mood", range: -100...100, values: Array(repeating: 0.0, count: 7), times: defaultTimes),
            // Arousal: 0 to 100
            .timeSlotChart(key: "energy", label: "Energy", range: 0...100, values: Array(repeating: 50.0, count: 7), times: defaultTimes)
        ]))
        
        // Card 2: Action / Intervention (a)
        // Activity List
        cards.append(CardData(type: .action, title: "What did you do?", subtitle: "Log your key activities", inputs: [
            .activityList(key: "actions", label: "Activities", limit: 5)
        ]))
        
        // Card 3: Outcome (o) & Optimality (O)
        // Focus, Motion, Fulfillment
        cards.append(CardData(type: .outcome, title: "Review your day", subtitle: "Reflect on effectiveness and fulfillment", inputs: [
            .slider(key: "focus", label: "Focus Level", range: 0...100, defaultValue: 50),
            // MotionType (Optional context)
            .picker(key: "motion", label: "Primary Motion", options: ["Stationary", "Walking", "Running", "Transit", "Unknown"], selectedIndex: 0),
            // Fulfillment (Slider 1.0 - 5.0)
            .slider(key: "fulfillment", label: "Fulfillment", range: 1...5, defaultValue: 3.0)
        ], textInput: .optional(key: "notes", placeholder: "Daily Note...")))
        
        return cards
    }
    
    func getTotalCardsCount() -> Int {
        return generateCards().count
    }
    
    // MARK: - Accumulation Logic
    
    /// WriteView에서 카드 넘길 때 호출
    func accumulate(card: CardData, inputs: [String: Any], textInput: String) {
        
        switch card.type {
        case .state:
            // Parse Mood/Energy Curves
            let moodVals = inputs["mood"] as? [Double] ?? []
            let energyVals = inputs["energy"] as? [Double] ?? []
            // Using "mood_times" or "energy_times"?
            // Since we bound it in UI, we need to extract it.
            // But `inputs` flat map might not store the 'times' if the UI component binding isn't set up to write to a separate key.
            // TimeSlotCurveChart binding is `values` and `times`.
            // We need to handle `times` key in SwipeableCardView -> CardInputView mapping. Assuming CardData defines key for values, does it define key for times?
            // Update: CardInput definition for .timeSlotChart needs to support `times` key implicitly or explicitly.
            // Current `generateCards` uses "mood" key. We'll need a convention, e.g. "mood_times".
            
            let moodValAvg = parseCurveAverage(moodVals) ?? 0.0
            let energyValAvg = parseCurveAverage(energyVals) ?? 50.0
            
            let curveTimes = inputs["mood_times"] as? [Double] // We will enforce this key convention
            
            draftSession.state = InternalState(
                mood: moodValAvg,
                energy: energyValAvg,
                moodValues: moodVals,
                energyValues: energyVals,
                curveControlHours: curveTimes
            )
            print("📦 Acc State: moodAvg=\(moodValAvg) (7pts), timesCount=\(curveTimes?.count ?? 0)")
            
        case .action:
            // Parse Actions List
            if let interventions = inputs["actions"] as? [Intervention] {
                draftSession.actions = interventions
                print("📦 Acc Actions: count=\(interventions.count)")
            }
            
        case .outcome:
            // Parse Outcome & Optimality
            let focus = inputs["focus"] as? Double ?? 50.0
            let motionIdx = inputs["motion"] as? Int ?? 0
            
            // Fulfillment is now Double from Slider
            let fulfillment = inputs["fulfillment"] as? Double ?? 3.0
            
            // Motion Enum mapping
            let motions: [MotionType] = [.stationary, .walking, .running, .automotive, .unknown]
            let selectedMotion = (motionIdx >= 0 && motionIdx < motions.count) ? motions[motionIdx] : .unknown
            
            draftSession.outcome = Outcome(focusLevel: focus, detectedMotion: selectedMotion)
            draftSession.optimality = Optimality(fulfillment: fulfillment)
            draftSession.notes = textInput
            
            print("📦 Acc Outcome: focus=\(focus), fulfill=\(fulfillment)")
            
        case .program:
            break
        }
    }
    
    private func parseCurveAverage(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sum = values.reduce(0, +)
        return sum / Double(values.count)
    }
    
    // MARK: - Commit (Save)
    
    func commitSession() async throws {
        print("💾 Committing Session...")
        
        // 1. Validation
        guard let state = draftSession.state,
              let outcome = draftSession.outcome,
              let optimality = draftSession.optimality else {
            throw NSError(domain: "WriteViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "Incomplete data"])
        }
        
        // 2. Capture World Context (Auto)
        let timeCtx = worldService.getCurrentTimeContext()
        let worldContext = WorldContext(
            weather: worldService.getCurrentWeather(),
            location: worldService.getCurrentLocation(),
            dayPhase: timeCtx.dayPhase,
            weekday: timeCtx.weekday,
            isHoliday: timeCtx.isHoliday,
            timeZoneIdentifier: timeCtx.timeZoneIdentifier
        )
        
        // 3. Create TimeSeriesDataPoint
        // If editingDataPointId exists, use it to update the existing record
        let dataPoint = TimeSeriesDataPoint(
            id: editingDataPointId ?? UUID(),
            world: worldContext,
            actions: draftSession.actions,
            state: state,
            outcome: outcome,
            optimality: optimality,
            notes: draftSession.notes
        )
        
        // 4. Save to DataService
        // Use async bridging for Combine publisher
        _ = try await Helper.asyncFirst(dataService.saveDataPoint(dataPoint))
        
        // 5. Update User Stats & Gem
        try await updateUserStats()
        try await checkAndAwardGem(for: dataPoint)
        
        print("✅ Session Committed: \(dataPoint.id) (Update: \(editingDataPointId != nil))")
        
        // 6. Cleanup
        draftSession = DraftSession()
        clearCache()
        editingDataPointId = nil // Reset edit state
        // Notify HomeView, etc.
        NotificationCenter.default.post(name: .didSaveCardData, object: nil)
    }
    
    // MARK: - Gamification Logic
    private func updateUserStats() async throws {
        do {
            // Fetch current stats
            var stats: UserStats
            do {
                stats = try await Helper.asyncFirst(dataService.fetchUserStats())
            } catch {
                 stats = UserStats(accountId: "", totalDataPoints: 0, totalGems: 0, streakDays: 0, lastRecordedAt: nil, updatedAt: Date())
            }
            
            // Update counts - Only increment totalDataPoints if NEW (not editing)
            stats.totalDataPoints += 1
            stats.updatedAt = Date()
            
            // Basic Streak Logic
            let calendar = Calendar.current
            if let lastDate = stats.lastRecordedAt {
                if !calendar.isDateInToday(lastDate) {
                    if calendar.isDate(lastDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: Date())!) {
                        stats.streakDays += 1
                    } else {
                        stats.streakDays = 1
                    }
                }
            } else {
                stats.streakDays = 1
            }
            stats.lastRecordedAt = Date()
            
            // Save
            _ = try await Helper.asyncFirst(dataService.updateUserStats(stats))
            print("✨ User Stats Updated: Streak \(stats.streakDays)")
        } catch {
            print("⚠️ Failed to update UserStats: \(error)")
        }
    }
    
    private func checkAndAwardGem(for point: TimeSeriesDataPoint) async throws {
        let today = Date()
        do {
            let existingGem = try await Helper.asyncFirst(dataService.fetchDailyGem(for: today))
            
            if existingGem == nil {
                // Initialize DailyGem with all required fields
                let newGem = DailyGem(
                    id: UUID(),
                    accountId: "unknown", // Will be overwritten by Service or Auth
                    date: today,
                    gemType: .diamond,
                    brightness: 1.0,
                    uncertainty: 0.1,
                    dataPointIds: [point.id.uuidString],
                    colorTheme: .teal,
                    createdAt: today
                )
                
                _ = try await Helper.asyncFirst(dataService.saveDailyGem(newGem))
                print("💎 Daily Gem Awarded!")
                
                // Update UserStats Gem Count
                if var stats = try? await Helper.asyncFirst(dataService.fetchUserStats()) {
                    stats.totalGems += 1
                    _ = try await Helper.asyncFirst(dataService.updateUserStats(stats))
                }
            } else {
                print("💎 Daily Gem already exists.")
            }
        } catch {
            print("⚠️ Gem Check Failed: \(error)")
        }
    }
    
    // MARK: - Helpers for WriteView
    func getRemainingCards() -> [CardData] {
        return generateCards()
    }
    
    func refreshCachedInputsIfNeeded() {
        if cachedInputs.isEmpty {
            cachedInputs = Array(repeating: [:], count: getTotalCardsCount())
            
            // Initialize default times for curve charts
            // If we don't do this, the bindng might be nil
            let defaultTimes: [Double] = [7.0, 9.6, 12.3, 15.0, 17.6, 20.3, 23.0]
            if cachedInputs.count > 0 {
                cachedInputs[0]["mood_times"] = defaultTimes
                cachedInputs[0]["energy_times"] = defaultTimes
            }
        }
    }
    
    // MARK: - Persistence (UserDefaults)
    private let kCachedInputsKey = "pip_write_cached_inputs"
    private let kCachedTextInputsKey = "pip_write_cached_text_inputs"
    private let kCachedEditingIdKey = "pip_write_cached_editing_id"
    
    /// Helper struct for Codable support of [String: Any]
    private struct CodableInput: Codable {
        let doubleValue: Double?
        let intValue: Int?
        let boolValue: Bool?
        let doubleArray: [Double]?
        let interventions: [Intervention]?
        
        init(_ value: Any) {
            self.doubleValue = value as? Double
            self.intValue = value as? Int
            self.boolValue = value as? Bool
            self.doubleArray = value as? [Double]
            self.interventions = value as? [Intervention]
        }
        
        var anyValue: Any? {
            if let v = doubleValue { return v }
            if let v = intValue { return v }
            if let v = boolValue { return v }
            if let v = doubleArray { return v }
            if let v = interventions { return v }
            return nil
        }
    }
    
    func saveCachedInputs() {
        // Serialize inputs
        let codableInputs = cachedInputs.map { dict -> [String: CodableInput] in
            var newDict: [String: CodableInput] = [:]
            for (key, value) in dict {
                newDict[key] = CodableInput(value)
            }
            return newDict
        }
        
        if let data = try? JSONEncoder().encode(codableInputs) {
            UserDefaults.standard.set(data, forKey: kCachedInputsKey)
        }
        
        if let textData = try? JSONEncoder().encode(cachedTextInputs) {
             UserDefaults.standard.set(textData, forKey: kCachedTextInputsKey)
        }
        
        // Save Editing ID
        if let editingId = editingDataPointId {
            UserDefaults.standard.set(editingId.uuidString, forKey: kCachedEditingIdKey)
        } else {
            UserDefaults.standard.removeObject(forKey: kCachedEditingIdKey)
        }
        
        print("💾 [WriteViewModel] Cached inputs & state saved to UserDefaults")
    }
    
    private func restoreCachedInputs() {
        var restoredInputs: [[String: Any]] = []
        var restoredTexts: [String] = []
        
        // Restore Inputs
        if let data = UserDefaults.standard.data(forKey: kCachedInputsKey),
           let codableInputs = try? JSONDecoder().decode([[String: CodableInput]].self, from: data) {
            
            restoredInputs = codableInputs.map { dict -> [String: Any] in
                var newDict: [String: Any] = [:]
                for (key, value) in dict {
                    if let realValue = value.anyValue {
                        newDict[key] = realValue
                    }
                }
                return newDict
            }
        }
        
        // Restore Texts
        if let textData = UserDefaults.standard.data(forKey: kCachedTextInputsKey),
           let texts = try? JSONDecoder().decode([String].self, from: textData) {
            restoredTexts = texts
        }
        
        // Restore Editing ID
        if let idString = UserDefaults.standard.string(forKey: kCachedEditingIdKey),
           let id = UUID(uuidString: idString) {
            self.editingDataPointId = id
            print("↻ [WriteViewModel] Restored editing ID: \(id)")
        }
        
        // Validation: Must match card count
        let total = getTotalCardsCount()
        
        if restoredInputs.count == total {
            self.cachedInputs = restoredInputs
            print("↻ [WriteViewModel] Restored \(restoredInputs.count) card inputs from cache")
        } else {
            // Clean invalid cache
            UserDefaults.standard.removeObject(forKey: kCachedInputsKey)
        }
        
        if restoredTexts.count == total {
            self.cachedTextInputs = restoredTexts
            print("↻ [WriteViewModel] Restored \(restoredTexts.count) text inputs from cache")
        } else {
             UserDefaults.standard.removeObject(forKey: kCachedTextInputsKey)
        }
    }
    
    func clearCache() {
        cachedInputs = []
        cachedTextInputs = []
        editingDataPointId = nil
        UserDefaults.standard.removeObject(forKey: kCachedInputsKey)
        UserDefaults.standard.removeObject(forKey: kCachedTextInputsKey)
        UserDefaults.standard.removeObject(forKey: kCachedEditingIdKey)
    }

    func updateLocalCache(inputs: [String: Any], for index: Int) {
        if index < cachedInputs.count {
            cachedInputs[index] = inputs
            saveCachedInputs() 
        }
    }
    
    func updateLocalTextCache(text: String, for index: Int) {
        // Ensure cachedTextInputs is sized correctly
        if cachedTextInputs.count != getTotalCardsCount() {
            cachedTextInputs = Array(repeating: "", count: getTotalCardsCount())
        }
        if index < cachedTextInputs.count {
            cachedTextInputs[index] = text
            saveCachedInputs()
        }
    }
    
    func saveCard(_ card: CardData, inputs: [String: Any], textInput: String, isLast: Bool) async throws {
        accumulate(card: card, inputs: inputs, textInput: textInput)
        if isLast {
            try await commitSession()
        }
    }
    
    func hasAccumulatedData() -> Bool {
        return !cachedInputs.isEmpty && !cachedInputs.allSatisfy { $0.isEmpty }
    }
    
    func getNotes(for card: CardData) -> String {
        return ""
    }
    
    // MARK: - Session Management
    func clearDraftDataForLogout() {
        draftSession = DraftSession()
        clearCache()
        editingDataPointId = nil
        isRestoring = false
        print("🧹 [WriteViewModel] Draft data cleared for logout")
    }
    
    // MARK: - DB Loading
    func checkAndLoadTodayData() {
        // If we already have unsaved draft data (hasAccumulatedData), we might choose to keep it.
        // BUT user complaint is "Edited data not loading".
        // Strategy: If draft exists, use draft. If empty, try load from DB.
        
        if hasAccumulatedData() {
            print("📝 [WriteViewModel] Using existing local draft.")
            return
        }
        
        isRestoring = true
        
        let today = Date()
        dataService.fetchDataPoints(for: today)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Error fetching today's data: \(error)")
                    }
                    self?.isRestoring = false
                },
                receiveValue: { [weak self] dataPoints in
                    guard let self = self else { return }
                    // If multiple, picking the last one (most recent)
                    if let recent = dataPoints.sorted(by: { $0.createdAt < $1.createdAt }).last {
                        self.mapDataPointToCache(recent)
                    } else {
                        print("No DB data for today")
                        self.isRestoring = false
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func mapDataPointToCache(_ point: TimeSeriesDataPoint) {
        // We need to construct [[String: Any]] matching generateCards() structure
        var newInputs: [[String: Any]] = Array(repeating: [:], count: getTotalCardsCount())
        var newTexts: [String] = Array(repeating: "", count: getTotalCardsCount())
        
        // Card 1: State (Mood & Energy)
        // If we have saved values, use them. Otherwise fallback to flat average (legacy)
        if let mValues = point.state.moodValues, let eValues = point.state.energyValues {
            newInputs[0]["mood"] = mValues
            newInputs[0]["energy"] = eValues
        } else {
             // Fallback for old data: 7 points of average
            newInputs[0]["mood"] = Array(repeating: point.state.mood, count: 7)
            newInputs[0]["energy"] = Array(repeating: point.state.energy, count: 7)
        }
        
        // Restore X-axis times if saved
        if let savedTimes = point.state.curveControlHours {
            newInputs[0]["mood_times"] = savedTimes
            newInputs[0]["energy_times"] = savedTimes
        } else {
             newInputs[0]["mood_times"] = [7.0, 9.6, 12.3, 15.0, 17.6, 20.3, 23.0]
             newInputs[0]["energy_times"] = [7.0, 9.6, 12.3, 15.0, 17.6, 20.3, 23.0]
        }
        
        // Card 2: Action
        newInputs[1]["actions"] = point.actions
        
        // Card 3: Outcome
        newInputs[2]["focus"] = point.outcome.focusLevel
        
        // Motion Mapping
        let motionIndex: Int
        if let detected = point.outcome.detectedMotion {
             // Mapping relied on WriteViewModel accumulation logic:
             // ["Stationary", "Walking", "Running", "Transit", "Unknown"]
             // [.stationary, .walking, .running, .automotive, .unknown]
             switch detected {
                 case .stationary: motionIndex = 0
                 case .walking: motionIndex = 1
                 case .running: motionIndex = 2
                 case .automotive: motionIndex = 3
                 case .cycling: motionIndex = 4 // Fallback
                 case .unknown: motionIndex = 4
             }
        } else {
            motionIndex = 4
        }
        newInputs[2]["motion"] = motionIndex
        
        // Fulfillment: Double (1.0 - 5.0).
        // Check `optimality.fulfillment`. If stored as `Double`, direct assign.
        // If stored as old `Int`, convert to Double.
        // Wait, TimeSeriesModels.swift update changed Type to Double.
        newInputs[2]["fulfillment"] = point.optimality.fulfillment
        
        // Text Notes
        if let notes = point.notes {
            newTexts[2] = notes
        }
        
        self.cachedInputs = newInputs
        self.cachedTextInputs = newTexts
        self.editingDataPointId = point.id // Set ID for update
        
        self.saveCachedInputs() // Save to local draft so it persists during this session
        
        print("📥 Loaded data from DB for point: \(point.id)")
        self.isRestoring = false
    }
}

// MARK: - Helper for Async Publisher
// Helper struct to bridge Combine publishers to async/await
struct Helper {
    static func asyncFirst<P: Publisher>(_ publisher: P) async throws -> P.Output {
        var cancellable: AnyCancellable?
        return try await withCheckedThrowingContinuation { continuation in
            var didFinish = false
            cancellable = publisher.first()
                .sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case .finished:
                            if !didFinish {
                                // If finished without value (empty), throw error or handle accordingly
                                // For .first(), it should usually emit value then finish.
                                // If it finishes empty, it's an error for this helper.
                                continuation.resume(throwing: NSError(domain: "Helper", code: -1, userInfo: [NSLocalizedDescriptionKey: "Publisher finished empty"]))
                            }
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    },
                    receiveValue: { value in
                        didFinish = true
                        continuation.resume(returning: value)
                    }
                )
        }
    }
}

// MARK: - Analytics Models & Service

struct UserBehaviorLog: Codable {
    let id: String         // UUID string
    let userId: String     // User ID or Anonymous ID
    let sessionType: String // e.g., "write_flow_morning"
    let startTime: Date
    var endTime: Date?
    var status: String     // "completed", "aborted", "unknown"
    var metrics: [String: AnyCodable] // Flattened metrics for flexibility
    
    enum CodingKeys: String, CodingKey {
        case id, userId, sessionType, startTime, endTime, status, metrics
    }
}



// MARK: - Service

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    private var currentSessionLog: UserBehaviorLog?
    private var eventLogs: [String] = [] // Temporary simple event log for debugging/analysis
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Session Management
    
    func startSession(name: String) {
        guard let user = Auth.auth().currentUser else { return }
        
        let logId = UUID().uuidString
        currentSessionLog = UserBehaviorLog(
            id: logId,
            userId: user.uid,
            sessionType: name,
            startTime: Date(),
            endTime: nil,
            status: "active",
            metrics: [:]
        )
        eventLogs = []
        print("📊 [Analytics] Session started: \(name) (\(logId))")
    }
    
    func logEvent(name: String, params: [String: Any] = [:]) {
        guard currentSessionLog != nil else { return }
        
        // In "Occam's Razor" spirit, we might not save every single event to DB.
        // But for calculation, we can track them in memory.
        print("📊 [Analytics] Event: \(name) - \(params)")
        
        // Example: Update metrics based on events
        // Real-world: You might want to aggregate counts here
        if let currentCount = currentSessionLog?.metrics["\(name)_count"]?.value as? Int {
             currentSessionLog?.metrics["\(name)_count"] = AnyCodable(currentCount + 1)
        } else {
             currentSessionLog?.metrics["\(name)_count"] = AnyCodable(1)
        }
    }
    
    func endSession(status: String, additionalMetrics: [String: Any] = [:]) {
        guard var log = currentSessionLog else { return }
        
        log.endTime = Date()
        log.status = status
        
        // Merge additional metrics
        for (key, value) in additionalMetrics {
            log.metrics[key] = AnyCodable(value)
        }
        
        // Calculate duration
        let duration = log.endTime!.timeIntervalSince(log.startTime)
        log.metrics["total_duration"] = AnyCodable(duration)
        
        print("📊 [Analytics] Session ended: \(log.sessionType) - Status: \(status), Duration: \(duration)s")
        
        // Upload to Firestore
        saveLogToFirestore(log)
        
        // Clear current session
        currentSessionLog = nil
        eventLogs = []
    }
    
    // MARK: - Navigation Session (Batched)
    
    private var navigationSessionLog: UserBehaviorLog?
    private var navigationEvents: [[String: Any]] = []
    
    /// Starts a loose navigation session when the app is active
    func startNavigationSession() {
        guard navigationSessionLog == nil else { 
            print("📊 [Analytics] Navigation session already active")
            return 
        }
        
        let userId = Auth.auth().currentUser?.uid ?? "anonymous"
        let logId = UUID().uuidString
        
        navigationSessionLog = UserBehaviorLog(
            id: logId,
            userId: userId,
            sessionType: "navigation_session",
            startTime: Date(),
            endTime: nil,
            status: "active",
            metrics: [:]
        )
        navigationEvents = []
        print("📊 [Analytics] Navigation session started (\(logId))")
    }
    
    /// Buffers a single navigation event (Tab Switch)
    func trackNavigationStep(toTab: String, duration: TimeInterval) {
        let stepInfo: [String: Any] = [
            "to_tab": toTab,
            "duration_s": duration,
            "timestamp": Date().timeIntervalSince1970
        ]
        navigationEvents.append(stepInfo)
        print("📊 [Analytics] Buffered navigation step: \(toTab) (\(String(format: "%.1f", duration))s)")
    }
    
    /// Flushes the navigation buffer to Firestore (Called on App Background)
    func endNavigationSession() {
        guard var log = navigationSessionLog else { return }
        guard !navigationEvents.isEmpty else {
            print("📊 [Analytics] Navigation session ended with no events. Skipping upload.")
            navigationSessionLog = nil
            return
        }
        
        log.endTime = Date()
        log.status = "completed"
        
        // Save the list of steps
        // Convert [String: Any] -> AnyCodable for the generic metrics map
        // Note: Firestore might need special handling for arrays of maps if not using AnyCodable wrapper logic properly,
        // but here we are mapping [String: Any] to AnyCodable.
        // Wait, AnyCodable expects a single value usually.
        // Let's store it as specific "steps" key.
        log.metrics["steps"] = AnyCodable(navigationEvents)
        
        let duration = log.endTime!.timeIntervalSince(log.startTime)
        log.metrics["total_duration"] = AnyCodable(duration)
        
        print("📊 [Analytics] Navigation session flushed. Count: \(navigationEvents.count), Duration: \(duration)s")
        saveLogToFirestore(log)
        
        navigationSessionLog = nil
        navigationEvents = []
    }
    
    // MARK: - Firestore
    
    private func saveLogToFirestore(_ log: UserBehaviorLog) {
        // Determine category based on session type
        let category: String
        if log.sessionType == "onboarding" {
            category = "onboarding"
        } else if log.sessionType.starts(with: "write_view") {
            category = "write_view"
        } else if log.sessionType == "tab_switched" {
             category = "navigation"
        } else {
            category = "general"
        }
        
        // Path: users/{uid}/internal_logs/{category}/sessions/{logId}
        let path = "users/\(log.userId)/internal_logs/\(category)/sessions"
        
        do {
            // Convert to dictionary for Firestore
            // Since AnyCodable wrapper is for Encodable, but Firestore needs [String: Any]
            // We manually map metrics back to [String: Any]
            var logData: [String: Any] = [
                "id": log.id,
                "userId": log.userId,
                "sessionType": log.sessionType,
                "startTime": Timestamp(date: log.startTime),
                "status": log.status,
                "metrics": log.metrics.mapValues { $0.value }
            ]
            
            if let endTime = log.endTime {
                logData["endTime"] = Timestamp(date: endTime)
            }
            
            db.collection(path).document(log.id).setData(logData) { error in
                if let error = error {
                    print("❌ [Analytics] Failed to upload log: \(error)")
                } else {
                    print("✅ [Analytics] Log uploaded successfully")
                }
            }
        } 
    }
}

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
    // MARK: - Persistence (UserDefaults)
    private let kCachedInputsKey = "pip_write_cached_inputs"
    private let kCachedTextInputsKey = "pip_write_cached_text_inputs"
    private let kCachedEditingIdKey = "pip_write_cached_editing_id"
    private let kCachedSessionStartTimeKey = "pip_write_cached_session_start_time"
    private let kCachedEditingDateKey = "pip_write_cached_editing_date"
    
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
    @Published var editingDataPointDate: Date? = nil

    // MARK: - Initialization
    init(dataService: DataServiceProtocol? = nil) {
        self.dataService = dataService ?? DataServiceManager.shared.currentService
        // Restore previous session if needed (TODO: Persistence)
        restoreCachedInputs()
    }
    
    // ...

    func commitSession() async throws {
        print("💾 Committing Session...")
        
        var effectiveDate = sessionStartTime ?? Date()
        
        // If editing an existing point, preserve its original date
        if let originalDate = editingDataPointDate {
             effectiveDate = originalDate
             print("✏️ Maintaining original date for edit: \(originalDate)")
        }
        
        // Analytics: Successful completion
        AnalyticsService.shared.endSession(status: "completed", additionalMetrics: [
            "total_cards": getTotalCardsCount()
        ])
        currentCardStartTime = nil

        // ...
        
        // 3. Create TimeSeriesDataPoint
        // If editingDataPointId exists, use it to update the existing record
        let dataPoint = TimeSeriesDataPoint(
            id: editingDataPointId ?? UUID(),
            timestamp: effectiveDate,
            world: worldContext,
            actions: draftSession.actions,
            state: state,
            outcome: outcome,
            optimality: optimality,
            notes: draftSession.notes
        )
        
        // ...
        
        // 6. Cleanup
        draftSession = DraftSession()
        clearCache()
        editingDataPointId = nil // Reset edit state
        editingDataPointDate = nil 
        sessionStartTime = nil
        // Notify HomeView, etc.
        NotificationCenter.default.post(name: .didSaveCardData, object: nil)
    }

    // ...

    private func mapDataPointToCache(_ point: TimeSeriesDataPoint) {
        // ... existing mapping logic ...
        
        self.cachedInputs = newInputs
        self.cachedTextInputs = newTexts
        self.editingDataPointId = point.id // Set ID for update
        self.editingDataPointDate = point.timestamp // Preserve original date
        
        self.saveCachedInputs() // Save to local draft so it persists during this session
        
        print("📥 Loaded data from DB for point: \(point.id)")
        self.isRestoring = false
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
        
        // Save Session Start Time
        if let startTime = sessionStartTime {
            UserDefaults.standard.set(startTime, forKey: kCachedSessionStartTimeKey)
        } else {
            UserDefaults.standard.removeObject(forKey: kCachedSessionStartTimeKey)
        }
        
        // Save Editing Date
        if let editDate = editingDataPointDate {
            UserDefaults.standard.set(editDate, forKey: kCachedEditingDateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: kCachedEditingDateKey)
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
        
        // Restore Session Start Time
        if let startTime = UserDefaults.standard.object(forKey: kCachedSessionStartTimeKey) as? Date {
            self.sessionStartTime = startTime
             print("↻ [WriteViewModel] Restored session start time: \(startTime)")
        }
        
        // Restore Editing Date
        if let editDate = UserDefaults.standard.object(forKey: kCachedEditingDateKey) as? Date {
            self.editingDataPointDate = editDate
            print("↻ [WriteViewModel] Restored editing date: \(editDate)")
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
        editingDataPointDate = nil
        sessionStartTime = nil
        UserDefaults.standard.removeObject(forKey: kCachedInputsKey)
        UserDefaults.standard.removeObject(forKey: kCachedTextInputsKey)
        UserDefaults.standard.removeObject(forKey: kCachedEditingIdKey)
        UserDefaults.standard.removeObject(forKey: kCachedSessionStartTimeKey)
        UserDefaults.standard.removeObject(forKey: kCachedEditingDateKey)
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





// MARK: - Service



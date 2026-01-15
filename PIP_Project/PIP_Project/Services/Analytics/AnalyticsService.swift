//
//  AnalyticsService.swift
//  PIP_Project
//
//  Created for Analytics Refactor
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

// MARK: - Analytics Models

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
        // Buffer event to current session metrics
        if var log = currentSessionLog {
            let countKey = "\(name)_count"
            if let currentCount = log.metrics[countKey]?.value as? Int {
                log.metrics[countKey] = AnyCodable(currentCount + 1)
            } else {
                log.metrics[countKey] = AnyCodable(1)
            }
            currentSessionLog = log
        } else if var log = navigationSessionLog {
             // Fallback: If inside navigation session (e.g. general interactions), track there
             let countKey = "\(name)_count"
             if let currentCount = log.metrics[countKey]?.value as? Int {
                 log.metrics[countKey] = AnyCodable(currentCount + 1)
             } else {
                 log.metrics[countKey] = AnyCodable(1)
             }
             navigationSessionLog = log
        }
        
        print("📊 [Analytics] Event logged: \(name) \(params)")
    }
    
    /// Buffers a detailed step object (dictionary) into a list within the current session metrics
    func trackSessionStep(stepData: [String: Any], listKey: String = "steps") {
        guard var log = currentSessionLog else { return }
        
        var currentList = (log.metrics[listKey]?.value as? [[String: Any]]) ?? []
        currentList.append(stepData)
        
        log.metrics[listKey] = AnyCodable(currentList)
        currentSessionLog = log
        
        print("📊 [Analytics] Session step tracked: \(listKey) count=\(currentList.count)")
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
    
    /// Buffers a specific screen view event (e.g. Insight Story)
    func trackScreenView(screenName: String, contentId: String? = nil) {
        var stepInfo: [String: Any] = [
            "type": "screen_view",
            "screen_name": screenName,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let contentId = contentId {
            stepInfo["content_id"] = contentId
        }
        
        navigationEvents.append(stepInfo)
        print("📊 [Analytics] Buffered screen view: \(screenName) (\(contentId ?? "none"))")
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
        log.metrics["steps"] = AnyCodable(navigationEvents)
        
        let duration = log.endTime!.timeIntervalSince(log.startTime)
        log.metrics["total_duration"] = AnyCodable(duration)
        
        print("📊 [Analytics] Navigation session flushed. Count: \(navigationEvents.count), Duration: \(duration)s")
        saveLogToFirestore(log)
        
        navigationSessionLog = nil
        navigationEvents = []
    }
    
    // MARK: - Firestore
    
    /// Retrieves a persistent random ID for unauthenticated users
    private func getLocalAnonymousId() -> String {
        let key = "pip_analytics_local_anonymous_id"
        if let id = UserDefaults.standard.string(forKey: key) {
            return id
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
    
    /// Resolves the unified subject_id (IdentityMapping > Local)
    private func resolveSubjectId() async -> String {
        // 1. If authenticated, try to get the IdentityMapping ID (Consistent across devices/installs for this user)
        if Auth.auth().currentUser != nil {
            do {
                let uuid = try await IdentityMappingService.shared.getAnonymousUserId()
                return uuid.uuidString
            } catch {
                print("⚠️ [Analytics] Failed to resolve IdentityMapping: \(error)")
                // Fallthrough to local ID
            }
        }
        
        // 2. Fallback: Local Device ID (Unauthenticated or Identity Error)
        return getLocalAnonymousId()
    }
    
    private func saveLogToFirestore(_ log: UserBehaviorLog) {
        Task {
            // Determine category
            let category: String
            if log.sessionType == "onboarding" {
                category = "onboarding"
            } else if log.sessionType.starts(with: "write_view") {
                category = "write_view"
            } else if log.sessionType == "tab_switched" || log.sessionType == "navigation_session" {
                category = "navigation"
            } else {
                category = "general"
            }
            
            // Resolve Subject ID
            let subjectId = await resolveSubjectId()
            let path = "analytic_logs"
            
            do {
                // Convert to dictionary
                var logData: [String: Any] = [
                    "id": log.id,
                    "subject_id": subjectId, // consistent ID
                    "category": category,
                    "sessionType": log.sessionType,
                    "startTime": Timestamp(date: log.startTime),
                    "status": log.status,
                    "metrics": log.metrics.mapValues { $0.value }
                ]
                
                if let endTime = log.endTime {
                    logData["endTime"] = Timestamp(date: endTime)
                }
                
                // Save
                try await db.collection(path).document(log.id).setData(logData)
                print("✅ [Analytics] Log saved: \(log.id) (subject: \(subjectId))")
            } catch {
                print("❌ [Analytics] Failed to save log: \(error)")
            }
        }
    }
}

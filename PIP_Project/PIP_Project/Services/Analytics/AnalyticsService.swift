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
import Network
import UIKit

// MARK: - Analytics Models

struct UserBehaviorLog: Codable {
    let id: String         // UUID string
    let userId: String     // User ID or Anonymous ID
    let sessionType: String // e.g., "write_flow_morning"
    let startTime: Date
    var endTime: Date?
    var status: String     // "completed", "aborted", "unknown"
    var metrics: [String: AnyCodable] // Flattened metrics for flexibility
    
    // New Fields for Global Performance Tracking
    var deviceModel: String?
    var deviceRegion: String?
    var networkType: String?
    
    enum CodingKeys: String, CodingKey {
        case id, userId, sessionType, startTime, endTime, status, metrics
        case deviceModel = "device_model"
        case deviceRegion = "device_region"
        case networkType = "network_type"
    }
}

// MARK: - Service

@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    private var currentSessionLog: UserBehaviorLog?
    private var eventLogs: [String] = [] // Temporary simple event log for debugging/analysis
    private let db = Firestore.firestore()
    
    // Identity Cache
    private var cachedSubjectId: String?
    private var cancellables = Set<AnyCancellable>()
    
    // Network Monitoring
    private let monitor = NWPathMonitor()
    private var currentNetworkType: String = "unknown"
    
    private init() {
        startNetworkMonitoring()
        setupIdentityListener()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Identity Management
    
    private func setupIdentityListener() {
        // Subscribe to IdentityMappingService to keep cachedSubjectId updated synchronously
        IdentityMappingService.shared.$currentMapping
            .sink { [weak self] mapping in
                if let mapping = mapping {
                    self?.cachedSubjectId = mapping.anonymousUserId.uuidString
                    print("📊 [Analytics] Cached Subject ID refreshed: \(mapping.anonymousUserId)")
                }
            }
            .store(in: &cancellables)
            
        // Trigger initial fetch if needed (though mapping service usually handles this)
        Task {
            do {
                _ = try await IdentityMappingService.shared.getAnonymousUserId()
            } catch {
                print("⚠️ [Analytics] Failed to initial fetch anonymous ID: \(error)")
            }
        }
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                        self.currentNetworkType = "wifi"
                    } else if path.usesInterfaceType(.cellular) {
                        self.currentNetworkType = "cellular"
                    } else if path.usesInterfaceType(.wiredEthernet) {
                        self.currentNetworkType = "ethernet"
                    } else {
                        self.currentNetworkType = "other"
                    }
                } else {
                    self.currentNetworkType = "none"
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    // MARK: - Device Info Helpers
    
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    private func getDeviceRegion() -> String {
        return Locale.current.regionCode ?? "unknown"
    }
    
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
    
    /// Buffers a specific screen view event with duration (Dwell Time)
    func trackScreenTime(screenName: String, duration: TimeInterval) {
        let stepInfo: [String: Any] = [
            "type": "screen_view",
            "screen_name": screenName,
            "duration_s": duration,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        navigationEvents.append(stepInfo)
        print("📊 [Analytics] Buffered screen time: \(screenName) (\(String(format: "%.1f", duration))s)")
    }
    
    /// Buffers a single navigation event (Tab Switch)
    func trackNavigationStep(toTab: String, duration: TimeInterval) {
         // Legacy wrapper or specific tab switch event
         // User requested "From -> To". We can log a 'tab_switch' event.
         // But waiting for implementation plan details.
         // Let's repurpose this or add a new one.
         // Plan said: Log `tab_switch`: `from: previousTabName`, `to: newTabName`.
    }
    
    func trackTabSwitch(from: String, to: String) {
        let stepInfo: [String: Any] = [
            "type": "tab_switch",
            "from_tab": from,
            "to_tab": to,
            "timestamp": Date().timeIntervalSince1970
        ]
        navigationEvents.append(stepInfo)
        print("📊 [Analytics] Buffered tab switch: \(from) -> \(to)")
    }

    /// Buffers a specific screen view event (e.g. Insight Story) without duration (Entrance)
    func trackScreenView(screenName: String, contentId: String? = nil) {
        var stepInfo: [String: Any] = [
            "type": "screen_view", // entrance
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
        
        // Check if there's anything to save (navigation steps OR other buffered metrics)
        let hasMetrics = !log.metrics.isEmpty
        let hasNavigationEvents = !navigationEvents.isEmpty
        
        guard hasNavigationEvents || hasMetrics else {
            print("📊 [Analytics] Navigation session ended with no events or metrics. Skipping upload.")
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
    
    /// Resolves the unified subject_id (IdentityMapping > Cache > Local)
    private func resolveSubjectId() -> String {
        // 1. Try Cached IdentityMapping (Fastest, set via Listener)
        if let cachedId = cachedSubjectId {
            return cachedId
        }
        
        // 2. Fallback: Local Device ID
        print("⚠️ [Analytics] Subject ID cache miss. Using local fallback.")
        return getLocalAnonymousId()
    }
    
    private func saveLogToFirestore(_ log: UserBehaviorLog) {
        // SYNCHRONOUS Firestore Write (Fire-and-forget)
        // This ensures the write command enters the Firestore SDK queue immediately on the Main Thread.
        // The SDK handles offline persistence and eventual syncing even if the app triggers background/suspend shortly after.
        
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
        
        // Resolve Subject ID Synchronously
        let subjectId = resolveSubjectId()
        let path = "analytic_logs"
        
        // Capture current device/network state
        let deviceModel = self.getDeviceModel()
        let deviceRegion = self.getDeviceRegion()
        let networkType = self.currentNetworkType
        
        // Convert to dictionary
        var logData: [String: Any] = [
            "id": log.id,
            "subject_id": subjectId,
            "category": category,
            "sessionType": log.sessionType,
            "startTime": Timestamp(date: log.startTime),
            "status": log.status,
            "metrics": log.metrics.mapValues { $0.value },
            
            // New Fields
            "device_model": deviceModel,
            "device_region": deviceRegion,
            "network_type": networkType
        ]
        
        if let endTime = log.endTime {
            logData["endTime"] = Timestamp(date: endTime)
        }
        
        // Write to Firestore (No 'await')
        db.collection(path).document(log.id).setData(logData) { error in
            if let error = error {
                print("❌ [Analytics] Failed to save log (async callback): \(error)")
            } else {
                 print("✅ [Analytics] Log saved successfully (async callback). ID: \(log.id)")
            }
        }
        
        print("🚀 [Analytics] Log write dispatched: \(log.id) (subject: \(subjectId))")
    }
}

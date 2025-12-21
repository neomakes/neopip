//
//  LocalizationService.swift
//  PIP_Project
//
//  Localization Service: 한/영 언어 설정 관리
//

import Foundation
import SwiftUI
import Combine

enum AppLanguage: String, Codable {
    case korean = "ko"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .korean: return "한국어"
        case .english: return "English"
        }
    }
}

@MainActor
class LocalizationService: ObservableObject {
    static let shared = LocalizationService()
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
        }
    }
    
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Default: English (as per user request)
            self.currentLanguage = .english
        }
    }
    
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
    
    // MARK: - Localized Strings
    
    func localized(_ key: String) -> String {
        switch currentLanguage {
        case .korean:
            return koreanStrings[key] ?? key
        case .english:
            return englishStrings[key] ?? key
        }
    }
    
    // MARK: - String Dictionaries
    
    private var koreanStrings: [String: String] = [
        // Home
        "totalRecords": "총 기록",
        "streakRecords": "연속 기록",
        "todayMood": "오늘 기분은 어땠나요?",
        "todayBehavior": "오늘의 행동은?",
        "todayPhysical": "오늘의 신체 상태는?",
        "todayNotes": "오늘의 한 줄",
        "return": "되돌리기",
        "recordedData": "기록된 데이터",
        "noData": "이 날짜에 기록된 데이터가 없습니다",
        "brightness": "밝기",
        "uncertainty": "불확실성",
        "dataCount": "데이터 수",
        "mind": "마음",
        "behavior": "행동",
        "physical": "신체",
        "social": "사회적",
        "cognitive": "인지",
        "other": "기타",
        // Common
        "save": "저장",
        "cancel": "취소",
        "delete": "삭제",
        "edit": "편집",
        "close": "닫기"
    ]
    
    private var englishStrings: [String: String] = [
        // Home
        "totalRecords": "Total Records",
        "streakRecords": "Streak",
        "todayMood": "How was your mood today?",
        "todayBehavior": "How was your behavior?",
        "todayPhysical": "How was your physical state?",
        "todayNotes": "Today's note",
        "return": "Return",
        "recordedData": "Recorded Data",
        "noData": "No data recorded for this date",
        "brightness": "Brightness",
        "uncertainty": "Uncertainty",
        "dataCount": "Data Count",
        "mind": "Mind",
        "behavior": "Behavior",
        "physical": "Physical",
        "social": "Social",
        "cognitive": "Cognitive",
        "other": "Other",
        // Common
        "save": "Save",
        "cancel": "Cancel",
        "delete": "Delete",
        "edit": "Edit",
        "close": "Close"
    ]
}

// MARK: - Localized String Extension
extension String {
    var localized: String {
        LocalizationService.shared.localized(self)
    }
}

//
//  AnalyticsModifier.swift
//  PIP_Project
//
//  Created for Analytics Implementation
//

import SwiftUI

struct AnalyticsScreenTrackingModifier: ViewModifier {
    let screenName: String
    let contentId: String?

    func body(content: Content) -> some View {
        content
            .onAppear {
                AnalyticsService.shared.trackScreenView(screenName: screenName, contentId: contentId)
            }
    }
}

extension View {
    /// Tracks screen view events via AnalyticsService
    func trackScreen(name: String, contentId: String? = nil) -> some View {
        self.modifier(AnalyticsScreenTrackingModifier(screenName: name, contentId: contentId))
    }
}

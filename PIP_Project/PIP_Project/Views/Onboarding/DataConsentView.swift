//
//  DataConsentView.swift
//  PIP_Project
//
//  Data consent step in onboarding
//  Follows ONBOARDING_FLOW_DESIGN.md specification
//

import SwiftUI

struct DataConsentView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    let dataTypes: [(id: String, name: String, icon: String, description: String, isRequired: Bool)] = [
        ("mood", "Mood Tracking", "😊", "Track your daily emotional state", true),
        ("stress", "Stress Level", "😰", "Monitor stress patterns", true),
        ("energy", "Energy Level", "⚡️", "Track your energy throughout the day", true),
        ("weather", "Weather Data", "🌤️", "Correlate mood with weather", false),
        ("location", "Location", "📍", "Understand location-based patterns", false),
        ("screenTime", "Screen Time", "📱", "Monitor digital habits", false),
        ("steps", "Steps", "👟", "Track physical activity", false),
        ("sleep", "Sleep Data", "😴", "Analyze sleep quality", false)
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)

            // Title
            VStack(spacing: 12) {
                Text("Privacy & Data")
                    .font(.pip.hero)
                    .foregroundColor(.white)

                Text("Choose what data you'd like to track")
                    .font(.pip.body)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Data consent list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(dataTypes, id: \.id) { dataType in
                        DataConsentRow(
                            icon: dataType.icon,
                            name: dataType.name,
                            description: dataType.description,
                            isRequired: dataType.isRequired,
                            isConsented: viewModel.isDataConsented(dataType.id),
                            onToggle: {
                                if !dataType.isRequired {
                                    viewModel.toggleDataConsent(dataType.id)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                // Accept all button
                if !viewModel.consentedDataTypes.isEmpty {
                    Button(action: {
                        viewModel.consentToAll()
                    }) {
                        Text("Allow All")
                            .font(.pip.caption)
                            .foregroundColor(Color.pip.home.buttonAddGrad1)
                    }
                    .padding(.bottom, 8)
                }

                // Continue button
                Button(action: {
                    viewModel.nextStep()
                }) {
                    Text("Continue")
                        .font(.pip.title2)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.pip.home.buttonAddGrad1,
                                    Color.pip.home.buttonAddGrad2
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .opacity(viewModel.canProceed() ? 1.0 : 0.5)
                }
                .disabled(!viewModel.canProceed())

                // Back button
                Button(action: {
                    viewModel.previousStep()
                }) {
                    Text("Back")
                        .font(.pip.body)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .onAppear {
            // Auto-consent to required data types
            for dataType in dataTypes where dataType.isRequired {
                if !viewModel.isDataConsented(dataType.id) {
                    viewModel.toggleDataConsent(dataType.id)
                }
            }
        }
    }
}

// MARK: - Data Consent Row
struct DataConsentRow: View {
    let icon: String
    let name: String
    let description: String
    let isRequired: Bool
    let isConsented: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Icon
                Text(icon)
                    .font(.system(size: 24))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(name)
                            .font(.pip.body)
                            .foregroundColor(.white)

                        if isRequired {
                            Text("Required")
                                .font(.pip.caption)
                                .foregroundColor(Color.pip.home.buttonAddGrad1)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.pip.home.buttonAddGrad1.opacity(0.2))
                                )
                        }
                    }

                    Text(description)
                        .font(.pip.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Toggle
                if isRequired {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.pip.home.buttonAddGrad1)
                } else {
                    Toggle("", isOn: Binding(
                        get: { isConsented },
                        set: { _ in onToggle() }
                    ))
                        .toggleStyle(SwitchToggleStyle(tint: Color.pip.home.buttonAddGrad1))
                        .labelsHidden()
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isRequired)
    }
}

#Preview {
    let viewModel = OnboardingViewModel()
    return DataConsentView(viewModel: viewModel)
}

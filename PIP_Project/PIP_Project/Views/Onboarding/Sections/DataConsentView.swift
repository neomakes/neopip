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
        ("mood", "Mood Tracking", "😊", "Motivation & Valence state", true),
        ("energy", "Energy Level", "⚡️", "Physical Resource & Arousal", true),
        ("focus", "Focus Strength", "🎯", "Subjective Outcome", true),
        ("weather", "Weather", "🌤️", "External Stressor", false),
        ("location", "Location Context", "📍", "Spatial Context", false),
        ("motion", "Motion Type", "🏃", "Objective Activity", false)
    ]

    var body: some View {
        VStack(spacing: 24) {
             Spacer()
                .frame(height: 40)

            // Title section with added Privacy Assurance
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Privacy & Data")
                        .font(.pip.hero)
                        .foregroundColor(.white)
                    
                    Text("Select data for your World Model")
                        .font(.pip.body)
                        .foregroundColor(.gray)
                }

                // Privacy Assurance Card
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Strong Security")
                            .font(.pip.button.bold())
                            .foregroundColor(.white)
                        
                        Text("All recorded data is stored separately from personally identifiable information (PII). Your identity remains anonymous to the analysis engine.")
                            .font(.pip.caption)
                            .foregroundColor(.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 32)
            
            // Spacer removed or reduced since we added content above
            // Spacer() 
            // We use standard spacing in VStack now or a small spacer
            Spacer().frame(height: 10)

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
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Select All (Recommended)")
                        }
                        .font(.pip.button.bold())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.pip.home.buttonAddGrad1, Color.pip.home.buttonAddGrad2],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.pip.home.buttonAddGrad1.opacity(0.5), Color.pip.home.buttonAddGrad2.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                                .background(Color.white.opacity(0.05).clipShape(Capsule()))
                        )
                    }
                    .padding(.bottom, 12)
                }

                // Continue button
                Button(action: {
                    viewModel.nextStep()
                }) {
                    VStack(spacing: 4) {
                        Text("Continue")
                            .font(.pip.title2)
                        if !viewModel.isConsentingToAllOptional() {
                            Text("Skipping optional data reduces insight accuracy")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
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
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.pip.home.buttonAddGrad1, Color.pip.home.buttonAddGrad2],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
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

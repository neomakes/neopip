//
//  OnboardingCompleteView.swift
//  PIP_Project
//
//  Final onboarding step - completion and first journal prompt
//  Follows ONBOARDING_FLOW_DESIGN.md specification
//

import SwiftUI

struct OnboardingCompleteView: View {
    let onStartJournaling: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.pip.home.buttonAddGrad1.opacity(0.3),
                                Color.pip.home.buttonAddGrad2.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.pip.home.buttonAddGrad1, Color.pip.home.buttonAddGrad2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
            }

            // Title
            VStack(spacing: 16) {
                Text("You're all set!")
                    .font(.pip.hero)
                    .foregroundColor(.white)

                Text("Your personal intelligence platform is ready")
                    .font(.pip.title1)
                    .foregroundColor(Color.pip.home.buttonAddGrad1)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Next steps
            VStack(alignment: .leading, spacing: 16) {
                Text("What's next?")
                    .font(.pip.title2)
                    .foregroundColor(.white)

                NextStepRow(
                    icon: "📝",
                    title: "Record your first day",
                    description: "Answer simple questions about your mood and energy"
                )

                NextStepRow(
                    icon: "💎",
                    title: "Create your first Gem",
                    description: "Your daily data becomes a beautiful Gem"
                )

                NextStepRow(
                    icon: "📊",
                    title: "Unlock insights",
                    description: "Get AI-powered insights after 3 days of data"
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                // Start journaling button
                Button(action: onStartJournaling) {
                    Text("Start Journaling")
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
                }

                // Skip button (go to home without journaling)
                Button(action: onStartJournaling) {
                    Text("Explore the app first")
                        .font(.pip.body)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Next Step Row
struct NextStepRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Text(icon)
                .font(.system(size: 32))
                .frame(width: 50, height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )

            // Text content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.pip.body)
                    .foregroundColor(.white)

                Text(description)
                    .font(.pip.caption1)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingCompleteView(onStartJournaling: {})
}

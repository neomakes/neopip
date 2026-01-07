//
//  InsightPreviewView.swift
//  PIP_Project
//
//  Insight preview step in onboarding
//  Shows value proposition with mock insights
//  Follows ONBOARDING_FLOW_DESIGN.md specification
//

import SwiftUI

struct InsightPreviewView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)

            // Title
            VStack(spacing: 12) {
                Text("What you'll discover")
                    .font(.pip.hero)
                    .foregroundColor(.white)

                Text("AI-powered insights about your patterns")
                    .font(.pip.body)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Mock insights carousel
            ScrollView {
                VStack(spacing: 24) {
                    // Insight 1: Pattern analysis
                    InsightPreviewCard(
                        icon: "🔮",
                        title: "Pattern Recognition",
                        description: "\"Your energy peaks at 10 AM on weekdays. Plan important tasks accordingly.\"",
                        gradient: [Color.pip.home.buttonAddGrad1, Color.pip.home.buttonAddGrad2]
                    )

                    // Insight 2: Prediction
                    InsightPreviewCard(
                        icon: "📈",
                        title: "Smart Predictions",
                        description: "\"Based on current trends, you'll reach your wellness goal in 3 weeks.\"",
                        gradient: [Color.blue, Color.purple]
                    )

                    // Insight 3: Correlations
                    InsightPreviewCard(
                        icon: "🔗",
                        title: "Hidden Connections",
                        description: "\"Your mood improves by 15% when you walk more than 8,000 steps.\"",
                        gradient: [Color.green, Color.pip.home.buttonAddGrad1]
                    )
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            // Info text
            VStack(spacing: 8) {
                Text("These insights get better with time")
                    .font(.pip.caption)
                    .foregroundColor(.gray)

                Text("The more data you collect, the more personalized and accurate your insights become")
                    .font(.pip.caption)
                    .foregroundColor(.gray.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)

            // Action buttons
            VStack(spacing: 12) {
                // Next button
                Button(action: {
                    viewModel.nextStep()
                }) {
                    Text("Start My Journey")
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
    }
}

// MARK: - Insight Preview Card
struct InsightPreviewCard: View {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            Text(icon)
                .font(.system(size: 40))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .opacity(0.2)
                        )
                )

            // Title
            Text(title)
                .font(.pip.title2)
                .foregroundColor(.white)

            // Description
            Text(description)
                .font(.pip.body)
                .foregroundColor(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }
}

#Preview {
    let viewModel = OnboardingViewModel()
    return InsightPreviewView(viewModel: viewModel)
}

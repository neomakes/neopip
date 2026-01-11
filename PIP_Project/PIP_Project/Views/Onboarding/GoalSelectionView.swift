//
//  GoalSelectionView.swift
//  PIP_Project
//
//  Goal selection step in onboarding (Tinder-style swipe)
//  Follows ONBOARDING_FLOW_DESIGN.md specification
//

import SwiftUI

struct GoalSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    let goals: [(category: GoalCategory, icon: String, title: String, description: String)] = [
        (.physical, "🏃", "Physical Health", "Build a stronger body"),
        (.wellness, "🧘", "Wellness & Peace", "Find inner calm and balance"),
        (.productivity, "💪", "Productivity", "Achieve more with less stress"),
        (.emotional, "😊", "Emotional Control", "Master your emotions"),
        (.learning, "📚", "Learning & Growth", "Expand your knowledge"),
        (.social, "👥", "Social Relations", "Meaningful connections")
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)

            // Title
            VStack(spacing: 12) {
                Text("What are your goals?")
                    .font(.pip.hero)
                    .foregroundColor(.white)

                Text("Select up to 3 goals that matter to you")
                    .font(.pip.body)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Goal Cards
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(goals, id: \.category) { goal in
                        GoalCard(
                            icon: goal.icon,
                            title: goal.title,
                            description: goal.description,
                            isSelected: viewModel.isGoalSelected(goal.category),
                            onTap: {
                                viewModel.toggleGoal(goal.category)
                            }
                        )
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            // Selected goals indicator
            if !viewModel.selectedGoals.isEmpty {
                HStack(spacing: 8) {
                    ForEach(viewModel.selectedGoals, id: \.self) { goal in
                        Text(goals.first(where: { $0.category == goal })?.icon ?? "")
                            .font(.system(size: 24))
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
            }

            // Action buttons
            VStack(spacing: 12) {
                // Helper text
                Text("You can change these later in Settings")
                    .font(.pip.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 4)

                // Next button
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
    }
}

// MARK: - Goal Card
struct GoalCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Text(icon)
                    .font(.system(size: 40))
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.pip.title2)
                        .foregroundColor(.white)

                    Text(description)
                        .font(.pip.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.pip.home.buttonAddGrad1)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.pip.home.buttonAddGrad1 : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let viewModel = OnboardingViewModel()
    return GoalSelectionView(viewModel: viewModel)
}

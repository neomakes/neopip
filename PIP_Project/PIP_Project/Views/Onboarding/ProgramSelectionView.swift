//
//  ProgramSelectionView.swift
//  PIP_Project
//
//  Program selection step in onboarding
//  Follows ONBOARDING_FLOW_DESIGN.md specification
//

import SwiftUI

struct ProgramSelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    // Mock programs for onboarding (will be replaced with real data)
    let mockPrograms: [(id: UUID, name: String, duration: String, icon: String)] = [
        (UUID(), "21-Day Emotional Journal", "3 weeks", "📔"),
        (UUID(), "Morning Meditation Habit", "30 days", "🧘"),
        (UUID(), "Weekly Reading Goal", "10 weeks", "📚"),
        (UUID(), "Daily Gratitude Practice", "21 days", "✨")
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)

            // Title
            VStack(spacing: 12) {
                Text("Choose your programs")
                    .font(.pip.hero)
                    .foregroundColor(.white)

                Text("Select programs to help achieve your goals")
                    .font(.pip.body)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Program Cards
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(mockPrograms, id: \.id) { program in
                        OnboardingProgramCard(
                            icon: program.icon,
                            name: program.name,
                            duration: program.duration,
                            isSelected: viewModel.isProgramSelected(program.id),
                            onTap: {
                                viewModel.toggleProgram(program.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
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
                }

                // Skip button
                Button(action: {
                    viewModel.skipStep()
                }) {
                    Text("Skip for now")
                        .font(.pip.body)
                        .foregroundColor(.gray)
                }

                // Back button
                Button(action: {
                    viewModel.previousStep()
                }) {
                    Text("Back")
                        .font(.pip.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Onboarding Program Card
struct OnboardingProgramCard: View {
    let icon: String
    let name: String
    let duration: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
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
                    Text(name)
                        .font(.pip.body)
                        .foregroundColor(.white)

                    Text(duration)
                        .font(.pip.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.pip.home.buttonAddGrad1)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.pip.home.buttonAddGrad1 : Color.clear,
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let viewModel = OnboardingViewModel()
    return ProgramSelectionView(viewModel: viewModel)
}

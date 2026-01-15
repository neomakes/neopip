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

    // Programs are fetched from OnboardingViewModel


    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)

            // Title
            VStack(spacing: 12) {
                Text("Choose your programs")
                    .font(.pip.hero)
                    .foregroundColor(.white)

                Text("Select up to 2 programs to help achieve your goals")
                    .font(.pip.body)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Program Cards
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.availablePrograms) { program in
                        OnboardingProgramCard(
                            icon: program.illustration3D?.previewImageURL ?? "🎯",
                            name: program.name,
                            duration: formatDuration(program.duration),
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

    private func formatDuration(_ days: Int) -> String {
        if days % 7 == 0 {
            let weeks = days / 7
            return weeks == 1 ? "1 week" : "\(weeks) weeks"
        } else {
            return "\(days) days"
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
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.pip.home.buttonAddGrad1, Color.pip.home.buttonAddGrad2],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: isSelected ? [Color.pip.home.buttonAddGrad1, Color.pip.home.buttonAddGrad2] : [.clear, .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
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

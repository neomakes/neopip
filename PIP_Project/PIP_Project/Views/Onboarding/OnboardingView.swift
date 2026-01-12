//
//  OnboardingView.swift
//  PIP_Project
//
//  Main onboarding flow container
//  Follows ONBOARDING_FLOW_DESIGN.md specification
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showMainApp = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color(hex: "#202020")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                OnboardingProgressView(
                    currentStep: viewModel.stepNumber,
                    totalSteps: viewModel.totalSteps
                )
                .padding(.top, 60)
                .padding(.horizontal, 32)

                // Content area - switch between steps
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeStepView(viewModel: viewModel)
                case .goalSelection:
                    GoalSelectionView(viewModel: viewModel)
                case .programSelection:
                    ProgramSelectionView(viewModel: viewModel)
                case .dataConsent:
                    DataConsentView(viewModel: viewModel)
                case .insightPreview:
                    InsightPreviewView(viewModel: viewModel)
                case .complete:
                    OnboardingCompleteView(
                        onStartJournaling: {
                            Task {
                                await viewModel.completeOnboarding()
                                showMainApp = true
                            }
                        }
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            MainTabView()
        }
    }
}

// MARK: - Progress Indicator
struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                if step <= currentStep {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.pip.home.buttonAddGrad1, Color.pip.home.buttonAddGrad2],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 8, height: 8)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

// MARK: - Welcome Step
struct WelcomeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Logo/Icon
            Image("LogoDisplay")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130, height: 130)
                .overlay(
                    Circle()
                        .stroke(Color.pip.home.buttonAddGrad1, lineWidth: 3)
                        .blur(radius: 10)
                )

            VStack(spacing: 16) {
                Text("Welcome to PIVOT")
                    .font(.pip.hero)
                    .foregroundColor(.white)

                Text("Your Personal Intelligence Platform")
                    .font(.pip.title1)
                    .foregroundColor(Color.pip.home.buttonAddGrad1)

                Text("Track your mind, behavior, and physical data\nwith ML/AI insights")
                    .font(.pip.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            // Next button
            Button(action: {
                viewModel.nextStep()
            }) {
                Text("Get Started")
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
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    OnboardingView()
}

import SwiftUI

struct ProgramStoryView: View {
    @StateObject private var viewModel: ProgramStoryViewModel
    @Environment(\.presentationMode) var presentationMode

    let program: Program
    let progress: ProgramProgress?

    init(program: Program, progress: ProgramProgress?) {
        self.program = program
        self.progress = progress
        _viewModel = StateObject(wrappedValue: ProgramStoryViewModel(program: program, progress: progress))
    }

    var cardType: AnalysisCardType {
        switch program.gemVisualization.colorTheme {
        case .teal:
            return .explanation
        case .amber:
            return .prediction
        case .tiger:
            return .control
        case .blue:
            return .correlation
        }
    }

    var cardColor: Color {
        switch cardType {
        case .explanation: return Color(red: 0.51, green: 0.92, blue: 0.92) // Teal
        case .prediction: return Color(red: 1.0, green: 0.65, blue: 0.0)   // Amber
        case .control: return Color(red: 1.0, green: 0.4, blue: 0.0)    // Tiger
        case .correlation: return Color(red: 0.0, green: 0.4, blue: 0.8)    // Blue
        }
    }

    var cardTypeLabel: String {
        cardType.rawValue.capitalized
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Base gradient background
                GradientUtils.createCardGradient(themeColor: cardColor).ignoresSafeArea()

                // Neon glow effect
                VStack {
                    HStack {
                        Spacer()
                        GradientUtils.createNeonGlow(themeColor: cardColor, scale: 1.0)
                    }
                    Spacer()
                }.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                } else if let story = viewModel.programStory {
                    VStack(spacing: 0) {
                        // Progress bar and header
                        ProgressBar(
                            pageCount: story.pages.count,
                            currentPage: $viewModel.currentPageIndex,
                            currentPageProgress: $viewModel.currentPageProgress
                        )
                        .padding(.top, 10)
                        .padding(.horizontal, 16)

                        // Story Header
                        storyHeader(story: story)
                            .padding(.vertical, 16)
                            .padding(.horizontal)

                        // Page content
                        if story.pages.indices.contains(viewModel.currentPageIndex) {
                            StoryPageView(page: story.pages[viewModel.currentPageIndex], viewModel: viewModel)
                                .transition(.opacity.animation(.easeInOut))
                        }

                        Spacer()
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage: errorMessage)
                } else {
                    loadingPlaceholder()
                }

                // Pause Overlay
                if viewModel.isPaused {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        viewModel.pauseStory()
                    }
                    .onEnded { value in
                        viewModel.resumeStory()

                        // It's a tap if the drag distance is negligible
                        if value.translation.width < 10 && value.translation.height < 10 {
                            let screenWidth = geometry.size.width
                            let tapLocationX = value.location.x

                            // Tapping left 20% of the screen
                            if tapLocationX < screenWidth * 0.2 {
                                viewModel.goToPreviousStory()
                            // Tapping right 20% of the screen
                            } else if tapLocationX > screenWidth * 0.8 {
                                viewModel.goToNextStory()
                            }
                            // Tapping the middle 60% does nothing for navigation
                        }
                    }
            )
            .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
                if shouldDismiss {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .onDisappear(perform: viewModel.stopStoryTimer)
        }
    }

    @ViewBuilder
    private func storyHeader(story: ProgramStory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Program name at the top
            Text(program.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
            
            HStack(alignment: .center, spacing: 8) {
                Text(cardTypeLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(cardColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(6)

                Text(story.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)

                Spacer()

                Button(action: {
                    viewModel.dismissStory()
                }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(8) // Add some padding to make it easier to tap
            }
        }
    }

    @ViewBuilder
    private func errorView(errorMessage: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48)).foregroundColor(.red)
            Text("Unable to load story").font(.headline).foregroundColor(.white)
            Text(errorMessage).font(.footnote).foregroundColor(.white.opacity(0.8)).multilineTextAlignment(.center)
            Button("Go Back") { presentationMode.wrappedValue.dismiss() }
                .padding(.horizontal, 20).padding(.vertical, 8)
                .background(Color.white.opacity(0.2)).cornerRadius(8)
        }
        .padding()
    }

    @ViewBuilder
    private func loadingPlaceholder() -> some View {
        VStack {
            Text("Loading story...")
                .foregroundColor(.white.opacity(0.8))
            ProgressView()
        }
    }
}

// MARK: - Subviews

private struct StoryPageView: View {
    let page: ProgramStoryPage
    @ObservedObject var viewModel: ProgramStoryViewModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            // Content based on page type
            switch page.contentType {
            case .text:
                textPageContent(content: page.content)
            case .image:
                imagePageContent(imageName: page.content.imageName ?? "")
            case .tip:
                tipPageContent(content: page.content)
            case .milestone:
                milestonePageContent(content: page.content)
            case .motivation:
                motivationPageContent(content: page.content)
            case .mixed:
                mixedPageContent(content: page.content)
            }

            Spacer(minLength: 16)

            // Bottom actions
            HStack(spacing: 16) {
                Spacer()
                
                // Like button
                Button(action: {
                    viewModel.toggleLike()
                }) {
                    Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                        .foregroundColor(viewModel.isLiked ? .red : .white)
                        .font(.system(size: 24))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    private func textPageContent(content: ProgramStoryPageContent) -> some View {
        VStack(spacing: 16) {
            if let headline = content.headline {
                Text(headline)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

            if let body = content.body {
                Text(body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(5)
            }
        }
    }

    private func imagePageContent(imageName: String) -> some View {
        VStack {
            if !imageName.isEmpty, let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable().scaledToFit().cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 10)
            } else if !imageName.isEmpty {
                VStack {
                    Image(systemName: "photo").font(.largeTitle)
                    Text("Missing asset: \(imageName)").font(.caption)
                }.foregroundColor(.white.opacity(0.7))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                    )
            }
        }
    }

    private func tipPageContent(content: ProgramStoryPageContent) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 20))

                Text("Pro Tip")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()
            }

            if let headline = content.headline {
                Text(headline)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            if let body = content.body {
                Text(body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(5)
            }
        }
        .padding(20)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(16)
    }

    private func milestonePageContent(content: ProgramStoryPageContent) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))

                Text("Milestone")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()
            }

            if let headline = content.headline {
                Text(headline)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            if let body = content.body {
                Text(body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(20)
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }

    private func motivationPageContent(content: ProgramStoryPageContent) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundColor(.yellow)

            if let mantra = content.mantra {
                Text(mantra)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }

    private func mixedPageContent(content: ProgramStoryPageContent) -> some View {
        VStack(spacing: 12) {
            if let headline = content.headline {
                Text(headline)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            if let body = content.body {
                Text(body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(5)
            }

            if let mantra = content.mantra {
                Text(mantra)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.accentColor)
                    .italic()
            }
        }
    }
}

private struct ProgressBar: View {
    let pageCount: Int
    @Binding var currentPage: Int
    @Binding var currentPageProgress: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<pageCount, id: \.self) { index in
                ProgressSegment(
                    isFilled: index < currentPage,
                    progress: (index == currentPage) ? currentPageProgress : 0
                )
            }
        }
        .frame(height: 3)
        .animation(.linear(duration: 0.05), value: currentPageProgress)
    }
}

private struct ProgressSegment: View {
    let isFilled: Bool
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(Color.white.opacity(0.35))

                // Progress
                if isFilled {
                    RoundedRectangle(cornerRadius: 1.5).fill(Color.white)
                } else if progress > 0 {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.white)
                        .frame(width: geo.size.width * progress)
                }
            }
        }
    }
}

#Preview {
    ProgramStoryView(program: Program(
        id: UUID(),
        name: "Test Program",
        description: "Test Description",
        category: GoalCategory.emotional,
        duration: 21,
        difficulty: DifficultyLevel.beginner,
        gemVisualization: GemVisualization(
            gemType: .diamond,
            colorTheme: .amber,
            brightness: 0.8,
            size: 1.0,
            customShape: nil
        ),
        illustration3D: nil,
        popularity: 0.85,
        rating: 4.5,
        reviewCount: 234,
        userCount: 1234,
        steps: [],
        prerequisites: nil,
        tags: ["test"],
        expectedEffects: ["test"],
        requiredDataTypes: ["test"],
        userReviews: nil,
        isRecommended: true,
        createdAt: Date()
    ), progress: nil)
}
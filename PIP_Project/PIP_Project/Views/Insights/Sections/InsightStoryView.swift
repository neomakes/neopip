import SwiftUI

struct InsightStoryView: View {
    @StateObject private var viewModel: InsightStoryViewModel
    @Environment(\.presentationMode) var presentationMode

    let cardType: AnalysisCardType

    init(cardId: String, cardType: AnalysisCardType) {
        _viewModel = StateObject(wrappedValue: InsightStoryViewModel(cardId: cardId))
        self.cardType = cardType
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
                // Base gradient background - 상단 검은색, 하단 카드 색상 (더 어둡게)
                LinearGradient(
                    gradient: Gradient(colors: [.black, cardColor.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                
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
                } else if let story = viewModel.insightStory {
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
            .onAppear {
                AnalyticsService.shared.trackScreenView(screenName: "InsightStoryView", contentId: viewModel.cardId)
            }
        }
    }
    
    @ViewBuilder
    private func storyHeader(story: InsightStory) -> some View {
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
                .foregroundColor(.white)
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
    
    @ViewBuilder
    private func errorView(errorMessage: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48)).foregroundColor(.red)
            Text("스토리를 로드할 수 없습니다").font(.headline).foregroundColor(.white)
            Text(errorMessage).font(.footnote).foregroundColor(.white.opacity(0.8)).multilineTextAlignment(.center)
            Button("돌아가기") { presentationMode.wrappedValue.dismiss() }
                .padding(.horizontal, 20).padding(.vertical, 8)
                .background(Color.white.opacity(0.2)).cornerRadius(8)
        }
        .padding()
    }
    
    @ViewBuilder
    private func loadingPlaceholder() -> some View {
        VStack {
            Text("스토리를 로드 중입니다...")
                .foregroundColor(.white.opacity(0.8))
            ProgressView()
        }
    }
}

// MARK: - Subviews

private struct StoryPageView: View {
    let page: StoryPage
    @ObservedObject var viewModel: InsightStoryViewModel

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 0)

            // Image
            if !page.imageName.isEmpty, let uiImage = UIImage(named: page.imageName) {
                Image(uiImage: uiImage)
                    .resizable().scaledToFit().cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 10)
            } else if !page.imageName.isEmpty {
                VStack {
                    Image(systemName: "photo").font(.largeTitle)
                    Text("Missing asset: \(page.imageName)").font(.caption)
                }.foregroundColor(.white.opacity(0.7))
            }

            Spacer(minLength: 16)

            // Content
            VStack(alignment: .leading, spacing: 12) {
                Text(page.headline)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                Text(page.body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(5)
            }
            .padding(20)

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
}

private struct ProgressBar: View {
    let pageCount: Int
    @Binding var currentPage: Int
    @Binding var currentPageProgress: Double

    var body: some View {
        HStack(spacing: 4) { // <- Add spacing here
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

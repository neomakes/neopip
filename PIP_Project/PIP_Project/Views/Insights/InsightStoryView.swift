import SwiftUI

struct InsightStoryView: View {
    @StateObject private var viewModel: InsightStoryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var waveAnimationTimer: Timer?
    @State private var waveProgress: Double = 0
    @State private var isWaving: Bool = false
    @State private var likeAnimation: Bool = false
    @State private var dragOffset: CGFloat = 0  // For interactive swipe translation
    
    let cardType: AnalysisCardType

    init(cardId: String, cardType: AnalysisCardType) {
        _viewModel = StateObject(wrappedValue: InsightStoryViewModel(cardId: cardId))
        self.cardType = cardType
    }

    var cardColor: Color {
        switch cardType {
        case .explanation:
            return Color(red: 0.51, green: 0.92, blue: 0.92)  // Teal
        case .prediction:
            return Color(red: 1.0, green: 0.65, blue: 0.0)    // Amber
        case .control:
            return Color(red: 1.0, green: 0.4, blue: 0.0)     // Tiger
        case .correlation:
            return Color(red: 0.0, green: 0.4, blue: 0.8)     // Blue
        }
    }
    
    var cardTypeLabel: String {
        switch cardType {
        case .explanation:
            return "설명"
        case .prediction:
            return "예측"
        case .control:
            return "제어"
        case .correlation:
            return "상관관계"
        }
    }

    var body: some View {
        ZStack {
            // Base gradient background (matching AnalysisCard design)
            GradientUtils.createCardGradient(themeColor: cardColor)
                .ignoresSafeArea()
                .onAppear {
                    print("🎬 [InsightStoryView] View appeared - cardType: \(cardType)")
                    print("📊 [InsightStoryView] viewModel state - isLoading: \(viewModel.isLoading), story: \(viewModel.insightStory?.title ?? "nil")")
                }
            
            // Neon glow effect
            VStack {
                HStack {
                    Spacer()
                    GradientUtils.createNeonGlow(themeColor: cardColor, scale: 1.0)
                }
                Spacer()
            }
            .ignoresSafeArea()
            
            // Wave animation overlay (when active)
            if isWaving {
                GradientUtils.createWaveGradient(themeColor: cardColor, progress: waveProgress)
                    .ignoresSafeArea()
            }

            if viewModel.isLoading {
                ProgressView()
            } else if let story = viewModel.insightStory {
                VStack(spacing: 0) {
                    // Progress bar and header
                    ProgressBar(pageCount: story.pages.count, currentPage: $viewModel.currentPageIndex, currentPageProgress: $viewModel.currentPageProgress)
                        .padding(.top, 10)
                        .padding(.horizontal, 16)

                    // Story title and subtitle with card type badge
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            // Card type badge
                            Text(cardTypeLabel)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(cardColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(6)
                            
                            Spacer()
                            
                            // Close button
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text(story.title)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        if !story.subtitle.isEmpty {
                            Text(story.subtitle)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.8))
                                .lineSpacing(3)
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal)

                    // Page content with smooth swipe transition
                    GeometryReader { geo in
                        ZStack {
                            ForEach(Array(story.pages.enumerated()), id: \.element.id) { idx, p in
                                StoryPageView(page: p)
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .offset(x: CGFloat(idx - viewModel.currentPageIndex) * geo.size.width + dragOffset)
                                    .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.25), value: viewModel.currentPageIndex)
                            }
                        }
                        .clipped()
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    dragOffset = value.translation.width
                                    viewModel.pauseTimers()
                                }
                                .onEnded { value in
                                    let threshold = geo.size.width * 0.25
                                    if value.translation.width < -threshold {
                                        print("DEBUG: Swipe left -> next page")
                                        viewModel.next()
                                    } else if value.translation.width > threshold {
                                        print("DEBUG: Swipe right -> previous page")
                                        viewModel.previous()
                                    }
                                    withAnimation(.interactiveSpring()) { dragOffset = 0 }
                                    viewModel.resumeTimers()
                                }
                        )
                        .onTapGesture { location in
                            let midX = geo.size.width / 2
                            if location.x < midX {
                                print("DEBUG: Left tap -> previous page")
                                viewModel.previous()
                            } else {
                                print("DEBUG: Right tap -> next page")
                                viewModel.next()
                            }
                        }
                    }
                    .frame(height: 520)
                    .onLongPressGesture(minimumDuration: 0.5, perform: {
                        // Long press started - pause timer
                        viewModel.pauseTimers()
                    }, onPressingChanged: { isPressing in
                        if !isPressing {
                            // Long press ended - resume timer
                            viewModel.resumeTimers()
                        }
                    })
                    Spacer()
                    
                    // Page counter and navigation info
                    HStack(spacing: 12) {
                        Text("\(viewModel.currentPageIndex + 1) / \(story.pages.count)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .onChange(of: viewModel.currentPageIndex) {
                                print("DEBUG: UI currentPageIndex changed to: \($0)")
                            }
                        
                        Spacer()
                        
                        // Like button with animation
                        Button(action: {
                            print("DEBUG: Heart button tapped")
                            toggleLike()
                        }) {
                            Image(systemName: (viewModel.insightStory?.isLiked ?? false) ? "heart.fill" : "heart")
                                .font(.largeTitle)
                                .foregroundColor((viewModel.insightStory?.isLiked ?? false) ? .red : .white)
                                .scaleEffect(likeAnimation ? 1.15 : 1.0)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    Text("스토리를 로드할 수 없습니다")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("돌아가기")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("스토리를 로드하는 중입니다")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("돌아가기")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear(perform: {
            startWaveAnimation()  // 스토리 시작 시 wave animation 자동 재생
        })
        .onChange(of: viewModel.currentPageIndex) {
            // 페이지 변경 시에도 wave animation 재생
            startWaveAnimation()
        }
        .onDisappear(perform: {
            viewModel.stopTimers()
            stopWaveAnimation()
        })
    }
    
    private func toggleLike() {
        print("DEBUG: toggleLike called")
        // Trigger heart animation
        withAnimation(.easeInOut(duration: 0.3)) {
            likeAnimation = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                likeAnimation = false
            }
        }
        
        // Trigger wave animation
        startWaveAnimation()
        
        // Toggle like state in view model
        viewModel.toggleLike()
        print("DEBUG: After toggle, isLiked = \(viewModel.insightStory?.isLiked ?? false)")
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func startWaveAnimation() {
        isWaving = true
        waveProgress = 0.0
        
        // Create timer for continuous wave animation
        waveAnimationTimer?.invalidate()
        waveAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            withAnimation(.linear(duration: 0.016)) {
                waveProgress += 0.016 / 3.0  // 3.0 second cycle
                
                // Keep waveProgress between 0 and 1
                if waveProgress >= 1.0 {
                    waveProgress = 0.0  // Loop
                }
            }
        }
    }
    
    private func stopWaveAnimation() {
        waveAnimationTimer?.invalidate()
        waveAnimationTimer = nil
        isWaving = false
    }
}

struct StoryPageView: View {
    let page: StoryPage

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Image section - try asset first, else fallback to GemView placeholder
            if !page.imageName.isEmpty, let uiImage = UIImage(named: page.imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
            } else if !page.imageName.isEmpty {
                // Asset missing — show placeholder with image name label
                VStack(spacing: 6) {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .foregroundColor(.white.opacity(0.8))
                    Text("Missing asset: \(page.imageName)")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 20)
                .transition(.opacity)
            } else {
                // No imageName — show a simple GemView placeholder
                GemView(gem: DailyGem(id: UUID(), accountId: UUID(), date: Date(), gemType: .sphere, brightness: 1.0, uncertainty: 0.2, dataPointIds: [], colorTheme: .teal, createdAt: Date()), size: 120)
                    .padding(.horizontal, 20)
                    .transition(.opacity)
            }
            
            Spacer()

            // Content section
            VStack(alignment: .leading, spacing: 14) {
                Text(page.headline)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                
                Text(page.body)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.95))
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.black.opacity(0.5))
            .cornerRadius(16)
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
}


struct ProgressBar: View {
    let pageCount: Int
    @Binding var currentPage: Int
    @Binding var currentPageProgress: Double

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(0..<pageCount, id: \.self) { index in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.3))
                        
                        // Progress indicator
                        if index == currentPage {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white)
                                .frame(width: geo.size.width / CGFloat(pageCount) * currentPageProgress, height: 3)
                        } else if index < currentPage {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white)
                                .frame(height: 3)
                        }
                    }
                    .frame(width: geo.size.width / CGFloat(pageCount), height: 3)
                }
            }
        }
        .frame(height: 3)
    }
}

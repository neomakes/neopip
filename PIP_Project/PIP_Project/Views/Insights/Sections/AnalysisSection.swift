import SwiftUI

/// Structure for card position information
struct CardPosition: Equatable {
    let id: Int
    let rect: CGRect
}

/// PreferenceKey for passing card position information
struct CardPositionKey: PreferenceKey {
    static var defaultValue: [CardPosition] = []
    
    static func reduce(value: inout [CardPosition], nextValue: () -> [CardPosition]) {
        value.append(contentsOf: nextValue())
    }
}

/// Analysis section - Carousel that displays the center card larger
struct AnalysisSection: View {
    let viewModel: InsightViewModel
    @State private var currentIndex = 0
    @State private var isAdjustingScroll = false
    @State private var showStoryView = false
    @State private var selectedCardId: String?
    @State private var selectedCardType: AnalysisCardType?

    private let cardSpacing: CGFloat = 8
    private let maxCardSize: CGFloat = 120
    private let minCardSize: CGFloat = 80
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Analysis Title
            HStack {
                HStack(alignment: .center, spacing:6) {
                    Image("title_logo_6")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                    
                    Text("Analysis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .onAppear {
                print("📊 [AnalysisSection] View appeared")
                print("   analysisCards count: \(viewModel.analysisCards.count)")
                print("   currentIndex: \(currentIndex)")
                print("   showStoryView: \(showStoryView)")
                print("   selectedCardId: \(selectedCardId ?? "nil")")
                print("   selectedCardType: \(selectedCardType?.rawValue ?? "nil")")
            }
            
            // MARK: - Analysis Carousel with Navigation
            if viewModel.analysisCards.isEmpty {
                // Empty state
                VStack(alignment: .center, spacing: 12) {
                    Text("Analysis data is being prepared")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
                .padding(.horizontal, 12)
                .onAppear {
                    print("⚠️ [AnalysisSection] No analysis cards available - showing empty state")
                }
            } else {
                VStack(spacing: 12) {
                    // Carousel
                    ScrollViewReader { scrollView in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: cardSpacing) {
                                let repeatedCards = viewModel.analysisCards + viewModel.analysisCards + viewModel.analysisCards
                                ForEach(repeatedCards.indices, id: \.self) { index in
                                    let actualIndex = index % viewModel.analysisCards.count
                                    let card = viewModel.analysisCards[actualIndex]
                                    AnalysisCard(
                                        card: card,
                                        size: cardSize(for: actualIndex, currentIndex: currentIndex),
                                        opacity: cardOpacity(for: actualIndex, currentIndex: currentIndex)
                                    )
                                    .onTapGesture {
                                        print("🖱️ [AnalysisCard] Tapped! cardId: \(card.id.uuidString), cardType: \(card.cardType)")
                                        self.selectedCardId = card.id.uuidString
                                        self.selectedCardType = card.cardType
                                        print("📍 [AnalysisCard] State updated - selectedCardId: \(String(describing: self.selectedCardId)), showStoryView: before=\(self.showStoryView)")
                                        self.showStoryView = true
                                        print("📍 [AnalysisCard] After toggle - showStoryView: \(self.showStoryView)")
                                    }
                                    .frame(width: cardSize(for: actualIndex, currentIndex: currentIndex))
                                    .id(index)
                                    .background(
                                        GeometryReader { geometry in
                                            Color.clear
                                                .preference(key: CardPositionKey.self, value: [CardPosition(id: index, rect: geometry.frame(in: .named("scrollView")))])
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, UIScreen.main.bounds.width / 2 - maxCardSize / 2)
                        }
                        .coordinateSpace(name: "scrollView")
                        .onPreferenceChange(CardPositionKey.self) { positions in
                            if isAdjustingScroll { return }
                            let screenCenter = UIScreen.main.bounds.width / 2
                            let closestCard = positions.min(by: { abs($0.rect.midX - screenCenter) < abs($1.rect.midX - screenCenter) })
                            if let closestCard = closestCard {
                                let actualIndex = closestCard.id % viewModel.analysisCards.count
                                currentIndex = actualIndex
                                
                                let count = viewModel.analysisCards.count
                                if closestCard.id < count {
                                    isAdjustingScroll = true
                                    scrollView.scrollTo(count * 2 - 1, anchor: .center)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isAdjustingScroll = false
                                    }
                                } else if closestCard.id >= count * 2 {
                                    isAdjustingScroll = true
                                    scrollView.scrollTo(count, anchor: .center)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        isAdjustingScroll = false
                                    }
                                }
                            }
                        }
                        .onAppear {
                            let count = viewModel.analysisCards.count
                            if count > 0 {
                                scrollView.scrollTo(count, anchor: .center)
                            }
                        }
                    }
                    .frame(height: maxCardSize + 10) // Add extra space
                    
                    // Page Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<viewModel.analysisCards.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .onChange(of: showStoryView) { newValue in
            if newValue {
                print("🎭 [AnalysisSection] Sheet attempting to present - cardId: \(selectedCardId ?? "nil"), cardType: \(selectedCardType?.rawValue ?? "nil")")
                if let cardId = selectedCardId, let cardType = selectedCardType {
                    print("✅ [AnalysisSection] Sheet conditions met, presenting InsightStoryView")
                } else {
                    print("⚠️ [AnalysisSection] Sheet conditions NOT met!")
                }
            }
        }
        .sheet(isPresented: $showStoryView) {
            if let cardId = selectedCardId, let cardType = selectedCardType {
                InsightStoryView(cardId: cardId, cardType: cardType)
            }
        }
        .onChange(of: showStoryView) { newValue in
            if !newValue {
                print("📪 [AnalysisSection] Sheet dismissed")
                print("   Resetting selectedCardId and selectedCardType")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.selectedCardId = nil
                    self.selectedCardType = nil
                }
            }
        }
    }
    
    func cardSize(for index: Int, currentIndex: Int) -> CGFloat {
        let distance = abs(index - currentIndex)
        let scale: CGFloat
        
        switch distance {
        case 0:
            scale = 1.0 // Center card: 120
        case 1:
            scale = 0.8 // Adjacent card: 96
        case 2:
            scale = 0.7 // Two positions away: 84
        default:
            scale = 0.67 // Others: 80 (minimum size)
        }
        
        return max(minCardSize, maxCardSize * scale)
    }
    
    func cardOpacity(for index: Int, currentIndex: Int) -> Double {
        let distance = abs(index - currentIndex)
        
        switch distance {
        case 0:
            return 1.0 // Center card: fully opaque
        case 1:
            return 0.7 // Adjacent card: 70% opaque
        case 2:
            return 0.2 // Two positions away card: 20% opaque
        default:
            return 0.2 // Others: 20% opaque
        }
    }
}

/// Individual analysis card (neon glow effect) - dynamic size support
struct AnalysisCard: View {
    let card: InsightAnalysisCard
    let size: CGFloat
    let opacity: Double
    
    private var scaleFactor: CGFloat {
        size / 120 // 120을 기준으로 스케일 계산
    }
    
    var cardColor: Color {
        switch card.cardType {
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
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background with gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    cardColor.opacity(0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Neon glow effect (bottom-right corner)
            Circle()
                .fill(cardColor.opacity(0.4))
                .frame(width: 120 * scaleFactor, height: 120 * scaleFactor)
                .blur(radius: 25 * scaleFactor)
                .offset(x: 40 * scaleFactor, y: 40 * scaleFactor)
            
            // Content
            VStack(alignment: .leading, spacing: 8 * scaleFactor) {
                Text(card.title)
                    .font(.system(size: 16 * scaleFactor, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Card type badge
                HStack {
                    Text(card.cardType.rawValue.capitalized)
                        .font(.system(size: 10 * scaleFactor, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8 * scaleFactor)
                        .padding(.vertical, 4 * scaleFactor)
                        .background(cardColor.opacity(0.3))
                        .cornerRadius(4 * scaleFactor)
                    
                    Spacer()
                }
            }
            .padding(16 * scaleFactor)
            
            // Border with theme color
            RoundedRectangle(cornerRadius: 12 * scaleFactor)
                .stroke(cardColor.opacity(0.5), lineWidth: 1 * scaleFactor)
        }
        .frame(width: size, height: size)
        .cornerRadius(12 * scaleFactor)
        .overlay(
            RoundedRectangle(cornerRadius: 12 * scaleFactor)
                .stroke(cardColor.opacity(0.3), lineWidth: 0.5 * scaleFactor)
        )
        .opacity(opacity)
    }
}


// Preview 제거 - InsightView 프리뷰에서 확인 가능

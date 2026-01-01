import SwiftUI

/// Structure for card position information
struct ProgramCardPosition: Equatable {
    let id: Int
    let rect: CGRect
}

/// PreferenceKey for passing card position information
struct ProgramCardPositionKey: PreferenceKey {
    static var defaultValue: [ProgramCardPosition] = []
    
    static func reduce(value: inout [ProgramCardPosition], nextValue: () -> [ProgramCardPosition]) {
        value.append(contentsOf: nextValue())
    }
}

/// Programs section - Carousel that displays the center card larger
struct ProgramsSection: View {
    @ObservedObject var viewModel: GoalViewModel
    @State private var currentIndex = 0
    @State private var isAdjustingScroll = false
    @State private var showProgramStory = false
    @State private var selectedProgram: Program?

    private let cardSpacing: CGFloat = 8
    private let maxCardSize: CGFloat = 120
    private let minCardSize: CGFloat = 80
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Programs Title
            HStack {
                HStack(alignment: .center, spacing: 6) {
                    Image("title_logo_7")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                    
                    Text("Suggestions")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // MARK: - Programs Carousel with Navigation
            if viewModel.newPrograms.isEmpty {
                // Empty state
                VStack(alignment: .center, spacing: 12) {
                    Text("Program recommendations are being prepared")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
                .padding(.horizontal, 12)
            } else {
                VStack(spacing: 12) {
                    // Carousel
                    ScrollViewReader { scrollView in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: cardSpacing) {
                                let repeatedPrograms = viewModel.newPrograms + viewModel.newPrograms + viewModel.newPrograms
                                ForEach(repeatedPrograms.indices, id: \.self) { index in
                                    let actualIndex = index % viewModel.newPrograms.count
                                    let program = viewModel.newPrograms[actualIndex]
                                    ProgramCard(
                                        program: program,
                                        size: cardSize(for: actualIndex, currentIndex: currentIndex),
                                        opacity: cardOpacity(for: actualIndex, currentIndex: currentIndex)
                                    )
                                    .onTapGesture {
                                        self.selectedProgram = program
                                        self.showProgramStory = true
                                    }
                                    .frame(width: cardSize(for: actualIndex, currentIndex: currentIndex))
                                    .id(index)
                                    .background(
                                        GeometryReader { geometry in
                                            Color.clear
                                                .preference(key: ProgramCardPositionKey.self, value: [ProgramCardPosition(id: index, rect: geometry.frame(in: .named("scrollView")))])
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, UIScreen.main.bounds.width / 2 - maxCardSize / 2)
                        }
                        .coordinateSpace(name: "scrollView")
                        .onPreferenceChange(ProgramCardPositionKey.self) { positions in
                            if isAdjustingScroll { return }
                            let screenCenter = UIScreen.main.bounds.width / 2
                            let closestCard = positions.min(by: { abs($0.rect.midX - screenCenter) < abs($1.rect.midX - screenCenter) })
                            if let closestCard = closestCard {
                                let actualIndex = closestCard.id % viewModel.newPrograms.count
                                currentIndex = actualIndex
                                
                                let count = viewModel.newPrograms.count
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
                            let count = viewModel.newPrograms.count
                            if count > 0 {
                                scrollView.scrollTo(count, anchor: .center)
                            }
                        }
                    }
                    .frame(height: maxCardSize + 10) // Add extra space
                    
                    // Page Indicators
                    HStack(spacing: 8) {
                        ForEach(0..<viewModel.newPrograms.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .sheet(isPresented: $showProgramStory) {
            if let program = selectedProgram {
                ProgramStoryView(program: program, progress: viewModel.programProgress[program.id.uuidString])
            }
        }
        .onChange(of: showProgramStory) { newValue in
            if !newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.selectedProgram = nil
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

/// Individual program card (neon glow effect) - dynamic size support
struct ProgramCard: View {
    let program: Program
    let size: CGFloat
    let opacity: Double
    
    private var scaleFactor: CGFloat {
        size / 120 // 120을 기준으로 스케일 계산
    }
    
    var cardColor: Color {
        if let themeNames = program.gemVisualization.gradientColors, !themeNames.isEmpty {
            if let themeName = themeNames.first, let theme = ColorThemeForGoal(rawValue: themeName) {
                return Color(hex: theme.hexColor)
            }
        }
        return Color.accentColor // Default accent color
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
                Text(program.name)
                    .font(.system(size: 16 * scaleFactor, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Program info badge
                HStack {
                    Text("\(program.duration) days")
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

#Preview {
    ProgramsSection(viewModel: GoalViewModel())
        .background(Color.black)
}

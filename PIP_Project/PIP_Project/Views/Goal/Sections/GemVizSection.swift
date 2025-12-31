import SwiftUI

/// Gem visualization view (3 gems displayed simultaneously, center selection emphasized)
///
/// Layout:
/// 1. **3 gems displayed simultaneously**: Left and right unselected + center selected
/// 2. **Utilize screen width**: Dynamic layout with GeometryReader
/// 3. **Drag snapping**: Natural transition with Phaser Snapping
/// 4. **Selected gem emphasis**: Larger in center, color overlay applied
/// 5. **Unselected gems**: Displayed with reduced opacity
/// 6. **List Indicator (dots)**: Page indicators at bottom
struct GemVizSection: View {
    @ObservedObject var viewModel: GoalViewModel
    @State private var isAnimating = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            // MARK: - 3 Gems Displayed Simultaneously with Navigation Buttons and Drag Gesture
            GeometryReader { geometry in
                let screenWidth = geometry.size.width
                let spacing = screenWidth / 3
                
                VStack(spacing: 5) {
                    HStack(spacing: 0) {
                        // Left navigation button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                let newIndex = (viewModel.currentProgramIndex - 1 + viewModel.ongoingPrograms.count) % viewModel.ongoingPrograms.count
                                viewModel.selectProgram(at: newIndex)
                            }
                        }) {
                            Image("icon_expand_left")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                        }
                        .opacity(0.8)  // 항상 활성화
                        .padding(.trailing, 16)
                        
                        // Gem Stack with Drag Gesture
                        ZStack(alignment: .center) {
                            // Left gem (unselected)
                            if viewModel.currentProgramIndex > 0 {
                                GemCard(
                                    program: viewModel.ongoingPrograms[viewModel.currentProgramIndex - 1],
                                    progress: viewModel.programProgress[viewModel.ongoingPrograms[viewModel.currentProgramIndex - 1].id.uuidString],
                                    isSelected: false,
                                    isAnimating: isAnimating
                                )
                                .offset(x: -spacing + dragOffset)
                                .zIndex(1)
                            }
                            
                            // Center gem (selected)
                            GemCard(
                                program: viewModel.ongoingPrograms[viewModel.currentProgramIndex],
                                progress: viewModel.programProgress[viewModel.ongoingPrograms[viewModel.currentProgramIndex].id.uuidString],
                                isSelected: true,
                                isAnimating: isAnimating
                            )
                            .offset(x: dragOffset)
                            .zIndex(2)
                            
                            // Right gem (unselected)
                            if viewModel.currentProgramIndex < viewModel.ongoingPrograms.count - 1 {
                                GemCard(
                                    program: viewModel.ongoingPrograms[viewModel.currentProgramIndex + 1],
                                    progress: viewModel.programProgress[viewModel.ongoingPrograms[viewModel.currentProgramIndex + 1].id.uuidString],
                                    isSelected: false,
                                    isAnimating: isAnimating
                                )
                                .offset(x: spacing + dragOffset)
                                .zIndex(1)
                            }
                        }
                        .frame(width: geometry.size.width - 80, height: 200) // 높이 줄임
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.width
                                }
                                .onEnded { value in
                                    let threshold = screenWidth / 6
                                    let velocity = value.predictedEndLocation.x - value.location.x
                                    
                                    // Snapping considering threshold and velocity (circular)
                                    if value.translation.width > threshold || velocity > 50 {
                                        // Swipe right - previous program (circular)
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            let newIndex = (viewModel.currentProgramIndex - 1 + viewModel.ongoingPrograms.count) % viewModel.ongoingPrograms.count
                                            viewModel.selectProgram(at: newIndex)
                                            dragOffset = 0
                                        }
                                    } else if value.translation.width < -threshold || velocity < -50 {
                                        // Swipe left - next program (circular)
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            let newIndex = (viewModel.currentProgramIndex + 1) % viewModel.ongoingPrograms.count
                                            viewModel.selectProgram(at: newIndex)
                                            dragOffset = 0
                                        }
                                    } else {
                                        // Snap back
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            dragOffset = 0
                                        }
                                    }
                                }
                        )
                        
                        // Right navigation button
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                let newIndex = (viewModel.currentProgramIndex + 1) % viewModel.ongoingPrograms.count
                                viewModel.selectProgram(at: newIndex)
                            }
                        }) {
                            Image("icon_expand_right")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                        }
                        .opacity(0.8)  // 항상 활성화
                        .padding(.leading, 16)
                    }
                    
                    // MARK: - List Indicator (Navigation Dots)
                    HStack(spacing: 8) {
                        Spacer()
                        ForEach(0..<viewModel.ongoingPrograms.count, id: \.self) { index in
                            Circle()
                                .fill(index == viewModel.currentProgramIndex ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        viewModel.selectProgram(at: index)
                                    }
                                }
                        }
                        Spacer()
                    }
                }
            }
            .frame(height: 200)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Gem Card Component
struct GemCard: View {
    let program: Program
    let progress: ProgramProgress?
    let isSelected: Bool
    let isAnimating: Bool
    
    var body: some View {
        let gemSize: CGFloat = isSelected ? 162 : 72  // 10% 줄임
        
        VStack(spacing: isSelected ? 16 : 0) {
            // Gem 3D 시각화
            ZStack(alignment: .top) {
                // Shadow effect
                Ellipse()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color("railroad_front").opacity(0.6),
                                Color.black.opacity(0.8)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: isSelected ? 108 : 72, height: isSelected ? 36 : 22)  // 10% 줄임
                    .offset(y: isSelected ? 108 : 59)  // 10% 줄임
                    .opacity(isSelected ? 1.0 : 0.6)  // 선택되지 않은 경우 투명도 조정
                
                VStack(spacing: 0) {
                    // Gem image with Gradient & Overlay
                    ZStack {
                        // 1. Base image
                        if let imageName = getShapeImageName(for: program) {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: gemSize, height: gemSize)
                        } else {
                            Image(systemName: "cube.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: gemSize, height: gemSize)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        
                        // 2. Radial gradient overlay
                        let improvementRate = progress?.improvementRate ?? 0.5
                        
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(improvementRate * 0.8 + 0.2), // 진행도가 높을수록 중앙 밝음
                                Color.black.opacity(0.5)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: isSelected ? 81 : 54
                        )
                        .opacity(improvementRate * 0.8 + 0.2) // improvementRate에 따라 밝기 조절 (0.2 ~ 1.0)
                        .mask(
                            Group {
                                if let imageName = getShapeImageName(for: program) {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                } else {
                                    Image(systemName: "cube.fill")
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                        )
                        
                        // 3. Linear gradient overlay (theme-based colors)
                        LinearGradient(
                            gradient: Gradient(colors: getThemeBasedGradientColors(for: program)),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(improvementRate * 0.6 + 0.2) // improvementRate에 따라 전체 opacity 조절
                        .mask(
                            Group {
                                if let imageName = getShapeImageName(for: program) {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                } else {
                                    Image(systemName: "cube.fill")
                                        .resizable()
                                        .scaledToFit()
                                }
                            }
                        )
                    }
                    .frame(width: gemSize, height: gemSize)
                    .scaleEffect(isSelected && isAnimating ? 1.05 : 0.95)
                    .offset(y: isSelected && isAnimating ? -12 : 0)
                }
            }
            
            // Program name (only for selected gem)
            // if isSelected {
            //     Text(program.name)
            //         .font(.pip.body)
            //         .foregroundColor(.white)
            //         .lineLimit(2)
            //         .multilineTextAlignment(.center)
            //         .padding(.horizontal, 16)
            // }
        }
        .opacity(isSelected ? 1.0 : 0.6)
    }
    
    /// Get 3D shape image name from Assets
    private func getShapeImageName(for program: Program) -> String? {
        let shapeId = (abs(program.id.hashValue) % 15) + 1
        return "3d_shape_\(shapeId)"
    }
    
    /// Convert ColorTheme to SwiftUI Color
    private func getColorFromTheme(_ theme: ColorThemeForGoal) -> Color {
        switch theme {
        case .teal:
            return Color(red: 0.08, green: 0.72, blue: 0.65) // #14B8A6
        case .amber:
            return Color(red: 0.96, green: 0.62, blue: 0.06) // #F59E0B
        case .tiger:
            return Color(red: 1.0, green: 0.42, blue: 0.21) // #FF6B35
        case .blue:
            return Color(red: 0.23, green: 0.51, blue: 0.96) // #3B82F6
        }
    }
    
    /// Return theme-based gradient colors for each gem
    private func getThemeBasedGradientColors(for program: Program) -> [Color] {
        if let gradientColors = program.gemVisualization.gradientColors, !gradientColors.isEmpty {
            return gradientColors.compactMap { ColorThemeForGoal(rawValue: $0) }.map { getColorFromTheme($0) }
        }
        
        // Fallback to a default gradient if colors are not available
        let fallbackColor = getColorFromTheme(program.gemVisualization.colorTheme)
        return [fallbackColor.opacity(0.7), fallbackColor.opacity(0.9)]
    }
}

#Preview {
    GemVizSection(viewModel: GoalViewModel())
        .background(Color.black)
}

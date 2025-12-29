import SwiftUI

/// Gem 시각화 뷰 (3개 젬 동시 표시, 중앙 선택 강조)
///
/// 레이아웃:
/// 1. **3개 젬 동시 표시**: 좌우 비선택 + 중앙 선택
/// 2. **화면 너비 활용**: GeometryReader로 동적 레이아웃
/// 3. **드래그 스냅핑**: Phaser Snapping으로 자연스러운 전환
/// 4. **선택된 젬 강조**: 가운데 크게, 색상 오버레이 적용
/// 5. **비선택 젬**: 뒤로 투명도 높여 표시
/// 6. **List Indicator (점)**: 하단 페이지 표시
struct GemVizSection: View {
    @ObservedObject var viewModel: GoalViewModel
    @State private var isAnimating = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .center, spacing: 5) {
            // MARK: - 3개 Gem 동시 표시 with Navigation Buttons and Drag Gesture
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
                            // 좌측 젬 (비선택)
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
                            
                            // 중앙 젬 (선택)
                            GemCard(
                                program: viewModel.ongoingPrograms[viewModel.currentProgramIndex],
                                progress: viewModel.programProgress[viewModel.ongoingPrograms[viewModel.currentProgramIndex].id.uuidString],
                                isSelected: true,
                                isAnimating: isAnimating
                            )
                            .offset(x: dragOffset)
                            .zIndex(2)
                            
                            // 우측 젬 (비선택)
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
                                    
                                    // Threshold와 velocity를 고려한 스냅핑 (순환)
                                    if value.translation.width > threshold || velocity > 50 {
                                        // 우측으로 스와이프 - 이전 프로그램 (순환)
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            let newIndex = (viewModel.currentProgramIndex - 1 + viewModel.ongoingPrograms.count) % viewModel.ongoingPrograms.count
                                            viewModel.selectProgram(at: newIndex)
                                            dragOffset = 0
                                        }
                                    } else if value.translation.width < -threshold || velocity < -50 {
                                        // 좌측으로 스와이프 - 다음 프로그램 (순환)
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            let newIndex = (viewModel.currentProgramIndex + 1) % viewModel.ongoingPrograms.count
                                            viewModel.selectProgram(at: newIndex)
                                            dragOffset = 0
                                        }
                                    } else {
                                        // 스냅 백
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
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
        let gemSize: CGFloat = isSelected ? 180 : 80  // 뒤에 있는 젬 더 작게
        
        VStack(spacing: isSelected ? 16 : 0) {
            // Gem 3D 시각화
            ZStack(alignment: .top) {
                // 그림자 효과
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
                    .frame(width: isSelected ? 120 : 80, height: isSelected ? 40 : 24)  // 높이 줄임
                    .offset(y: isSelected ? 120 : 65)  // 선택된 젬 ellipse 거리 늘림
                    .opacity(isSelected ? 1.0 : 0.6)  // 선택되지 않은 경우 투명도 조정
                
                VStack(spacing: 0) {
                    // Gem 이미지 with Gradient & Overlay
                    ZStack {
                        // 1. 기본 이미지
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
                        
                        // 2. 방사형 그라데이션 오버레이
                        let programColor = getColorFromTheme(program.gemVisualization.colorTheme)
                        let improvementRate = progress?.improvementRate ?? 0.5
                        
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(improvementRate * 0.8 + 0.2), // 진행도가 높을수록 중앙 밝음
                                Color.black.opacity(0.5)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: isSelected ? 90 : 60
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
                        
                        // 3. 선형 그라데이션 오버레이 (랜덤 색상)
                        LinearGradient(
                            gradient: Gradient(colors: getRandomGradientColors(for: program)),
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
            
            // 프로그램 이름 (선택된 젬만 표시)
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
    
    /// Assets에서 3D Shape 이미지 이름 가져오기
    private func getShapeImageName(for program: Program) -> String? {
        let shapeId = (abs(program.id.hashValue) % 15) + 1
        return "3d_shape_\(shapeId)"
    }
    
    /// ColorTheme를 SwiftUI Color로 변환
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
    
    /// 각 젬마다 랜덤 색상 선형 그라데이션 색상 반환
    private func getRandomGradientColors(for program: Program) -> [Color] {
        let seed = abs(program.id.hashValue)
        return [
            randomColor(seed: seed),
            randomColor(seed: seed + 1),
            randomColor(seed: seed + 2)
        ]
    }
    
    /// 시드를 사용한 랜덤 색상 생성
    private func randomColor(seed: Int) -> Color {
        srand48(seed)
        return Color(red: drand48(), green: drand48(), blue: drand48())
    }
}

#Preview {
    GemVizSection(viewModel: GoalViewModel())
        .background(Color.black)
}

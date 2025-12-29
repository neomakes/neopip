import SwiftUI

/// Gem 시각화 뷰 (진행 중인 프로그램별 3D Shape 기반)
///
/// 레이아웃:
/// 1. **기본 이미지**: Assets의 3d_shape_{1..15} 이미지
/// 2. **방사형 그라데이션 오버레이**: 중심(흰색) → 가장자리(검은색)
///    - opacity = brightness (프로그램 진행률)
/// 3. **선형 그라데이션 오버레이**: 3개 색상 blend
///    - colorGradient 기반 (프로그램 특성)
/// 4. **색상 테두리 stroke**: colorGradient 색상 사용
///
/// 시각적 의미:
/// - brightness (방사형 opacity): 프로그램 진행률
/// - colorGradient: 프로그램의 고유 특징
/// - shapeAssetId: 프로그램별 고유 3D Shape (1~15)
struct GemVizSection: View {
    @ObservedObject var viewModel: GoalViewModel
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // MARK: - Header
            HStack {
                Text("Active Program")
                    .font(.pip.title2)
                    .foregroundColor(.white)
                
                Spacer()
                
                if !viewModel.ongoingPrograms.isEmpty {
                    Text("\(viewModel.currentProgramIndex + 1)/\(viewModel.ongoingPrograms.count)")
                        .font(.pip.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            
            // MARK: - Gem Visualization Area
            VStack {
                if !viewModel.ongoingPrograms.isEmpty {
                    let program = viewModel.ongoingPrograms[viewModel.currentProgramIndex]
                    let progress = viewModel.currentProgramProgress()
                    
                    // ZStack: 그림자가 뒤에, Gem이 위에 오도록 배치
                    ZStack(alignment: .top) {
                        // 그림자 효과 (타원)
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
                            .frame(width: 150, height: 60)
                            .offset(y: 170)
                        
                        VStack(spacing: 0) {
                            // Gem 이미지
                            ZStack {
                                // 1. 기본 이미지 (3d_shape_{shapeAssetId})
                                if let imageName = getShapeImageName(for: program) {
                                    Image(imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 240, height: 240)
                                } else {
                                    // Fallback: placeholder
                                    Image(systemName: "cube.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 240, height: 240)
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                                
                                // 2. 방사형 그라데이션 오버레이 (brightness 기반)
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.7),
                                        Color.black
                                    ]),
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 120
                                )
                                .opacity((progress?.improvementRate ?? 0.5) * (isAnimating ? 0.7 : 1.0))
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
                                
                                // 3. 선형 그라데이션 오버레이 (colorGradient 기반)
                                if let progress = progress, !progress.radarChartData.isEmpty {
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.accentColor.opacity(0.6),
                                            Color.accentColor.opacity(0.3)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .opacity(0.25 * (isAnimating ? 0.7 : 1.0))
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
                            }
                            .frame(width: 240, height: 240)
                            .scaleEffect(isAnimating ? 1.05 : 0.95)
                            .offset(y: isAnimating ? -15 : 0)
                        }
                    }
                    
                    // Program Info
                    VStack(spacing: 8) {
                        Text(program.name)
                            .font(.pip.body)
                            .foregroundColor(.white)
                        
                        if let progress = progress {
                            HStack(spacing: 12) {
                                ProgressView(value: progress.improvementRate)
                                    .tint(.accentColor)
                                
                                Text(String(format: "%.0f%%", progress.improvementRate * 100))
                                    .font(.pip.caption)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                            isAnimating = true
                        }
                    }
                    
                } else {
                    // No programs
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                        
                        VStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                            
                            Text("No Active Program")
                                .font(.pip.body)
                                .foregroundColor(.gray)
                            
                            Text("Select a program to get started")
                                .font(.pip.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(height: 240)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 16)
    }
    
    /// Assets에서 3D Shape 이미지 이름 가져오기
    private func getShapeImageName(for program: Program) -> String? {
        // Mock: 프로그램ID 기반 1~15 범위의 shapeAssetId로 매핑
        let shapeId = (program.id.hashValue % 15) + 1
        return "3d_shape_\(shapeId)"
    }
    
    /// Hex 색상 문자열을 SwiftUI Color로 변환
    private func colorFromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        
        guard hex.count == 6 else {
            return Color.gray
        }
        
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        
        guard scanner.scanHexInt64(&rgbValue) else {
            return Color.gray
        }
        
        let red = Double((rgbValue >> 16) & 0xFF) / 255.0
        let green = Double((rgbValue >> 8) & 0xFF) / 255.0
        let blue = Double(rgbValue & 0xFF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
}

#Preview {
    GemVizSection(viewModel: GoalViewModel())
        .background(Color.black)
}

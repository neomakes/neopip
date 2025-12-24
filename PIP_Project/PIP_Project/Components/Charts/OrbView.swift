import SwiftUI

/// Orb 시각화 컴포넌트 (3D Liquid Water Droplet)
/// Canvas API를 사용하여 물방울 형태의 Orb를 렌더링합니다.
/// 
/// Parameters:
/// - brightness: 내부 광도 (0.0 ~ 1.0) - 사용자 모델 재생성 성능
/// - borderBrightness: 테두리 광도 (0.0 ~ 1.0) - 예측 정확도
/// - complexity: 기하학적 복잡도 (1 ~ 10)
/// - uncertainty: 블러 정도 (0.0 ~ 1.0)
/// - colorGradient: 색상 배열 [색1, 색2, 색3] (16진수)
struct OrbView: View {
    let brightness: Double
    let borderBrightness: Double
    let complexity: Int
    let uncertainty: Double
    let colorGradient: [String]
    
    @State private var rotation: Double = 0
    @State private var pulse: Double = 0
    
    var body: some View {
        ZStack {
            // 배경
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 280, height: 280)
            
            // 하단 그림자 (3D 효과)
            Ellipse()
                .fill(Color.black.opacity(0.4))
                .frame(width: 200, height: 60)
                .blur(radius: 20)
                .offset(y: 130)
            
            // 메인 Orb
            ZStack {
                // 1. 배경 그라데이션 (brightness 적용)
                let colors = parseColorGradient(colorGradient)
                let gradientColors = colors.map { color in
                    color.opacity(brightness * 0.8)
                }
                
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: gradientColors),
                            center: UnitPoint(x: 0.4, y: 0.3),
                            startRadius: 0,
                            endRadius: 120
                        )
                    )
                
                // 2. 노이즈 기반 반점들 추가 (물방울 표면 불규칙성)
                ForEach(0..<complexity, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(0.1 * Double(complexity - index) / Double(complexity)))
                        .frame(width: 20 + CGFloat(index) * 5, height: 20 + CGFloat(index) * 5)
                        .offset(
                            x: CGFloat(cos(Double(index) * .pi / Double(complexity))) * 50,
                            y: CGFloat(sin(Double(index) * .pi / Double(complexity))) * 50
                        )
                }
                
                // 3. 테두리 (borderBrightness)
                Circle()
                    .stroke(
                        colors.first?.opacity(borderBrightness * 0.6) ?? Color.white.opacity(0.3),
                        lineWidth: 3
                    )
                
                // 4. 하이라이트 (물 속 광선)
                Circle()
                    .fill(Color.white.opacity(0.3 * brightness))
                    .frame(width: 60, height: 60)
                    .offset(x: -40, y: -50)
                
                // 5. 추가 광선 효과
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colors.first?.opacity(borderBrightness * 0.3) ?? Color.white.opacity(0.2),
                                Color.clear
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
            .frame(width: 240, height: 240)
            .rotationEffect(.degrees(rotation))
            .blur(radius: uncertainty * 15)
        }
        .frame(width: 280, height: 280)
        .onAppear {
            // 회전 애니메이션
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            
            // 맥박 애니메이션
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulse = 0.3
            }
        }
    }
    
    // MARK: - 색상 파싱
    private func parseColorGradient(_ gradient: [String]) -> [Color] {
        return gradient.map { colorString in
            let hex = colorString.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
            let rgb = Int(hex, radix: 16) ?? 0
            
            let red = Double((rgb >> 16) & 0xFF) / 255.0
            let green = Double((rgb >> 8) & 0xFF) / 255.0
            let blue = Double(rgb & 0xFF) / 255.0
            
            return Color(red: red, green: green, blue: blue)
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color(red: 0.05, green: 0.05, blue: 0.08)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        VStack(spacing: 40) {
            Text("Orb Visualization")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 30) {
                // High brightness, high prediction accuracy
                VStack(spacing: 8) {
                    Text("High Confidence")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    OrbView(
                        brightness: 0.85,
                        borderBrightness: 0.95,
                        complexity: 7,
                        uncertainty: 0.15,
                        colorGradient: ["#82EBEB", "#40DBDB", "#31B0B0"]
                    )
                }
                
                // Low brightness, medium accuracy
                VStack(spacing: 8) {
                    Text("Medium Confidence")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    OrbView(
                        brightness: 0.65,
                        borderBrightness: 0.70,
                        complexity: 5,
                        uncertainty: 0.30,
                        colorGradient: ["#FF6600", "#FFB300", "#FFD700"]
                    )
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

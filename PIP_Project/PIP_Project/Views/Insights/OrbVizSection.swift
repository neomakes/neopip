import SwiftUI

struct OrbVizSection: View {
    @ObservedObject var viewModel: InsightViewModel
    
    @State private var rotation: Double = 0
    @State private var pulse: Double = 0
    
    var body: some View {
        Group {
            if let orbViz = viewModel.orbVisualization {
                ZStack {
                    // 배경
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .frame(width: 200, height: 200)
                    
                    // 하단 그림자 (3D 효과)
                    Ellipse()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 200, height: 45)
                        .blur(radius: 10)
                        .offset(y: 130)
                    
                    // 메인 Orb
                    ZStack {
                        // 1. 배경 그라데이션 (brightness 적용)
                        let colors = parseColorGradient(orbViz.colorGradient)
                        let gradientColors = colors.map { color in
                            color.opacity(orbViz.brightness * 0.8)
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
                        ForEach(0..<orbViz.complexity, id: \.self) { index in
                            Circle()
                                .fill(Color.white.opacity(0.1 * Double(orbViz.complexity - index) / Double(orbViz.complexity)))
                                .frame(width: 20 + CGFloat(index) * 5, height: 20 + CGFloat(index) * 5)
                                .offset(
                                    x: CGFloat(cos(Double(index) * .pi / Double(orbViz.complexity))) * 50,
                                    y: CGFloat(sin(Double(index) * .pi / Double(orbViz.complexity))) * 50
                                )
                        }
                        
                        // 3. 테두리 (borderBrightness)
                        Circle()
                            .stroke(
                                colors.first?.opacity(orbViz.borderBrightness * 0.6) ?? Color.white.opacity(0.3),
                                lineWidth: 3
                            )
                        
                        // 4. 하이라이트 (물 속 광선)
                        Circle()
                            .fill(Color.white.opacity(0.3 * orbViz.brightness))
                            .frame(width: 60, height: 60)
                            .offset(x: -40, y: -50)
                        
                        // 5. 추가 광선 효과
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        colors.first?.opacity(orbViz.borderBrightness * 0.3) ?? Color.white.opacity(0.2),
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
                    .blur(radius: orbViz.uncertainty * 15)
                }
                .frame(width: 168, height: 168)
                .scaleEffect(0.85)
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
            } else {
                ProgressView()
                    .frame(width: 168, height: 168)
            }
        }
    }
    
    // MARK: - Color Parsing
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
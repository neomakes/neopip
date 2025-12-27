import SwiftUI

/// Orb 시각화 뷰 (Assets 이미지 기반 + 방사형/선형 그라데이션 오버레이)
///
/// 레이아웃:
/// 1. **기본 이미지**: Assets의 liquid_orb 이미지
/// 2. **방사형 그라데이션 오버레이**: 중심(흰색) → 가장자리(검은색)
///    - opacity = brightness (예측 정확도)
/// 3. **선형 그라데이션 오버레이**: 3개 색상 blend
///    - colorGradient 기반 (고유 특징)
/// 4. **색상 테두리 stroke**: colorGradient 색상 사용
///    - opacity = borderBrightness (예측 불확실성)
///
/// 시각적 의미:
/// - brightness (방사형 opacity): 모델의 예측 정확도
/// - borderBrightness (테두리 opacity): 예측 불확실성
/// - colorGradient: 사용자의 고유 특징
struct OrbVizSection: View {
    @ObservedObject var viewModel: InsightViewModel
    
    var body: some View {
        Group {
            if let orbViz = viewModel.orbVisualization {
                // ZStack: 그림자가 뒤에, Orb가 위에 오도록 배치
                ZStack(alignment: .top) {
                    // 그림자 효과 (타원) - RailroadView의 Gem 그림자와 동일 방식
                    Ellipse()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color("railroad_front"),
                                    Color.black.opacity(1.0)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 150, height: 60)
                        .offset(y: 170)  // Orb 아래에 배치
                    
                    VStack(spacing: 0) {
                        // Orb 이미지
                        ZStack {
                            // 1. 기본 이미지 (liquid_orb)
                            Image("liquid_orb")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 240, height: 240)
                            
                            // 2. 방사형 그라데이션 오버레이 (brightness 기반)
                            // 중심: 연한 회색(밝음) → 가장자리: 검은색(어두움)
                            // mask: 이미지 범위 내에서만 표시
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(white: 0.7),  // 중심: 연한 회색
                                    Color.black         // 가장자리: 검은색
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 120
                            )
                            .opacity(orbViz.brightness)  // 예측 정확도에 따라
                            .mask(
                                Image("liquid_orb")
                                    .resizable()
                                    .scaledToFit()
                            )
                            
                            // 3. 선형 그라데이션 오버레이 (colorGradient 기반)
                            // 3개 색상으로 선형 그라데이션
                            // mask: 이미지 범위 내에서만 표시
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    colorFromHex(orbViz.colorGradient[0]),
                                    colorFromHex(orbViz.colorGradient[1]),
                                    colorFromHex(orbViz.colorGradient[2])
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .opacity(0.25)  // 투명도 높임 (고유 색상의 미묘한 표현)
                            .mask(
                                Image("liquid_orb")
                                    .resizable()
                                    .scaledToFit()
                            )
                        }
                        .frame(width: 240, height: 240)
                    }
                }
                
            } else {
                // 로딩 상태
                ProgressView()
                    .frame(width: 240, height: 240)
            }
        }
    }
    
    /// Hex 색상 문자열을 SwiftUI Color로 변환
    /// - Parameter hex: "#RRGGBB" 형식의 문자열
    /// - Returns: SwiftUI Color
    private func colorFromHex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        
        guard hex.count == 6 else {
            return Color.gray  // 기본값
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

import Foundation
import SwiftUI

// MARK: - Color Utility
/// 색상 생성 및 관련 유틸리티
struct ColorUtility {
    /// uniqueFeatures로부터 3개의 색상 그라데이션을 생성합니다.
    /// - Parameter uniqueFeatures: [String: Double] 형태의 고유 특징값들 (각 값은 0.0 ~ 1.0)
    /// - Returns: 3개의 16진 색상 코드 배열 (예: ["#82EBEB", "#40DBDB", "#31B0B0"])
    static func generateColorGradient(from uniqueFeatures: [String: Double]) -> [String] {
        // 최상위 3개의 Feature 추출
        let sortedFeatures = uniqueFeatures
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.value }
        
        // Feature 값이 3개 미만인 경우 처리
        let paddedFeatures: [Double] = {
            var features = sortedFeatures
            while features.count < 3 {
                features.append(Double.random(in: 0.3...0.8))
            }
            return Array(features)
        }()
        
        // 각 Feature 값을 색상으로 변환
        let colors = paddedFeatures.map { featureValue in
            hslToHex(
                hue: featureValue * 360.0,    // 0~360도로 매핑
                saturation: 0.7,               // 채도 고정 (70%)
                lightness: 0.6                 // 명도 고정 (60%)
            )
        }
        
        return colors
    }
    
    /// HSL 색상을 16진 코드로 변환합니다.
    /// - Parameters:
    ///   - hue: 색조 (0 ~ 360도)
    ///   - saturation: 채도 (0 ~ 1.0)
    ///   - lightness: 명도 (0 ~ 1.0)
    /// - Returns: 16진 색상 코드 (예: "#82EBEB")
    private static func hslToHex(hue: Double, saturation: Double, lightness: Double) -> String {
        let c = (1 - abs(2 * lightness - 1)) * saturation
        let x = c * (1 - abs((hue / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = lightness - c / 2
        
        var r: Double = 0
        var g: Double = 0
        var b: Double = 0
        
        switch hue {
        case 0..<60:
            r = c; g = x; b = 0
        case 60..<120:
            r = x; g = c; b = 0
        case 120..<180:
            r = 0; g = c; b = x
        case 180..<240:
            r = 0; g = x; b = c
        case 240..<300:
            r = x; g = 0; b = c
        default: // 300..<360
            r = c; g = 0; b = x
        }
        
        let red = UInt8((r + m) * 255)
        let green = UInt8((g + m) * 255)
        let blue = UInt8((b + m) * 255)
        
        return String(format: "#%02X%02X%02X", red, green, blue)
    }
    
    /// 16진 색상 코드를 SwiftUI Color로 변환합니다.
    /// - Parameter hex: 16진 색상 코드 (예: "#82EBEB")
    /// - Returns: SwiftUI Color
    static func hexToColor(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        
        var rgbValue: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgbValue)
        
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0xFF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0xFF) / 255.0
        
        return Color(red: red, green: green, blue: blue)
    }
    
    /// 색상 배열을 SwiftUI Gradient로 변환합니다.
    /// - Parameter hexColors: 16진 색상 코드 배열
    /// - Returns: SwiftUI Gradient
    static func createGradient(from hexColors: [String]) -> Gradient {
        let colors = hexColors.map { hexToColor($0) }
        return Gradient(colors: colors)
    }
}

// MARK: - Extension: Color
extension Color {
    /// 주어진 opacity를 적용한 색상을 반환합니다.
    func withOpacity(_ opacity: Double) -> Color {
        return self.opacity(opacity)
    }
}

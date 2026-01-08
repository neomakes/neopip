//
//  GemView.swift
//  PIP_Project
//
//  Gem 시각화 컴포넌트: DailyGem 데이터를 기반으로 동적 렌더링
//

import SwiftUI

/// Gem 시각화 메인 컴포넌트
/// 실제 gem 이미지 Asset을 사용하여 표시
struct GemView: View {
    let gem: DailyGem
    let size: CGFloat
    
    init(gem: DailyGem, size: CGFloat = 100) {
        self.gem = gem
        self.size = size
    }
    
    var body: some View {
        // 날짜 기반으로 gem 이미지 순환 (gem_1 ~ gem_18)
        let gemImageName = getGemImageName(for: gem.date)
        
        Image(gemImageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .opacity(gem.brightness) // 데이터 완성도에 따라 투명도 조절
            .overlay(
                // 불확실성에 따른 네온 효과
                RoundedRectangle(cornerRadius: size / 2)
                    .stroke(
                        getThemeColor(gem.colorTheme).opacity(gem.uncertainty * 0.5),
                        lineWidth: 2
                    )
            )
            .shadow(
                color: getThemeColor(gem.colorTheme).opacity(gem.uncertainty * 0.3),
                radius: 10,
                x: 0,
                y: size * 0.1
            )
    }
    
    /// 날짜 기반으로 gem 이미지 이름 계산 (gem_1 ~ gem_18 순환)
    /// 날짜 순서대로 gem_1, gem_2, ..., gem_18, gem_1, ... 순환
    private func getGemImageName(for date: Date) -> String {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        
        // 1970년 1월 1일부터의 일수 계산
        let epoch = calendar.startOfDay(for: Date(timeIntervalSince1970: 0))
        guard let days = calendar.dateComponents([.day], from: epoch, to: startOfDay).day else {
            return "gem_1" // 기본값
        }
        
        // 1~18 순환 (0-based index를 1-based로 변환)
        let gemIndex = (days % 18) + 1
        return "gem_\(gemIndex)"
    }
    
    /// 색상 테마에 따른 색상 반환
    private func getThemeColor(_ theme: ColorTheme) -> Color {
        switch theme {
        case .teal:
            return Color(red: 0.51, green: 0.92, blue: 0.92) // #82EBEB
        case .amber:
            return Color(red: 1.0, green: 0.65, blue: 0.0) // Amber
        case .tiger:
            return Color(red: 1.0, green: 0.4, blue: 0.0) // Tiger
        case .blue:
            return Color(red: 0.0, green: 0.4, blue: 0.8) // French Blue
        }
    }
}

// MARK: - Sphere Gem View
struct SphereGemView: View {
    let brightness: Double
    let colorTheme: ColorTheme
    let uncertainty: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // 기본 구체
            Circle()
                .fill(glassGradient)
                .frame(width: size, height: size)
                .brightness(brightness - 0.3)
                .overlay(
                    Circle()
                        .stroke(themeColor.opacity(0.3), lineWidth: 2)
                )
            
            // 하이라이트
            Circle()
                .fill(
                    RadialGradient(
                        colors: [themeColor.opacity(0.4), Color.clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
            
            // 네온 그림자 (불확실성)
            Circle()
                .fill(themeColor.opacity(uncertainty * 0.3))
                .frame(width: size * 1.2, height: size * 1.2)
                .blur(radius: 10)
                .offset(y: size * 0.1)
        }
    }
    
    private var themeColor: Color {
        switch colorTheme {
        case .teal:
            return Color(red: 0.51, green: 0.92, blue: 0.92) // #82EBEB
        case .amber:
            return Color(red: 1.0, green: 0.65, blue: 0.0) // Amber
        case .tiger:
            return Color(red: 1.0, green: 0.4, blue: 0.0) // Tiger
        case .blue:
            return Color(red: 0.0, green: 0.4, blue: 0.8) // French Blue
        }
    }
    
    private var glassGradient: LinearGradient {
        LinearGradient(
            colors: [
                themeColor.opacity(0.6),
                themeColor.opacity(0.2),
                Color.white.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Diamond Gem View
struct DiamondGemView: View {
    let brightness: Double
    let colorTheme: ColorTheme
    let uncertainty: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // 다이아몬드 형태
            DiamondShape()
                .fill(glassGradient)
                .frame(width: size, height: size)
                .brightness(brightness - 0.3)
                .overlay(
                    DiamondShape()
                        .stroke(themeColor.opacity(0.3), lineWidth: 2)
                )
            
            // 하이라이트
            DiamondShape()
                .fill(
                    LinearGradient(
                        colors: [themeColor.opacity(0.4), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: size, height: size)
            
            // 네온 그림자
            DiamondShape()
                .fill(themeColor.opacity(uncertainty * 0.3))
                .frame(width: size * 1.2, height: size * 1.2)
                .blur(radius: 10)
                .offset(y: size * 0.1)
        }
    }
    
    private var themeColor: Color {
        switch colorTheme {
        case .teal: return Color(red: 0.51, green: 0.92, blue: 0.92)
        case .amber: return Color(red: 1.0, green: 0.65, blue: 0.0)
        case .tiger: return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .blue: return Color(red: 0.0, green: 0.4, blue: 0.8)
        }
    }
    
    private var glassGradient: LinearGradient {
        LinearGradient(
            colors: [
                themeColor.opacity(0.6),
                themeColor.opacity(0.2),
                Color.white.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Crystal Gem View
struct CrystalGemView: View {
    let brightness: Double
    let colorTheme: ColorTheme
    let uncertainty: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // 수정 형태 (팔각형)
            OctagonShape()
                .fill(glassGradient)
                .frame(width: size, height: size)
                .brightness(brightness - 0.3)
                .overlay(
                    OctagonShape()
                        .stroke(themeColor.opacity(0.3), lineWidth: 2)
                )
            
            // 하이라이트
            OctagonShape()
                .fill(
                    LinearGradient(
                        colors: [themeColor.opacity(0.4), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: size, height: size)
            
            // 네온 그림자
            OctagonShape()
                .fill(themeColor.opacity(uncertainty * 0.3))
                .frame(width: size * 1.2, height: size * 1.2)
                .blur(radius: 10)
                .offset(y: size * 0.1)
        }
    }
    
    private var themeColor: Color {
        switch colorTheme {
        case .teal: return Color(red: 0.51, green: 0.92, blue: 0.92)
        case .amber: return Color(red: 1.0, green: 0.65, blue: 0.0)
        case .tiger: return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .blue: return Color(red: 0.0, green: 0.4, blue: 0.8)
        }
    }
    
    private var glassGradient: LinearGradient {
        LinearGradient(
            colors: [
                themeColor.opacity(0.6),
                themeColor.opacity(0.2),
                Color.white.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Prism Gem View
struct PrismGemView: View {
    let brightness: Double
    let colorTheme: ColorTheme
    let uncertainty: Double
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // 프리즘 형태 (삼각형 기반)
            TriangleShape()
                .fill(glassGradient)
                .frame(width: size, height: size)
                .brightness(brightness - 0.3)
                .overlay(
                    TriangleShape()
                        .stroke(themeColor.opacity(0.3), lineWidth: 2)
                )
            
            // 하이라이트
            TriangleShape()
                .fill(
                    LinearGradient(
                        colors: [themeColor.opacity(0.4), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: size, height: size)
            
            // 네온 그림자
            TriangleShape()
                .fill(themeColor.opacity(uncertainty * 0.3))
                .frame(width: size * 1.2, height: size * 1.2)
                .blur(radius: 10)
                .offset(y: size * 0.1)
        }
    }
    
    private var themeColor: Color {
        switch colorTheme {
        case .teal: return Color(red: 0.51, green: 0.92, blue: 0.92)
        case .amber: return Color(red: 1.0, green: 0.65, blue: 0.0)
        case .tiger: return Color(red: 1.0, green: 0.4, blue: 0.0)
        case .blue: return Color(red: 0.0, green: 0.4, blue: 0.8)
        }
    }
    
    private var glassGradient: LinearGradient {
        LinearGradient(
            colors: [
                themeColor.opacity(0.6),
                themeColor.opacity(0.2),
                Color.white.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Custom Shapes

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        path.move(to: CGPoint(x: center.x, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: center.y))
        path.closeSubpath()
        
        return path
    }
}

struct OctagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        for i in 0..<8 {
            let angle = Double(i) * 2 * .pi / 8 - .pi / 2
            let x = center.x + radius * CGFloat(cos(angle))
            let y = center.y + radius * CGFloat(sin(angle))
            
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        
        return path
    }
}

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Preview
#Preview("Sphere Gem") {
    ZStack {
        Color.black.ignoresSafeArea()
        GemView(
            gem: DailyGem(
                id: UUID(),
                accountId: String(),
                date: Date(),
                gemType: .sphere,
                brightness: 0.8,
                uncertainty: 0.2,
                dataPointIds: [],
                colorTheme: .teal,
                createdAt: Date()
            ),
            size: 100
        )
    }
}

#Preview("Diamond Gem") {
    ZStack {
        Color.black.ignoresSafeArea()
        GemView(
            gem: DailyGem(
                id: UUID(),
                accountId: String(),
                date: Date(),
                gemType: .diamond,
                brightness: 0.7,
                uncertainty: 0.3,
                dataPointIds: [],
                colorTheme: .amber,
                createdAt: Date()
            ),
            size: 100
        )
    }
}

#Preview("Crystal Gem") {
    ZStack {
        Color.black.ignoresSafeArea()
        GemView(
            gem: DailyGem(
                id: UUID(),
                accountId: String(),
                date: Date(),
                gemType: .crystal,
                brightness: 0.75,
                uncertainty: 0.25,
                dataPointIds: [],
                colorTheme: .tiger,
                createdAt: Date()
            ),
            size: 100
        )
    }
}

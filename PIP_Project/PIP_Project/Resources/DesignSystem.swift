import SwiftUI

// MARK: - 01. Font Setting
// Pretendard 폰트 기반 일관된 타이포그래피 체계
extension UIFont {
    // Pretendard 커스텀 폰트 로더
    static func pretendard(weight: String, size: CGFloat) -> UIFont {
        let fontName = "Pretendard-\(weight)"
        if let customFont = UIFont(name: fontName, size: size) {
            return customFont
        }
        // Fallback to system font if custom font is not available
        return .systemFont(ofSize: size, weight: .regular)
    }
    
    // 자주 사용되는 Pretendard 스타일들
    static let pipHero = pretendard(weight: "ExtraBold", size: 34)
    static let pipTitle1 = pretendard(weight: "Bold", size: 24)
    static let pipTitle2 = pretendard(weight: "SemiBold", size: 18)
    static let pipSubtitle = pretendard(weight: "SemiBold", size: 16)
    static let pipBody = pretendard(weight: "Regular", size: 16)
    static let pipCaption = pretendard(weight: "Light", size: 12)
    static let pipOverline = pretendard(weight: "SemiBold", size: 10)
    static let pipButton = pretendard(weight: "SemiBold", size: 14)
}

extension Font {
    struct PIPFont {
        // 메인 헤드라인 (홈 화면 "Hi, UserName")
        static let hero = Font(UIFont.pretendard(weight: "ExtraBold", size: 34))
        
        // 섹션 타이틀
        static let title1 = Font(UIFont.pretendard(weight: "Bold", size: 24))
        
        // 서브 타이틀 (섹션 헤드, 카드 타이틀)
        static let title2 = Font(UIFont.pretendard(weight: "SemiBold", size: 18))
        
        // 강조된 바디 텍스트 (라벨, 숫자)
        static let subtitle = Font(UIFont.pretendard(weight: "SemiBold", size: 16))
        
        // 일반 본문 텍스트
        static let body = Font(UIFont.pretendard(weight: "Regular", size: 16))
        
        // 보조 텍스트 (설명, 메타 정보)
        static let caption = Font(UIFont.pretendard(weight: "Light", size: 12))
        
        // 작은 라벨 (태그, 오버라인 텍스트)
        static let overline = Font(UIFont.pretendard(weight: "SemiBold", size: 10))
        
        // 버튼 텍스트
        static let button = Font(UIFont.pretendard(weight: "SemiBold", size: 14))
    }
    
    static let pip = PIPFont.self
}

// MARK: - 02. Color Setting
extension Color {
    struct PIPColor {
        // Basic & Launch (네이밍 일관성을 위해 소문자로 시작 권장)
        let bgGrad1 = Color("bg_grad_1")
        let bgGrad2 = Color("bg_grad_2")
        let lineTabbar = Color("line_tabbar")
        
        // Tab-specific Colors
        let tabBar = TabBarColors()
        let home = HomeColors()
        let insight = InsightColors()
        let goal = GoalColors()
        let status = StatusColors()
    }
    
    struct TabBarColors {
        let addButtonGrad1 = Color("button_add_grad_1")
        let addButtonGrad2 = Color("button_add_grad_2")
        
        // Alias for consistency with HomeColors
        var buttonAddGrad1: Color { addButtonGrad1 }
        var buttonAddGrad2: Color { addButtonGrad2 }
    }
    
    struct HomeColors {
        let buttonAddGrad1 = Color("button_add_grad_1")
        let buttonAddGrad2 = Color("button_add_grad_2")
        let numRecords = Color("num_records")
        let numStreaks = Color("num_streaks")
        let railroadFront = Color("railroad_front")
        let boxGradOut = Color("box_grad_out")
        let buttonCheck = Color("button_check")
        let buttonReturn = Color("button_return")
        let textIntro = Color("text_intro")
    }
    
    struct InsightColors {
        let bgAnalsGrad1 = Color("bg_anals_grad_1")
        let bgAnalsGrad2 = Color("bg_anals_grad_2")
        let bgAnalsGrad3 = Color("bg_anals_grad_3")
        let shadowOrbGrad = Color("shadow_orb_grad")
        let textDataLabel = Color("text_data_label")
        let textScoreAnals = Color("text_score_anals")
        let textUncertainty = Color("text_uncertainty")
    }
    
    struct GoalColors {
        let bgProgGrad1 = Color("bg_prog_grad_1")
        let bgProgGrad2 = Color("bg_prog_grad_2")
        let bgProgGrad3 = Color("bg_prog_grad_3")
        let shadowGemGrad = Color("shadow_gem_grad")
        let textProgram = Color("text_program")
    }

    struct StatusColors {
        let bgBadgeGrad1 = Color("bg_badge_grad_1")
        let bgBadgeGrad2 = Color("bg_badge_grad_2")
        let bgBadgeGrad3 = Color("bg_badge_grad_3")
        let numRecords = Color("num_records")
        let numStreaks = Color("num_streaks")
        let numWins = Color("num_wins")
        let buttonSetting = Color("button_setting")
        let textHi = Color("text_hi")
    }
    
    struct GemDetailColors {
        let journalBoxBackground = Color.white.opacity(0.05)
        let journalTextColor = Color.white.opacity(0.8)
        let scrollIndicator = Color.white
    }
    
    static let pip = PIPColor()
    static let gemDetail = GemDetailColors()
}

// MARK: - Gradient Utilities
struct GradientUtils {
    /// Creates a diagonal wave gradient for InsightStoryView animations
    /// - Parameters:
    ///   - themeColor: The theme color to create gradient with
    ///   - progress: Animation progress value (0.0 - 1.0)
    /// - Returns: LinearGradient from black to theme color, with progress-based endpoint movement
    static func createWaveGradient(themeColor: Color, progress: Double) -> LinearGradient {
        // Calculate dynamic startPoint based on progress
        // Wave moves from top-left to bottom-right
        let startX = 0.0 + (progress * 0.3)  // Moves right gradually
        let startY = 0.0 + (progress * 0.3)  // Moves down gradually
        
        // Calculate dynamic endPoint
        let endX = 1.0 - (progress * 0.3)    // Moves left gradually
        let endY = 1.0 - (progress * 0.3)    // Moves up gradually
        
        return LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                themeColor.opacity(0.15)
            ]),
            startPoint: .init(x: startX, y: startY),
            endPoint: .init(x: endX, y: endY)
        )
    }
    
    /// Creates a static diagonal gradient for card backgrounds (matching AnalysisCard design)
    static func createCardGradient(themeColor: Color) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                themeColor.opacity(0.1),
                themeColor.opacity(0.2),
                themeColor.opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Creates a gradient with multiple theme colors for richer backgrounds
    static func createCardGradientWithColors(themeColors: [Color]) -> LinearGradient {
        let gradientColors = themeColors.flatMap { color in
            [color.opacity(0.1), color.opacity(0.2), color.opacity(0.3)]
        }
        return LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Creates a neon glow effect for cards
    static func createNeonGlow(themeColor: Color, scale: CGFloat = 1.0) -> some View {
        Circle()
            .fill(themeColor.opacity(0.4))
            .frame(width: 120 * scale, height: 120 * scale)
            .blur(radius: 25 * scale)
            .offset(x: 40 * scale, y: 40 * scale)
    }
}

// MARK: - 03. Layout Constants
extension CGFloat {
    enum PIPLayout {
        // TabBar
        static var fullScreenWidth: CGFloat {
            UIScreen.main.bounds.width
        }
        
        // Standard iPhone Safe Area Bottom Height (Approx 34pt)
        static var safeAreaBottomHeight: CGFloat {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            return windowScene?.windows.first?.safeAreaInsets.bottom ?? 0
        }
        
        // TabBar Height = Safe Area + Content Area (requested 4~5pt padding)
        // This ensures icons sit perfectly above the Home Indicator
        static var tabbarHeight: CGFloat {
            let iconHeight: CGFloat = 44
            let topPadding: CGFloat = 14
            let requestedBottomPadding: CGFloat = 2
            return safeAreaBottomHeight + iconHeight + topPadding + requestedBottomPadding
        }
        
        static let tabbarHorizontalPadding: CGFloat = 20
        static let tabbarCornerRadius: CGFloat = 40
        static let tabbarAddButtonSize: CGFloat = 56
        static let tabbarAddButtonCornerRadius: CGFloat = 28

        // Home Railroad
        static let railroadWidth: CGFloat = 402
        static let railroadHeight: CGFloat = 700
        
        // Home > Gem Detail View - Auto Layout Rules
        static let gemDetailTabViewMaxHeight: CGFloat = 520 // TabView 전체 높이
        static let gemDetailTabViewBottomPadding: CGFloat = 20 // 페이지 인디케이터 하단 패딩
        static let gemDetailChartBottomPadding: CGFloat = 15 // 차트 아래 페이지 인디케이터와의 거리
        static let gemDetailIndicatorHeight: CGFloat = 6 // 페이지 인디케이터 높이 (추정)
        static let gemDetailChartToIndicatorSpacing: CGFloat = 5 // 차트와 인디케이터 사이 공간
        static let gemDetailIndicatorToJournalSpacing: CGFloat = 16 // 인디케이터와 저널박스 사이 간격 (명시적 Spacer)
        static let gemDetailJournalPadding: CGFloat = 16 // 저널박스 상하 패딩
        static let gemDetailTitleToChartSpacing: CGFloat = 24 // 제목과 차트 사이 간격
        static let gemDetailNavButtonPadding: CGFloat = 10 // 네비게이션 버튼 좌우 패딩
        static let gemDetailTitleFontSize: CGFloat = 18 // Radar Chart 데이터셋 제목 폰트 크기

        // Write View
        static let writeSheetWidth: CGFloat = 380
        static let writeSheetHeight: CGFloat = 715
        static let writeSheetCornerRadius: CGFloat = 33
        static let writeTextBoxWidth: CGFloat = 339
        static let writeTextBoxHeight: CGFloat = 129
        
        // Analysis Dashboard
        static let dashBoardWidth: CGFloat = 380
        static let dashBoardHeight: CGFloat = 173
        static let dashBoardCornerRadius: CGFloat = 12.5
        
        // Gem Detail View
        static let gemDetailChartMaxWidth: CGFloat = 380
        static let gemDetailChartMaxHeight: CGFloat = 380
        static let gemDetailChartPadding: CGFloat = 20
        static let gemDetailJournalMaxHeight: CGFloat = 80 // 스크롤 인디케이터 표시를 위해 높이 감소
        static let gemDetailJournalCornerRadius: CGFloat = 16
    }
}

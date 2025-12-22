import SwiftUI

// MARK: - 01. Font Setting
extension Font {
    struct PIPFont {
        static let hero = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 24, weight: .semibold, design: .default)
        static let title2 = Font.system(size: 18, weight: .medium, design: .default)
        static let body = Font.system(size: 16, weight: .regular, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
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
        static let gemDetailTitleFontSize: CGFloat = 24
    }
}

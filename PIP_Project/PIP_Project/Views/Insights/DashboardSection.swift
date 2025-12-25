import SwiftUI
import Foundation

// MARK: - Dashboard Section
/// Dashboard 섹션 - 3개 카테고리 (Mind, Behavior, Physical)를 가로 슬라이딩으로 표시
/// Orb 시각화는 별도의 OrbVizSection 컴포넌트에서 처리
struct DashboardSection: View {
    @ObservedObject var viewModel: InsightViewModel
    @State private var selectedCategoryIndex = 0
    
    let categories = ["Mind", "Behavior", "Physical"]
    
    // 각 카테고리별 데이터 매핑
    let categoryData: [String: [(icon: String, label: String)]] = [
        "Mind": [
            (icon: "Icon_mood", label: "Mood"),
            (icon: "Icon_stress", label: "Stress"),
            (icon: "Icon_energy", label: "Energy"),
            (icon: "Icon_focus", label: "Focus")
        ],
        "Behavior": [
            (icon: "Icon_productivity", label: "Productivity"),
            (icon: "Icon_social_activity", label: "Social"),
            (icon: "Icon_digital_distraction", label: "Digital"),
            (icon: "Icon_exploration", label: "Explore")
        ],
        "Physical": [
            (icon: "Icon_sleep", label: "Sleep"),
            (icon: "Icon_fatigue", label: "Fatigue"),
            (icon: "Icon_activity", label: "Activity"),
            (icon: "Icon_nutrition", label: "Nutrition")
        ]
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            titleView
            carouselView
        }
    }
    
    private var titleView: some View {
        DashboardTitleView()
    }
    
    private var carouselView: some View {
        DashboardCarouselView(
            categories: categories,
            categoryData: categoryData,
            selectedCategoryIndex: $selectedCategoryIndex,
            viewModel: viewModel
        )
    }
}

// MARK: - Dashboard Title
struct DashboardTitleView: View {
    var body: some View {
        HStack {
            HStack(alignment: .center, spacing: 6) {
                Image("title_logo_7")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)
                
                Text("Dashboard")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Dashboard Carousel
struct DashboardCarouselView: View {
    let categories: [String]
    let categoryData: [String: [(icon: String, label: String)]]
    @Binding var selectedCategoryIndex: Int
    let viewModel: InsightViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                NavigationButton(direction: .left) {
                    selectedCategoryIndex = (selectedCategoryIndex - 1 + categories.count) % categories.count
                }
                
                DashboardCardView(
                    categories: categories,
                    categoryData: categoryData,
                    selectedCategoryIndex: $selectedCategoryIndex,
                    viewModel: viewModel
                )
                .frame(maxWidth: .infinity)
                
                NavigationButton(direction: .right) {
                    selectedCategoryIndex = (selectedCategoryIndex + 1) % categories.count
                }
            }
            
            NavigationDotsView(
                count: categories.count,
                selectedIndex: $selectedCategoryIndex
            )
        }
    }
}

// MARK: - Navigation Button
enum NavigationDirection {
    case left, right
    
    var iconName: String {
        switch self {
        case .left: return "icon_expand_left"
        case .right: return "icon_expand_right"
        }
    }
}

struct NavigationButton: View {
    let direction: NavigationDirection
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(direction.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Dashboard Card View
struct DashboardCardView: View {
    let categories: [String]
    let categoryData: [String: [(icon: String, label: String)]]
    @Binding var selectedCategoryIndex: Int
    let viewModel: InsightViewModel
    
    var body: some View {
        ZStack {
            if selectedCategoryIndex < categories.count {
                let categoryName = categories[selectedCategoryIndex]
                let items = categoryData[categoryName] ?? []
                
                DashboardCategoryCard(
                    categoryName: categoryName,
                    items: items,
                    selectedCategoryIndex: $selectedCategoryIndex,
                    categories: categories,
                    viewModel: viewModel
                )
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Category Card
struct DashboardCategoryCard: View {
    let categoryName: String
    let items: [(icon: String, label: String)]
    @Binding var selectedCategoryIndex: Int
    let categories: [String]
    let viewModel: InsightViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: iconNameForCategory(categoryName))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(categoryName)
                    .font(.PIPFont.title2)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            DashboardGridView(
                items: items,
                viewModel: viewModel
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black)
                .shadow(color: neonColorForCategory(categoryName).opacity(0.7), radius: 5, x: 4, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .gesture(
            DragGesture()
                .onEnded { value in
                    withAnimation {
                        if value.translation.width < -50 {
                            selectedCategoryIndex = (selectedCategoryIndex + 1) % categories.count
                        } else if value.translation.width > 50 {
                            selectedCategoryIndex = (selectedCategoryIndex - 1 + categories.count) % categories.count
                        }
                    }
                }
        )
    }
    
    // MARK: - Helper Functions
    private func iconNameForCategory(_ category: String) -> String {
        switch category {
        case "Mind":
            return "brain"
        case "Behavior":
            return "hand.raised"
        case "Physical":
            return "heart"
        default:
            return "circle"
        }
    }
    
    private func neonColorForCategory(_ category: String) -> Color {
        switch category {
        case "Mind":
            return .red
        case "Behavior":
            return .blue
        case "Physical":
            return .orange
        default:
            return .white
        }
    }
}

// MARK: - Grid View
struct DashboardGridView: View {
    let items: [(icon: String, label: String)]
    let viewModel: InsightViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(0..<2), id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(Array(0..<2), id: \.self) { col in
                        let index = row * 2 + col
                        if index < items.count {
                            DashboardItemCard(
                                icon: items[index].icon,
                                label: items[index].label,
                                score: Double.random(in: 40...100),
                                percentage: Bool.random() ? Double.random(in: 1...10) : -Double.random(in: 1...10),
                                uncertainty: Double.random(in: 0...100)
                            )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Navigation Dots
struct NavigationDotsView: View {
    let count: Int
    @Binding var selectedIndex: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            ForEach(Array(0..<count), id: \.self) { index in
                Circle()
                    .fill(index == selectedIndex ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .onTapGesture {
                        withAnimation {
                            selectedIndex = index
                        }
                    }
            }
            Spacer()
        }
    }
}

/// Dashboard 개별 항목 카드
struct DashboardItemCard: View {
    let icon: String
    let label: String
    let score: Double
    let percentage: Double
    let uncertainty: Double
    
    var body: some View {
        HStack(spacing: 8) {
            // 아이콘
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            
            // 설명 부분
            VStack(alignment: .leading, spacing: 2) {
                // 항목명
                Text(label)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                // 수치 부분
                HStack(spacing: 5) {
                    // 점수
                    Text(String(format: "%.0f", score))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    // 변동량 (+/-)
                    Text(String(format: "%+.0f%%", percentage))
                        .font(.system(size: 8, weight: .regular))
                        .foregroundColor(.red)
                    
                    // 불확실성
                    Text(String(format: "%.0f%%", uncertainty))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.green)
                    
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            Color.white.opacity(max(0.1, uncertainty < 0.6 ? 0.2 : 0.05)),
                            lineWidth: 1
                        )
                )
        )
    }
}


// Preview 제거 - InsightView 프리뷰에서 확인 가능

import SwiftUI

/// Analysis 섹션 - 가로 스크롤 분석 카드 (StatusView AchievementsSection 패턴)
struct AnalysisSection: View {
    let viewModel: InsightViewModel
    @State private var selectedIndex = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Analysis Title
            HStack {
                HStack(alignment: .center, spacing: 6) {
                    Image("title_logo_7")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                    
                    Text("Analysis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // MARK: - Analysis Carousel with Navigation
            if viewModel.analysisCards.isEmpty {
                // Empty state
                VStack(alignment: .center, spacing: 12) {
                    Text("분석 데이터가 준비 중입니다")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
                .padding(.horizontal, 16)
            } else {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        // Left navigation button
                        Button(action: {
                            withAnimation {
                                selectedIndex = (selectedIndex - 1 + viewModel.analysisCards.count) % viewModel.analysisCards.count
                            }
                        }) {
                            Image("icon_expand_left")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // Analysis Card Display
                        ZStack {
                            if selectedIndex < viewModel.analysisCards.count {
                                AnalysisCard(
                                    card: viewModel.analysisCards[selectedIndex]
                                )
                                .transition(.opacity)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Right navigation button
                        Button(action: {
                            withAnimation {
                                selectedIndex = (selectedIndex + 1) % viewModel.analysisCards.count
                            }
                        }) {
                            Image("icon_expand_right")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    // Navigation dots at bottom
                    HStack(spacing: 8) {
                        Spacer()
                        ForEach(0..<viewModel.analysisCards.count, id: \.self) { index in
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
                    .padding(.top, 8)
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

/// 개별 분석 카드 (네온 그로우 효과)
struct AnalysisCard: View {
    let card: InsightAnalysisCard
    
    var cardColor: Color {
        switch card.cardType {
        case .explanation:
            return Color(red: 0.51, green: 0.92, blue: 0.92)  // Teal
        case .prediction:
            return Color(red: 1.0, green: 0.65, blue: 0.0)    // Amber
        case .control:
            return Color(red: 1.0, green: 0.4, blue: 0.0)     // Tiger
        case .correlation:
            return Color(red: 0.0, green: 0.4, blue: 0.8)     // Blue
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background with gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    cardColor.opacity(0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Neon glow effect (bottom-right corner)
            Circle()
                .fill(cardColor.opacity(0.4))
                .frame(width: 120, height: 120)
                .blur(radius: 25)
                .offset(x: 40, y: 40)
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(card.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                if let subtitle = card.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Card type badge
                HStack {
                    Text(card.cardType.rawValue.capitalized)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(cardColor.opacity(0.3))
                        .cornerRadius(4)
                    
                    Spacer()
                }
            }
            .padding(16)
            
            // Border with theme color
            RoundedRectangle(cornerRadius: 12)
                .stroke(cardColor.opacity(0.5), lineWidth: 1)
        }
        .frame(height: 180)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(cardColor.opacity(0.3), lineWidth: 0.5)
        )
    }
}


// Preview 제거 - InsightView 프리뷰에서 확인 가능

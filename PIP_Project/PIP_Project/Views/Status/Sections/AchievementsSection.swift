// PIP_Project/PIP_Project/Views/Status/Sections/AchievementsSection.swift
import SwiftUI

// MARK: - Achievements Section
struct AchievementsSection: View {
    let achievements: [Achievement]
    @Binding var selectedIndex: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(alignment: .center, spacing: 6) {
                    Image("title_logo_8")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 24)
                    
                    Text("Achievements")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Achievement carousel with navigation buttons integrated
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Left navigation button
                    Button(action: {
                        withAnimation {
                            selectedIndex = (selectedIndex - 1 + achievements.count) % achievements.count
                        }
                    }) {
                        Image("icon_expand_left")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                    
                    // Achievement item
                    ZStack {
                        if selectedIndex < achievements.count {
                            let achievement = achievements[selectedIndex]
                            
                            VStack(spacing: 12) {
                                // Preview image or gradient
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: achievement.colorScheme.map { Color(hex: $0) }),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    
                                    VStack(spacing: 0) {
                                        Spacer()
                                        HStack(spacing: 0) {
                                            Spacer()
                                            Image("3d_shape_\(Int.random(in: 1...15))")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 100, height: 100)
                                                .blendMode(.screen)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                }
                                .frame(height: 100)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(achievement.title)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text(achievement.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(12)
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        withAnimation {
                                            if value.translation.width < -50 {
                                                selectedIndex = (selectedIndex + 1) % achievements.count
                                            } else if value.translation.width > 50 {
                                                selectedIndex = (selectedIndex - 1 + achievements.count) % achievements.count
                                            }
                                        }
                                    }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right navigation button
                    Button(action: {
                        withAnimation {
                            selectedIndex = (selectedIndex + 1) % achievements.count
                        }
                    }) {
                        Image("icon_expand_right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    }
                }
                
                // Navigation dots at bottom (separated from card)
                HStack(spacing: 8) {
                    Spacer()
                    ForEach(0..<achievements.count, id: \.self) { index in
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
            .padding(.horizontal, 16)
        }
    }
}
